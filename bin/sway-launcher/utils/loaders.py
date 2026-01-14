import importlib
import logging
from collections.abc import Iterable
from typing import Protocol, cast

# 使用 PEP 695 定义类型别名，更易读且支持内省
type ConfigItem = (
    tuple[str, str] | tuple[str, str, tuple[object, ...]] | tuple[str, str, tuple[object, ...], dict[str, object]]
)


# 定义一个简单的调用协议，替代 Callable/BoundCallable
class Creator(Protocol):
    def __call__(self, *args: object, **kwargs: object) -> object: ...


logger = logging.getLogger(__name__)


def load_instances[T](config_list: Iterable[ConfigItem], target_type: type[T] | None = None) -> list[T]:
    """
    通用动态实例加载器。

    Usage Examples:
        TOOLS_REGISTRY = [
            ("tool.color_picker", "ColorPicker"),  # 无参数
            ("tool.clipboard", "Clipboard"),  # 无参数
            ("tool.yazi", "Yazi"),  # 无参数
            ("tool.example", "Example", ("Example\r(Extra info)",)),  # 单参数
        ]
        tools: list[Tool] = load_instances(TOOLS_REGISTRY)
    """
    instances: list[T] = []

    for item in config_list:
        try:
            # 1. 解析配置
            match item:
                case (str() as mod, str() as cls, *rest):
                    # 根据剩余参数长度解包 args 和 kwargs
                    args = cast(tuple[object, ...], rest[0]) if len(rest) > 0 else ()
                    kwargs = cast(dict[str, object], rest[1]) if len(rest) > 1 else {}

            # 2. 动态加载：getattr 返回值直接配合 Protocol
            module = importlib.import_module(mod)
            factory: Creator = getattr(module, cls)
            instance = factory(*args, **kwargs)

            # 3. 类型过滤
            if target_type is not None:
                if isinstance(instance, target_type):
                    instances.append(instance)
                else:
                    logger.warning(f"Type mismatch: {cls} is not {target_type}")
            else:
                # 若无 target_type，则假定符合 T (调用者需负责此处的类型安全)
                instances.append(cast(T, instance))

        except Exception:
            logger.exception(f"Failed to load instance from {item}")

    return instances
