# utils/xdg_parser.py
import logging
import os
import re
import shutil
from pathlib import Path

from .exception_handler import handle_exception

logger = logging.getLogger(__name__)

# 清理 Exec 占位符并去空格
STRIP_EXEC_RE = re.compile(r"%[fFuUikpst]")

DESKTOP_FIELDS: set[str] = {
    "Name",
    "GenericName",
    "Exec",
    "TryExec",
    "Icon",
    "Type",
    "NoDisplay",
    "Hidden",
    "OnlyShowIn",
    "NotShowIn",
    "URL",
}


def get_current_desktops() -> set[str]:
    """获取当前桌面环境列表，转为大写集合"""
    raw = os.getenv("XDG_CURRENT_DESKTOP", "").upper()
    # 使用集合推导式：处理可能的冒号分隔、过滤空值、去除空格，并最终转为 set
    return {d.strip() for d in raw.split(":") if d.strip()}


def parse_list_field(field_value: str) -> set[str]:
    """安全解析以分号分隔的 XDG 列表字段，去除空值"""
    if not field_value:
        return set()
    return {item.strip() for item in field_value.upper().split(";") if item.strip()}


@handle_exception({})
def parse_desktop_entry(path: Path) -> dict[str, str]:
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
    entry: dict[str, str] = parse_desktop_entry(path)
    if not entry:
        logger.warning(f"Parse desktop file ({path}) failed")
        return None

    # 1. 基础过滤
    if entry.get("NoDisplay") == "true" or entry.get("Hidden") == "true":
        return None

    # 2. XDG 桌面过滤
    if only_in := entry.get("OnlyShowIn"):
        if not (parse_list_field(only_in) & current_desktops):
            return None
    if not_in := entry.get("NotShowIn"):
        if parse_list_field(not_in) & current_desktops:
            return None

    # 3. 检查 TryExec (如果 TryExec 指定的程序不可执行，则忽略)
    if (try_exec := entry.get("TryExec")) and not shutil.which(try_exec):
        return None

    # 4. 字段提取
    final_exec = ""
    entry_type = entry.get("Type", "Application")
    if entry_type == "Application":
        if not (exec_raw := entry.get("Exec")):
            return None
        final_exec = STRIP_EXEC_RE.sub("", exec_raw).strip()
    elif entry_type == "Link":
        final_exec = entry.get("URL", "")
    else:
        # 忽略 Directory, Service 等类型
        return None

    if not final_exec:
        return None

    return {
        "app_id": path.stem,
        "name": entry.get("Name", path.stem),
        "generic": entry.get("GenericName", ""),
        "icon": entry.get("Icon", ""),
        "exec": final_exec,
        "path": str(path),
    }
