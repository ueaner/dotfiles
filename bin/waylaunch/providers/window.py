"""Launcher Item 的具体实现。"""

from compositor import Compositor, Window
from core.protocols import Config, Entry, Item, ItemProvider, Theme

# 常用的零宽字符有: "\u200b" "\u200c" "\u200d" "\ufeff"

# 定义窗口条目的标识符，以便在匹配时与其他条目类型区分（如桌面应用）
MARKER_WINDOW = "\u200c"
ALIGN_MAX_LEN = 25


class WindowItem(Item):
    """窗口条目的具体实现"""

    data: Window
    theme: Theme
    align_len: int
    prefix_len: int

    def __init__(self, data: Window, theme: Theme, align_len: int):
        self.data = data
        self.theme = theme
        self.align_len = align_len
        self.prefix_len = align_len - 3

    def icon(self) -> str:
        return self.data.icon

    def name(self) -> str:
        if self.theme in (Theme.PANEL, Theme.LAUNCHPAD):
            # 横向排列显示，整体缩短 display_name 显示长度
            # 追加一个 · ● 🔘 标记
            display_name = f"{self.data.app_id}"
        else:
            dot = "<span color='black'>·</span>"
            if len(self.data.app_id) > self.align_len:
                # 截断并添加3个点
                display_name = f"{self.data.app_id[: self.prefix_len]}... {dot} {self.data.name}"
            else:
                # 右侧补空格
                display_name = f"{self.data.app_id.ljust(self.align_len)} {dot} {self.data.name}"

        # 添加零宽字符标记
        return f"{MARKER_WINDOW}{display_name}"

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        await compositor.focus_window(str(self.data.id))


class WindowItemProvider(ItemProvider[Item]):
    async def items(self, config: Config, compositor: Compositor) -> list[Item]:
        windows = await compositor.windows()
        # 对齐 app_id 字段右补全空格或截断，便于在 Rofi 上整齐显示
        max_len = max((len(w.app_id) for w in windows), default=0)
        align_len = min(max_len, ALIGN_MAX_LEN)
        return [WindowItem(w, config.theme, align_len) for w in windows]

    def to_entry(self, item: Item) -> Entry:
        """将 WindowItem 转换为结构化的 Entry"""
        return Entry(text=item.name(), icon=item.icon(), active=True, markup=True)
