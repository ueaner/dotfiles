from collections.abc import Callable
from typing import Any

from waylaunch.compositor import Compositor
from waylaunch.core.logger import logger
from waylaunch.core.protocols import Item, ItemProvider, Picker

# 使用 type[ItemProvider[Any]] 消除泛型不变性带来的类型警告。
type PluginType = type[Compositor] | type[Picker] | type[ItemProvider[Any]]


class PluginRegistry:
    """插件注册表"""

    compositors: dict[str, type[Compositor]]
    pickers: dict[str, type[Picker]]
    providers: dict[str, type[ItemProvider[Item]]]

    def __init__(self) -> None:
        self.compositors = {}
        self.pickers = {}
        self.providers = {}

    def register[T: PluginType](self, name: str) -> Callable[[T], T]:
        """注册插件

        Args:
            name: 插件名称

        Returns:
            装饰器函数
        """

        def decorator(obj: T) -> T:

            # 使用运行时特征检测判断类型
            if issubclass(obj, Compositor):
                logger.info(f"Loaded compositor plugin: {name} {obj}")
                self.compositors[name] = obj
                return obj

            if issubclass(obj, Picker):
                logger.info(f"Loaded picker plugin: {name} {obj}")
                self.pickers[name] = obj
                return obj

            if issubclass(obj, ItemProvider):
                logger.info(f"Loaded provider plugin: {name} {obj}")
                self.providers[name] = obj  # pyright: ignore[reportArgumentType]
                return obj

            raise TypeError(
                f"Failed to register '{obj.__name__}' as '{name}': "
                f"Class does not implement any supported plugin protocols "
                f"(Compositor, Picker, or ItemProvider)."
            )

        return decorator


registry = PluginRegistry()
