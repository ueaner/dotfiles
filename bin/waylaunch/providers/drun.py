import asyncio
from asyncio.subprocess import DEVNULL
from pathlib import Path

from compositor import Compositor
from core.protocols import Config, Entry, Item, ItemProvider
from utils.xdg_desktop_entry import App, get_all_apps

# 高优先级目录在前
DESKTOP_DIRS = [
    Path.home() / ".local/share/applications",
    Path.home() / ".local/share/flatpak/exports/share/applications",
    Path("/usr/share/applications"),
]


class AppItem(Item):
    """应用条目的具体实现"""

    data: App

    def __init__(self, data: App):
        self.data = data

    def icon(self) -> str:
        return self.data.icon

    def name(self) -> str:
        return self.data.name

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        if "flatpak" in self.data.path.lower():
            exec_cmd = ["flatpak", "run", self.data.app_id]
        else:
            exec_cmd = ["gtk-launch", self.data.app_id]

        if returncode == 0:
            await asyncio.create_subprocess_exec(
                *exec_cmd,
                # 脱离终端交互
                stdout=DEVNULL,
                stderr=DEVNULL,
                stdin=DEVNULL,
                # 让应用在新的会话中运行，不受 Python 退出影响
                start_new_session=True,
            )
        elif returncode == 10:  # Shift+Return 逻辑
            target_ws = await compositor.first_empty_workspace()
            await compositor.exec([" ".join(exec_cmd)], str(target_ws))


class AppItemProvider(ItemProvider[AppItem]):
    async def items(self, config: Config, compositor: Compositor) -> list[AppItem]:
        apps = get_all_apps(DESKTOP_DIRS)
        return [AppItem(app) for app in apps]

    def to_entry(self, item: AppItem) -> Entry:
        """将 AppItem 转换为结构化的 Entry"""
        return Entry(
            text=item.name(),
            icon=item.icon(),
            # 传递隐藏的搜索关键词
            meta=item.data.generic if item.data.generic else "",
        )
