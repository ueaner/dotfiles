"""Compositor detection.

This module provides automatic detection of the running Wayland compositor.
"""

import asyncio
import os
import re
from asyncio.subprocess import PIPE

from waylaunch.compositor.compositor import Compositor
from waylaunch.compositor.models import DiscoveryMeta
from waylaunch.compositor.null_adapter import NullAdapter
from waylaunch.core.logger import logger
from waylaunch.core.models import PluginsType
from waylaunch.core.registry import registry


async def _detect_active_adapter_proc_names(adapters: dict[str, type[Compositor]]) -> set[str]:
    all_names = {name for _, a in adapters.items() for name in a.metadata().proc_names if name}
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


async def detect(names: PluginsType) -> Compositor:
    """Detect the current running compositor.

    Detection priority:
    1. names variable
    2. Compositor-specific environment variables
    3. XDG_CURRENT_DESKTOP environment variable
    4. Process detection

    Returns:
        The detected Compositor

    Raises:
        RuntimeError: If no supported compositor is detected
    """
    # 获取环境快照
    xdg_desktop = {
        n.strip().lower() for n in os.environ.get("XDG_CURRENT_DESKTOP", "").split(":") if n.strip()
    }
    proc_names = await _detect_active_adapter_proc_names(registry.compositors)

    def is_match(meta: DiscoveryMeta) -> bool:
        return (
            # A. 环境变量名
            any(var in os.environ for var in meta.env_vars)
            or
            # B. 桌面环境名 (XDG_CURRENT_DESKTOP)
            bool({n.lower() for n in meta.desktop_names} & xdg_desktop)
            or
            # C. 进程名 (pgrep 结果)
            any(proc in proc_names for proc in meta.proc_names)
        )

    # 1. 指定环境及检测顺序
    if names:
        for name in names:
            if (adapter_cls := registry.compositors.get(name)) and is_match(adapter_cls.metadata()):
                return adapter_cls()
        logger.warning(
            "Specified compositors not found (%s); falling back to auto-detection...",
            ", ".join(names),
        )

    # 2. 自动探测环境

    for name, adapter_cls in registry.compositors.items():
        if name not in names and is_match(adapter_cls.metadata()):
            logger.info("Auto-detected compositor: %s", adapter_cls.__name__)
            return adapter_cls()

    # Fallback
    return NullAdapter()
