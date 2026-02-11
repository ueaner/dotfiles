# Clipboard
import subprocess

from utils.launcher import Item


class Clipboard(Item):
    _name: str

    def __init__(self, name: str = "Clipboard"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "clipboard"

    def run(self, returncode: int = 0) -> None:
        subprocess.run(
            ["rofi", "-show", "clipboard", "-modes", "clipboard:~/.local/bin/cliphist-rofi-img", "-show-icons"]
        )
