from config import FA_ICON_DIR
from tool.tool import Tool
from utils.icon_finder import find_fa_icon
from utils.launcher import RunnableItem

# ToolItem = Tool


class ToolItem(RunnableItem):
    """工具启动器的项目类型"""

    data: Tool

    def __init__(self, data: Tool):
        self.data = data

    def icon(self) -> str:
        return self.data.icon()

    def name(self) -> str:
        return self.data.name()

    def format(self) -> str:
        """格式化显示字符串"""
        icon_path = find_fa_icon(self.icon(), FA_ICON_DIR)
        return f"{self.name()}\0icon\x1f{icon_path}"

    def run(self, returncode: int = 0) -> None:
        self.data.run()
