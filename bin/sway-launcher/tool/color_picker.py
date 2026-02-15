# Color Picker
import subprocess

from core.contract import Item


class ColorPicker(Item):
    """取色器，依赖 grimpicker"""

    _name: str

    def __init__(self, name: str = "Color Picker"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "fa-eye-dropper"

    def run(self, returncode: int = 0) -> None:
        subprocess.run(["grimpicker", "--copy"])
