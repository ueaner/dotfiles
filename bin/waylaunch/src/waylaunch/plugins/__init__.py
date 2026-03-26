from typing import Any

from waylaunch.compositor import Compositor
from waylaunch.core.logger import logger
from waylaunch.core.models import PluginsType
from waylaunch.core.protocols import Item, ItemProvider, Picker
from waylaunch.core.registry import registry

# pyright: reportUnusedImport=false
# flake8: noqa: F401

TARGET_GROUPS = [
    "waylaunch.plugins.compositor",
    "waylaunch.plugins.picker",
    "waylaunch.plugins.provider",
]


def load_plugins() -> None:
    """加载插件"""
    from waylaunch.plugins.compositor import SwayAdapter
    from waylaunch.plugins.picker import RofiPicker
    from waylaunch.plugins.provider import AppItemProvider, ToolItemProvider, WindowItemProvider

    try:
        from importlib.metadata import entry_points

        # 1. 显式组名获取 + 自动去重
        eps = {ep for group_name in TARGET_GROUPS for ep in entry_points(group=group_name)}

        for entry in eps:
            try:
                # 2. 这里的 load() 只负责将代码引入内存，不涉及实例化
                entry.load()
                logger.info(
                    f"Loaded plugin: {entry.name} from group '{entry.group}' ({entry.value})"
                )
            except Exception:
                logger.exception(f"Failed to load plugin '{entry.name}' at {entry.value}")
    except Exception:  # noqa: S110
        pass  # 兼容某些没有 entry_points 分组的环境


async def get_compositor(names: PluginsType) -> Compositor:
    """获取 compositor 实例

    Args:
        names: 指定合成器列表，None 则使用自动检测
    """

    # 按指定顺序或注册顺序检测
    from waylaunch.compositor import detector

    return await detector.detect(names)


def get_picker(names: PluginsType) -> Picker | None:
    """获取 picker 实例（按顺序检测可用性）"""
    if names:
        for name in names:
            if name in registry.pickers:
                return registry.pickers[name]()
        logger.warning(
            "Specified pickers not found (%s); falling back to auto-detection...",
            ", ".join(names),
        )

    # 这里的 next(iter_expr, default) 可以优雅地处理没找到的情况
    first_available_cls = next(
        (cls for cls in registry.pickers.values() if cls.is_available()), None
    )

    if not first_available_cls:
        logger.error("No available picker found on this system!")
        return None

    logger.info("Auto-detected picker: %s", first_available_cls.__name__)
    return first_available_cls()


def create_providers(names: PluginsType) -> list[ItemProvider[Item]]:
    """获取 provider 实例列表

    Args:
        names: 数据提供者列表，包含子分组，如 {"window": None, "tool": ["recording", "screenshot"]}
    """

    if names:
        return [registry.providers[name]() for name in names if name in registry.providers]

    return [cls() for cls in registry.providers.values()]
