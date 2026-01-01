import subprocess

from .run_commands import run_commands


# grim -g "$(slurp -p)" -t ppm - | magick - -format "%[pixel:p{0,0}]" txt:- | tail -n 1 | cut -d " " -f 4 | wl-copy
class Example:
    def __init__(self, name="Color Picker"):
        self._name = name

    def name(self):
        return self._name

    def icon(self):
        return "eye-dropper"

    def run(self):
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
