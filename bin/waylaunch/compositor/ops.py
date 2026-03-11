from __future__ import annotations

from typing import Protocol, runtime_checkable


@runtime_checkable
class WindowOps(Protocol):
    """窗口操作协议接口定义"""

    async def focus_application(self, app_id: str) -> bool:
        """聚焦特定应用"""
        ...

    async def focus_window(self, window_id: str) -> bool:
        """聚焦特定窗口"""
        ...

    async def set_window_floating(self, window_id: str, enable: bool = True) -> bool:
        """切换特定窗口浮动状态"""
        ...

    async def set_window_sticky(self, window_id: str, enable: bool) -> bool:
        """在所有工作区上显示特定窗口"""
        ...

    async def set_window_urgent(self, window_id: str, enable: bool) -> bool:
        """切换特定窗口紧急状态"""
        ...

    async def set_window_minimized(self, window_id: str) -> bool:
        """最小化特定窗口"""
        ...

    async def set_window_maximized(self, window_id: str) -> bool:
        """最大化特定窗口"""
        ...

    async def set_window_fullscreen(self, window_id: str) -> bool:
        """全屏特定窗口"""
        ...

    async def move_window_to_workspace(self, window_id: str, workspace: str) -> bool:
        """将窗口移动到指定工作区"""
        ...


@runtime_checkable
class WorkspaceOps(Protocol):
    """工作区操作协议接口定义"""

    async def focus_workspace(self, workspace: str) -> bool:
        """切换到指定工作区"""
        ...

    async def set_workspace_layout(self, workspace: str, layout: str) -> bool:
        """设置工作区布局 (如: splith, tabbed, master)"""
        ...

    async def rename_workspace(self, old_name: str, new_name: str) -> bool:
        """重命名工作区"""
        ...

    async def move_workspace_to_output(self, workspace: str, output: str) -> bool:
        """将工作区移动到指定显示器"""
        ...
