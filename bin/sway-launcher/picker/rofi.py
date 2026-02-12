"""Rofi 选择器实现"""

import math
import subprocess

from core.contract import Config, Entry, Picker, Theme
from utils.exception_handler import report_exception


def calculate_window_size(count: int, max_cols: int = 5, max_lines: int = 3) -> tuple[int, int, str, str]:
    """
    计算 Rofi 布局。每列最多 max_cols 个，最多 max_lines 行。

    Args:
        count: 条目个数。
        max_cols: 最大列数。
        max_lines: 最大行数。
    """
    cols = min(count, max_cols)
    lines = min(math.ceil(count / max_cols), max_lines)

    # height (em): 2 + (lines - 1) + 7.3 * lines
    #
    #   2em:           window { padding: 1em }
    #   (lines - 1)em:  listview { spacing: 1em; }
    #   7.3 * lines:
    #     2.3em:       element { padding: 1em; spacing: 0.3em; }
    #     3em:         element-icon { size: 3em; }
    #     2em:         element-text: 1em or 2em (-eh 2)

    width = round(2 + (cols - 1) + 7.3 * cols, 1)
    height = round(2 + (lines - 1) + 7.3 * lines, 1)

    return cols, lines, f"{width}em", f"{height}em"


class RofiPicker(Picker):
    """Rofi 选择器实现"""

    def __init__(
        self,
        command: str = "rofi",
        prompt: str = "Launcher",
        theme: Theme | None = None,
        extra_args: list[str] | None = None,
    ):
        self.command = command
        self.prompt = prompt
        self.theme = theme or Theme.default()
        self.extra_args = extra_args or []

    def is_cancelled(self, returncode: int) -> bool:
        """判断用户是否取消了选择

        Rofi 返回码说明:
        0: 成功选定
        1: 用户取消 (Esc / 点击外部)
        10-28: 自定义键位 (Custom Keybindings)
        """
        # 通常只有 returncode 为 0 或自定义键位时才继续
        return returncode == 1

    def _serialize_entry(self, entry: Entry) -> str:
        """将 Entry 对象转换为 Rofi 脚本协议格式
        格式参考: text\0icon\x1ficon_name\x1fmeta\x1fsearch_terms
        """
        # Rofi 的协议中，text 后面紧跟 \0 进入选项部分，选项间用 \x1f 分割
        parts = [entry.text, "\0"]
        options: list[str] = []

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

    def show(self, entries: list[Entry], config: Config) -> tuple[str, int]:
        """显示 Rofi 并返回用户选择的结果"""
        if not entries:
            return "", 0

        # 将 Entry 列表序列化为 Rofi 识别的字符串列表
        rows = [self._serialize_entry(e) for e in entries]

        # 构建命令
        rofi_cmd = self.build_command(config, rows)

        # 构建输入
        input_str = "\n".join(rows)

        # 执行命令
        selected_name, proc_returncode = self.execute_command(rofi_cmd, input_str)

        return selected_name, proc_returncode

    def build_command(self, config: Config, rows: list[str]) -> list[str]:
        """构建 Rofi 命令"""
        # 从配置中获取参数
        theme = config.theme if config.theme else self.theme
        prompt = config.prompt if config.prompt else self.prompt
        extra_args = config.extra_args if config.extra_args else self.extra_args

        cmd = [
            self.command,
            "-dmenu",
            "-i",
            "-p",
            prompt,
            "-matching",
            "fuzzy",
            "-markup-rows",  # 支持 Pango Markup
        ]

        # 检查是否需要支持多行显示
        if any("\r" in row.split("\0")[0] for row in rows):
            # -eh 2 允许 element-text 使用 "\r" 显示为两行，
            # 使用 " ".join(display_name.split()) == " ".join(selected_name.split()) 匹配选中项
            cmd.extend(["-eh", "2"])

        # 添加额外参数（如键盘绑定）
        cmd.extend(extra_args)

        # 根据主题添加特定选项
        cmd.extend(self.add_theme_options(theme, rows))

        return cmd

    def add_theme_options(self, theme: Theme, rows: list[str]) -> list[str]:
        """根据主题添加选项"""
        if not Theme.is_valid(theme):
            report_exception(
                error=Exception(f"Unknown theme '{theme}', falling back to {Theme.default()} (default) theme."),
                notify=True,
            )
            return []

        # 菜单 menu, 面板 panel, 全屏 launchpad
        match theme:
            case Theme.PANEL:
                # 计算 Rofi 布局
                cols, lines, width, _ = calculate_window_size(len(rows))
                # 设置 window width 确保单个工具的显示不会太宽
                theme_str = f"listview {{ columns: {cols}; lines: {lines}; }} window {{ width: {width}; }}"
                return ["-theme", "panel", "-theme-str", theme_str]

            case Theme.LAUNCHPAD:
                return ["-theme", "launchpad"]

            case Theme.MENU:
                return ["-theme", "menu"]

    def execute_command(self, cmd: list[str], input_str: str) -> tuple[str, int]:
        """执行命令并获取结果"""
        proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
        )
        stdout, _ = proc.communicate(input=input_str)
        # 获取用户选择和返回码
        return stdout.strip(), proc.returncode
