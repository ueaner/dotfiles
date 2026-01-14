from pathlib import Path

from config import FA_ICON_DIR
from tool.clipboard import Clipboard
from tool.color_picker import ColorPicker
from tool.tool import Tool
from tool.yazi import Yazi
from utils.icon_finder import find_fa_icon
from utils.launcher import Config, Item, ItemProvider


def create_tools() -> list[Tool]:
    """自定义工具列表"""
    # 方式1：工具类有改动时（如换目录、改名称等），无法实时捕获到明确的问题
    # tools: list[Tool] = load_instances(TOOLS_REGISTRY)

    # 方式2：可在配置参数中，通过 key 指定要加载的工具
    #        实现类似: python ~/bin/sway-launcher -run color_picker 的效果
    # # fmt: off
    # tool_classes: dict[str, type[Tool]] = {
    #     "color_picker": ColorPicker,  # 取色器
    #     "clipboard":    Clipboard,    # 剪切板
    #     "yazi":         Yazi,         # 文件管理
    # }
    # # fmt: on
    # tools = [cls() for cls in tool_classes.values()]

    # 方式3：
    tools: list[Tool] = [
        ColorPicker(),  # 取色器
        Clipboard(),  # 剪切板
        Yazi(),  # 文件管理
    ]
    return tools


class ToolItemProvider(ItemProvider[Item]):
    def items(self, config: Config) -> list[Item]:
        tools: list[Tool] = create_tools()
        return [ToolItem(tool, FA_ICON_DIR) for tool in tools]


class ToolItem(Item):
    """工具条目的具体实现"""

    data: Tool
    fa_icon_dir: Path

    def __init__(self, data: Tool, fa_icon_dir: Path):
        self.data = data
        self.fa_icon_dir = fa_icon_dir

    def icon(self) -> str:
        return self.data.icon()

    def name(self) -> str:
        return self.data.name()

    def format(self) -> str:
        """格式化显示字符串"""
        icon_path = find_fa_icon(self.icon(), self.fa_icon_dir)
        return f"{self.name()}\0icon\x1f{icon_path}"

    def run(self, returncode: int = 0) -> None:
        self.data.run()
