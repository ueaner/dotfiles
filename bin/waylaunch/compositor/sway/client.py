"""
Sway IPC Client (Asyncio)
=========================

一个基于 Python 3.12+ asyncio 构建的高性能、健壮的 Sway/i3 窗口管理器 IPC 客户端。

核心特性:
- 🚀 全异步无阻塞设计，基于 struct 的极速二进制报文解析。
- 🛡️ 工业级健壮性：支持带抖动的指数退避自动重连、防止内存/Task 泄漏。
- 🔄 状态保持：网络断开或 Sway 重启后，自动恢复之前的事件订阅。
- 🎨 现代 API：提供类似 Web 框架的 `@client.on("event")` 装饰器路由机制。
"""

import asyncio
import contextlib
import json
import logging
import os
import random
import struct
from collections import deque
from collections.abc import Callable, Coroutine
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path
from types import TracebackType
from typing import Any, NotRequired, Self, TypedDict, final

# ============================================================================
# 1. 常量与全局配置
# ============================================================================

logger = logging.getLogger(__name__)

SWAY_IPC_MAGIC = b"i3-ipc"
# 协议头结构: 6字节魔法字符串 (i3-ipc) + 4字节长度 (uint32) + 4字节类型 (uint32)
HEADER_STRUCT = struct.Struct("<6sII")
HEADER_SIZE = HEADER_STRUCT.size


# ============================================================================
# 2. 类型定义与异常
# ============================================================================

# 通用载荷类型：支持字节、字符串、字典或列表
type Payload = bytes | str | dict[str, Any] | list[Any]
# 事件处理器类型：接收任意参数，返回协程
type Handler = Callable[..., Coroutine[Any, Any, None]]


class SwayIpcError(Exception):
    """Sway IPC 基础异常类"""


class ConnectionError(SwayIpcError):
    """连接相关的异常"""


class ProtocolError(SwayIpcError):
    """协议解析错误（如非法的魔法字节、长度溢出等）"""


class DisconnectedError(ConnectionError):
    """在等待响应时连接意外断开"""


class CommandResult(TypedDict):
    """适用于 RUN_COMMAND / SUBSCRIBE / SEND_TICK / SYNC 消息类型的响应结果"""

    success: bool
    parse_error: NotRequired[bool]
    error: NotRequired[bool]


# ============================================================================
# 3. 协议枚举 (Enums)
# ============================================================================


class IpcMessageType(IntEnum):
    """Sway IPC command types."""

    RUN_COMMAND = 0
    GET_WORKSPACES = 1
    SUBSCRIBE = 2
    GET_OUTPUTS = 3
    GET_TREE = 4
    GET_MARKS = 5
    GET_BAR_CONFIG = 6
    GET_VERSION = 7
    GET_BINDING_MODES = 8
    GET_CONFIG = 9
    SEND_TICK = 10
    SYNC = 11
    GET_BINDING_STATE = 12
    GET_INPUTS = 100
    GET_SEATS = 101


class IpcEventType(IntEnum):
    """Sway IPC event types (OR'd with 0x80000000)."""

    WORKSPACE = 0x80000000
    OUTPUT = 0x80000001
    MODE = 0x80000002
    WINDOW = 0x80000003
    BARCONFIG_UPDATE = 0x80000004
    BINDING = 0x80000005
    SHUTDOWN = 0x80000006
    TICK = 0x80000007
    BAR_STATE_UPDATE = 0x80000014
    INPUT = 0x80000015


# ============================================================================
# 4. 数据模型 (Data Models)
# ============================================================================


@dataclass(frozen=True, slots=True)
class IpcHeader:
    """IPC message header."""

    magic: bytes
    payload_length: int
    message_type: int  # 使用 int 以同时兼容 Command 和 Event 类型

    @classmethod
    def unpack(cls, data: bytes | memoryview | bytearray) -> Self:
        """Unpack header from buffer using pre-compiled struct."""
        if len(data) < HEADER_SIZE:
            raise ProtocolError(f"Header too short: {len(data)} bytes")

        magic, length, msg_type = HEADER_STRUCT.unpack(data[:HEADER_SIZE])
        if magic != SWAY_IPC_MAGIC:
            raise ProtocolError(f"Invalid magic bytes: {magic!r}")

        return cls(magic, length, msg_type)

    def pack(self) -> bytes:
        """Pack header to bytes."""
        return HEADER_STRUCT.pack(self.magic, self.payload_length, self.message_type)


