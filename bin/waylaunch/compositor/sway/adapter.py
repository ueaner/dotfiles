import asyncio
import logging
from typing import Self

from compositor.compositor import Compositor, DiscoveryMeta
from compositor.models import Window, WindowState, Workspace, WorkspaceState
from compositor.sway.client import CommandResult, IpcMessageType, SwayClient

from .types import (
    ContainerNode,
    FullscreenMode,
    RootNode,
    SwayNode,
    WindowChangeType,
    WindowEvent,
    WorkspaceChangeType,
    WorkspaceEvent,
    WorkspaceNode,
    X11Window,
    is_container,
    is_scratchpad_workspace,
    is_workspace,
)

logger = logging.getLogger(__name__)


class SwayAdapter(Compositor):
    """Adapter for Sway window manager.

    This adapter implements the Compositor protocol using Sway's IPC.
    """

    @classmethod
    def metadata(cls) -> DiscoveryMeta:
        return DiscoveryMeta(desktop_names=["sway"], env_vars=["SWAYSOCK"], proc_names=["sway"])

    def __init__(self):
        self.client = SwayClient()
        self._window_cache: dict[str, Window] = {}
        self._workspace_cache: dict[str, Workspace] = {}
        self._window_lock = asyncio.Lock()
        self._workspace_lock = asyncio.Lock()
        self._scratchpad_cache: Workspace | None = None
        self._scratchpad_lock = asyncio.Lock()
        self._is_running = True

    async def __aenter__(self) -> Self:
        await self.start()
        return self

    async def __aexit__(self, *_) -> None:
        await self.stop()

    async def start(self) -> None:
        """启动适配器：建立连接、订阅事件、注册处理函数"""
        # 0. 启动适配器，建立连接
        await self.client.start()

        # 1. 先做一次全量同步，填充 _workspace_cache / _workspace_cache 数据
        await self.sync_full_state()

        # 2. 订阅事件
        await self.client.subscribe(["window", "workspace"])

        # 3. 注册处理函数
        @self.client.on("window")
        async def on_window_event(data: WindowEvent):  # type: ignore
            await self._process_window_event(data)

        @self.client.on("workspace")
        async def on_workspace_event(data: WorkspaceEvent):  # type: ignore
            await self._process_workspace_event(data)

    async def stop(self) -> None:
        """停止适配器"""
        await self.client.stop()

    async def _process_window_event(self, data: WindowEvent):
        change = data.get("change")
        container = data.get("container")

        id = str(container["id"])

        async with self._window_lock:
            match change:
                case WindowChangeType.NEW:
                    new_win = self._build_window(container)
                    self._window_cache[id] = new_win
                    # NOTE: 添加窗口到工作区？
                case WindowChangeType.CLOSE:
                    del self._window_cache[id]
                    # NOTE: 从工作区移除窗口？
                case WindowChangeType.TITLE:
                    win = self._window_cache.get(id)
                    if win:
                        win.name = container.get("name")
                case _:
                    # 和 Scratchpad 交互时，会连续发送多个事件
                    # 当 CLOSE 事件先到时，后续其他事件无法获取到对应的 win
                    win = self._window_cache.get(id)
                    if win:
                        win.state = self._parse_window_state(container)

    async def _process_workspace_event(self, data: WorkspaceEvent):
        change = data.get("change")
        workspace = data.get("current")
        if not workspace:
            return

        id = str(workspace["id"])

        async with self._workspace_lock:
            match change:
                case WorkspaceChangeType.INIT:
                    new_ws = self._build_workspace(workspace)
                    self._workspace_cache[id] = new_ws
                case WorkspaceChangeType.EMPTY:
                    del self._workspace_cache[id]
                case WorkspaceChangeType.RENAME:
                    ws = self._workspace_cache.get(id)
                    if ws:
                        ws.name = workspace.get("name")
                case _:
                    ws = self._workspace_cache.get(id)
                    if ws:
                        ws.state = self._parse_workspace_state(workspace)
                        ws.window_ids = [str(id) for id in workspace.get("focus", [])]

    def _parse_window_state(self, node: ContainerNode) -> WindowState:
        """
        将 Sway 节点的原始属性映射为统一的 WindowState 标志位
        """
        state = WindowState.NONE

        # 1. 基础布尔值直接映射
        if node.get("visible"):
            state |= WindowState.VISIBLE
        if node.get("focused"):
            state |= WindowState.FOCUSED
        if node.get("urgent"):
            state |= WindowState.URGENT
        if node.get("sticky"):
            state |= WindowState.STICKY

        # 2. 全屏模式
        f_mode = node.get("fullscreen_mode", FullscreenMode.NONE)
        if f_mode == FullscreenMode.WORKSPACE:
            state |= WindowState.MAXIMIZED
        elif f_mode == FullscreenMode.GLOBAL:
            state |= WindowState.FULLSCREEN

        # 3. 浮动状态
        floating_val = node.get("floating", "auto_off")
        if "on" in floating_val:
            state |= WindowState.FLOATING

        # 4. 最小化
        if node.get("scratchpad_state") != "none":
            state |= WindowState.MINIMIZED

        return state

    def _parse_workspace_state(self, node: WorkspaceNode) -> WorkspaceState:
        """
        将 Sway 节点的原始属性映射为统一的 WorkspaceState 标志位
        """
        state = WorkspaceState.NONE

        if node.get("visible"):
            state |= WorkspaceState.VISIBLE
        if node.get("focused"):
            state |= WorkspaceState.FOCUSED
        if node.get("urgent"):
            state |= WorkspaceState.URGENT
        if is_scratchpad_workspace(node):
            state |= WorkspaceState.SPECIAL

        return state

    def _build_window(self, node: ContainerNode) -> Window:
        """
        构建窗口信息

        需要为 window_properties.class 拷贝一份全小写名称的图标，到 ~/.local/share/icons 目录
        """
        # 1. 提取原始属性
        xprops: X11Window = node.get("window_properties") or {}
        node_app_id = node.get("app_id", "")
        sandbox_id = node.get("sandbox_app_id", "")
        klass = xprops.get("class", "")

        # 2. 识别 app_id (优先级：X11 Class -> Wayland app_id -> Sandbox ID)
        app_id = klass or node_app_id or sandbox_id

        # 3. 确定图标名称 (优先级：Sandbox -> app_id -> Class)
        icon = sandbox_id or node_app_id or klass

        # 4. 清洗窗口名称 (处理 BOM 和特殊前缀)
        raw_name = node.get("name") or ""
        clean_name = raw_name.lstrip("\ufeff").removeprefix(" - ")

        return Window(
            id=str(node.get("id")),
            app_id=app_id,
            name=clean_name,
            icon=icon,
            state=self._parse_window_state(node),
            is_xwayland=node.get("shell") == "xwayland",
            pid=int(node.get("pid", -1)),
        )

    def _build_workspace(self, node: WorkspaceNode) -> Workspace:
        """构建工作区信息"""
        # window_ids = [str(w["id"]) for w in (node.get("nodes", []) + node.get("floating_nodes", []))]
        window_ids = [str(id) for id in node.get("focus", [])]
        return Workspace(
            id=str(node.get("id")),
            name=str(node.get("name")),
            state=self._parse_workspace_state(node),
            num=node.get("num", -1),
            output=node.get("output", ""),
            window_ids=window_ids,
        )

    async def sync_full_state(self):
        """拉取整棵树并填充 _window_cache / _workspace_cache"""
        async with self._window_lock, self._workspace_lock, self._scratchpad_lock:
            tree: RootNode = await self.client.send_command(IpcMessageType.GET_TREE)
            win_ids: set[str] = set()
            windows: list[Window] = []
            ws_ids: set[str] = set()
            workspaces: list[Workspace] = []

            def walk(node: SwayNode) -> None:
                if is_container(node):
                    node_id = str(node.get("id"))
                    if node_id in self._window_cache:
                        win = self._window_cache[node_id]
                        win.name = node.get("name", "").lstrip("\ufeff").removeprefix(" - ")
                        win.state = self._parse_window_state(node)
                    else:
                        win = self._build_window(node)
                        self._window_cache[node_id] = win

                    win_ids.add(node_id)
                    windows.append(win)
                elif is_workspace(node):
                    node_id = str(node.get("id"))
                    if is_scratchpad_workspace(node):
                        # 没有订阅 Scratchpad 变动的事件
                        if self._scratchpad_cache:
                            self._scratchpad_cache.id = node_id
                            self._scratchpad_cache.name = node.get("name")
                            self._scratchpad_cache.state = self._parse_workspace_state(node)
                            self._scratchpad_cache.num = node.get("num", -1)
                            self._scratchpad_cache.window_ids = [str(id) for id in node.get("focus", [])]
                            self._scratchpad_cache.output = node.get("output", "")
                        else:
                            self._scratchpad_cache = self._build_workspace(node)
                    else:
                        if node_id in self._workspace_cache:
                            ws = self._workspace_cache[node_id]
                            ws.name = node.get("name")
                            ws.state = self._parse_workspace_state(node)
                            ws.num = node.get("num", -1)
                            ws.window_ids = [str(id) for id in node.get("focus", [])]
                            ws.output = node.get("output", "")
                        else:
                            ws = self._build_workspace(node)
                            self._workspace_cache[node_id] = ws

                        ws_ids.add(node_id)
                        workspaces.append(ws)

                for child in node.get("nodes", []) + node.get("floating_nodes", []):
                    walk(child)

            walk(tree)

            # 清理过期缓存
            stale_ids = set(self._window_cache.keys()) - win_ids
            for sid in stale_ids:
                del self._window_cache[sid]

            stale_ids = set(self._workspace_cache.keys()) - ws_ids
            for sid in stale_ids:
                del self._workspace_cache[sid]

    # --- 状态查询 ---

    async def windows(self) -> list[Window]:
        """获取所有窗口"""
        return list(self._window_cache.values())

    async def workspaces(self) -> list[Workspace]:
        """获取所有工作区"""
        return list(self._workspace_cache.values())

    async def focused_window(self) -> Window | None:
        """获取当前焦点窗口"""
        return next((w for w in self._window_cache.values() if w.state.is_focused), None)

    async def focused_workspace(self) -> Workspace | None:
        """获取当前焦点工作区"""
        return next((w for w in self._workspace_cache.values() if w.state.is_focused), None)

    async def first_empty_workspace(self) -> int:
        """获取首个空闲工作区编号 (num)"""
        # 1. 检查当前 focused workspace 是否为空
        focused_ws = await self.focused_workspace()
        if focused_ws and not focused_ws.window_ids:
            return focused_ws.num

        # 获取所有已存在的工作区对象
        all_ws = list(self._workspace_cache.values())

        # 2. 按 num 排序，找第一个空的 workspace
        empty_ws = next((ws for ws in sorted(all_ws, key=lambda x: x.num) if not ws.window_ids), None)
        if empty_ws:
            return empty_ws.num

        # 3. 如果都没有，返回最大 num + 1
        if all_ws:
            max_num = max(ws.num for ws in all_ws)
            return max_num + 1

        return 1  # 兜底情况：如果 cache 全空，返回编号 1

    async def exec(self, command: list[str], workspace: str = "") -> bool:
        """
        执行命令。
        当工作区参数不为空时，在指定工作区执行命令。
        """

        cmd_str = "; ".join(command)
        full_cmd = f"workspace {workspace}; exec {cmd_str}" if workspace else f"exec {cmd_str}"
        res: list[CommandResult] = await self.client.send_command(IpcMessageType.RUN_COMMAND, full_cmd)
        return res[0].get("success", False)

    async def focus_window(self, window_id: str) -> bool:
        """聚焦特定窗口"""
        cmd = f"[con_id={window_id}] focus"
        res: list[CommandResult] = await self.client.send_command(IpcMessageType.RUN_COMMAND, cmd)
        return res[0].get("success", False)
