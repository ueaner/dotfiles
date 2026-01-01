# utils/icon_finder.py
import os


def find_icon(icon_name, icon_dirs):
    """
    查找图标的实际绝对路径
    :param icon_name: 图标名称 (来自 .desktop 的 Icon 字段)
    :param icon_dirs: 搜索目录列表 (来自调用者注入)
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
