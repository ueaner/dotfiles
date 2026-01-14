# Yazi File Manager
import subprocess

from .tool import Tool


class Yazi(Tool):
    _name: str

    def __init__(self, name: str = "Yazi"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "yazi"

    # swaymsg '[app_id="yazi"] focus' || foot --app-id=yazi -e yazi
    def run(self) -> None:
        # 1. 尝试执行聚焦命令
        # capture_output=True 用于隐藏控制台输出
        result = subprocess.run(["swaymsg", '[app_id="yazi"] focus'], capture_output=True)

        # 2. 如果返回码不为 0 (表示没找到窗口)，则启动程序
        if result.returncode != 0:
            # 使用 Popen 启动后台进程，这样 Python 脚本不会被阻塞
            subprocess.Popen(["foot", "--app-id=yazi", "-e", "yazi"])
