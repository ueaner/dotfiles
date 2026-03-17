"""核心协议"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Protocol, runtime_checkable

from compositor import Compositor


class Layout(StrEnum):
    MENU = "menu"  # 浮动菜单
    BOARD = "board"  # 浮动网格
    LAUNCHPAD = "launchpad"  # 全屏网格

    @classmethod
    def is_valid(cls, value: str) -> bool:
        # 检查值是否在枚举的值集合中
        return value in cls

    @classmethod
    def default(cls) -> Layout:
        return cls.MENU


@dataclass(frozen=True)
class Config:
    """Launcher 配置类

    Args:
        prompt: 提示文字（可选，默认为 "Launcher"）
        layout: 选择器布局（可选，默认为 "menu"）
        extra_args: 额外参数列表（可选，默认为空列表）
        show_types: 显示类型（可选，默认为 ["window", "drun"]）
    """

    # For Picker
    prompt: str = "Launcher"
    layout: Layout | None = None
    extra_args: list[str] = field(default_factory=list[str])
    # For Items
    show_types: list[str] = field(default_factory=list[str])
    # show_types: list[str] = field(default_factory=lambda: ["window", "drun"])


@runtime_checkable
class Item(Protocol):
    """通用条目协议，所有在 launcher 中显示的条目应遵循此协议"""

    @property
    def name(self) -> str:
        """显示名称"""
        ...

    @property
    def icon(self) -> str:
        """图标名称"""
        ...

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        """执行条目"""
        ...


@dataclass(frozen=True)
class Entry:
    """视觉表现层：定义 Picker 界面上这一行长什么样"""

    # 核心显示内容
    text: str  # 这一行显示的文本内容
    # 基础元数据 (Row Options)
    icon: str = ""  # 图标名称或路径
    meta: str = ""  # 隐藏的搜索关键词
    # 状态控制
    urgent: bool = False  # 是否标记为紧急红色 (urgent)
    active: bool = False  # 是否标记为活动蓝色 (active)
    markup: bool = False  # 是否允许 Pango Markup 标签


@runtime_checkable
class ItemProvider[T: Item](Protocol):
    """条目提供者接口"""

    @property
    def layout(self) -> Layout:
        """布局"""
        return Layout.MENU

    async def items(self, config: Config, compositor: Compositor) -> list[T]: ...

    def to_entry(self, item: T) -> Entry:
        """将业务对象转换为 Picker 上的 Entry 的默认实现"""
        return Entry(
            text=item.name,
            icon=item.icon,
        )


@runtime_checkable
class Picker(Protocol):
    """选择器协议，如 Rofi, dmenu, wofi, fuzzel 等"""

    async def show(self, entries: list[Entry], config: Config) -> tuple[int, str, int]:
        """显示选择器并返回用户选择的结果。

        Args:
            entries: 待展示的条目列表。
            config: 配置参数。

        Returns:
            一个元组，包含：
                - 选中条目的索引（从 0 开始；若未获取到或不支持获取则为 -1）。
                - 选中条目的文本内容。
                - 进程返回码（用于判断用户是正常选择、按下 Esc 还是其他异常退出）。
        """
        ...

    def is_cancelled(self, returncode: int) -> bool:
        """根据返回码判断用户是否取消了选择"""
        ...
