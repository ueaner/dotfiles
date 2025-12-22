#!/usr/bin/env python3
# 基于 rofi -dmenu 自定义已打开窗口列表和应用列表菜单，支持图标展示、遵循 XDG 规范去重过滤；
# 可使用 Shift+Return 在新工作区中打开选中的应用（如果在 Sway 中指定了特定应用所属的工作区，则遵循 Sway 的配置）。

import json
import os
import subprocess
from pathlib import Path

# --- 配置区 ---
DEBUG_LOG = Path("/tmp/sway-rofi-launcher-debug.json")
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


def get_current_desktops():
    """获取当前桌面环境列表，转为小写集合"""
    raw = os.getenv("XDG_CURRENT_DESKTOP", "").upper()
    # 使用集合推导式：处理可能的冒号分隔、过滤空值、去除空格，并最终转为 set
    return {d.strip() for d in raw.split(":") if d.strip()}


def parse_list_field(field_value):
    """安全解析以分号分隔的 XDG 列表字段，去除空值"""
    if not field_value:
        return set()
    return {item.strip() for item in field_value.upper().split(";") if item.strip()}


def find_icon(icon_name):
    """查找图标的实际绝对路径"""
    if not icon_name:
        return "application-x-executable"
    if os.path.isabs(icon_name):
        return icon_name if os.path.exists(icon_name) else "application-x-executable"

    for d in ICON_DIRS:
        if not d.exists():
            continue
        for ext in [".svg", ".png"]:
            full_path = os.path.join(d, f"{icon_name}{ext}")
            # 早期返回（Early Return）
            if os.path.exists(full_path):
                return full_path

    return "application-x-executable"


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
    display_name = f"{name} ({generic})" if generic else name

    return {
        "id": path.stem,
        "name": name,
        "display_name": display_name,  # 用于 Rofi 展示
        "icon": find_icon(app.get("Icon", "")),
        "exec": app.get("Exec", "") if app_type == "Application" else app.get("URL", ""),
        "path": str(path),
    }


def get_all_apps():
    """扫描所有目录并按规则去重"""
    # 扫描并去重 .desktop 应用
    id_to_path = {}
    for d in DESKTOP_DIRS:
        if not d.exists():
            continue
        for entry in d.rglob("*.desktop"):
            # 先到先得（First-win）
            if entry.stem not in id_to_path:
                id_to_path[entry.stem] = entry

    apps = []
    current_desktops = get_current_desktops()

    for path in id_to_path.values():
        parsed = parse_desktop_file(path, current_desktops)
        if parsed:
            apps.append(parsed)
    apps.sort(key=lambda x: x["name"].lower())

    return apps


def get_running_windows():
    """获取运行中的窗口列表"""
    try:
        tree = json.loads(subprocess.check_output(["swaymsg", "-t", "get_tree"]))
    except Exception as e:
        subprocess.run(["notify-send", "Rofi Error", str(e)])
        return []

    windows = []

    def walk(node):
        # type 为 con 或 floating_con
        if node.get("name") and node.get("type") in ("con", "floating_con"):
            if node.get("app_id") or node.get("sandbox_app_id"):
                windows.append(
                    {
                        "id": node.get("app_id") or node.get("sandbox_app_id"),
                        "name": node["name"],  # title
                        "con_id": node["id"],
                        # "icon": "<span color='#7aa6da'>●</span>", # 🔘
                        # 取图标优先使用 sandbox_app_id
                        "icon": find_icon(node.get("sandbox_app_id") or node.get("app_id")),
                    }
                )
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            walk(child)

    walk(tree)

    # 1. 获取 id 字段的最大长度
    max_len = max(len(item["id"]) for item in windows)
    # 2. 将每个 id 字段右补全空格，用于 Rofi 展示
    for item in windows:
        item["display_name"] = f"{item['id'].ljust(max_len)} · {item['name']}"

    return windows


def get_first_empty_workspace():
    """寻找第一个空闲工作区 (Sway 逻辑)"""
    try:
        ws_raw = subprocess.check_output(["swaymsg", "-t", "get_workspaces"])
        workspaces = json.loads(ws_raw)
        if not workspaces:
            return 1

        nums = sorted([w["num"] for w in workspaces if w["num"] > 0])
        focused_id = next((w["num"] for w in workspaces if w["focused"]), None)

        # 查找间断点 (Holes)
        holes = sorted(list(set(range(1, nums[-1] + 1)) - set(nums)))
        if holes:
            return holes[0]

        # 检查当前工作区是否为空
        if focused_id is not None:
            tree_raw = subprocess.check_output(["swaymsg", "-t", "get_tree"])
            tree = json.loads(tree_raw)

            def find_ws(node, target):
                if node.get("type") == "workspace" and node.get("num") == target:
                    return node
                for c in node.get("nodes", []) + node.get("floating_nodes", []):
                    res = find_ws(c, target)
                    if res:
                        return res
                return None

            ws_node = find_ws(tree, focused_id)
            if ws_node and (len(ws_node.get("nodes", [])) + len(ws_node.get("floating_nodes", []))) == 0:
                return focused_id

        return nums[-1] + 1
    except Exception as e:
        subprocess.run(["notify-send", "Rofi Error", str(e)])
        return None


def main():
    # 1. 获取运行中的窗口
    windows = get_running_windows()

    # 2. 扫描并去重 .desktop 应用 (先到先得)
    apps = get_all_apps()

    # 写入调试文件
    with open(DEBUG_LOG, "w", encoding="utf-8") as f:
        json.dump(
            {"current_env": os.getenv("XDG_CURRENT_DESKTOP", ""), "windows": windows, "apps": apps},
            f,
            indent=4,
            ensure_ascii=False,
        )

    # 3. 构造 Rofi 列表，运行窗口在前（normal.active），待启动应用在后
    # 格式：显示文本 \0 icon \x1f 图标路径 \x1f info \x1f 附加数据
    rofi_input = (
        "\n".join([f"{w['display_name']}\0icon\x1f{w['icon']}\x1factive\x1ftrue" for w in windows])
        + "\n"
        + "\n".join([f"{a['display_name']}\0icon\x1f{a['icon']}" for a in apps])
    )

    # 4. 调用 Rofi
    proc = subprocess.Popen(
        [
            "rofi",
            "-dmenu",
            "-i",
            "-p",
            "Apps",
            "-kb-accept-alt",
            "",
            "-kb-custom-1",
            "Shift+Return",
            "-matching",
            "fuzzy",
            "-sort",
            "-sorting-method",
            "fzf",
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )
    stdout, _ = proc.communicate(input=rofi_input)

    # 5. 处理选中项
    selected_name = stdout.strip()
    if not selected_name:
        return

    target = next((w for w in windows if w["display_name"] == selected_name), None)
    if target:
        subprocess.run(["swaymsg", f"[con_id={target['con_id']}] focus"])
        return

    target = next((a for a in apps if a["display_name"] == selected_name), None)
    if target:
        if proc.returncode == 0:
            subprocess.Popen(["gtk-launch", target["id"]], stdout=subprocess.DEVNULL)
        elif proc.returncode == 10:
            target_ws = get_first_empty_workspace()
            if target_ws:
                subprocess.Popen(["swaymsg", f"workspace {target_ws}; exec gtk-launch {target['id']}"])
            else:
                subprocess.Popen(["gtk-launch", target["id"]])
        return


if __name__ == "__main__":
    main()
