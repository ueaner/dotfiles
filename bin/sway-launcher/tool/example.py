import subprocess

from core.contract import Item

from .run_commands import run_commands


# grim -g "$(slurp -p)" -t ppm - | magick - -format "%[pixel:p{0,0}]" txt:- | tail -n 1 | cut -d " " -f 4 | wl-copy
class Example(Item):
    _name: str

    def __init__(self, name: str = "Color Picker"):
        self._name = name

    def name(self) -> str:
        return self._name

    def icon(self) -> str:
        return "eye-dropper"

    def run(self, returncode: int = 0) -> None:
        # 获取坐标
        proc = subprocess.run(["slurp", "-p"], capture_output=True, text=True)
        if proc.returncode != 0:
            return

        geom = proc.stdout.strip()
        # 链式命令执行
        cmds = [
            ["grim", "-g", geom, "-t", "ppm", "-"],
            ["magick", "-", "-format", "%[pixel:p{0,0}]", "txt:-"],
            ["tail", "-n", "1"],
            ["cut", "-d", " ", "-f", "4"],
            ["wl-copy", "-n"],
        ]
        run_commands(cmds)
        subprocess.run(["notify-send", "Color Picker", "Color copied to clipboard."])
