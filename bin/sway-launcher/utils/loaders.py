import importlib
import logging
from typing import Iterable, TypeVar

# 获取当前模块的专属 logger "utils.loaders"
logger = logging.getLogger(__name__)

# 定义泛型，以便调用时可以指定返回类型（如 list[Tool]）
T = TypeVar("T")


def load_instances(config_list: Iterable[tuple], target_type: type[T] | None = None) -> list[T]:
    """
    通用实例加载器。

    支持配置格式：
    - (mod_path, cls_name)
    - (mod_path, cls_name, (args, ...))
    - (mod_path, cls_name, (args, ...), {kwargs, ...})
    """
    instances: list[T] = []

    for item in config_list:
        try:
            # 1. 解析配置
            match item:
                case mod_path, cls_name:
                    args, kwargs = (), {}
                case mod_path, cls_name, tuple() as args:
                    kwargs = {}
                case mod_path, cls_name, tuple() as args, dict() as kwargs:
                    pass
                case _:
                    logger.error(f"Invalid format: {item}")
                    continue

            # 2. 动态加载
            module = importlib.import_module(mod_path)
            cls = getattr(module, cls_name)
            instance = cls(*args, **kwargs)

            # 3. 类型校验 (可选)
            if target_type and not isinstance(instance, target_type):
                logger.warning(f"Type mismatch: {cls_name} not a {target_type.__name__}")

            instances.append(instance)

        except Exception as e:
            # 将详细错误信息写入日志文件
            logger.error(f"Failed to load {item}: {str(e)}", exc_info=True)

    return instances
