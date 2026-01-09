#!/usr/bin/env python3

"""基于 rofi -dmenu 的自定义工具列表。

该脚本通过 rofi 界面展示并启动自定义工具，支持多种视觉布局模式（如菜单、面板、全屏启动板）。

用法:
    python ~/bin/sway-launcher/utools.py [选项]

参数说明:
    -theme: 指定显示的布局主题。
        - menu: 标准的列表菜单展示（默认）。
        - panel: 面板模式。
        - launchpad: 全屏启动板模式（适合高密度图标展示）。

示例:
    $ python ~/bin/sway-launcher/utools.py
    $ python ~/bin/sway-launcher/utools.py -theme panel
    $ python ~/bin/sway-launcher/utools.py -theme launchpad
"""

import argparse
import logging
import subprocess
from typing import NamedTuple

from config import FA_ICON_DIR, TOOLS_REGISTRY
from tools.tool import Tool
from utils.exception_handler import handle_exception, report_exception
from utils.icon_finder import find_fa_icon
from utils.loaders import load_instances
from utils.rofi_helper import calculate_window_size

# 获取 tools 模块的 logger
logger = logging.getLogger("utools")


class Args(NamedTuple):
    theme: str


def parse_arguments() -> Args:
    """解析命令行参数"""
    parser = argparse.ArgumentParser(description="Sway Tool Launcher")
    parser.add_argument("-theme", dest="theme", default="menu", help="Layout theme: menu, panel or launchpad")
    return Args(**vars(parser.parse_args()))


def build_rofi_command(theme: str, tools: list[Tool]) -> list[str]:
    """构建 Rofi 命令"""
    rofi_cmd = [
        "rofi",
        "-dmenu",
        "-i",
        "-p",
        "Tools",
        "-matching",
        "fuzzy",
    ]

    # any() 会在找到第一个包含 "\r" 的元素时立即停止遍历
    if any("\r" in t.name() for t in tools):
        # -eh 2 允许 element-text 使用 "\r" 显示为两行，
        # 使用 " ".join(display_name.split()) == " ".join(selected_name.split()) 匹配选中项
        rofi_cmd.extend(["-eh", "2"])

    # 菜单 menu, 面板 panel, 全屏 launchpad
    match theme:
        case "panel":
            # 计算 Rofi 布局
            cols, rows, width, _ = calculate_window_size(len(tools))
            # rofi -show drun -theme-str 'listview { columns: 3; lines: 5; } window { y-offset: 20%; width: 60%; }'
            # 设置 window width 确保单个工具的显示不会太宽
            theme_str = f"listview {{ columns: {cols}; lines: {rows}; }} window {{ width: {width}; }}"
            rofi_cmd.extend(["-theme", "panel", "-theme-str", theme_str])
            logger.debug(f"Applying Panel theme. -theme-str: {theme_str}")

        case "launchpad":
            # Applying full-screen launchpad logic
            rofi_cmd.extend(["-theme", "launchpad"])
            logger.debug("Applying Launchpad theme.")

        case "menu":
            logger.debug("Applying Menu (default) theme.")

        case _:
            report_exception(
                error=Exception(f"Unknown theme '{theme}', falling back to Menu (default) theme."),
                notify=True,
            )

    return rofi_cmd


@handle_exception(fallback=("", 1))
def execute_rofi_and_get_selection(rofi_cmd: list[str], tools: list[Tool]) -> tuple[str, int]:
    """执行 Rofi 并获取用户选择和返回码"""
    # Rofi 显示列表
    rofi_input = "\n".join([f"{t.name()}\0icon\x1f{find_fa_icon(t.icon(), FA_ICON_DIR)}" for t in tools])

    # 执行 Rofi 命令
    proc = subprocess.Popen(
        rofi_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )
    stdout, _ = proc.communicate(input=rofi_input)
    # 获取用户选择和返回码
    return stdout.strip(), proc.returncode


def main() -> None:
    # 1. 解析命令行参数
    args = parse_arguments()
    theme = args.theme

    # 2. 注册所有工具
    tools: list[Tool] = load_instances(TOOLS_REGISTRY)

    # 如果未全部加载成功，则弹出桌面通知
    tools_count = len(tools)
    expected_count = len(TOOLS_REGISTRY)
    if tools_count < expected_count:
        report_exception(
            error=Exception(f"Only {tools_count}/{expected_count} tools loaded."),
            notify=True,
        )

    # 3. 调用 Rofi
    rofi_cmd = build_rofi_command(theme, tools)
    selected_name, _ = execute_rofi_and_get_selection(rofi_cmd, tools)

    if not selected_name:
        return

    # 4. 匹配选择并运行工具
    selected_clean = " ".join(selected_name.split())
    for t in tools:
        if " ".join(t.name().split()) == selected_clean:
            t.run()
            return

    report_exception(
        error=Exception(f"No match tool: {selected_clean}"),
        notify=True,
    )


if __name__ == "__main__":
    main()
