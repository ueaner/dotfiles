from dataclasses import dataclass, field
from typing import Protocol, runtime_checkable

from compositor.models import Window, Workspace


@dataclass(frozen=True, slots=True)
class DiscoveryMeta:
    """
    Wayland 合成器探测元数据。

    Attributes:
        desktop_names: 匹配 XDG_CURRENT_DESKTOP 环境变量的字符串列表 (不区分大小写)。
        proc_names: 该合成器主进程的二进制文件名称列表（用于进程表快照匹配）。
        env_vars: 该合成器特有的环境变量名列表（如 'SWAYSOCK'）。
    """

    desktop_names: list[str]
    proc_names: list[str] = field(default_factory=list[str])
    env_vars: list[str] = field(default_factory=list[str])


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
