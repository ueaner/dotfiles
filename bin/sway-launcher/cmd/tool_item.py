from config import FA_ICON_DIR
from tool.clipboard import Clipboard
from tool.color_picker import ColorPicker
from tool.yazi import Yazi
from utils.icon_finder import find_fa_icon
from utils.launcher import Config, Entry, Item, ItemProvider


def create_tools() -> list[Item]:
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
    tools: list[Item] = [
        ColorPicker(),  # 取色器
        Clipboard(),  # 剪切板
        Yazi(),  # 文件管理
    ]
    return tools


class ToolItemProvider(ItemProvider[Item]):
    def items(self, config: Config) -> list[Item]:
        tools: list[Item] = create_tools()
        return tools

    def to_entry(self, item: Item) -> Entry:
        """将 Item 转换为结构化的 Entry"""
        icon_path = find_fa_icon(item.icon(), FA_ICON_DIR)
        return Entry(text=item.name(), icon=icon_path)
