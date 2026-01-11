# utils/sway_helper.py
import json
import logging
import subprocess
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

from .exception_handler import handle_exception
from .sway_types import ContainerNode, RootNode, SwayNode, Workspace, X11Window, is_container, is_scratchpad_output
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
def sway_get_tree() -> RootNode | None:
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


def build_window_info(node: ContainerNode) -> WindowInfo | None:
    xprops: X11Window | None = node.get("window_properties")

    app_id: str | None = (xprops.get("class") if xprops else None) or node.get("app_id") or node.get("sandbox_app_id")
    if not app_id:
        return None

    # XXX: rofi -show window 只读取 ~/.local/share/icons 目录下全小写名称的图标?
    # XWayland 启动的应用 sandbox_* 相关信息为空，需要单独为 window_properties.class 拷贝一份图标

    # "<span color='#7aa6da'>●</span>", # 🔘
    # 取图标优先使用 sandbox_app_id
    icon: str | None = node.get("sandbox_app_id") or node.get("app_id") or (xprops.get("class") if xprops else None)

    return WindowInfo(
        app_id=app_id,
        name=node.get("name").lstrip("\ufeff").removeprefix(" - "),
        con_id=node.get("id"),
        shell=node.get("shell", ""),
        icon=icon,
    )


# https://man.archlinux.org/man/sway-ipc.7.en#4._GET_TREE
def get_running_windows() -> list[WindowInfo]:
    """获取运行中的窗口列表"""
    windows: list[WindowInfo] = []

    tree = sway_get_tree()
    if not tree:
        return windows

    def walk(node: SwayNode) -> None:
        if is_container(node):
            if win := build_window_info(node):
                windows.append(win)

        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            walk(child)

    walk(tree)

    return windows


def get_scratchpad_windows() -> list[WindowInfo]:
    """获取 Scratchpad 窗口列表"""
    windows: list[WindowInfo] = []

    tree = sway_get_tree()
    if not tree:
        return windows

    for output in tree.get("nodes"):
        if not is_scratchpad_output(output):
            continue
        for workspace in output.get("nodes"):
            for container in workspace.get("floating_nodes", []):
                if win := build_window_info(container):
                    windows.append(win)

    return windows


def get_first_empty_workspace() -> int:
    """
    获取第一个空闲工作区编号。
    1. 优先返回当前聚焦且为空的工作区。
    2. 寻找编号序列中第一个缺失的数字（填补空隙）。
    3. 返回 最大编号 + 1（开启新空间）。
    """
    # # 获取工作区列表
    # workspaces: list[Workspace] = sway_get_workspaces()
    # if not workspaces:
    #     return 1

    # focused_ws = next((w for w in workspaces if w.get("focused")), None)
    # focused_num = focused_ws.get("num") if focused_ws else None
    # if not focused_num:
    #     return 1
    # existing_nums = {w["num"] for w in workspaces if w["num"] > 0}

    # RootNode
    tree = sway_get_tree()
    if not tree:
        return 1

    # 工作区编号全局唯一
    ws_nums: set[int] = set()

    # 1. 检查当前聚焦的工作区是否为空
    for o in tree.get("nodes"):
        if is_scratchpad_output(o):
            continue

        focused_ws_name = o.get("current_workspace") if o.get("current_workspace") else None
        for w in o.get("nodes"):
            if (
                focused_ws_name
                and w.get("name") == focused_ws_name
                # workspace.get("num", 0) == focused_num
                and not w.get("nodes")
                and not w.get("floating_nodes")
            ):
                return w.get("num")

            if w["num"] > 0:
                ws_nums.add(w["num"])

    # 2. 寻找编号序列中的缺失项（填补空缺）
    ws_max_num = max(ws_nums) if ws_nums else 0

    for i in range(1, ws_max_num + 1):
        if i not in ws_nums:
            return i

    # 3. 开启全新编号
    return ws_max_num + 1
