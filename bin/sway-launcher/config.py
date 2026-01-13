import logging
from pathlib import Path

DEBUG_LOG = "/tmp/sway-launcher-debug.log"

# 日志配置，如果已经有其他地方配置过了，这里只会获取 logger
logging.basicConfig(
    filename=DEBUG_LOG,
    level=logging.INFO,  # 设置日志级别过滤门槛
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    encoding="utf-8",
)

# --------------- launchpad & mission control ---------------

# 高优先级目录在前
DESKTOP_DIRS = [
    Path.home() / ".local/share/applications",
    Path.home() / ".local/share/flatpak/exports/share/applications",
    Path("/usr/share/applications"),
]
ICON_DIRS = [
    Path("/usr/share/icons/hicolor/scalable/apps"),
    Path("/usr/share/icons/hicolor/256x256/apps"),
    Path("/usr/share/icons/HighContrast/scalable/apps"),
    Path("/usr/share/icons/HighContrast/256x256/apps"),
    Path("/usr/share/icons/HighContrast/scalable/devices"),
    Path("/usr/share/icons/HighContrast/256x256/devices"),
    Path("/usr/share/pixmaps"),
    Path.home() / ".local/share/icons/hicolor/scalable/apps",
    Path.home() / ".local/share/icons/hicolor/256x256/apps",
    Path.home() / ".local/share/flatpak/exports/share/icons/hicolor/scalable/apps",
    Path.home() / ".local/share/flatpak/exports/share/icons/hicolor/512x512/apps",
    Path.home() / ".local/share/flatpak/exports/share/icons/hicolor/256x256/apps",
]

# --------------- utools ---------------

BACKGROUND_TOOLS = {"wl-copy", "xclip", "xsel"}

FA_ICON_DIR: Path = Path.home() / ".local/share/fa-icons"

TOOLS = [
    ("tool.color_picker", "ColorPicker"),  # 无参数
    ("tool.clipboard", "Clipboard"),  # 无参数
    ("tool.yazi", "Yazi"),  # 无参数
    # ("tool.example", "Example", ("Example\r(Extra info)",)),  # 单参数
]
