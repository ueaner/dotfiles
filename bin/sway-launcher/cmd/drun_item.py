import subprocess

from config import DESKTOP_DIRS
from utils.launcher import Config, Item, ItemProvider
from utils.sway_helper import App, get_all_apps


class AppItem(Item):
    """应用条目的具体实现"""

    data: App

    def __init__(self, data: App):
        self.data = data

    def icon(self) -> str:
        return self.data.icon

    def name(self) -> str:
        return self.data.name

    def run(self, returncode: int = 0) -> None:
        if "flatpak" in self.data.path.lower():
            exec_cmd = ["flatpak", "run", self.data.app_id]
        else:
            exec_cmd = ["gtk-launch", self.data.app_id]

        if returncode == 0:
            subprocess.Popen(exec_cmd, stdout=subprocess.DEVNULL)
        elif returncode == 10:  # Shift+Return 逻辑
            from utils.sway_helper import get_first_empty_workspace

            target_ws = get_first_empty_workspace()
            subprocess.Popen(["swaymsg", f"workspace {target_ws}; exec {' '.join(exec_cmd)}"])


class AppItemProvider(ItemProvider[AppItem]):
    def items(self, config: Config) -> list[AppItem]:
        apps = get_all_apps(DESKTOP_DIRS)
        return [AppItem(app) for app in apps]

    def format(self, item: AppItem) -> str:
        if item.data.generic:
            # 传递搜索关键词，将 generic 信息填入 meta 字段，Rofi 会搜索它但不会显示它
            return f"{item.name()}\0icon\x1f{item.icon()}\x1fmeta\x1f{item.data.generic}"
        else:
            return f"{item.name()}\0icon\x1f{item.icon()}"
