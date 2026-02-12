from typing import Any

from core.contract import Config, Item, ItemProvider
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


def create_providers(config: Config) -> list[ItemProvider[Item]]:
    """工厂函数：根据配置动态生产提供者实例。"""
    return [_PROVIDER_MAPPING[t]() for t in config.show_types if t in _PROVIDER_MAPPING]
