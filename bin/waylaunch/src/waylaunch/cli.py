#!/usr/bin/env python3
"""Wayland 应用启动器：窗口切换、桌面应用、自定义工具。

用法:
    waylaunch [选项]

选项:
    --provider    显示内容：window(窗口) drun(应用) tool(工具)
    --layout      布局主题：menu(菜单) board(面板) launchpad(启动板)
    --prompt      提示文字
    --compositor  窗口管理器：sway

示例:
    waylaunch                                     # 默认：显示窗口和应用
    waylaunch --provider window                   # 仅显示已打开窗口
    waylaunch --provider drun --layout launchpad  # 应用以启动板样式显示
    waylaunch --provider tool --layout board      # 工具以面板样式显示
"""

import argparse
import asyncio
import os
import sys
from pathlib import Path

from waylaunch.start_launcher import start_launcher

PROG = os.path.basename(sys.argv[0])


def build_parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(
        prog=PROG,
        description="Wayland launcher: window switcher, desktop apps, and custom tools.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    root.add_argument(
        "-c",
        "--config",
        type=Path,
        default=Path("~/.config/waylaunch/config.toml").expanduser(),
        help="Path to the configuration file (default: ~/.config/waylaunch/config.toml)",
    )

    root.add_argument(
        "--prompt",
        dest="picker.prompt",
        default="Launcher",
        help="Input prompt text (default: Launcher)",
    )

    root.add_argument(
        "--layout",
        dest="picker.layout",
        help="Picker layout theme: menu, board, or launchpad",
    )

    root.add_argument(
        "--picker",
        nargs="+",
        dest="picker.plugins",
        help="Picker backends: rofi, wofi, etc.",
    )

    root.add_argument(
        "--provider",
        dest="provider.plugins",
        nargs="+",
        default=["window", "drun"],
        help="Data sources: window (active windows), drun (desktop apps), tool (custom scripts)",
    )

    root.add_argument(
        "--compositor",
        nargs="+",
        dest="compositor.plugins",
        help="Target window manager: sway, hyprland, etc.",
    )

    root.set_defaults(func=start_launcher)

    return root


def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    asyncio.run(args.func(args))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("\nInterrupted")
