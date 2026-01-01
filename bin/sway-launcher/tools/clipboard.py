# Clipboard
import subprocess


class Clipboard:
    def __init__(self, name="Clipboard"):
        self._name = name

    def name(self):
        return self._name

    def icon(self):
        return "clipboard"

    def run(self):
        subprocess.run(["rofi", "-show", "clipboard", "-modes", "clipboard:~/.local/bin/cliphist-rofi-img", "-show-icons"])
