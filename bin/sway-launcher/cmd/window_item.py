"""Launcher Item 的具体实现。"""

import subprocess

from utils.launcher import RunnableItem, Theme
from utils.sway_helper import App

# 使用零宽字符做标记，避免和桌面应用重名而匹配不到，如 "\u200b" "\u200c" "\u200d" "\ufeff"
MARKER_WINDOW = "\u200c"
ALIGN_MAX_LEN = 25


class WindowItem(RunnableItem):
    """窗口项目的具体实现"""

    data: App
    theme: Theme
    align_len: int

    def __init__(self, data: App, theme: Theme, max_len: int):
        self.data = data
        self.theme = theme
        self.align_len = min(max_len, ALIGN_MAX_LEN)

    def icon(self) -> str:
        return self.data.icon

    def name(self) -> str:
        if self.theme in (Theme.PANEL, Theme.LAUNCHPAD):
            # 横向排列显示，整体缩短 display_name 显示长度
            # 追加一个 · ● 🔘 标记
            display_name = f"{self.data.app_id}"
        else:
            if len(self.data.app_id) > self.align_len:
                # 截断并添加3个点
                display_name = f"{self.data.app_id[:22]}... · {self.data.name}"
            else:
                # 右侧补空格
                display_name = f"{self.data.app_id.ljust(self.align_len)} · {self.data.name}"

        # 添加零宽字符标记
        return f"{MARKER_WINDOW}{display_name}"

    def format(self) -> str:
        return f"{self.name()}\0icon\x1f{self.icon()}\x1factive\x1ftrue"

    def run(self, returncode: int = 0) -> None:
        subprocess.run(["swaymsg", f"[con_id={self.data.con_id}] focus"])
