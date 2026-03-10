from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol, runtime_checkable

from compositor.models import Window, Workspace
from compositor.ops import WindowOps, WorkspaceOps


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
    proc_names: list[str] = field(default_factory=list)
    env_vars: list[str] = field(default_factory=list)


@runtime_checkable
class Compositor(WindowOps, WorkspaceOps, Protocol):
    """Compositor 协议接口定义"""

    async def start(self) -> None: ...
    async def stop(self) -> None: ...

    # --- 状态查询 ---

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

    # --- 执行命令 ---

    async def exec(self, command: list[str], workspace: str = "") -> bool:
        """
        执行命令。
        当工作区参数不为空时，在指定工作区执行命令。
        """
        ...
