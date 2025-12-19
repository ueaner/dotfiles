#!/usr/bin/env python3
# 基于 rofi -dmenu 自定义应用列表菜单，支持图标展示、遵循 XDG 规范去重过滤；
# 可使用 Shift+Return 在新工作区中打开选中的应用（如果在 Sway 中指定了特定应用所属的工作区，则遵循 Sway 的配置）。

import json
import os
import subprocess
import sys
from pathlib import Path

# --- 配置区 ---
DEBUG_LOG = Path("/tmp/rofi-drun-debug.json")
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


def find_icon_path(icon_name):
    """查找图标的实际绝对路径"""
    if not icon_name:
        return "application-x-executable"
    if icon_name.startswith("/"):
        return icon_name if os.path.exists(icon_name) else "application-x-executable"

    for d in ICON_DIRS:
        for ext in [".svg", ".png"]:
            full_path = os.path.join(d, f"{icon_name}{ext}")
            # 早期返回（Early Return）
            if os.path.exists(full_path):
                return full_path
    return "application-x-executable"


def get_current_desktop_set():
    """获取当前桌面环境集合"""
    raw_env = os.getenv("XDG_CURRENT_DESKTOP", "").upper()
    # 使用 filter(None, ...) 确保过滤掉 split 产生的空字符串
    return set(filter(None, [d.strip() for d in raw_env.split(":")]))


def parse_desktop_file(file_path, current_desktops):
    """解析单份 .desktop 文件并应用 XDG 过滤逻辑"""
    app_info = {}
    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            in_section = False
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_section = True
                    continue
                elif line.startswith("["):
                    in_section = False
                if in_section and "=" in line:
                    k, v = line.split("=", 1)
                    app_info[k.strip()] = v.strip()

        # 1. 基础过滤
        if app_info.get("NoDisplay") == "true" or app_info.get("Hidden") == "true":
            return None

        # 2. XDG 桌面过滤 (使用 Set 集合运算)
        def get_set_from_key(key):
            # .desktop 列表由分号分割，必须过滤空值
            raw_val = app_info.get(key, "").upper()
            return set(filter(None, [s.strip() for s in raw_val.split(";")]))

        only_show_in = get_set_from_key("OnlyShowIn")
        not_show_in = get_set_from_key("NotShowIn")

        if only_show_in and not (current_desktops & only_show_in):
            return None
        if not_show_in and (current_desktops & not_show_in):
            return None

        # 3. 字段提取
        app_type = app_info.get("Type", "Application")
        if app_type == "Application" and "Exec" not in app_info:
            return None
        if app_type == "Link" and "URL" not in app_info:
            return None

        generic_name = app_info.get("GenericName", "")
        display_name = f"{app_info.get('Name', file_path.stem)} ({generic_name})" if generic_name else app_info.get("Name", file_path.stem)

        return {
            "display_name": display_name,  # 用于 Rofi 展示
            "name": app_info.get("Name", file_path.stem),
            "icon": find_icon_path(app_info.get("Icon", "")),
            "exec": app_info.get("Exec", "") if app_type == "Application" else app_info.get("URL", ""),
            "id": file_path.name,
            "path": str(file_path),
        }
    except Exception:
        return None


def get_all_apps():
    """扫描所有目录并按规则去重"""
    # 1. 收集所有 ID 对应的“最高优先级文件路径”
    id_to_path = {}
    for d in DESKTOP_DIRS:
        if not d.exists():
            continue
        for entry in d.rglob("*.desktop"):
            # 先到先得（First-win）
            if entry.stem not in id_to_path:
                id_to_path[entry.stem] = entry

    # 2. 统一解析这些最高优先级的文件
    apps = []
    current_desktops = get_current_desktop_set()

    for app_id, file_path in id_to_path.items():
        parsed = parse_desktop_file(file_path, current_desktops)
        if parsed:
            apps.append(parsed)

    sorted_apps = sorted(apps, key=lambda x: x["name"].lower())

    # 写入调试文件
    with open(DEBUG_LOG, "w", encoding="utf-8") as f:
        json.dump(
            {"current_env": list(current_desktops), "apps": sorted_apps},
            f,
            indent=4,
            ensure_ascii=False,
        )

    return sorted_apps


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
        print(f"Sway logic error: {e}", file=sys.stderr)
        return None


def main():
    apps = get_all_apps()
    if not apps:
        return

    rofi_input = "\n".join([f"{a['display_name']}\0icon\x1f{a['icon']}" for a in apps])

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

    selected_name = stdout.strip()
    if not selected_name:
        return

    target = next((a for a in apps if a["display_name"] == selected_name), None)
    if not target:
        return

    if proc.returncode == 0:
        subprocess.Popen(["gtk-launch", target["id"]], stdout=subprocess.DEVNULL)
    elif proc.returncode == 10:
        target_ws = get_first_empty_workspace()
        if target_ws:
            subprocess.Popen(["swaymsg", f"workspace {target_ws}; exec gtk-launch {target['id']}"])
        else:
            subprocess.Popen(["gtk-launch", target["id"]])


if __name__ == "__main__":
    main()
