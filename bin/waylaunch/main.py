#!/usr/bin/env python3
"""基于 Wayland 的窗口切换、桌面应用与自定义工具启动器。

用法:
    python ~/bin/waylaunch [选项]

参数说明:
    -show: 指定菜单显示内容，可选单个类型，或使用逗号分隔组合多个类型。
        window 已打开窗口
        drun   桌面应用
        tool   自定义工具
        默认为 "window,drun" 即展示已打开窗口和桌面应用列表。
    -layout: 指定选择器显示的布局主题。
        - menu: 标准的列表菜单展示 (默认)。
        - board: 面板模式。
        - launchpad: 全屏启动板模式 (适合高密度图标展示)。

示例:
    $ python ~/bin/waylaunch -show window                 # 仅显示已打开窗口
    $ python ~/bin/waylaunch -show "window,drun"          # 同时显示窗口和应用列表 (默认)
    $ python ~/bin/waylaunch -show drun -layout launchpad  # 以 Launchpad 样式显示应用列表
    $ python ~/bin/waylaunch -show tool -layout board      # 以面板模式显示工具列表
"""

import argparse
import asyncio
import os
import sys
from cmd.start_launcher import start_launcher

from core.logging import setup_logging

PROG = os.path.basename(sys.argv[0])


def build_parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(
        prog=PROG,
        description="Waylaunch",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    root.add_argument(
        "-show",
        dest="show",
        default="window,drun",
        help="Show types: window, drun, tool, window,drun,tool, or window,drun",
    )
    root.add_argument(
        "-layout",
        dest="layout",
        # default="menu",
        help="Layout theme: menu, board or launchpad",
    )

    root.set_defaults(func=start_launcher)

    return root


def main(argv: list[str] | None = None) -> None:
    setup_logging()

    parser = build_parser()
    args = parser.parse_args(argv)
    asyncio.run(args.func(args))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("\nInterrupted")
