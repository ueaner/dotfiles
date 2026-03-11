from compositor.compositor import Compositor, DiscoveryMeta
from compositor.models import Window, Workspace


class NullAdapter(Compositor):
    """Null Compositor 实现"""

    async def start(self) -> None: ...
    async def stop(self) -> None: ...

    # --- 状态查询 ---

    @classmethod
    def metadata(cls) -> DiscoveryMeta:
        return DiscoveryMeta(desktop_names=["null"])

    async def windows(self) -> list[Window]:
        return []

    async def workspaces(self) -> list[Workspace]:
        return []

    async def focused_window(self) -> Window | None:
        return None

    async def focused_workspace(self) -> Workspace | None:
        return None

    async def first_empty_workspace(self) -> int:
        return -1

    # --- 执行命令 ---

    async def exec(self, command: list[str], workspace: str = "") -> bool:
        return True

    # --- 窗口操作 (Window Management) ---

    async def focus_application(self, app_id: str) -> bool:
        return True

    async def focus_window(self, window_id: str) -> bool:
        return True

    async def set_window_floating(self, window_id: str, enable: bool = True) -> bool:
        return True

    async def set_window_sticky(self, window_id: str, enable: bool) -> bool:
        return True

    async def set_window_urgent(self, window_id: str, enable: bool) -> bool:
        return True

    async def set_window_minimized(self, window_id: str) -> bool:
        return True

    async def set_window_maximized(self, window_id: str) -> bool:
        return True

    async def set_window_fullscreen(self, window_id: str) -> bool:
        return True

    async def move_window_to_workspace(self, window_id: str, workspace: str) -> bool:
        return True

    # --- 工作区操作 (Workspace Management) ---

    async def focus_workspace(self, workspace: str) -> bool:
        return True

    async def set_workspace_layout(self, workspace: str, layout: str) -> bool:
        return True

    async def rename_workspace(self, old_name: str, new_name: str) -> bool:
        return True

    async def move_workspace_to_output(self, workspace: str, output: str) -> bool:
        return True
