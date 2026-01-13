#!/usr/bin/env python3
"""基于 rofi -dmenu 的窗口切换、桌面应用与自定义工具启动器。

用法:
    python ~/bin/sway-launcher [选项]

参数说明:
    -show: 指定菜单显示内容，可选单个类型，或使用逗号分隔组合多个类型。
        window 已打开窗口
        drun   桌面应用
        tool   自定义工具
        默认为 "window,drun" 即展示已打开窗口和桌面应用列表。
    -theme: 指定显示的布局主题。
        - menu: 标准的列表菜单展示（默认）。
        - panel: 面板模式。
        - launchpad: 全屏启动板模式（适合高密度图标展示）。

示例:
    $ python ~/bin/sway-launcher -show window                 # 仅显示已打开窗口
    $ python ~/bin/sway-launcher -show "window,drun"          # 同时显示窗口和应用列表（默认）
    $ python ~/bin/sway-launcher -show drun -theme launchpad  # 以 Launchpad 样式显示应用列表
    $ python ~/bin/sway-launcher -show tool -theme panel      # 以 Launchpad 样式显示工具列表
"""

import argparse
import os
import sys
from cmd.cmd_launcher import cmd_launcher

PROG = os.path.basename(sys.argv[0])


def build_parser() -> argparse.ArgumentParser:
    # 全局解析器
    root = argparse.ArgumentParser(
        prog=PROG,
        description="Sway Launcher",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    root.add_argument(
        "-show",
        dest="show",
        default="window,drun",
        help="Show types: window, drun, tool, window,drun,tool, or window,drun",
    )
    root.add_argument(
        "-theme",
        dest="theme",
        default="menu",
        help="Layout theme: menu, panel or launchpad",
    )
    root.set_defaults(func=cmd_launcher)

    # # 子命令
    # sub = root.add_subparsers(dest="command", required=True, metavar="command", help="Subcommand Help")

    # p = sub.add_parser("tool", help="Tool Launcher")
    # p.add_argument("-theme", dest="theme", default="menu", help="Layout theme: menu, panel or launchpad")
    # p.set_defaults(func=cmd_tool)

    return root


# ---------- main ----------
def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    # 执行子命令
    args.func(args)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("\nInterrupted")
