#!/usr/bin/env python3
# 基于 rofi -dmenu 自定义已打开窗口列表和应用列表菜单，支持图标展示、遵循 XDG 规范去重过滤；
# 可使用 Shift+Return 在新工作区中打开选中的应用（如果在 Sway 中指定了特定应用所属的工作区，则遵循 Sway 的配置）。
# 可通过 window, drun 或 window,drun 参数，选择 Rofi 菜单中显示哪些内容，默认为 window,drun 都显示
#
# 使用：
# python ~/bin/sway-launcher/main.py -show window
# python ~/bin/sway-launcher/main.py -show "window,drun"
# python ~/bin/sway-launcher/main.py -show drun -theme launchpad

import argparse
import json
import logging
import math
import os
import subprocess

from config import DESKTOP_DIRS
from utils.sway_helper import get_all_apps, get_first_empty_workspace, get_running_windows

# 获取 main 模块的 logger
logger = logging.getLogger(__name__)


def is_flatpak(path):
    return "flatpak" in str(path).lower()


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
    parser = argparse.ArgumentParser(description="Sway Launcher")
    parser.add_argument("-show", dest="show_types", default="window,drun", help="Show types: window, drun, or window,drun")
    parser.add_argument("-theme", dest="theme", default="menu", help="Layout theme: menu, panel or launchpad")
    args = parser.parse_args()

    # 将参数解析为列表，例如 ["window", "drun"]
    show_list = [s.strip() for s in args.show_types.split(",")]

    # 2. 根据参数按需获取数据
    windows = []
    apps = []
    rofi_lines = []

    # 运行窗口在前（normal.active），待启动应用在后
    if "window" in show_list:
        # 获取运行中的窗口
        windows = get_running_windows()
        # 处理运行窗口的 display_name 显示字段
        # 获取 id 字段的最大长度
        max_len = max((len(item["id"]) for item in windows), default=0)
        # 将每个 id 字段右补全空格，便于在 Rofi 上整齐显示
        for w in windows:
            # 处理应用 display_name 显示字段
            w["display_name"] = f"{w['id'].ljust(max_len)} · {w['name']}"
            # 格式：显示文本 \0 icon \x1f 图标路径 \x1f info \x1f 附加数据
            rofi_lines.append(f"{w['display_name']}\0icon\x1f{w['icon']}\x1factive\x1ftrue")

    if "drun" in show_list:
        # 扫描并去重 .desktop 应用 (先到先得)
        apps = get_all_apps(DESKTOP_DIRS)
        for a in apps:
            # 处理应用 display_name 显示字段
            a["display_name"] = a["name"]
            # 应用部分：使用 \x1fmeta\x1f 传递搜索关键词
            line = f"{a['display_name']}\0icon\x1f{a['icon']}"
            if a.get("generic"):
                # 将 generic 信息填入 meta 字段，Rofi 会搜索它但不会显示它
                line += f"\x1fmeta\x1f{a['generic']}"
            rofi_lines.append(line)

    # 写入调试文件
    logger.debug(
        json.dumps(
            {"current_env": os.getenv("XDG_CURRENT_DESKTOP", ""), "windows": windows, "apps": apps, "len(rofi_lines)": len(rofi_lines)},
            ensure_ascii=False,
        )
    )

    if not rofi_lines:
        return

    # 3. Rofi 列表
    rofi_input = "\n".join(rofi_lines)

    # 4. 调用 Rofi
    rofi_cmd = [
        "rofi",
        "-dmenu",
        "-i",
        "-p",
        "Apps",
        "-kb-accept-alt",
        "",
        "-kb-custom-1",
        "Shift+Return",
        "-matching",
        "fuzzy",
        "-sort",
        "-sorting-method",
        "fzf",
    ]

    # 菜单 menu, 面板 panel, 全屏 launchpad
    match args.theme:
        case "panel":  # 使用横向大图标主题
            # 计算 Rofi 布局
            cols, rows, width, _ = calculate_window_size(len(rofi_lines))
            # rofi -show drun -theme-str 'listview { columns: 3; lines: 5; } window { y-offset: 20%; width: 60%; }'
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
        rofi_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )
    stdout, _ = proc.communicate(input=rofi_input)

    # 5. 处理选中项
    selected_name = stdout.strip()
    if not selected_name:
        return

    target = next((w for w in windows if w["display_name"] == selected_name), None)
    if target:
        subprocess.run(["swaymsg", f"[con_id={target['con_id']}] focus"])
        return

    target = next((a for a in apps if a["display_name"] == selected_name), None)
    if target:
        if proc.returncode == 0:
            subprocess.Popen(["gtk-launch", target["id"]], stdout=subprocess.DEVNULL)
        elif proc.returncode == 10:
            # Shift+Return 逻辑
            target_ws = get_first_empty_workspace()
            exec_cmd = f"flatpak run {target['id']}" if is_flatpak(target["path"]) else f"gtk-launch {target['id']}"
            subprocess.Popen(["swaymsg", f"workspace {target_ws}; exec {exec_cmd}"])
        return

    logger.warning(f"No match window/application: {selected_name}")
    subprocess.run(["notify-send", "Rofi No Match", selected_name])


if __name__ == "__main__":
    main()