@dataclass(frozen=True, slots=True)
class IpcMessage:
    """Complete IPC message."""

    header: IpcHeader
    payload: bytes

    def decode(self) -> Any:
        """Decode payload as JSON. Handles empty payloads gracefully."""
        return json.loads(self.payload) if self.payload else {}

    @property
    def is_event(self) -> bool:
        """Fast bitwise check for event types."""
        return bool(self.header.message_type & 0x80000000)

    @property
    def event_name(self) -> str | None:
        """将底层 message_type 转换为可读的事件字符串 (如 'window', 'workspace')"""
        if not self.is_event:
            return None
        try:
            return IpcEventType(self.header.message_type).name.lower()
        except ValueError:
            return f"unknown_event_{self.header.message_type:x}"


# ============================================================================
# 5. 核心客户端 (SwayClient)
# ============================================================================


@final
class SwayClient:
    """
    Sway IPC 核心客户端。
    负责维护底层的 Unix Domain Socket 连接、多路复用命令/响应、以及并行分发事件。
    """

    __slots__ = (  # noqa: RUF023
        "_path",  # Socket 路径
        "_reader",  # 异步读取流
        "_writer",  # 异步写入流
        "_pending",  # 等待响应的 Future 队列 (多路复用核心)
        "_events",  # 待分发的事件队列
        "_wlock",  # 写入锁，保证多协程并发发送命令时不产生数据交错
        "_conn_ready",  # 连接就绪事件信号
        "_handlers",  # 事件处理器映射表: {"window": [handler1, ...]}
        "_subscriptions",  # 记录当前已订阅的事件集合 (用于重连后自动恢复)
        "_worker",  # 后台网络监工任务 (_supervisor)
        "_distributor",  # 后台事件分发任务 (_event_dispatcher)
        "_running_tasks",  # 正在执行的业务 Handler 任务集合 (防止 GC 并在停机时等待)
        "_is_running",  # 客户端运行状态标识
    )

    def __init__(self, socket_path: str | Path | None = None, buffer: int = 100) -> None:
        self._path = self._resolve_path(socket_path)
        self._reader: asyncio.StreamReader | None = None
        self._writer: asyncio.StreamWriter | None = None
        self._pending: deque[asyncio.Future[IpcMessage]] = deque()
        self._events: asyncio.Queue[IpcMessage] = asyncio.Queue(maxsize=buffer)
        self._wlock = asyncio.Lock()
        self._conn_ready = asyncio.Event()

        self._handlers: dict[str, list[Handler]] = {}
        self._subscriptions: set[str] = set()
        self._running_tasks: set[asyncio.Task[None]] = set()

        self._worker: asyncio.Task[None] | None = None
        self._distributor: asyncio.Task[None] | None = None
        self._is_running = False

    def __repr__(self) -> str:
        return (
            f"<{self.__class__.__name__} "
            f"path={self._path} "
            f"connected={self.is_connected} "
            f"pending={len(self._pending)} "
            f"handlers={sum(len(v) for v in self._handlers.values())} "
            f"subscriptions={self._subscriptions}>"
        )

    # ---------------------------------------------------------
    # 5.1 生命周期管理 (Lifecycle Management)
    # ---------------------------------------------------------

    async def __aenter__(self) -> Self:
        await self.start()
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> None:
        await self.stop()

    async def start(self) -> None:
        """启动客户端守护进程与事件分发引擎"""
        if self._is_running:
            return
        self._is_running = True

        # 启动双引擎：网络 IO 循环 & 业务事件分发循环
        self._worker = asyncio.create_task(self._supervisor())
        self._distributor = asyncio.create_task(self._event_dispatcher())

        # 等待首次连接建立完成
        await self._conn_ready.wait()

    async def stop(self) -> None:
        """优雅关闭客户端，释放所有资源并等待进行中的任务完成"""
        if not self._is_running:
            return
        self._is_running = False
        self._conn_ready.clear()  # 阻断外部继续调用 send_command

        # 1. 停止后台常驻的引擎任务
        worker, distributor = self._worker, self._distributor
        # 立即置空，防止重复取消
        self._worker = self._distributor = None

        for task in (worker, distributor):
            if task and not task.done():
                task.cancel()
                # 广泛抑制所有异常，确保主流程顺利往下走，完成清理
                with contextlib.suppress(Exception, asyncio.CancelledError):
                    await task

        # 2. 等待所有用户级的业务 Handler 执行完毕 (或强制中断)
        while self._running_tasks:
            pending = list(self._running_tasks)
            for t in pending:
                t.cancel()
            await asyncio.gather(*pending, return_exceptions=True)

        # 3. 清理底层网络 Socket
        await self._cleanup(graceful=True)

    # ---------------------------------------------------------
    # 5.2 公开 API (Public API)
    # ---------------------------------------------------------

    @property
    def is_connected(self) -> bool:
        """检查当前是否处于连接状态"""
        return self._writer is not None and not self._writer.is_closing()

    def on(self, event_type: str) -> Callable[[Handler], Handler]:
        """
        注册事件监听器的装饰器。

        示例:
            @client.on("window")
            async def handle_window(data):
                print(data)
        """

        def decorator(handler: Handler) -> Handler:
            self._handlers.setdefault(event_type.lower(), []).append(handler)
            return handler

        return decorator

    async def subscribe(self, events: list[str]) -> bool:
        """
        订阅指定事件。支持记录状态，以便在断线重连时自动恢复。

        Args:
            events: 需要订阅的事件列表，如 ["window", "workspace"]
        """
        if not events:
            return True

        res: CommandResult = await self.send_command(IpcMessageType.SUBSCRIBE, events)

        # 如果服务端确认成功，将事件加入内部订阅记录
        if res.get("success"):
            self._subscriptions.update(events)
            logger.debug(f"Subscriptions updated: {self._subscriptions}")

        return res.get("success")

    async def unsubscribe(self, events: list[str]) -> bool:
        """
        取消订阅指定事件。

        Args:
            events: 需要取消订阅的事件列表，如 ["window", "workspace"]
        """
        if not events or not set(events).intersection(self._subscriptions):
            return True

        # 重新发送完整的订阅列表
        new_subs = self._subscriptions - set(events)
        res: CommandResult = await self.send_command(IpcMessageType.SUBSCRIBE, list(new_subs))

        # 如果服务端确认成功，更新内部订阅记录
        if res.get("success"):
            self._subscriptions = new_subs
            logger.debug(f"Subscriptions updated (unsubscribed): {self._subscriptions}")

        return res.get("success")

    async def send_command(self, msg_type: IpcMessageType, payload: Payload = "") -> Any:
        """
        向 Sway 发送 IPC 命令并等待响应。

        该方法采用多路复用设计：仅在写入阶段加锁，随后利用 Future 挂起等待响应，
        允许成百上千个协程并发调用而不会阻塞网络吞吐。
        """
        await self._conn_ready.wait()
        raw_p = self._encode(payload)
        loop = asyncio.get_running_loop()
        fut = loop.create_future()

        # 1. 细粒度加锁：仅锁定写出流
        async with self._wlock:
            if not self.is_connected:
                raise DisconnectedError("Lost connection")
            self._pending.append(fut)
            try:
                header = IpcHeader(SWAY_IPC_MAGIC, len(raw_p), msg_type)
                self._writer.write(header.pack() + raw_p)  # type: ignore
                await self._writer.drain()  # type: ignore
            except Exception as e:
                with contextlib.suppress(ValueError):
                    self._pending.remove(fut)
                fut.set_exception(e)
                raise

        # 2. 锁外等待：等待 _read_loop 将结果塞入该 Future
        try:
            return (await fut).decode()
        except asyncio.CancelledError:
            with contextlib.suppress(ValueError):
                self._pending.remove(fut)
            raise

    async def get_event(self) -> Any:
        """直接从内部队列获取下一个事件（若不使用 @on 装饰器，可使用此方法进行同步式消费）"""
        return (await self._events.get()).decode()

    # ---------------------------------------------------------
    # 5.3 内部网络核心 (Internal Network Core)
    # ---------------------------------------------------------

    async def _supervisor(self) -> None:
        """
        网络守护进程。
        负责建立连接、断线重连（带 Jitter 退避机制）、以及状态自动恢复。
        """
        backoff = 0.5
        while self._is_running:
            try:
                self._reader, self._writer = await asyncio.open_unix_connection(self._path)
                backoff = 0.5

                # 重连后的状态恢复
                if self._subscriptions:
                    events_list = list(self._subscriptions)
                    await self.send_command(IpcMessageType.SUBSCRIBE, events_list)
                    logger.info(f"Auto-resubscribed to events: {events_list}")

                self._conn_ready.set()
                logger.debug(f"Connected to Sway IPC at {self._path}")

                # 阻塞直到连接被异常掐断
                await self._read_loop()

            except asyncio.CancelledError:
                # 明确处理取消：这是正常的停机信号
                logger.debug("Supervisor received cancellation")
                raise  # 重新抛出，确保 stop() 能完成
            except (OSError, asyncio.IncompleteReadError, ProtocolError) as e:
                # 可恢复的网络错误
                self._conn_ready.clear()
                if self._is_running:
                    # 指数退避算法并添加抖动，防止重连风暴
                    sleep_time = backoff + random.uniform(0, 0.5)  # noqa: S311
                    logger.warning(f"IPC Link broken ({e}). Reconnecting in {sleep_time:.2f}s...")
                    await self._cleanup()
                    await asyncio.sleep(sleep_time)
                    backoff = min(backoff * 2, 10)
            except Exception as e:
                # 未预期的错误，记录但继续运行
                logger.exception(f"Unexpected error in supervisor: {e}")
                self._conn_ready.clear()
                await self._cleanup()
                await asyncio.sleep(1)

    async def _read_loop(self) -> None:
        """纯粹的包读取循环。解包后分发至 Future 响应队列或 Event 队列。"""
        while self._is_running and self._reader:
            h_data = await self._reader.readexactly(HEADER_SIZE)
            header = IpcHeader.unpack(h_data)
            p_data = await self._reader.readexactly(header.payload_length)
            msg = IpcMessage(header, p_data)

            if msg.is_event:
                self._dispatch_raw_event(msg)
            elif self._pending:
                # Sway 的 IPC 响应是严格保序的 (FIFO)
                fut = self._pending.popleft()
                if not fut.done():
                    fut.set_result(msg)
            else:
                logger.error(f"Orphaned response received: type={msg.header.message_type}")

    def _dispatch_raw_event(self, msg: IpcMessage) -> None:
        """将事件推入缓冲区，如果缓冲满，则丢弃最老的事件以防止内存爆满"""
        try:
            self._events.put_nowait(msg)
        except asyncio.QueueFull:
            self._events.get_nowait()
            self._events.put_nowait(msg)

    async def _cleanup(self, graceful: bool = False) -> None:
        """安全地销毁底层 socket 对象，清理积压的等待队列"""
        if self._writer is None:
            return

        async with self._wlock:
            if self._writer:
                if graceful:
                    self._writer.close()
                with contextlib.suppress(OSError, asyncio.CancelledError):
                    await self._writer.wait_closed()
                self._writer = self._reader = None

        # 连接断开，必须叫醒所有正阻塞在 send_command 的协程，抛出异常
        while self._pending:
            if not (fut := self._pending.popleft()).done():
                fut.set_exception(DisconnectedError("Sway IPC link broken"))

    # ---------------------------------------------------------
    # 5.4 内部事件引擎 (Internal Event Engine)
    # ---------------------------------------------------------

    async def _event_dispatcher(self) -> None:
        """从缓冲队列中持续消费事件，并映射到用户注册的 Handler 上并行执行"""
        while self._is_running:
            try:
                msg = await self._events.get()
                if (name := msg.event_name) and (handlers := self._handlers.get(name)):
                    # 仅解码一次，分发给所有注册者
                    data = msg.decode()
                    for handler in handlers:
                        self._start_handler_task(handler, data)
                self._events.task_done()
            except asyncio.CancelledError:
                break

    def _start_handler_task(self, handler: Handler, data: dict[str, Any]) -> None:
        """为业务回调创建独立 Task，并将其纳入追踪池，防止被垃圾回收"""
        task = asyncio.create_task(self._safe_run_handler(handler, data))
        self._running_tasks.add(task)
        # 任务结束后自我移除，避免内存泄漏
        task.add_done_callback(self._running_tasks.discard)

    async def _safe_run_handler(self, handler: Handler, data: dict[str, Any]) -> None:
        """包装业务回调的执行，提供异常隔离"""
        try:
            await handler(data)
        except Exception:
            # 即便业务侧写出严重 bug，分发引擎依然坚挺
            func_name = getattr(handler, "__name__", "anonymous_handler")
            logger.exception(f"Unhandled exception in event handler '{func_name}'")

    # ---------------------------------------------------------
    # 5.5 工具方法 (Utilities)
    # ---------------------------------------------------------

    @staticmethod
    def _encode(p: Payload) -> bytes:
        """根据输入类型序列化 Payload"""
        match p:
            case dict() | list():
                return json.dumps(p).encode()
            case str():
                return p.encode()
            case bytes():
                return p

        raise TypeError(f"Invalid payload type: {type(p)}")

    @staticmethod
    def _resolve_path(p: str | Path | None) -> Path:
        """按优先级解析并定位 Sway IPC Socket 路径"""
        if isinstance(p, Path):
            return p
        if isinstance(p, str):
            return Path(p)
        if s := os.environ.get("SWAYSOCK"):
            return Path(s)
        if x := os.environ.get("XDG_RUNTIME_DIR"):  # noqa: SIM102
            if sock := next(Path(x).glob("sway-ipc.*.sock"), None):
                return sock
        raise ConnectionError(
            "Could not locate Sway IPC socket automatically. Are you running Sway?"
        )
