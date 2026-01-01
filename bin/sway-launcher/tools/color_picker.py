import subprocess


class ColorPicker:
    """取色器，依赖 grimpicker"""

    def __init__(self, name="Color Picker"):
        self._name = name

    def name(self):
        return self._name

    def icon(self):
        return "eye-dropper"

    def run(self):
        subprocess.run(["grimpicker", "--copy"])
