# Yazi File Manager

from compositor import Compositor
from core.protocols import Item


class Yazi(Item):
    _name: str

    def __init__(self, name: str = "Yazi"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "yazi"

    # swaymsg '[app_id="yazi"] focus' || foot --app-id=yazi -e yazi
    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        await compositor.exec(["swaymsg '[app_id=yazi] focus' || foot --app-id=yazi -e yazi"])

        # # 1. 尝试聚焦应用
        # ok = await compositor.focus_application("yazi")

        # # 2. 聚焦失败 (表示应用未启动)，则启动程序
        # if not ok:
        #     await compositor.exec(["foot --app-id=yazi -e yazi"])
