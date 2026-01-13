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
    """通用项目协议，所有在 launcher 中显示的项目应遵循此协议"""

    def name(self) -> str:
        """返回项目的显示名称"""
        ...

    def icon(self) -> str:
        """返回项目的图标名称"""
        ...

    def format(self) -> str:
        """格式化显示字符串"""
        ...


@runtime_checkable
class RunnableItem(Item, Protocol):
    """可执行项目协议，包含运行方法"""

    def run(self, returncode: int = 0) -> None:
        """执行项目"""
        ...


@runtime_checkable
class Picker(Protocol):
    """选择器协议，如 Rofi, dmenu, wofi, fuzzel 等"""

    def show(self, items: list[str], config: Config) -> tuple[str, int]:
        """显示选择器并返回用户选择的结果"""
        ...

    def is_cancelled(self, returncode: int) -> bool:
        """根据返回码判断用户是否取消了选择"""
        ...


class Launcher[T: RunnableItem]:
    """Launcher 基础类，依赖于选择器接口"""

    config: Config
    picker: Picker

    def __init__(self, config: Config, picker: Picker):
        self.config = config
        self.picker = picker

    def items(self) -> list[T]:
        """获取要显示的项目列表，由子类实现"""
        raise NotImplementedError

    def format(self, item: T) -> str:
        """格式化单个项目为显示字符串

        子类可以覆盖此方法，对所有的 items 进行统一格式化
        """
        return item.format()

    def handle_selection(self, selected_item: T, returncode: int = 0) -> None:
        """处理用户选择的项目

        子类可以覆盖此方法，扩展选中后要执行的动作
        """
        selected_item.run(returncode)

    def match(self, item: T, selected_name: str) -> bool:
        """匹配选中的项目，默认按名称匹配"""
        # 清理空格进行匹配，处理可能的多行显示
        item_name = " ".join(item.name().split())
        selected_clean = " ".join(selected_name.split())
        return item_name == selected_clean

    def launch(self) -> None:
        """启动 launcher 的主要流程"""
        # 1. 获取项目
        items = self.items()

        if not items:
            report_exception(
                error=Exception(f"The items data is empty. (-show {','.join(self.config.show_types)})"),
                notify=True,
            )
            return

        # 2. 格式化项目为字符串列表
        formatted_items = [self.format(item) for item in items]

        # 3. 通过选择器接口显示并获取用户选择
        result = self.picker.show(formatted_items, self.config)

        if not result:
            return

        selected_name, returncode = result

        # 用户是否取消
        if self.picker.is_cancelled(returncode):
            return

        # 4. 匹配选中项并处理
        for item in items:
            if self.match(item, selected_name):
                self.handle_selection(item, returncode)
                return

        # 如果没有找到匹配项，进行错误处理
        report_exception(
            error=Exception(f"No match item: {selected_name}"),
            notify=True,
        )
