# utils/sway_helper.py
import json
import logging
import subprocess
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

from .exception_handler import handle_exception
from .sway_types import SwayNode, Workspace, X11Window, is_container
from .xdg_parser import get_current_desktops, parse_desktop_file

logger = logging.getLogger(__name__)


@dataclass(slots=True)
class AppInfo:
    """已安装的应用信息"""

    app_id: str
    name: str
    generic: str
    exec: str
    path: str
    icon: str | None = None
    display_name: str | None = None


@dataclass(slots=True)
class WindowInfo:
    """运行中的窗口信息"""

    app_id: str
    name: str  # title
    con_id: int
    shell: str
    icon: str | None = None
    display_name: str | None = None


@handle_exception(fallback=None, notify=True)
def sway_get_tree() -> SwayNode | None:
    """swaymsg get_tree"""
    result = subprocess.run(
        ["swaymsg", "-t", "get_tree"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


@handle_exception(fallback=[], notify=True)
def sway_get_workspaces() -> list[Workspace]:
    """swaymsg get_workspaces"""
    result = subprocess.run(
        ["swaymsg", "-t", "get_workspaces"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


# from line_profiler import profile
# @profile
def get_all_apps(desktop_dirs: Iterable[Path]) -> list[AppInfo]:
    """扫描 desktop_dirs 目录并按规则去重、解析"""
    # 扫描并去重 .desktop 应用
    id_to_path: dict[str, Path] = {}
    for d in desktop_dirs:
        if not d.is_dir():
            continue

        for entry in d.iterdir():
            if not entry.name.endswith(".desktop") or not entry.is_file():
                continue

            # stem 获取文件名（不含扩展名），作为 App ID
            app_id = entry.stem
            if app_id not in id_to_path:
                id_to_path[app_id] = entry

    apps: list[AppInfo] = []
    current_desktops = get_current_desktops()

    for path in id_to_path.values():
        parsed = parse_desktop_file(path, current_desktops)
        if parsed:
            # 将字典解包或手动映射到 dataclass
            apps.append(AppInfo(**parsed))

    apps.sort(key=lambda x: x.name.lower())

    # logger.debug(
    #     json.dumps(
    #         {
    #             "apps": [asdict(item) for item in apps],
    #         },
    #         ensure_ascii=False,
    #     )
    # )

    return apps


# https://man.archlinux.org/man/sway-ipc.7.en#4._GET_TREE
def get_running_windows() -> list[WindowInfo]:
    """获取运行中的窗口列表"""
    tree = sway_get_tree()
    if not tree:
        return []

    windows: list[WindowInfo] = []

    # XXX: rofi -show window 只读取 ~/.local/share/icons 目录下全小写名称的图标?
    # XWayland 启动的应用 sandbox_* 相关信息为空，需要单独为 window_properties.class 拷贝一份图标
    def walk(node: SwayNode) -> None:
        if is_container(node):
            xprops: X11Window | None = node.get("window_properties")

            app_id: str | None = (
                (xprops.get("class") if xprops else None) or node.get("app_id") or node.get("sandbox_app_id")
            )
            # "<span color='#7aa6da'>●</span>", # 🔘
            # 取图标优先使用 sandbox_app_id
            icon: str | None = (
                node.get("sandbox_app_id") or node.get("app_id") or (xprops.get("class") if xprops else None)
            )

            if app_id:
                windows.append(
                    WindowInfo(
                        app_id=app_id,
                        name=node.get("name").lstrip("\ufeff").removeprefix(" - "),
                        con_id=node.get("id"),
                        shell=node.get("shell", ""),
                        icon=icon,
                    )
                )
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            walk(child)

    walk(tree)

    # logger.debug(
    #     json.dumps(
    #         {
    #             "running windows": [asdict(w) for w in windows],
    #         },
    #         ensure_ascii=False,
    #     )
    # )

    return windows


def get_first_empty_workspace() -> int:
    """
    逻辑优先级：
    1. 优先返回当前聚焦且为空的工作区。
    2. 寻找编号序列中第一个缺失的数字（填补空隙）。
    3. 返回 最大编号 + 1（开启新空间）。
    """
    # 获取工作区列表
    workspaces: list[Workspace] = sway_get_workspaces()
    if not workspaces:
        return 1

    # 1. 检查当前聚焦的工作区是否为空
    focused_ws = next((w for w in workspaces if w.get("focused")), None)
    if focused_ws:
        # 获取树结构
        tree_raw = subprocess.run(
            ["swaymsg", "-t", "get_tree"],
            capture_output=True,
            text=True,
            check=True,
        )
        tree = json.loads(tree_raw.stdout)

        def find_node_by_num(node: SwayNode, num: int) -> SwayNode | None:
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
