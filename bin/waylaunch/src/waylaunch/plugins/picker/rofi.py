"""Rofi 选择器实现"""

import asyncio
import math
import shutil
from asyncio.subprocess import PIPE

from waylaunch.core.config import Config
from waylaunch.core.logger import logger
from waylaunch.core.models import Layout
from waylaunch.core.protocols import Entry, Picker
from waylaunch.core.registry import registry


def calculate_window_size(
    count: int, max_cols: int = 5, max_lines: int = 3
) -> tuple[int, int, str, str]:
    """
    计算 Rofi 布局。每列最多 max_cols 个，最多 max_lines 行。

    Args:
        count: 条目个数。
        max_cols: 最大列数。
        max_lines: 最大行数。
    """
    cols = min(count, max_cols) or 1
    lines = min(math.ceil(count / max_cols), max_lines) or 1

    # height (em): 2 + (lines - 1) + 7.3 * lines
    #
    #   2em:           window { padding: 1em }
    #   (lines - 1)em:  listview { spacing: 1em; }
    #   7.3 * lines:
    #     2.3em:       element { padding: 1em; spacing: 0.3em; }
    #     3em:         element-icon { size: 3em; }
    #     2em:         element-text: 1em or 2em (-eh 2)

    base_val = 7.3
    width = round(2 + (cols - 1) + base_val * cols, 1)
    height = round(2 + (lines - 1) + base_val * lines, 1)

    return cols, lines, f"{width}em", f"{height}em"


@registry.register("rofi")
class RofiPicker(Picker):
    """Rofi 选择器实现"""

    def __init__(
        self,
        command: str = "rofi",
        prompt: str = "Launcher",
        layout: Layout | None = None,
    ):
        self.command = command
        self.prompt = prompt
        self.layout = layout

    @classmethod
    def is_available(cls) -> bool:
        """检测 rofi 命令是否可用"""
        return shutil.which(cls().command) is not None

    def is_cancelled(self, returncode: int) -> bool:
        """判断用户是否取消了选择

        Rofi 返回码说明:
        0: 成功选定
        1: 用户取消 (Esc / 点击外部)
        10-28: 自定义键位 (Custom Keybindings)
        """
        # 通常只有 returncode 为 0 或自定义键位时才继续
        return returncode == 1

    def _serialize_entry(self, entry: Entry, config: Config) -> str:
        """将 Entry 对象转换为 Rofi 脚本协议格式
        Rofi 的协议中，text 后面紧跟 \0 进入选项部分，选项间用 \x1f 分割
        格式参考: text\0icon\x1ficon_name\x1fmeta\x1fsearch_terms
        """
        layout = config.picker.layout or self.layout
        text, display = entry.title, ""

        if layout not in (Layout.BOARD, Layout.LAUNCHPAD) and entry.subtitle:
            align_len = min(entry.title_max_len, config.picker.align_max_len)
            if len(entry.title) > align_len:
                display = f"{entry.title[: align_len - 3]}... · {entry.subtitle}"
            else:
                display = f"{entry.title.ljust(align_len)} · {entry.subtitle}"
            text = f"{entry.title}{entry.subtitle}"

        options: list[str] = []

        parts = [text, "\0"]
        if display:
            options.append(f"display\x1f{display}")

        if entry.icon:
            options.append(f"icon\x1f{entry.icon}")
        if entry.meta:
            options.append(f"meta\x1f{entry.meta}")
        if entry.urgent:
            options.append("urgent\x1ftrue")
        if entry.active:
            options.append("active\x1ftrue")
        if entry.markup:
            options.append("markup\x1ftrue")

        return "".join(parts) + "\x1f".join(options)

    async def show(self, entries: list[Entry], config: Config) -> tuple[int, str, int]:
        """显示 Rofi 并返回用户选择的结果"""
        if not entries:
            return -1, "", 0

        # 将 Entry 列表序列化为 Rofi 识别的字符串列表
        rows = [self._serialize_entry(e, config) for e in entries]

        # 构建命令
        cmd = self.build_command(config, rows)

        # 构建输入
        input_str = "\n".join(rows)

        # 执行命令
        output, code = await self.execute_command(cmd, input_str)
        logger.info(f"rofi exit: {code}, output: {output}")
        if not output:
            return -1, "", code

        idx, _, text = output.partition(" ")
        return int(idx), text, code

    def _build_keybindings(self, config: Config) -> list[str]:
        """构建 Rofi 键映射，处理冲突检测"""
        kb = config.picker.keybindings
        # 将 custom 键位定义为元组，方便后续迭代处理
        custom_map = {
            "-kb-custom-1": kb.custom_1,
            "-kb-custom-2": kb.custom_2,
            "-kb-custom-3": kb.custom_3,
        }

        # 使用集合推导式快速获取所有用户键位（小写）
        user_keys_lower = {k.lower() for keys in custom_map.values() for k in keys}

        # 定义内置冲突映射
        builtin_conflicts = {
            "-kb-accept-alt": {"shift+return"},
            "-kb-accept-custom": {"control+return"},
            "-kb-accept-custom-alt": {"control+shift+return"},
        }

        result: list[str] = []

        # 1. 冲突检测：利用集合交集判断，若有重合则置空内置键
        for arg, conflicts in builtin_conflicts.items():
            if not conflicts.isdisjoint(user_keys_lower):
                result += [arg, ""]

        # 2. 映射自定义键：使用 dict.items() 减少重复的 if 分支
        for arg, keys in custom_map.items():
            if keys:
                result += [arg, ",".join(keys)]

        return result

    def build_command(self, config: Config, rows: list[str]) -> list[str]:
        """构建 Rofi 命令"""
        p = config.picker

        cmd = [
            self.command,
            "-dmenu",
            "-i",
            "-matching",
            "fuzzy",
            "-markup-rows",
            # 返回索引和选中条目内容
            "-format",
            "i s",
            "-p",
            p.prompt or self.prompt,
        ]

        # 处理键映射冲突检测
        cmd += self._build_keybindings(config)

        # 检查是否需要支持多行显示
        if any("\r" in r.partition("\0")[0] for r in rows):
            cmd += ["-eh", "2"]

        # 根据主题添加特定选项
        cmd += self.add_theme_options(p.layout or self.layout, rows, config)

        logger.info(f"{cmd=}")

        return cmd

    def add_theme_options(
        self, layout: Layout | None, rows: list[str], config: Config
    ) -> list[str]:
        """根据主题添加选项"""

        # 菜单 menu, 面板 board, 全屏 launchpad
        match layout:
            case Layout.BOARD:
                cols, lines, w, _ = calculate_window_size(len(rows))
                return [
                    "-theme",
                    config.picker.themes.board,
                    "-theme-str",
                    f"listview {{columns:{cols};lines:{lines};}} window {{width:{w};}}",
                ]

            case Layout.LAUNCHPAD:
                return ["-theme", config.picker.themes.launchpad]

            case Layout.MENU:
                return ["-theme", config.picker.themes.menu]

            case _:
                return []

    async def execute_command(self, cmd: list[str], input_str: str) -> tuple[str, int]:
        """异步执行命令并获取选择结果"""
        proc = await asyncio.create_subprocess_exec(*cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
        stdout, _ = await proc.communicate(input_str.encode())

        return stdout.decode().strip(), proc.returncode or 0
