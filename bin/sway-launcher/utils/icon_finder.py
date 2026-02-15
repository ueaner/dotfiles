# utils/icon_finder.py
import os
from pathlib import Path


def find_icon(icon_name: str, icon_dirs: list[Path]) -> str:
    """
    查找桌面图标路径

    Args:
        icon_name: 图标名称 (来自 .desktop 的 Icon 字段)
        icon_dirs: 搜索目录列表 (来自调用者注入)
    """
    if not icon_name:
        return "application-x-executable"

    if os.path.isabs(icon_name):
        return icon_name if os.path.exists(icon_name) else "application-x-executable"

    for d in icon_dirs:
        if not d.exists():
            continue
        for ext in [".svg", ".png"]:
            full_path = os.path.join(d, f"{icon_name}{ext}")
            # 早期返回（Early Return）
            if os.path.exists(full_path):
                return full_path

    return "application-x-executable"


def find_fa_icon(icon_name: str, icon_dir: Path) -> str:
    """
    查找 Font Awesome 图标路径

    Args:
        icon_name: 图标名称 (来自 icon_dir 的文件名，不带扩展名)
        icon_dir:  搜索目录 (来自调用者注入)
    """
    icon_path = icon_dir / f"{icon_name}.svg"
    # 如果找不到，则回退到原始名称，此时 Rofi 会按桌面图标查找
    return str(icon_path) if icon_path.exists() else icon_name
