"""Launcher 流程方法协议和抽象实现。

定义通用的 Launcher 接口，支持不同的 dmenu 替代品实现（如 Rofi），
提供统一的模板抽象层。
"""

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Protocol, runtime_checkable

from utils.exception_handler import report_exception


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
        """将业务对象转换为 Picker 上的 Entry (一行数据)"""
        ...


@runtime_checkable
class Picker(Protocol):
    """选择器协议，如 Rofi, dmenu, wofi, fuzzel 等"""

    def show(self, entries: list[Entry], config: Config) -> tuple[str, int]:
        """显示选择器并返回用户选择的结果"""
        ...

    def is_cancelled(self, returncode: int) -> bool:
        """根据返回码判断用户是否取消了选择"""
        ...


class Launcher[T: Item]:
    """Launcher 基础类，依赖于选择器接口"""

    config: Config
    picker: Picker
    item_providers: list[ItemProvider[T]]

    def __init__(self, config: Config, picker: Picker, item_providers: list[ItemProvider[T]]):
        self.config = config
        self.picker = picker
        self.item_providers = item_providers

    def handle_selection(self, selected_item: T, returncode: int = 0) -> None:
        """处理用户选择的条目

        子类可以覆盖此方法，扩展选中后要执行的动作
        """
        selected_item.run(returncode)

    def launch(self) -> None:
        """启动 launcher 的主要流程"""

        # 1. 存储 (Item, Entry) 的对应关系
        contexts: list[tuple[T, Entry]] = []

        for provider in self.item_providers:
            raw_items = provider.items(self.config)
            contexts.extend([(item, provider.to_entry(item)) for item in raw_items])

        if not contexts:
            report_exception(
                error=Exception(f"The items data is empty. (-show {','.join(self.config.show_types)})"),
                notify=True,
            )
            return

        # 2. 提取用于给 Picker 显示的 Entry 列表
        entries = [ctx[1] for ctx in contexts]

        # 3. 显示并获取选择结果
        result = self.picker.show(entries, self.config)

        if not result:
            return

        selected_text, returncode = result

        # 用户是否取消
        if self.picker.is_cancelled(returncode):
            return

        # 4. 匹配选中项并处理
        for item, entry in contexts:
            if entry.text == selected_text:
                self.handle_selection(item, returncode)
                return

        # 如果没有找到匹配项，进行错误处理
        report_exception(
            error=Exception(f"No match item: {selected_text}"),
            notify=True,
        )
