# Color Picker

from compositor import Compositor
from core.protocols import Item


class ColorPicker(Item):
    """取色器，依赖 grimpicker"""

    _name: str

    def __init__(self, name: str = "Color Picker"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "fa-eye-dropper"

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        await compositor.exec(["grimpicker --copy"])
