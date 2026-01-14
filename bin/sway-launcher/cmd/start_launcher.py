"""启动器主入口模块。

处理命令行参数并根据配置动态创建相应的条目提供者，
整合窗口、应用和工具条目，并通过 Rofi 显示界面。
"""

import argparse

from utils.exception_handler import report_exception
from utils.launcher import Config, Item, ItemProvider, Launcher, Theme
from utils.rofi_picker import RofiPicker

from .drun_item import AppItemProvider
from .tool_item import ToolItemProvider
from .window_item import WindowItemProvider


def create_providers(config: Config) -> list[ItemProvider[Item]]:
    """根据配置动态创建提供者"""
    # fmt: off
    mapping: dict[str, type[ItemProvider[Item]]] = {
        "window": WindowItemProvider,  # 运行中的窗口
        "drun":   AppItemProvider,     # 已安装的应用
        "tool":   ToolItemProvider,    # 自定义工具
    }
    # fmt: on
    return [mapping[t]() for t in config.show_types if t in mapping]


def start_launcher(args: argparse.Namespace) -> None:
    # 参数验证
    theme = args.theme
    if not Theme.is_valid(theme):
        report_exception(
            error=Exception(f"Unknown theme '{theme}', falling back to {Theme.default()} (default) theme."),
            notify=True,
        )
        theme = Theme.default()

    config = Config(
        prompt="Launcher",
        theme=theme,
        extra_args=["-kb-accept-alt", "", "-kb-custom-1", "Shift+Return"],
        show_types=args.show.split(",") if args.show else ["window", "drun"],  # 默认显示类型
    )

    launcher = Launcher[Item](
        config=config,
        picker=RofiPicker(),
        item_providers=create_providers(config),
    )

    # 启动 launcher
    launcher.launch()
