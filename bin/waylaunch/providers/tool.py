#!/usr/bin/env python3
import asyncio
import tomllib
from pathlib import Path

from compositor import Compositor
from core.protocols import Config, Item, ItemProvider, Layout

TOOLS_FILE = Path.home() / ".config/waylaunch/tools.toml"


async def exec(cmd: str) -> None:
    """启动脱离进程，立即返回不等待。"""
    if not cmd:
        return

    await asyncio.create_subprocess_shell(
        cmd,
        stdout=asyncio.subprocess.DEVNULL,
        stderr=asyncio.subprocess.DEVNULL,
        stdin=asyncio.subprocess.DEVNULL,
        start_new_session=True,
    )


class Tool:
    def __init__(self, name: str, icon: str, cmd: str) -> None:
        self.name = name
        self.icon = icon
        self.cmd = cmd

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        await compositor.exec([self.cmd])
        # await exec(self.cmd)


def create_tools() -> list[Item]:
    """自定义工具列表"""
    with open(TOOLS_FILE, "rb") as f:
        data = tomllib.load(f)

    tools: list[Item] = [
        Tool(
            name=t.get("name", t.get("icon")),
            icon=t.get("icon", ""),
            cmd=t.get("run", ""),
        )
        for t in data.get("tool", [])
        if t.get("name") or t.get("icon")
    ]

    return tools


class ToolItemProvider(ItemProvider[Item]):
    layout = Layout.BOARD  # pyright: ignore

    async def items(self, config: Config, compositor: Compositor) -> list[Item]:
        return create_tools()
