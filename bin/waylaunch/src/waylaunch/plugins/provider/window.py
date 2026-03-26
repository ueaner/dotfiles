"""Launcher Item 的具体实现。"""

from waylaunch.compositor import Compositor, Window
from waylaunch.core.config import Config
from waylaunch.core.protocols import Entry, Item, ItemProvider
from waylaunch.core.registry import registry

# 定义窗口条目的标识符，以便在匹配时与其他条目类型区分（如桌面应用）
MARKER_WINDOW = "\u200b"


class WindowItem(Item):
    """窗口条目的具体实现"""

    data: Window
    title_max_len: int

    def __init__(self, data: Window, title_max_len: int):
        self.data = data
        self.title_max_len = title_max_len

    @property
    def icon(self) -> str:
        return self.data.icon

    @property
    def name(self) -> str:
        return f"{MARKER_WINDOW}{self.data.app_id}"

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        await compositor.focus_window(str(self.data.id))


@registry.register("window")
class WindowItemProvider(ItemProvider[WindowItem]):
    async def items(self, config: Config, compositor: Compositor) -> list[WindowItem]:
        windows = await compositor.windows()
        # 对齐 app_id 字段右补全空格或截断，以便在 Picker 上整齐显示
        title_max_len = max((len(w.app_id) for w in windows), default=0)
        return [WindowItem(w, title_max_len) for w in windows]

    def to_entry(self, item: WindowItem) -> Entry:
        """将 WindowItem 转换为结构化的 Entry"""
        return Entry(
            title=item.data.app_id,
            subtitle=item.name,
            title_max_len=item.title_max_len,
            icon=item.icon,
            active=True,
            markup=True,
        )
