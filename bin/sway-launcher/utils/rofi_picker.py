"""Rofi 选择器实现"""

import math
import subprocess

from utils.exception_handler import report_exception
from utils.launcher import Config, Picker, Theme


def calculate_window_size(count: int, max_cols: int = 5, max_rows: int = 3) -> tuple[int, int, str, str]:
    """
    计算 Rofi 布局。每列最多 max_cols 个，最多 max_rows 行。

    Args:
        count: 条目个数。
        max_cols: 最大列数。
        max_rows: 最大行数。
    """
    cols = min(count, max_cols)
    rows = min(math.ceil(count / max_cols), max_rows)

    # height (em): 2 + (rows - 1) + 7.3 * rows
    #
    #   2em:           window { padding: 1em }
    #   (rows - 1)em:  listview { spacing: 1em; }
    #   7.3 * rows:
    #     2.3em:       element { padding: 1em; spacing: 0.3em; }
    #     3em:         element-icon { size: 3em; }
    #     2em:         element-text: 1em or 2em (-eh 2)

    width = round(2 + (cols - 1) + 7.3 * cols, 1)
    height = round(2 + (rows - 1) + 7.3 * rows, 1)

    return cols, rows, f"{width}em", f"{height}em"


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

    def show(self, items: list[str], config: Config) -> tuple[str, int]:
        """显示 Rofi 并返回用户选择的结果"""
        if not items:
            return "", 0

        # 构建命令
        rofi_cmd = self.build_command(config, items)

        # 构建输入
        input_str = "\n".join(items)

        # 执行命令
        selected_name, proc_returncode = self.execute_command(rofi_cmd, input_str)

        return selected_name, proc_returncode

    def build_command(self, config: Config, items: list[str]) -> list[str]:
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
        ]

        # 检查是否需要支持多行显示
        if any("\r" in item for item in items):
            # -eh 2 允许 element-text 使用 "\r" 显示为两行，
            # 使用 " ".join(display_name.split()) == " ".join(selected_name.split()) 匹配选中项
            cmd.extend(["-eh", "2"])

        # 添加额外参数（如键盘绑定）
        cmd.extend(extra_args)

        # 根据主题添加特定选项
        cmd.extend(self.add_theme_options(theme, items))

        return cmd

    def add_theme_options(self, theme: Theme, items: list[str]) -> list[str]:
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
                cols, rows, width, _ = calculate_window_size(len(items))
                # 设置 window width 确保单个工具的显示不会太宽
                theme_str = f"listview {{ columns: {cols}; lines: {rows}; }} window {{ width: {width}; }}"
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
