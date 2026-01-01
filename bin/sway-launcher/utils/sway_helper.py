# utils/sway_helper.py
import json
import subprocess

from .xdg_parser import get_current_desktops, parse_desktop_file


def get_all_apps(desktop_dirs):
    """扫描 desktop_dirs 目录并按规则去重、解析"""
    # 扫描并去重 .desktop 应用
    id_to_path = {}
    for d in desktop_dirs:
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
                        "icon": node.get("sandbox_app_id") or node.get("app_id"),
                    }
                )
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            walk(child)

    walk(tree)

    # # 1. 获取 id 字段的最大长度
    # max_len = max(len(item["id"]) for item in windows)
    # # 2. 将每个 id 字段右补全空格，用于 Rofi 展示
    # for item in windows:
    #     item["display_name"] = f"{item['id'].ljust(max_len)} · {item['name']}"

    return windows


def get_first_empty_workspace():
    """
    逻辑优先级：
    1. 优先返回当前聚焦且为空的工作区。
    2. 寻找编号序列中第一个缺失的数字（填补空隙）。
    3. 返回 最大编号 + 1（开启新空间）。
    """
    try:
        # 获取工作区列表
        ws_raw = subprocess.run(["swaymsg", "-t", "get_workspaces"], capture_output=True, text=True, check=True)
        workspaces = json.loads(ws_raw.stdout)

        if not workspaces:
            return 1

        # 1. 检查当前聚焦的工作区是否为空
        focused_ws = next((w for w in workspaces if w["focused"]), None)
        if focused_ws:
            # 获取树结构
            tree_raw = subprocess.run(["swaymsg", "-t", "get_tree"], capture_output=True, text=True, check=True)
            tree = json.loads(tree_raw.stdout)

            def find_node_by_num(node, num):
                if node.get("type") == "workspace" and node.get("num") == num:
                    return node
                # 递归查找所有节点（包含浮动节点）
                for child in node.get("nodes", []) + node.get("floating_nodes", []):
                    res = find_node_by_num(child, num)
                    if res:
                        return res
                return None

            ws_node = find_node_by_num(tree, focused_ws["num"])
            # 判断空标准：既没有平铺节点也没有浮动节点
            if ws_node and not ws_node.get("nodes") and not ws_node.get("floating_nodes"):
                return focused_ws["num"]

        # 2. 寻找编号序列中的缺失项（填补空缺）
        existing_nums = {w["num"] for w in workspaces if w["num"] > 0}
        max_num = max(existing_nums) if existing_nums else 0

        for i in range(1, max_num + 1):
            if i not in existing_nums:
                return i

        # 3. 开启全新编号
        return max_num + 1

    except Exception as e:
        # 降级处理 发生错误（如 Sway 未响应或解析失败）时，安全返回 1
        subprocess.run(["notify-send", "Sway Error", str(e)])
        return 1
