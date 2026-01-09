"""统一异常处理模块"""

import logging
import shutil
import subprocess
import sys
from collections.abc import Callable
from functools import wraps
from typing import ParamSpec, TypeVar, cast

logger = logging.getLogger(__name__)


def report_exception(error: Exception, context: str = "", notify: bool = False) -> None:
    """
    统一错误处理：记录日志且可选发送桌面通知

    Args:
        error: 捕获的异常
        context: 错误上下文描述
        notify: 是否发送桌面通知，默认不发送，避免在循环中使用 notify = True
    """
    error_msg = f"{context}: {str(error)}" if context else str(error)
    print(error_msg)

    # 检查当前是否有活跃的异常堆栈
    if sys.exc_info()[0] is not None:
        # 使用 logger.exception 自动捕获堆栈跟踪
        logger.exception(error_msg)
    else:
        # 如果没有活跃堆栈，则作为 error 记录，可手动关联异常对象
        # logger.error(error_msg, exc_info=error)
        logger.error(error_msg)

    if not notify:
        return

    if not shutil.which("notify-send"):
        # 如果 notify-send 命令不存在，记录一条警告日志
        logger.warning("Notification skipped: 'notify-send' not found in PATH.")
        return

    # 发送桌面通知
    try:
        # -a 指定应用名称，-u critical 确保突出显示错误信息
        subprocess.run(
            ["notify-send", "-a", "Python Scripts", "-u", "critical", "Error", error_msg],
            check=False,
            capture_output=True,
            timeout=5,
        )
    except subprocess.TimeoutExpired:
        logger.warning("Notification timed out.")
    except Exception as e:
        logger.warning(f"Notification failed: {e}")


P = ParamSpec("P")
R = TypeVar("R")


def handle_exception(
    fallback: object = None,
    context: str = "",
    reraise: bool = False,
    notify: bool = False,
) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """
    错误处理装饰器

    Args:
        fallback: 出错时的默认返回值 (e.g., [], {}, 0)
        context: 错误上下文描述 (e.g., "数据库连接")
        reraise: 是否重新抛出异常。True 则处理完后 raise，False 则静默返回 fallback
        notify: 是否发送桌面通知

    Usage Examples:
        # 场景 1: 静默处理，出错时返回默认值
        @handle_exception(fallback=0, context="关键计算", reraise=False)
        def divide(a: int, b: int) -> float:
            return a / b  # b 为 0 时，触发异常后返回 []

        # 场景 2: 记录并通知，但继续向上抛出异常由上层逻辑处理
        @handle_exception(context="支付接口", reraise=True)
        def process_payment():
            raise ConnectionError("Timeout")

        # 场景 3: 基础用法，仅记录错误并返回 None
        @handle_exception()
        def risky_task():
            import os
            os.remove("/non/existent/path")
    """

    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        # @wraps 确保被装饰函数的元数据（__name__, __doc__ 等属性）不丢失
        @wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            try:
                return func(*args, **kwargs)
            except Exception as e:
                # 构造上下文：优先使用自定义 context，否则使用函数名
                ctx = f"{context} in {func.__name__}" if context else f"Error in {func.__name__}"
                report_exception(e, ctx, notify)

                if reraise:
                    raise

                # 将 object 强制转换为 R 返回
                return cast(R, fallback)

        return wrapper

    return decorator
