import subprocess

from utils.launcher import RunnableItem
from utils.sway_helper import App


class AppItem(RunnableItem):
    """应用项目的具体实现"""

    data: App

    def __init__(self, data: App):
        self.data = data

    def icon(self) -> str:
        return self.data.icon

    def name(self) -> str:
        return self.data.name

    def format(self) -> str:
        if self.data.generic:
            # 传递搜索关键词，将 generic 信息填入 meta 字段，Rofi 会搜索它但不会显示它
            return f"{self.name()}\0icon\x1f{self.icon()}\x1fmeta\x1f{self.data.generic}"
        else:
            return f"{self.name()}\0icon\x1f{self.icon()}"

    def run(self, returncode: int = 0) -> None:
        if returncode == 0:
            subprocess.Popen(["gtk-launch", self.data.app_id], stdout=subprocess.DEVNULL)
        elif returncode == 10:
            from utils.sway_helper import get_first_empty_workspace

            target_ws = get_first_empty_workspace()
            subprocess.Popen(["swaymsg", f"workspace {target_ws}; exec {self.data.exec}"])
