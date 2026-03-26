"""核心协议"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from typing import Protocol, runtime_checkable

from waylaunch.compositor import Compositor
from waylaunch.core.config import Config


@dataclass(frozen=True)
class Entry:
    """视觉表现层：定义 Picker 界面上这一行长什么样"""

    # 核心显示内容
    title: str  # 标题
    subtitle: str = ""  # 副标题
    title_max_len: int = 0  # 当前组内 title 的最大字符长度，用于对齐
    # 基础元数据 (Row Options)
    icon: str = ""  # 图标名称或路径
    meta: str = ""  # 隐藏的搜索关键词
    # 状态控制
    urgent: bool = False  # 是否标记为紧急红色 (urgent)
    active: bool = False  # 是否标记为活动蓝色 (active)
    markup: bool = False  # 是否允许 Pango Markup 标签


@runtime_checkable
class Item(Protocol):
    """通用条目协议，所有在 Picker 中显示的条目应遵循此协议"""

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


@runtime_checkable
class ItemProvider[T: Item](Protocol):
    """条目提供者接口"""

    async def items(self, config: Config, compositor: Compositor) -> Sequence[T]: ...

    def to_entry(self, item: T) -> Entry:
        """将业务对象转换为 Picker 上的 Entry"""
        ...


@runtime_checkable
class Picker(Protocol):
    """选择器协议，如 Rofi, dmenu, fuzzel, fzf 等"""

    @classmethod
    def is_available(cls) -> bool: ...

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
