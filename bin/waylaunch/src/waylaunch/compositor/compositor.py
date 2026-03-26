from typing import Protocol, runtime_checkable

from waylaunch.compositor.models import DiscoveryMeta, Window, Workspace


@runtime_checkable
class Compositor(Protocol):
    """Compositor 协议接口定义"""

    async def start(self) -> None: ...
    async def stop(self) -> None: ...

    # 状态查询 (Queries)

    @classmethod
    def metadata(cls) -> DiscoveryMeta:
        """Compositor 探测元数据"""
        ...

    async def windows(self) -> list[Window]:
        """获取所有窗口"""
        ...

    async def workspaces(self) -> list[Workspace]:
        """获取所有工作区"""
        ...

    async def focused_window(self) -> Window | None:
        """获取当前焦点窗口"""
        ...

    async def focused_workspace(self) -> Workspace | None:
        """获取当前焦点工作区"""
        ...

    async def first_empty_workspace(self) -> int:
        """获取首个空闲工作区编号 (num)"""
        ...

    # 命令操作 (Actions)

    async def exec(self, command: list[str], workspace: str = "") -> bool:
        """
        执行命令。

        Args:
            command: 命令及其参数列表
            workspace: 可选，指定执行的工作区
        """
        ...

    async def focus_application(self, app_id: str) -> bool:
        """聚焦特定应用"""
        ...

    async def focus_window(self, window_id: str) -> bool:
        """聚焦特定窗口"""
        ...

    async def focus_workspace(self, workspace: str) -> bool:
        """切换到指定工作区"""
        ...
