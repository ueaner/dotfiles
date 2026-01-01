#!/usr/bin/env python3
# 基于 rofi -dmenu 的自定义工具列表

# 使用：
# python ~/bin/sway-launcher/utools.py -theme menu
# python ~/bin/sway-launcher/utools.py # 作用同上，默认使用 menu 菜单展示工具列表
# python ~/bin/sway-launcher/utools.py -theme panel
# python ~/bin/sway-launcher/utools.py -theme launchpad

import argparse
import logging
import math
import subprocess

from config import DEBUG_LOG, FA_ICON_DIR, TOOLS_REGISTRY
from utils.loaders import load_instances

# 获取 tools 模块的 logger
logger = logging.getLogger("utools")


def format_icon(name: str) -> str:
    icon_path = FA_ICON_DIR / f"{name}.svg"
    return str(icon_path) if icon_path.exists() else "application-x-executable"


def calculate_window_size(count: int) -> tuple[int, int, str, str]:
    """
    计算 Rofi 布局，每列最多 5 个，最多 3 行
    :param count: 工具个数
    """
    cols = min(count, 5)
    rows = min(math.ceil(count / 5), 3)

    # window { padding: 1.3em }
    # width = round(9.8 + (cols - 1) * 8.3, 1)
    # height = round(9.8 + (rows - 1) * 8.3, 1)
    # window { padding: 1em }
    width = round(9.3 + (cols - 1) * 8.3, 1)
    height = round(9.3 + (rows - 1) * 8.3, 1)

    return cols, rows, f"{width}em", f"{height}em"


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
    rofi_input = "\n".join([f"{t.name()}\0icon\x1f{format_icon(t.icon())}" for t in tools])

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
