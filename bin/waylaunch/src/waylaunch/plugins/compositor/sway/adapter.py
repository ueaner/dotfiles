import asyncio
from types import TracebackType
from typing import Self

from waylaunch.compositor import (
    Compositor,
    DiscoveryMeta,
    Window,
    WindowState,
    Workspace,
    WorkspaceState,
)
from waylaunch.core.registry import registry

from .client import CommandResult, IpcMessageType, SwayClient
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


@registry.register("sway")
class SwayAdapter(Compositor):
    """Adapter for Sway window manager.

    This adapter implements the Compositor protocol using Sway's IPC.
    """

    @classmethod
    def metadata(cls) -> DiscoveryMeta:
        """发现元数据：用于自动识别 Sway 环境"""
        return DiscoveryMeta(desktop_names=["sway"], env_vars=["SWAYSOCK"], proc_names=["sway"])

    def __init__(self) -> None:
        self.client = SwayClient()

        self._window_cache: dict[str, Window] = {}
        self._window_lock = asyncio.Lock()
        self._workspace_cache: dict[str, Workspace] = {}
        self._workspace_lock = asyncio.Lock()
        self._scratchpad_cache: Workspace | None = None
        self._scratchpad_lock = asyncio.Lock()

    # ---------------------------------------------------------
    # 1 生命周期管理 (Lifecycle Management)
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
        """启动适配器：建立连接、全量同步、订阅事件、注册事件处理函数"""
        # 1. 启动客户端，建立 IPC 连接
        await self.client.start()

        # 2. 全量同步：拉取整棵树并填充缓存
        await self.sync_full_state()

        # 2. 订阅事件
        await self.client.subscribe(["window", "workspace"])

        # 4. 注册事件处理函数
        @self.client.on("window")
        async def on_window_event(data: WindowEvent):  # type: ignore
            await self._process_window_event(data)

        @self.client.on("workspace")
        async def on_workspace_event(data: WorkspaceEvent):  # type: ignore
            await self._process_workspace_event(data)

    async def stop(self) -> None:
        """停止适配器：断开连接并清理资源"""
        await self.client.stop()

    # ==========================================================
    # 2. 状态查询 API (Compositor Protocol - Queries)
    # ==========================================================

    async def windows(self) -> list[Window]:
        """获取所有窗口列表"""
        return list(self._window_cache.values())

    async def workspaces(self) -> list[Workspace]:
        """获取所有工作区列表"""
        return list(self._workspace_cache.values())

    async def focused_window(self) -> Window | None:
        """获取当前焦点窗口"""
        return next((w for w in self._window_cache.values() if w.state.is_focused), None)

    async def focused_workspace(self) -> Workspace | None:
        """获取当前焦点工作区"""
        return next((w for w in self._workspace_cache.values() if w.state.is_focused), None)

    async def first_empty_workspace(self) -> int:
        """
        获取首个空闲工作区编号。

        策略：
        1. 优先返回当前焦点工作区（如果为空）
        2. 其次返回编号最小的空工作区
        3. 最后返回最大编号 + 1
        """
        # 1. 检查当前焦点工作区是否为空
        focused_ws = await self.focused_workspace()
        if focused_ws and not focused_ws.window_ids:
            return focused_ws.num

        # 获取所有工作区
        all_ws = list(self._workspace_cache.values())

        # 2. 按编号排序，找第一个空工作区
        empty_ws = next(
            (ws for ws in sorted(all_ws, key=lambda x: x.num) if not ws.window_ids), None
        )
        if empty_ws:
            return empty_ws.num

        # 3. 没有空的，返回最大编号 + 1
        if all_ws:
            return max(ws.num for ws in all_ws) + 1

        return 1  # 兜底：缓存为空时返回 1

    # ==========================================================
    # 3. 操作 API (Compositor Protocol - Actions)
    # ==========================================================

    async def exec(self, command: list[str], workspace: str = "") -> bool:
        """
        执行命令。

        Args:
            command: 命令及其参数列表
            workspace: 可选，指定执行的工作区
        """
        cmd_str = "; ".join(command)
        full_cmd = f"workspace {workspace}; exec {cmd_str}" if workspace else f"exec {cmd_str}"
        res: list[CommandResult] = await self.client.send_command(
            IpcMessageType.RUN_COMMAND, full_cmd
        )
        return res[0].get("success", False)

    async def focus_application(self, app_id: str) -> bool:
        """聚焦特定应用"""
        cmd = f"[app_id={app_id}] focus"
        res: list[CommandResult] = await self.client.send_command(IpcMessageType.RUN_COMMAND, cmd)
        return res[0].get("success", False)

    async def focus_window(self, window_id: str) -> bool:
        """聚焦特定窗口"""
        cmd = f"[con_id={window_id}] focus"
        res: list[CommandResult] = await self.client.send_command(IpcMessageType.RUN_COMMAND, cmd)
        return res[0].get("success", False)

    async def focus_workspace(self, workspace: str) -> bool:
        """切换到指定工作区"""
        cmd = f"workspace {workspace}"
        res: list[CommandResult] = await self.client.send_command(IpcMessageType.RUN_COMMAND, cmd)
        return res[0].get("success", False)

    # ==========================================================
    # 4. 内部实现 (Private Implementation)
    # ==========================================================

    # 4.1 事件处理 ------------------------------------------------

    async def _process_window_event(self, data: WindowEvent) -> None:
        """处理窗口事件，更新缓存"""
        change = data.get("change")
        container = data.get("container")
        if not container:
            return

        id = str(container["id"])

        async with self._window_lock:
            match change:
                case WindowChangeType.NEW:
                    self._window_cache[id] = self._build_window(container)
                case WindowChangeType.CLOSE:
                    del self._window_cache[id]
                case WindowChangeType.TITLE:
                    if win := self._window_cache.get(id):
                        win.name = container.get("name")
                case _:
                    # 其他变更：更新状态（窗口可能已关闭，需检查）
                    if win := self._window_cache.get(id):
                        win.state = self._parse_window_state(container)

    async def _process_workspace_event(self, data: WorkspaceEvent) -> None:
        """处理工作区事件，更新缓存"""
        change = data.get("change")
        workspace = data.get("current")
        if not workspace:
            return

        id = str(workspace["id"])

        async with self._workspace_lock:
            match change:
                case WorkspaceChangeType.INIT:
                    self._workspace_cache[id] = self._build_workspace(workspace)
                case WorkspaceChangeType.EMPTY:
                    del self._workspace_cache[id]
                case WorkspaceChangeType.RENAME:
                    if ws := self._workspace_cache.get(id):
                        ws.name = workspace.get("name")
                case _:
                    # 其他变更：更新状态和窗口ID列表（工作区可能已关闭，需检查）
                    if ws := self._workspace_cache.get(id):
                        ws.state = self._parse_workspace_state(workspace)
                        ws.window_ids = [str(id) for id in workspace.get("focus", [])]
                        ws.output = workspace.get("output", ws.output)

    # 4.2 全量同步 ------------------------------------------------

    async def sync_full_state(self) -> None:
        """拉取完整状态树，重建缓存"""
        async with self._window_lock, self._workspace_lock, self._scratchpad_lock:
            tree: RootNode = await self.client.send_command(IpcMessageType.GET_TREE)

            win_ids: set[str] = set()
            ws_ids: set[str] = set()

            def walk(node: SwayNode) -> None:
                """递归遍历树节点"""
                node_id = str(node.get("id"))

                # container 类型下 name = null 时，是 container 嵌套的情况
                if is_container(node) and node.get("name"):
                    self._update_window_cache(node, node_id)
                    win_ids.add(node_id)

                elif is_workspace(node):
                    if is_scratchpad_workspace(node):
                        self._update_scratchpad_cache(node, node_id)
                    else:
                        self._update_workspace_cache(node, node_id)
                        ws_ids.add(node_id)

                # 递归子节点
                children = node.get("nodes", []) + node.get("floating_nodes", [])  # type: ignore[operator]
                for child in children:
                    walk(child)

            walk(tree)
            self._purge_stale_cache(win_ids, ws_ids)

    def _purge_stale_cache(self, win_ids: set[str], ws_ids: set[str]) -> None:
        """清理过期缓存"""
        # 清理窗口
        for sid in set(self._window_cache.keys()) - win_ids:
            del self._window_cache[sid]
        # 清理工作区
        for sid in set(self._workspace_cache.keys()) - ws_ids:
            del self._workspace_cache[sid]

    # 4.3 缓存更新辅助方法 ----------------------------------------

    def _update_window_cache(self, node: ContainerNode, node_id: str) -> None:
        """更新或创建窗口缓存条目"""
        if node_id in self._window_cache:
            win = self._window_cache[node_id]
            win.name = self._clean_name(node.get("name", ""))
            win.state = self._parse_window_state(node)
        else:
            self._window_cache[node_id] = self._build_window(node)

    def _update_workspace_cache(self, node: WorkspaceNode, node_id: str) -> None:
        """更新或创建工作区缓存条目"""
        if node_id in self._workspace_cache:
            ws = self._workspace_cache[node_id]
            ws.name = node.get("name")
            ws.state = self._parse_workspace_state(node)
            ws.num = node.get("num", -1)
            ws.window_ids = [str(id) for id in node.get("focus", [])]
            ws.output = node.get("output", "")
        else:
            self._workspace_cache[node_id] = self._build_workspace(node)

    def _update_scratchpad_cache(self, node: WorkspaceNode, node_id: str) -> None:
        """更新或创建 Scratchpad 缓存条目"""
        if self._scratchpad_cache:
            sp = self._scratchpad_cache
            sp.id = node_id
            sp.name = node.get("name")
            sp.state = self._parse_workspace_state(node)
            sp.num = node.get("num", -1)
            sp.window_ids = [str(id) for id in node.get("focus", [])]
            sp.output = node.get("output", "")
        else:
            self._scratchpad_cache = self._build_workspace(node)

    # 4.4 对象构建与解析 ------------------------------------------

    def _build_window(self, node: ContainerNode) -> Window:
        """
        从 Sway 节点构建 Window 对象

        需要为 window_properties.class 拷贝一份全小写名称的图标，到 ~/.local/share/icons 目录
        """
        # 提取属性
        xprops: X11Window = node.get("window_properties") or {}
        node_app_id = node.get("app_id", "")
        sandbox_id = node.get("sandbox_app_id", "")
        klass = xprops.get("class", "")

        # 识别 app_id (优先级：X11 Class > Wayland app_id > Sandbox ID)
        app_id = klass or node_app_id or sandbox_id
        # 确定图标名称 (优先级：Sandbox ID > Wayland app_id > X11 Class)
        icon = sandbox_id or node_app_id or klass

        return Window(
            id=str(node.get("id")),
            app_id=app_id,
            name=self._clean_name(node.get("name", "")),
            icon=icon,
            state=self._parse_window_state(node),
            is_xwayland=node.get("shell") == "xwayland",
            pid=int(node.get("pid", -1)),
        )

    def _build_workspace(self, node: WorkspaceNode) -> Workspace:
        """从 Sway 节点构建 Workspace 对象"""
        # window_ids = [str(w["id"]) for w in (node.get("nodes", []) + node.get("floating_nodes", []))]
        return Workspace(
            id=str(node.get("id")),
            name=str(node.get("name")),
            state=self._parse_workspace_state(node),
            num=node.get("num", -1),
            output=node.get("output", ""),
            window_ids=[str(id) for id in node.get("focus", [])],
        )

    def _parse_window_state(self, node: ContainerNode) -> WindowState:
        """
        将 Sway 节点的原始属性映射为统一的 WindowState 标志位
        """
        state = WindowState.NONE

        # 基础标志
        if node.get("visible"):
            state |= WindowState.VISIBLE
        if node.get("focused"):
            state |= WindowState.FOCUSED
        if node.get("urgent"):
            state |= WindowState.URGENT
        if node.get("sticky"):
            state |= WindowState.STICKY

        # 全屏模式
        f_mode = node.get("fullscreen_mode", FullscreenMode.NONE)
        if f_mode == FullscreenMode.WORKSPACE:
            state |= WindowState.MAXIMIZED
        elif f_mode == FullscreenMode.GLOBAL:
            state |= WindowState.FULLSCREEN

        # 浮动状态
        floating_val = node.get("floating", "auto_off")
        if "on" in floating_val:
            state |= WindowState.FLOATING

        # 最小化（Scratchpad）
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

    def _extract_all_window_ids(self, node: WorkspaceNode | ContainerNode) -> list[str]:
        """递归提取节点及其所有子节点下的窗口 ID"""
        ids: list[str] = []
        if is_container(node):
            ids.append(str(node["id"]))

        # 递归处理普通节点和浮动节点
        children: list[WorkspaceNode | ContainerNode] = node.get("nodes", []) + node.get(
            "floating_nodes", []
        )  # type: ignore[operator]
        for child in children:
            ids.extend(self._extract_all_window_ids(child))
        return ids

    # 4.5 工具方法 ------------------------------------------------

    @staticmethod
    def _clean_name(raw_name: str) -> str:
        """清洗窗口名称：移除 BOM 和特殊前缀"""
        return raw_name.lstrip("\ufeff").removeprefix(" - ") if raw_name else raw_name
