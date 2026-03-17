"""启动器主入口模块。

处理命令行参数并根据配置动态创建相应的条目提供者，
整合窗口、应用和工具条目，并通过 Rofi 显示界面。
"""

import argparse

from compositor import detector
from core.launcher import Launcher
from core.protocols import Config, Item, Layout
from picker.rofi import RofiPicker
from providers import create_providers


async def start_launcher(args: argparse.Namespace) -> None:
    layout = Layout(args.layout) if Layout.is_valid(args.layout) else None
    show_types: list[str] = args.show.split(",") if args.show else ["window", "drun"]

    providers = create_providers(show_types)

    if not layout:
        layouts = {p.layout for p in providers}
        layout = layouts.pop() if len(layouts) == 1 else Layout.default()

    config = Config(
        prompt="Launcher",
        layout=layout,
        extra_args=["-kb-accept-alt", "", "-kb-custom-1", "Shift+Return"],
        show_types=args.show.split(",") if args.show else ["window", "drun"],  # 默认显示类型
    )

    compositor = await detector.detect()

    launcher = Launcher[Item](
        config=config,
        picker=RofiPicker(),
        item_providers=providers,
        compositor=compositor,
    )

    # 启动 launcher
    async with launcher:
        await launcher.launch()
