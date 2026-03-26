"""
统一异常处理装饰器

捕获函数执行中的异常，记录日志并返回指定的 fallback 值。
"""

from __future__ import annotations

import functools
import warnings
from collections.abc import Callable
from typing import overload

from waylaunch.core.logger import logger

type Factory[T] = Callable[[], T]

# 运行时检测的可变类型
_MUTABLE_TYPES: tuple[type, ...] = (list, dict, set, bytearray)


@overload
def handle_exception[**P, R](func: Callable[P, R]) -> Callable[P, R]: ...


@overload
def handle_exception[**P, R](
    *,
    fallback: None = None,
    context: str = "",
    reraise: bool = False,
) -> Callable[[Callable[P, R]], Callable[P, R | None]]: ...


@overload
def handle_exception[**P, R, T](
    *,
    fallback: Factory[T],
    context: str = "",
    reraise: bool = False,
) -> Callable[[Callable[P, R]], Callable[P, T]]: ...


@overload
def handle_exception[**P, R, T](
    *,
    fallback: T,
    context: str = "",
    reraise: bool = False,
) -> Callable[[Callable[P, R]], Callable[P, T]]: ...


def handle_exception[**P, R](
    func: Callable[P, R] | None = None,
    *,
    fallback: object = None,
    context: str = "",
    reraise: bool = False,
) -> Callable[P, object] | Callable[[Callable[P, R]], Callable[P, object]]:
    """
    异常处理装饰器。

    ⚠️ 安全警告: list/dict/set 等可变类型必须使用工厂函数（如 list），
    不能使用字面量（如 []），否则多次调用会共享同一对象。

    Args:
        func: 被装饰函数（用于 @handle_exception 无括号语法）
        fallback: 异常时返回的值或工厂函数
        context: 错误上下文描述
        reraise: 是否重新抛出异常

    Returns:
        装饰后的函数，异常时返回 fallback

    Usage:
        @handle_exception                                    # 无参，返回 None
        @handle_exception(fallback=0)                        # 不可变值，返回 0
        @handle_exception(fallback=list)                     # 工厂函数，返回 []（新实例）
        @handle_exception(context="关键操作", reraise=True)  # 记录日志并重新抛出异常
    """

    def decorator(fn: Callable[P, R]) -> Callable[P, object]:
        # 运行时安全检查
        if fallback is not None and not callable(fallback) and isinstance(fallback, _MUTABLE_TYPES):
            warnings.warn(
                f"Using mutable {type(fallback).__name__} as fallback causes "
                f"shared state across calls. Use a factory function instead: "
                f"fallback={type(fallback).__name__}",
                RuntimeWarning,
                stacklevel=2,
            )

        @functools.wraps(fn)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> object:
            try:
                return fn(*args, **kwargs)
            except Exception as e:
                # 添加上下文注释，增强异常信息
                note = (
                    f"{context} ({fn.__qualname__})" if context else f"Function: {fn.__qualname__}"
                )
                e.add_note(note)

                # 结构化日志（避免 LogRecord 保留字段冲突）
                error_msg = (
                    f"{context} ({fn.__qualname__})" if context else f"Error in {fn.__qualname__}"
                )

                logger.exception(
                    error_msg,
                    stacklevel=2,
                    extra={
                        "ctx": context,
                        "func": fn.__qualname__,
                        "mod": fn.__module__,
                        "exc_type": type(e).__name__,
                        "err": str(e),
                    },
                )
                if reraise:
                    raise
                # 调用工厂函数（排除 str 和 bytes，它们作为普通值处理）
                if callable(fallback) and not isinstance(fallback, (str, bytes)):
                    return fallback()
                return fallback

        return wrapper

    if func is not None and callable(func):
        return decorator(func)
    return decorator
