#!/usr/bin/env python3
import asyncio
import tomllib
from collections.abc import Sequence
from pathlib import Path
from typing import Self

from pydantic import BaseModel, ConfigDict, Field

from waylaunch.compositor import Compositor
from waylaunch.core.config import Config
from waylaunch.core.protocols import Entry, Item, ItemProvider
from waylaunch.core.registry import registry

TOOLS_FILE = "~/.config/waylaunch/tools.toml"


class ToolItem(BaseModel):
    name: str  # pyright: ignore
    icon: str  # pyright: ignore
    command: str = Field(alias="run")

    async def run(self, compositor: Compositor, returncode: int = 0) -> None:
        await compositor.exec([self.command])
        # await exec(self.cmd)


class ToolConfig(BaseModel):
    model_config = ConfigDict(frozen=True, populate_by_name=True, extra="forbid")

    tool: dict[str, list[ToolItem]] = Field(default_factory=dict[str, list[ToolItem]])

    @classmethod
    def load_toml(cls, path: str | Path) -> Self:

        path = Path(path).expanduser()
        if not path.exists():
            return cls()

        try:
            with path.open("rb") as f:
                data = tomllib.load(f)
            return cls.model_validate(data)
        except (tomllib.TOMLDecodeError, Exception) as e:
            print(f"Error loading config: {e}")
            return cls()


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


def create_tools(groups: list[str] | None) -> Sequence[Item]:
    """自定义工具列表"""
    config = ToolConfig.load_toml(TOOLS_FILE)

    if groups:
        active_tools: list[ToolItem] = []
        for name in groups:
            if name in config.tool:
                active_tools.extend(config.tool[name])
        if active_tools:
            return active_tools

    return [item for tools in config.tool.values() for item in tools]


@registry.register("tool")
class ToolItemProvider(ItemProvider[Item]):
    async def items(self, config: Config, compositor: Compositor) -> Sequence[Item]:
        tool = config.provider.plugins.get("tool")
        groups = tool.groups if tool else None
        return create_tools(groups)

    def to_entry(self, item: Item) -> Entry:
        """将 Item 转换为结构化的 Entry"""
        return Entry(
            title=item.name,
            icon=item.icon,
        )
