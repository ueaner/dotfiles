#!/usr/bin/env python3
"""基于 rofi -dmenu 的窗口切换、桌面应用与自定义工具启动器。

用法:
    python ~/bin/sway-launcher <子命令> [选项]

子命令:
    apps: 选择并切到到窗口，或启动桌面应用。
    tools: 选择并启动自定义工具。

参数说明:
    -show: 指定菜单显示内容，可选 "window", "drun" 或 "window,drun"（默认）。
    -theme: 指定显示的布局主题。
        - menu: 标准的列表菜单展示（默认）。
        - panel: 面板模式。
        - launchpad: 全屏启动板模式（适合高密度图标展示）。

示例:
    $ python ~/bin/sway-launcher apps -show window                 # 仅显示已打开窗口
    $ python ~/bin/sway-launcher apps -show "window,drun"          # 同时显示窗口和应用列表（默认）
    $ python ~/bin/sway-launcher apps -show drun -theme launchpad  # 以 Launchpad 样式显示应用列表

    $ python ~/bin/sway-launcher tools                   # 以 Menu 菜单列表样式显示自定义工具列表
    $ python ~/bin/sway-launcher tools -theme panel      # 以 Panel 面板样式显示自定义工具列表
    $ python ~/bin/sway-launcher tools -theme launchpad  # 以 Launchpad 样式显示自定义工具列表
"""

import argparse
import os
import sys
from cmd.apps import cmd_apps
from cmd.tools import cmd_tools

PROG = os.path.basename(sys.argv[0])


def build_parser() -> argparse.ArgumentParser:
    # 全局解析器
    root = argparse.ArgumentParser(
        prog=PROG,
        description="Sway Apps/Tools launcher",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    # 子命令
    sub = root.add_subparsers(dest="command", required=True, metavar="command", help="子命令帮助")

    # 1. apps
    p = sub.add_parser("apps", help="Apps Launcher")
    p.add_argument("-show", dest="show", default="window,drun", help="Show types: window, drun, or window,drun")
    p.add_argument("-theme", dest="theme", default="menu", help="Layout theme: menu, panel or launchpad")
    p.set_defaults(func=cmd_apps)

    # 2. tools
    p = sub.add_parser("tools", help="Tools Launcher")
    p.add_argument("-theme", dest="theme", default="menu", help="Layout theme: menu, panel or launchpad")
    p.set_defaults(func=cmd_tools)

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
