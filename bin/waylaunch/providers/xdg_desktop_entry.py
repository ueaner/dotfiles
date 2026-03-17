import os
import shutil
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

from core.exception_handler import handle_exception
from core.logging import logger

DESKTOP_FIELDS: set[str] = {
    "Name",
    "GenericName",
    "Icon",
    "TryExec",
    "NoDisplay",
    "Hidden",
    "OnlyShowIn",
    "NotShowIn",
    # "Type",
    # "Exec",  # re.compile(r"%[fFuUikpst]")
    # "URL",
}


@dataclass(slots=True)
class App:
    app_id: str
    name: str
    icon: str
    generic: str = ""
    path: str = ""


def get_all_apps(desktop_dirs: Iterable[Path]) -> list[App]:
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

    apps: list[App] = []
    current_desktops = get_current_desktops()

    for path in id_to_path.values():
        parsed = parse_desktop_file(path, current_desktops)
        if parsed:
            # 将字典解包或手动映射到 dataclass
            apps.append(
                App(
                    app_id=parsed["app_id"],
                    name=parsed["name"],
                    icon=parsed["icon"],
                    generic=parsed["generic"],
                    path=parsed["path"],
                )
            )

    apps.sort(key=lambda x: x.name.lower())

    return apps


def get_current_desktops() -> set[str]:
    """获取当前桌面环境列表，转为大写集合"""
    raw = os.getenv("XDG_CURRENT_DESKTOP", "").upper()
    # 处理可能的冒号分隔、过滤空值、去除空格，并最终转为 set
    return {d.strip() for d in raw.split(":") if d.strip()}


def parse_list_field(field_value: str) -> set[str]:
    """安全解析以分号分隔的 XDG 列表字段，去除空值"""
    if not field_value:
        return set()
    return {item.strip() for item in field_value.upper().split(";") if item.strip()}


@handle_exception
def parse_desktop_entry(path: Path) -> dict[str, str] | None:
    """解析 .desktop 文件的 Desktop Entry 部分"""
    entry: dict[str, str] = {}
    with open(path, encoding="utf-8") as f:
        in_entry = False
        for line in f:
            if line.startswith(("[", "#", "\n")):
                if line.startswith("[Desktop Entry]"):
                    in_entry = True
                    continue
                if in_entry and line.startswith("["):  # 已经离开目标段落
                    break
                continue

            if in_entry and "=" in line:
                k, v = line.split("=", 1)
                key = k.strip()
                # 仅保留关键字段，减少内存占用
                if key in DESKTOP_FIELDS:
                    entry[key] = v.strip().strip('"')

    return entry


def parse_desktop_file(path: Path, current_desktops: set[str]) -> dict[str, str] | None:
    """解析单个 .desktop 文件"""
    entry = parse_desktop_entry(path)
    if not entry:
        logger.warning(f"Parse desktop file ({path}) failed")
        return None

    # 1. 基础过滤
    if entry.get("NoDisplay") == "true" or entry.get("Hidden") == "true":
        return None

    # 2. XDG 桌面过滤
    if (only_in := entry.get("OnlyShowIn")) and not (parse_list_field(only_in) & current_desktops):
        return None
    if (not_in := entry.get("NotShowIn")) and (parse_list_field(not_in) & current_desktops):
        return None

    # 3. 检查 TryExec (如果 TryExec 指定的程序不可执行，则忽略)
    if (try_exec := entry.get("TryExec")) and not shutil.which(try_exec):
        return None

    return {
        "app_id": path.stem,
        "name": entry.get("Name", path.stem),
        "icon": entry.get("Icon", ""),
        "generic": entry.get("GenericName", ""),
        "path": str(path),
    }
