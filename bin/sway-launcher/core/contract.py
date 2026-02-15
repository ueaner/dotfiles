"""核心协议"""

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Protocol, runtime_checkable


class Theme(StrEnum):
    MENU = "menu"
    PANEL = "panel"
    LAUNCHPAD = "launchpad"

    @classmethod
    def is_valid(cls, value: str) -> bool:
        # 检查值是否在枚举的值集合中
        return value in cls._value2member_map_

    @classmethod
    def default(cls) -> Theme:
        return Theme.MENU


@dataclass(frozen=True)
class Config:
    """Launcher 配置类

    Args:
        prompt: 提示文字（可选，默认为 "Launcher"）
        theme: 主题配置（可选，默认为 "menu"）
        extra_args: 额外参数列表（可选，默认为空列表）
        show_types: 显示类型（可选，默认为 ["window", "drun"]）
    """

    # For Picker
    prompt: str = "Launcher"
    theme: Theme = Theme.default()
    extra_args: list[str] = field(default_factory=list)
    # For Items
    show_types: list[str] = field(default_factory=list)
    # show_types: list[str] = field(default_factory=lambda: ["window", "drun"])


@runtime_checkable
class Item(Protocol):
    """通用条目协议，所有在 launcher 中显示的条目应遵循此协议"""

    def name(self) -> str:
        """显示名称"""
        ...

    def icon(self) -> str:
        """图标名称"""
        ...

    def run(self, returncode: int = 0) -> None:
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

    def items(self, config: Config) -> list[T]: ...

    def to_entry(self, item: T) -> Entry:
        """将业务对象转换为 Picker 上的 Entry 的默认实现"""
        return Entry(
            text=item.name(),
            icon=item.icon(),
        )


@runtime_checkable
class Picker(Protocol):
    """选择器协议，如 Rofi, dmenu, wofi, fuzzel 等"""

    def show(self, entries: list[Entry], config: Config) -> tuple[str, int]:
        """显示选择器并返回用户选择的结果"""
        ...

    def is_cancelled(self, returncode: int) -> bool:
        """根据返回码判断用户是否取消了选择"""
        ...
