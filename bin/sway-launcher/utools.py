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

from config import DEBUG_LOG, FA_ICON_DIR, TOOLS_REGISTRY
from utils.icon_finder import find_fa_icon
from utils.loaders import load_instances
from utils.rofi_helper import calculate_window_size

# 获取 tools 模块的 logger
logger = logging.getLogger("utools")


def main():
    # 1. 解析命令行参数
    parser = argparse.ArgumentParser(description="Sway Tool Launcher")
    parser.add_argument("-theme", dest="theme", default="menu", help="Layout theme: menu, panel or launchpad")
    args = parser.parse_args()

    # 工具总数
    expected_count = len(TOOLS_REGISTRY)

    # 1. 注册所有工具
    tools = load_instances(TOOLS_REGISTRY)

    # 判断是否全部加载成功
    if len(tools) < expected_count:
        logger.warning(f"Only {len(tools)}/{expected_count} tools loaded.")
        subprocess.run(["notify-send", "Tool Load Error", f"Only {len(tools)}/{expected_count} tools loaded. See {DEBUG_LOG}."])

    # 2. 构造 Rofi 输入内容
    # Rofi 支持格式：显示文本\0icon\x1f图标路径
    rofi_input = "\n".join([f"{t.name()}\0icon\x1f{find_fa_icon(t.icon(), FA_ICON_DIR)}" for t in tools])

    # 4. 调用 Rofi 选择
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
        # -eh 2 允许 element-text 显示为两行，配合 '\r' 使用
        # 当包含 '\r' 时，使用 " ".join(item["display_name"].split()) == " ".join(selected_name.split()) 进行比对
        rofi_cmd.extend(["-eh", "2"])

    # 菜单 menu, 面板 panel, 全屏 launchpad
    match args.theme:
        case "panel":  # 使用横向大图标主题
            # 计算 Rofi 布局
            cols, rows, width, _ = calculate_window_size(len(tools))
            # rofi -show drun -theme-str 'listview { columns: 5; lines: 3; } window { width: 60%; y-offset: 20%; }'
            # rofi window 的 width 默认设置了 60%, 对于少于 5 个工具的列表，需要设置 window 的 width, 以便单个工具的显示不会太宽
            theme_str = f"listview {{ columns: {cols}; lines: {rows}; }} window {{ width: {width}; }}"
            rofi_cmd.extend(["-theme", "panel", "-theme-str", theme_str])
            logger.info(f"Applying Panel theme. -theme-str: {theme_str}")

        case "launchpad":
            # Applying full-screen launchpad logic
            rofi_cmd.extend(["-theme", "launchpad"])
            logger.info("Applying Launchpad theme.")

        case "menu":
            logger.info("Applying Menu (default) theme.")

        case _:
            logger.warning(f"Unknown theme '{args.theme}', falling back to Menu (default) theme.")
            subprocess.run(["notify-send", "Tool (Unknown theme)", f"Unknown theme '{args.theme}', falling back to default."])

    proc = subprocess.Popen(
        # 使用横向大图标主题
        rofi_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )
    stdout, _ = proc.communicate(input=rofi_input)
    selected_name = stdout.strip()
    if not selected_name:
        return

    # 5. 匹配并运行工具
    selected_clean = " ".join(selected_name.split())
    for t in tools:
        if " ".join(t.name().split()) == selected_clean:
            t.run()
            return

    logger.warning(f"No match tool: {selected_clean}")
    subprocess.run(["notify-send", "Tool (No match)", selected_clean])


if __name__ == "__main__":
    main()
