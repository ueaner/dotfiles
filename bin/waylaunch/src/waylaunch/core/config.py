from __future__ import annotations

import tomllib
from pathlib import Path
from typing import Any, Protocol, Self

from pydantic import Field

from waylaunch.core.models import (
    BaseConfig,
    CompositorConfig,
    Layout,
    LoggingConfig,
    PickerConfig,
    ProviderConfig,
)


class RuntimeArgs(Protocol):
    """定义传入参数必须具备的属性结构"""

    config: Path
    prompt: str | None  # picker.prompt
    layout: Layout | None  # picker.layout
    picker: list[str] | None  # picker.plugins
    provider: list[str] | None  # provider.plugins
    compositor: list[str] | None  # compositor.plugins


class Config(BaseConfig):
    """
    系统主配置：整合所有模块并支持多源加载
    优先级：CLI Args > TOML File > Defaults
    """

    provider: ProviderConfig = Field(default_factory=ProviderConfig)
    compositor: CompositorConfig = Field(default_factory=CompositorConfig)
    picker: PickerConfig = Field(default_factory=PickerConfig)
    logging: LoggingConfig = Field(default_factory=LoggingConfig)

    @classmethod
    def load(cls, args: RuntimeArgs) -> Self:
        """
        核心加载方法：集成命令行解析和文件读取
        """
        # A. 加载 TOML 数据
        config: dict[str, Any] = {}
        config_path = args.config.expanduser()
        if config_path.exists():
            with config_path.open("rb") as f:
                toml_data = tomllib.load(f)
                config.update(toml_data)

        # B. 提取命令行覆盖项 (手动映射到嵌套结构)
        # 参数控制样式和基础行为，快捷键等逻辑则硬编码在配置文件中
        cli_overrides: dict[str, dict[str, Any]] = {
            "picker": {},
            "provider": {},
            "compositor": {},
        }

        for key, value in vars(args).items():
            if value is not None and "." in key:
                parent, child = key.split(".")
                cli_overrides.setdefault(parent, {})[child] = value

        # C. 合并数据并实例化
        # 合并顺序：TOML 基础 -> CLI 覆盖
        for key, val in cli_overrides.items():
            if key in config and isinstance(config[key], dict):
                target = config[key]
                target.update(val)
            else:
                config[key] = val

        return cls.model_validate(config)
