# Color Picker
import subprocess

from .tool import Tool


class ColorPicker(Tool):
    """取色器，依赖 grimpicker"""

    _name: str

    def __init__(self, name: str = "Color Picker"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "eye-dropper"

    def run(self) -> None:
        subprocess.run(["grimpicker", "--copy"])
