"""Launcher 主入口。

处理命令行参数，根据配置动态创建数据提供者 (Provider)、
选择器 (Picker) 和合成器适配器 (Compositor)，并启动 Launcher 流程。
"""

from waylaunch.core.config import Config, RuntimeArgs
from waylaunch.core.launcher import Launcher
from waylaunch.core.logger import setup_logging
from waylaunch.core.protocols import Item
from waylaunch.plugins import create_providers, get_compositor, get_picker, load_plugins


async def start_launcher(args: RuntimeArgs) -> None:
    # 解析配置
    config = Config.load(args)
    # 配置日志
    setup_logging(filename=config.logging.file.path, level=config.logging.level)
    # 加载插件
    load_plugins()

    providers = create_providers(config.provider.plugins)
    picker = get_picker(config.picker.plugins)
    compositor = await get_compositor(config.compositor.plugins)

    if not picker:
        return None

    launcher = Launcher[Item](
        config=config,
        picker=picker,
        item_providers=providers,
        compositor=compositor,
    )

    # 启动 launcher
    async with launcher:
        await launcher.launch()
