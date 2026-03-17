"""Launcher Item 的具体实现。"""

from compositor import Compositor, Window
from core.protocols import Config, Entry, Item, ItemProvider, Layout

# 定义窗口条目的标识符，以便在匹配时与其他条目类型区分（如桌面应用）
MARKER_WINDOW = "\u200b"
ALIGN_MAX_LEN = 25


class WindowItem(Item):
    """窗口条目的具体实现"""

    data: Window
    layout: Layout
    align_len: int
    prefix_len: int

    def __init__(self, data: Window, layout: Layout, align_len: int):
        self.data = data
        self.layout = layout
        self.align_len = align_len
        self.prefix_len = align_len - 3

    @property
    def icon(self) -> str:
        return self.data.icon

    @property
    def name(self) -> str:
        if self.layout in (Layout.BOARD, Layout.LAUNCHPAD):
            # 横向排列显示，添加零宽字符标记，整体缩短显示长度
            display_name = f"{MARKER_WINDOW}{self.data.app_id}"
        else:
            # 纵向排列显示
            dot = "·"
            if len(self.data.app_id) > self.align_len:
                # 截断并添加3个点
                display_name = f"{self.data.app_id[: self.prefix_len]}... {dot} {self.data.name}"
            else:
                # 右侧补空格
                display_name = f"{self.data.app_id.ljust(self.align_len)} {dot} {self.data.name}"

        return f"{display_name}"

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        await compositor.focus_window(str(self.data.id))


class WindowItemProvider(ItemProvider[Item]):
    layout = Layout.BOARD  # pyright: ignore

    async def items(self, config: Config, compositor: Compositor) -> list[Item]:
        windows = await compositor.windows()
        # 对齐 app_id 字段右补全空格或截断，以便在 Picker 上整齐显示
        max_len = max((len(w.app_id) for w in windows), default=0)
        align_len = min(max_len, ALIGN_MAX_LEN)
        layout = config.layout if config.layout else self.layout
        return [WindowItem(w, layout, align_len) for w in windows]

    def to_entry(self, item: Item) -> Entry:
        """将 WindowItem 转换为结构化的 Entry"""
        return Entry(text=item.name, icon=item.icon, active=True, markup=True)
