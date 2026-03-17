from pathlib import Path

from compositor import Compositor
from core.protocols import Config, Entry, Item, ItemProvider, Layout
from providers.xdg_desktop_entry import App, get_all_apps

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

    @property
    def icon(self) -> str:
        return self.data.icon

    @property
    def name(self) -> str:
        return self.data.name

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        if "flatpak" in self.data.path.lower():
            cmd = f"flatpak run {self.data.app_id}"
        else:
            # cmd = f"gtk-launch {self.data.app_id}"
            cmd = f"gio launch {self.data.path}"

        if returncode == 0:
            await compositor.exec([cmd])
        elif returncode == 10:  # Shift+Return 逻辑
            target_ws = await compositor.first_empty_workspace()
            await compositor.exec([cmd], str(target_ws))


class AppItemProvider(ItemProvider[AppItem]):
    layout = Layout.LAUNCHPAD  # pyright: ignore

    async def items(self, config: Config, compositor: Compositor) -> list[AppItem]:
        apps = get_all_apps(DESKTOP_DIRS)
        return [AppItem(app) for app in apps]

    def to_entry(self, item: AppItem) -> Entry:
        """将 AppItem 转换为结构化的 Entry"""
        return Entry(
            text=item.name,
            icon=item.icon,
            # 传递隐藏的搜索关键词
            meta=item.data.generic if item.data.generic else "",
        )
