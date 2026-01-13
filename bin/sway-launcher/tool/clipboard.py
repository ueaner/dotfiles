# Clipboard
import subprocess


class Clipboard:
    _name: str

    def __init__(self, name: str = "Clipboard"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "clipboard"

    def run(self) -> None:
        subprocess.run(
            ["rofi", "-show", "clipboard", "-modes", "clipboard:~/.local/bin/cliphist-rofi-img", "-show-icons"]
        )
