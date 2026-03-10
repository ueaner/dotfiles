from __future__ import annotations

from dataclasses import dataclass, field
from enum import IntFlag, auto


class WindowState(IntFlag):
    """窗口状态标志"""

    # fmt: off
    NONE       = 0
    VISIBLE    = auto()  # 可见（多屏幕）
    FOCUSED    = auto()
    URGENT     = auto()
    MINIMIZED  = auto()  # Sway Scratchpad, Hyprland special:xxx
    MAXIMIZED  = auto()
    FULLSCREEN = auto()
    FLOATING   = auto()
    STICKY     = auto()  # 在所有 workspace 上显示
    # fmt: on

    @property
    def is_visible(self) -> bool:
        return WindowState.VISIBLE in self

    @property
    def is_focused(self) -> bool:
        return WindowState.FOCUSED in self

    @property
    def is_urgent(self) -> bool:
        return WindowState.URGENT in self

    @property
    def is_minimized(self) -> bool:
        return WindowState.MINIMIZED in self

    @property
    def is_maximized(self) -> bool:
        return WindowState.MAXIMIZED in self

    @property
    def is_fullscreen(self) -> bool:
        return WindowState.FULLSCREEN in self

    @property
    def is_floating(self) -> bool:
        return WindowState.FLOATING in self

    @property
    def is_sticky(self) -> bool:
        return WindowState.STICKY in self


class WorkspaceState(IntFlag):
    """工作区状态"""

    # fmt: off
    NONE    = 0
    VISIBLE = auto()  # 可见（多屏幕）
    FOCUSED = auto()  # 拥有焦点
    URGENT  = auto()  # 有紧急窗口
    SPECIAL = auto()  # 特殊工作区: Sway Scratchpad, Hyprland special:xxx
    # fmt: on

    @property
    def is_visible(self) -> bool:
        return WorkspaceState.VISIBLE in self

    @property
    def is_focused(self) -> bool:
        return WorkspaceState.FOCUSED in self

    @property
    def is_urgent(self) -> bool:
        return WorkspaceState.URGENT in self

    @property
    def is_special(self) -> bool:
        return WorkspaceState.SPECIAL in self


@dataclass(slots=True)
class Window:
    """窗口模型"""

    id: str
    app_id: str  # 不带 .desktop 后缀, Wayland: app_id, XWayland: class
    name: str
    icon: str
    state: WindowState = WindowState.NONE
    is_xwayland: bool = False
    pid: int = -1


@dataclass(slots=True)
class Workspace:
    """工作区模型"""

    id: str
    name: str
    state: WorkspaceState = WorkspaceState.NONE
    num: int = -1  # 数字编号（如果有）
    window_ids: list[str] = field(default_factory=list)
    output: str = ""  # 所在显示器
