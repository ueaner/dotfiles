"""基于 rofi -dmenu 的窗口切换、桌面应用与自定义工具启动器。

该脚本整合了当前打开的窗口列表和系统应用列表（drun），以及自定义工具列表。
支持图标展示并遵循 XDG 规范进行去重过滤。
支持通过快捷键 Shift+Return 在新工作区中打开选中的应用（尊重 Sway 中为特定应用指定所属工作区的配置）。
支持多种视觉布局模式（如菜单、面板、全屏启动板）。
"""

import argparse
import logging

from config import DESKTOP_DIRS, TOOLS
from tool.tool import Tool
from utils.exception_handler import report_exception
from utils.launcher import Config, Launcher, RunnableItem, Theme
from utils.loaders import load_instances
from utils.rofi_picker import RofiPicker
from utils.sway_helper import get_all_apps, get_running_windows

from .drun_item import AppItem
from .tool_item import ToolItem
from .window_item import WindowItem


def cmd_launcher(args: argparse.Namespace) -> None:
    # 参数验证
    theme = args.theme
    if not Theme.is_valid(theme):
        report_exception(
            error=Exception(f"Unknown theme '{theme}', falling back to {Theme.default()} (default) theme."),
            notify=True,
        )
        theme = Theme.default()

    # 创建应用启动器实例
    launcher = CmdLauncher(
        Config(
            prompt="Launcher",
            theme=theme,
            extra_args=["-kb-accept-alt", "", "-kb-custom-1", "Shift+Return"],
            show_types=args.show.split(",") if args.show else ["window", "drun"],  # 默认显示类型
        ),
        RofiPicker(),
    )

    # 启动 launcher
    launcher.launch()


"""启动器实现，使用抽象的 Launcher 协议"""


class CmdLauncher(Launcher[RunnableItem]):
    """启动器实现"""

    logger = logging.getLogger(__name__)

    def items(self) -> list[RunnableItem]:
        """获取要显示的项目列表"""
        picker_items: list[RunnableItem] = []

        # 获取运行中的窗口
        if "window" in self.config.show_types:
            windows = get_running_windows()
            # 对齐 app_id 字段右补全空格或截断，便于在 Rofi 上整齐显示
            max_len = max((len(w.app_id) for w in windows), default=0)
            for w in windows:
                picker_items.append(WindowItem(w, self.config.theme, max_len))

        # 获取已安装的应用
        if "drun" in self.config.show_types:
            apps = get_all_apps(DESKTOP_DIRS)
            for app in apps:
                picker_items.append(AppItem(app))

        # 获取自定义工具
        if "tool" in self.config.show_types:
            tools: list[Tool] = load_instances(TOOLS)
            for tool in tools:
                picker_items.append(ToolItem(tool))

        return picker_items
