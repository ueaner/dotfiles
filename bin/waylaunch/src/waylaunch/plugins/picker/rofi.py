"""Rofi 选择器实现"""

import asyncio
import math
import shutil
from asyncio.subprocess import PIPE
from typing import Final

from waylaunch.core.config import Config
from waylaunch.core.logger import logger
from waylaunch.core.models import Layout
from waylaunch.core.protocols import Entry, Picker
from waylaunch.core.registry import registry

# Rofi 脚本行协议常量：用于分割显示文本、元数据和属性
ROFI_NULL: Final = "\0"  # 分割显示文本与配置项
ROFI_SEP: Final = "\x1f"  # 分割各配置项对 (key\x1fvalue)


def calculate_window_size(
    count: int, max_cols: int = 5, max_lines: int = 3
) -> tuple[int, int, str, str]:
    """
    计算 Rofi 窗口的动态布局。
    根据条目数量自动调整列数和行数，并估算窗口的 em 宽度以确保视觉紧凑。

    Args:
        count: 条目个数。
        max_cols: 最大列数。
        max_lines: 最大行数。
    """
    cols = max(1, min(count, max_cols))
    lines = max(1, min(math.ceil(count / max_cols), max_lines))

    # height (em): 2 + (lines - 1) + 7.3 * lines
    #
    #   2em:           window { padding: 1em }
    #   (lines - 1)em:  listview { spacing: 1em; }
    #   7.3 * lines:
    #     2.3em:       element { padding: 1em; spacing: 0.3em; }
    #     3em:         element-icon { size: 3em; }
    #     2em:         element-text: 1em or 2em (-eh 2)

    unit_val = 7.3
    width = round(2 + (cols - 1) + unit_val * cols, 1)
    height = round(2 + (lines - 1) + unit_val * lines, 1)

    return cols, lines, f"{width}em", f"{height}em"


@registry.register("rofi")
class RofiPicker(Picker):
    """Rofi 选择器实现，支持 dmenu 模式协议。"""

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
        """检查系统中是否存在 rofi 可执行文件"""
        return shutil.which(cls().command) is not None

    def is_cancelled(self, returncode: int) -> bool:
        """
        判断用户是否取消了选择

        Args:
            returncode: 返回码。
                - 0: 正常选择
                - 1: 取消/退出
                - 10-28: 自定义组合键
        """
        return returncode == 1

    async def show(self, entries: list[Entry], config: Config) -> tuple[int, str, int]:
        """渲染 Rofi 界面并处理用户交互"""
        if not entries:
            return -1, "", 0

        # 1. 序列化数据：将 Entry 对象转为 Rofi 协议行
        rows = [self._serialize_entry(e, config) for e in entries]
        input_data = "\n".join(rows)

        # 2. 构建并执行命令
        cmd = self.build_command(config, rows)
        output, code = await self._execute(cmd, input_data)

        logger.info(f"rofi exit: {code}, output: {output}")

        if not output or self.is_cancelled(code):
            return -1, "", code

        # 3. 解析输出格式 "i s" (索引 选中文本)
        idx, _, text = output.partition(" ")
        return int(idx), text, code

    def _serialize_entry(self, entry: Entry, config: Config) -> str:
        """
        将条目转换为 Rofi 脚本行协议格式。
        格式: 显示文本\0配置键1\x1f值1\x1f配置键2\x1f值2...
        """
        layout = config.picker.layout or self.layout
        search_text = entry.title
        options: list[str] = []

        # 处理列表模式下的副标题对齐
        if layout == Layout.MENU and entry.subtitle:
            align_len = min(entry.title_max_len, config.picker.align_max_len)
            # 处理标题过长的情况
            display = (
                f"{entry.title[: align_len - 3]}..."
                if len(entry.title) > align_len
                else entry.title.ljust(align_len)
            )

            options.append(f"display{ROFI_SEP}{display} · {entry.subtitle}")
            # 搜索文本包含标题和副标题，增加搜索命中率
            search_text = f"{entry.title} {entry.subtitle}"

        # 映射属性到 Rofi 行选项
        attr_map = {
            "icon": entry.icon,
            "meta": entry.meta,
            "urgent": "true" if entry.urgent else None,
            "active": "true" if entry.active else None,
            "markup": "true" if entry.markup else None,
        }

        for key, val in attr_map.items():
            if val:
                options.append(f"{key}{ROFI_SEP}{val}")

        return f"{search_text}{ROFI_NULL}{ROFI_SEP.join(options)}"

    def build_command(self, config: Config, rows: list[str]) -> list[str]:
        """构建 Rofi 命令"""
        p = config.picker
        layout = p.layout or self.layout

        cmd = [
            self.command,
            "-dmenu",
            "-i",
            "-matching",
            "fuzzy",
            "-markup-rows",
            "-format",
            "i s",  # 输出格式：索引 + 空格 + 条目文本
            "-p",
            p.prompt or self.prompt,
        ]

        # 添加按键绑定相关参数
        cmd += self._get_keybinding_args(config)

        # 自动检测是否需要多行支持 (如果标题包含换行符)
        if any(ROFI_NULL in r.partition(ROFI_NULL)[0] for r in rows):
            cmd += ["-eh", "2"]

        # 添加主题相关参数
        cmd += self._get_theme_args(layout, len(rows), config)

        logger.info(f"{cmd=}")

        return cmd

    def _get_keybinding_args(self, config: Config) -> list[str]:
        """配置自定义快捷键并自动解决内置键位冲突"""
        kb = config.picker.keybindings
        # 记录用户占用的键位（转小写以便匹配）
        user_keys = {k.lower() for k in (kb.custom_1 + kb.custom_2 + kb.custom_3)}

        args: list[str] = []

        # 1. 冲突检测：若有重合则置空内置键
        builtin_conflicts = {
            "-kb-accept-alt": "shift+return",
            "-kb-accept-custom": "control+return",
            "-kb-accept-custom-alt": "control+shift+return",
        }
        for flag, key in builtin_conflicts.items():
            if key in user_keys:
                args += [flag, ""]

        # 2. 映射自定义键
        custom_map = {
            "-kb-custom-1": kb.custom_1,
            "-kb-custom-2": kb.custom_2,
            "-kb-custom-3": kb.custom_3,
        }
        for flag, keys in custom_map.items():
            if keys:
                args += [flag, ",".join(keys)]

        return args

    def _get_theme_args(self, layout: Layout | None, count: int, config: Config) -> list[str]:
        """根据布局类型返回对应的主题和 CSS 覆盖参数"""
        themes = config.picker.themes

        # 菜单 menu, 面板 board, 全屏 launchpad
        match layout:
            case Layout.BOARD:
                cols, lines, w, _ = calculate_window_size(count)
                # 使用 -theme-str 动态修改 Rofi 主题中的变量
                layout_css = f"listview {{columns:{cols};lines:{lines};}} window {{width:{w};}}"
                return ["-theme", themes.board, "-theme-str", layout_css]

            case Layout.LAUNCHPAD:
                return ["-theme", themes.launchpad]

            case Layout.MENU:
                return ["-theme", themes.menu]

            case _:
                return []

    async def _execute(self, cmd: list[str], input_str: str) -> tuple[str, int]:
        """执行底层子进程通讯，返回选择结果"""
        proc = await asyncio.create_subprocess_exec(*cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
        stdout, stderr = await proc.communicate(input_str.encode())

        if stderr:
            logger.debug(f"Rofi error output: {stderr.decode().strip()}")

        return stdout.decode().strip(), proc.returncode or 0
