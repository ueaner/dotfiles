from typing import Any

from core.protocols import Item, ItemProvider
from providers.drun import AppItemProvider
from providers.tool import ToolItemProvider
from providers.window import WindowItemProvider

# 定义内部映射表，完全隔离具体的 Provider 类名。
# 使用 type[ItemProvider[Any]] 消除泛型不变性带来的类型警告。
# fmt: off
_PROVIDER_MAPPING: dict[str, type[ItemProvider[Any]]] = {
    "window": WindowItemProvider,  # 运行中的窗口
    "drun":   AppItemProvider,     # 已安装的应用
    "tool":   ToolItemProvider,    # 自定义工具
}
# fmt: on


def register_provider(name: str, cls: type[ItemProvider[Any]]) -> None:
    if name not in _PROVIDER_MAPPING:
        _PROVIDER_MAPPING[name] = cls


def create_providers(show_types: list[str]) -> list[ItemProvider[Item]]:
    """工厂函数：根据配置动态生产提供者实例。"""
    return [_PROVIDER_MAPPING[t]() for t in show_types if t in _PROVIDER_MAPPING]
