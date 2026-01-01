# utils/xdg_parser.py
import os
import re
import subprocess


def get_current_desktops():
    """获取当前桌面环境列表，转为大写集合"""
    raw = os.getenv("XDG_CURRENT_DESKTOP", "").upper()
    # 使用集合推导式：处理可能的冒号分隔、过滤空值、去除空格，并最终转为 set
    return {d.strip() for d in raw.split(":") if d.strip()}


def parse_list_field(field_value):
    """安全解析以分号分隔的 XDG 列表字段，去除空值"""
    if not field_value:
        return set()
    return {item.strip() for item in field_value.upper().split(";") if item.strip()}


def parse_desktop_file(path, current_desktops):
    """解析单个 .desktop 文件"""
    app = {}
    try:
        # 使用 errors='ignore' 防止非 UTF-8 编码导致崩溃
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            in_entry = False
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_entry = True
                    continue
                if line.startswith("[") and in_entry:
                    break
                if in_entry and "=" in line:
                    k, v = line.split("=", 1)
                    app[k.strip()] = v.strip()
    except Exception as e:
        subprocess.run(["notify-send", "Rofi Error", str(e)])
        return None

    # 1. 基础过滤
    if app.get("NoDisplay") == "true" or app.get("Hidden") == "true":
        return None

    # 2. XDG 桌面过滤 OnlyShowIn / NotShowIn
    only_show_in = parse_list_field(app.get("OnlyShowIn", ""))
    if only_show_in and not (only_show_in & current_desktops):
        return None

    not_show_in = parse_list_field(app.get("NotShowIn", ""))
    if not_show_in and (not_show_in & current_desktops):
        return None

    # 3. 字段提取
    app_type = app.get("Type", "Application")
    if app_type == "Application" and "Exec" not in app:
        return None
    if app_type == "Link" and "URL" not in app:
        return None

    name = app.get("Name", path.stem)
    generic = app.get("GenericName", "")
    # display_name = f"{name} ({generic})" if generic else name

    return {
        "id": path.stem,
        "name": name,
        "generic": generic,
        # "display_name": display_name,  # 用于 Rofi 展示
        "icon": app.get("Icon", ""),
        "exec": re.sub(r"%[fFuUikpst]", "", app.get("Exec", "")) if app_type == "Application" else app.get("URL", ""),
        "path": str(path),
    }
