"""Compositor detection.

This module provides automatic detection of the running Wayland compositor.
"""

import asyncio
import os
import re
from asyncio.subprocess import PIPE
from importlib.metadata import entry_points

from compositor.compositor import Compositor
from compositor.null_adapter import NullAdapter
from compositor.sway import SwayAdapter
from core.logging import logger

_BUILTIN_ADAPTERS: list[type[Compositor]] = [
    SwayAdapter,
]


def _get_all_adapters() -> list[type[Compositor]]:
    """获取适配器列表"""
    adapters = list(_BUILTIN_ADAPTERS)
    try:
        eps = entry_points(group="waylaunch.compositor.adapters")
        for entry in eps:
            try:
                adapter_cls = entry.load()
                if adapter_cls not in adapters:
                    adapters.append(adapter_cls)
                logger.debug(f"Loaded external adapter: {entry.name}")
            except Exception as e:
                # 隔离错误：第三方插件崩了，不能把主程序带崩
                logger.error(f"Failed to load external adapter '{entry.name}': {e}")
    except Exception:  # noqa: S110
        pass  # 兼容某些没有 entry_points 分组的环境

    return adapters


async def _detect_active_adapter_proc_names(adapters: list[type[Compositor]]) -> set[str]:
    all_names = {name for a in adapters for name in a.metadata().proc_names if name}
    if not all_names:
        return set()

    pattern = "|".join(re.escape(n) for n in all_names)

    process = await asyncio.create_subprocess_exec(
        "pgrep",
        "-x",
        "-l",
        pattern,
        stdout=PIPE,
        stderr=PIPE,
    )

    stdout, _ = await process.communicate()

    if process.returncode == 0:
        output = stdout.decode().strip()
        return {
            parts[1]
            for line in output.splitlines()
            if (parts := line.split(maxsplit=1)) and len(parts) > 1
        }

    return set()


async def detect() -> Compositor:
    """Detect the current running compositor.

    Detection priority:
    1. Environment variable WAYLAUNCH_COMPOSITOR
    2. Compositor-specific environment variables
    3. XDG_CURRENT_DESKTOP environment variable
    4. Process detection

    Returns:
        The detected Compositor

    Raises:
        RuntimeError: If no supported compositor is detected
    """
    # 加载适配器列表
    adapters = _get_all_adapters()

    # 获取环境快照
    waylaunch = os.environ.get("WAYLAUNCH_COMPOSITOR", "").lower()
    xdg_desktop = {
        n.strip().lower() for n in os.environ.get("XDG_CURRENT_DESKTOP", "").split(":") if n.strip()
    }
    proc_names = await _detect_active_adapter_proc_names(adapters)

    # 1. 手动指定环境 WAYLAUNCH_COMPOSITOR
    if waylaunch:
        for adapter_cls in adapters:
            meta = adapter_cls.metadata()
            if any(name.lower() == waylaunch for name in meta.desktop_names):
                return adapter_cls()
        logger.warning(
            f"Specified compositor '{waylaunch}' not found, falling back to auto-detection."
        )

    # 2. 自动探测环境
    for adapter_cls in adapters:
        meta = adapter_cls.metadata()

        # A. 环境变量名
        if any(var in os.environ for var in meta.env_vars):
            return adapter_cls()

        # B. 桌面环境名 (XDG_CURRENT_DESKTOP)
        if {n.lower() for n in meta.desktop_names} & xdg_desktop:
            return adapter_cls()

        # C. 进程名 (pgrep 结果)
        if any(proc in proc_names for proc in meta.proc_names):
            return adapter_cls()

    # Fallback
    # raise RuntimeError(
    #     "Unable to detect Wayland compositor. "
    #     "Set WAYLAUNCH_COMPOSITOR environment variable to specify the compositor."
    # )
    return NullAdapter()
