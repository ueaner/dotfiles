#!/usr/bin/env python3

"""基于 rofi -dmenu 的窗口管理与应用启动器。

该脚本整合了当前打开的窗口列表和系统应用列表（drun），支持图标展示并遵循 XDG 规范进行去重过滤。
支持通过快捷键 Shift+Return 在新工作区中打开选中的应用（尊重 Sway 中为特定应用指定所属工作区的配置）。

用法:
    python ~/bin/sway-launcher/main.py [选项]

参数说明:
    -show: 指定菜单显示内容，可选 "window", "drun" 或 "window,drun"（默认）。
    -theme: 指定显示的布局主题。
        - menu: 标准的列表菜单展示（默认）。
        - panel: 面板模式。
        - launchpad: 全屏启动板模式（适合高密度图标展示）。

示例:
    $ python ~/bin/sway-launcher/main.py -show window                 # 仅显示已打开窗口
    $ python ~/bin/sway-launcher/main.py -show "window,drun"          # 同时显示窗口和应用列表
    $ python ~/bin/sway-launcher/main.py -show drun -theme launchpad  # 以 Launchpad 样式启动应用列表
"""

import argparse
import json
import logging
import subprocess
from typing import NamedTuple

from config import DESKTOP_DIRS
from utils.exception_handler import handle_exception, report_exception
from utils.rofi_helper import calculate_window_size
from utils.sway_helper import AppInfo, WindowInfo, get_all_apps, get_first_empty_workspace, get_running_windows

# 获取 main 模块的 logger
logger = logging.getLogger(__name__)


class Args(NamedTuple):
    show_types: str
    theme: str


def parse_arguments() -> Args:
    """解析命令行参数"""
    parser = argparse.ArgumentParser(description="Sway Launcher")
    parser.add_argument(
        "-show", dest="show_types", default="window,drun", help="Show types: window, drun, or window,drun"
    )
    parser.add_argument("-theme", dest="theme", default="menu", help="Layout theme: menu, panel or launchpad")
    return Args(**vars(parser.parse_args()))


def build_rofi_lines(show_list: list[str]) -> tuple[list[WindowInfo], list[AppInfo], list[str]]:
    """构建 Rofi 显示行"""
    windows: list[WindowInfo] = []
    apps: list[AppInfo] = []
    rofi_lines: list[str] = []

    # 运行窗口在前（normal.active），待启动应用在后
    if "window" in show_list:
        # 获取运行中的窗口
        windows = get_running_windows()

        # 处理运行窗口的 display_name 显示字段
        # 获取 app_id 字段的最大长度
        max_len = max((len(w.app_id) for w in windows), default=0)
        # 对齐宽度最大 20
        align_len = min(max_len, 25)
        # 将每个 id 字段右补全空格，便于在 Rofi 上整齐显示
        for w in windows:
            if len(w.app_id) > align_len:
                # 截断前17位并添加3个点，总长20
                w.display_name = f"{w.app_id[:22]}... · {w.name}"
            else:
                # 右侧补空格，确保总长20
                w.display_name = f"{w.app_id.ljust(align_len)} · {w.name}"

            # 格式：显示文本 \0 icon \x1f 图标路径 \x1f info \x1f 附加数据
            rofi_lines.append(f"{w.display_name}\0icon\x1f{w.icon}\x1factive\x1ftrue")

        logger.debug(f"windows: {json.dumps([[w.app_id, w.icon, w.shell, w.con_id] for w in windows])}")

    if "drun" in show_list:
        # 扫描并去重 .desktop 应用 (先到先得)
        apps = get_all_apps(DESKTOP_DIRS)
        for a in apps:
            a.display_name = a.name
            # 应用部分：使用 \x1fmeta\x1f 传递搜索关键词
            line = f"{a.display_name}\0icon\x1f{a.icon}"
            if a.generic:
                # 将 generic 信息填入 meta 字段，Rofi 会搜索它但不会显示它
                line += f"\x1fmeta\x1f{a.generic}"
            rofi_lines.append(line)

    return windows, apps, rofi_lines


def build_rofi_command(theme: str, rofi_lines: list[str]) -> list[str]:
    """构建 Rofi 命令"""
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
    match theme:
        case "panel":  # 使用横向大图标主题
            # 计算 Rofi 布局
            cols, rows, width, _ = calculate_window_size(len(rofi_lines))
            # rofi -show drun -theme-str 'listview { columns: 3; lines: 5; } window { y-offset: 20%; width: 60%; }'
            # rofi window 的 width 默认设置了 60%, 对于少于 5 个工具的列表，
            # 需要设置 window 的 width, 以便单个工具的显示不会太宽
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


# @handle_exception(fallback=cast(tuple[str, int], ("", 1)))
@handle_exception(fallback=("", 1))
def execute_rofi_and_get_selection(rofi_cmd: list[str], rofi_lines: list[str]) -> tuple[str, int]:
    """执行 Rofi 并获取用户选择和返回码"""
    # Rofi 显示列表
    rofi_input = "\n".join(rofi_lines)

    # 执行 Rofi 命令
    proc = subprocess.Popen(
        rofi_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )
    stdout, _ = proc.communicate(input=rofi_input)
    return stdout.strip(), proc.returncode


def is_flatpak(path: str) -> bool:
    return "flatpak" in str(path).lower()


def handle_selected_item(
    selected_name: str, windows: list[WindowInfo], apps: list[AppInfo], proc_returncode: int
) -> None:
    """处理选择的项目"""
    target_win: WindowInfo | None = next((w for w in windows if w.display_name == selected_name), None)
    if target_win:
        subprocess.run(["swaymsg", f"[con_id={target_win.con_id}] focus"])
        return

    target_app: AppInfo | None = next((a for a in apps if a.display_name == selected_name), None)
    if target_app:
        if proc_returncode == 0:
            subprocess.Popen(["gtk-launch", target_app.app_id], stdout=subprocess.DEVNULL)
        elif proc_returncode == 10:
            # Shift+Return 逻辑
            target_ws = get_first_empty_workspace()
            exec_cmd = (
                f"flatpak run {target_app.app_id}" if is_flatpak(target_app.path) else f"gtk-launch {target_app.app_id}"
            )
            subprocess.Popen(["swaymsg", f"workspace {target_ws}; exec {exec_cmd}"])
        return

    report_exception(
        error=Exception(f"No match window/application: {selected_name}"),
        notify=True,
    )


def main() -> None:
    # 1. 解析命令行参数
    args = parse_arguments()
    theme = args.theme

    # 将参数解析为列表，例如 ["window", "drun"]
    show_list = [s.strip() for s in args.show_types.split(",")]

    # 2. 根据参数按需获取数据并构建 Rofi 行
    windows, apps, rofi_lines = build_rofi_lines(show_list)

    if not rofi_lines:
        return

    # 3. 调用 Rofi
    rofi_cmd = build_rofi_command(theme, rofi_lines)
    selected_name, proc_returncode = execute_rofi_and_get_selection(rofi_cmd, rofi_lines)

    # 4. 处理选中项
    if not selected_name:
        return

    handle_selected_item(selected_name, windows, apps, proc_returncode)


if __name__ == "__main__":
    main()


# import cProfile
# cProfile.run("main()", sort="tottime")
