from __future__ import annotations

from enum import StrEnum

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, field_validator

# --- 1. 协议定义 (增强类型约束) ---


class Layout(StrEnum):
    MENU = "menu"  # 浮动菜单
    BOARD = "board"  # 浮动网格
    LAUNCHPAD = "launchpad"  # 全屏网格

    @classmethod
    def is_valid(cls, value: str) -> bool:
        # 检查值是否在枚举的值集合中
        return value in cls

    @classmethod
    def default(cls) -> Layout:
        return cls.MENU


# --- 2. 基础子模型 ---


class BaseConfig(BaseModel):
    model_config = ConfigDict(frozen=True, populate_by_name=True, extra="forbid")


class PickerThemes(BaseConfig):
    menu: str = "menu"
    board: str = "board"
    launchpad: str = "launchpad"


class PickerKeybindings(BaseConfig):
    custom_1: list[str] = Field(
        default_factory=list, validation_alias=AliasChoices("custom_1", "custom-1")
    )
    custom_2: list[str] = Field(
        default_factory=list, validation_alias=AliasChoices("custom_2", "custom-2")
    )
    custom_3: list[str] = Field(
        default_factory=list, validation_alias=AliasChoices("custom_3", "custom-3")
    )


class PluginConfig(BaseModel):
    """单个插件配置：明确 groups 属性，支持其他未知属性"""

    model_config = ConfigDict(frozen=True, extra="allow")

    groups: list[str] | None = None


type PluginsType = dict[str, PluginConfig]


def _parse_plugins(
    v: PluginsType | list[str], default_return: PluginsType | None = None
) -> PluginsType:
    """
    解析插件配置列表
    输入: ["window", "tool:recording,screenshot"]
    输出: {"window": PluginConfig(), "tool": PluginConfig(groups=["recording", "screenshot"])}
    """
    # 1. 如果已经是字典，转换为 PluginConfig
    if isinstance(v, dict):
        return {
            k: PluginConfig.model_validate(v) if isinstance(v, dict) else PluginConfig()
            for k, v in v.items()
        }

    # 2. 如果不是列表（比如是 None 或其他），返回默认字典
    if not isinstance(v, list):  # pyright: ignore[reportUnnecessaryIsInstance]
        return default_return if default_return is not None else {}

    parsed: PluginsType = {}
    for item in v:
        # 确保 item 是字符串再处理
        if not isinstance(item, str):  # pyright: ignore[reportUnnecessaryIsInstance]
            continue

        name, sep, groups_str = item.partition(":")
        groups_str = groups_str.strip()

        if not sep or not groups_str:
            parsed[name] = PluginConfig()
        else:
            groups = [g.strip() for g in groups_str.split(",") if g.strip()]
            parsed[name] = PluginConfig(groups=groups)

    return parsed


class ProviderConfig(BaseConfig):
    """Provider 配置"""

    plugins: PluginsType = Field(default_factory=dict)

    @field_validator("plugins", mode="before")
    @classmethod
    def _parse_plugins(cls, v: PluginsType | list[str]) -> PluginsType:
        return _parse_plugins(v)


class CompositorConfig(BaseConfig):
    """Compositor 配置"""

    plugins: PluginsType = Field(default_factory=dict)

    @field_validator("plugins", mode="before")
    @classmethod
    def _parse_plugins(cls, v: PluginsType | list[str]) -> PluginsType:
        return _parse_plugins(v)


class PickerConfig(BaseConfig):
    """Picker 配置"""

    plugins: PluginsType = Field(default_factory=dict)

    @field_validator("plugins", mode="before")
    @classmethod
    def _parse_plugins(cls, v: PluginsType | list[str]) -> PluginsType:
        return _parse_plugins(v)

    prompt: str = "Launcher"
    matching: str = "fuzzy"
    layout: Layout = Layout.default()
    align_max_len: int = 25
    board_max_cols: int = 5
    board_max_lines: int = 3
    themes: PickerThemes = Field(default_factory=PickerThemes)
    keybindings: PickerKeybindings = Field(default_factory=PickerKeybindings)


class LogLevel(StrEnum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class LogFileConfig(BaseConfig):
    path: str = "/tmp/waylaunch.log"  # noqa: S108
    max_bytes: int = 10485760  # 10MB
    backup_count: int = 5
    encoding: str = "utf-8"


class LogNotifyConfig(BaseConfig):
    level: LogLevel = LogLevel.ERROR
    timeout: int = 1


class LoggingConfig(BaseConfig):
    level: LogLevel = LogLevel.INFO
    async_enabled: bool = False
    handlers: list[str] = Field(default_factory=lambda: ["file", "notify_send"])

    file: LogFileConfig = Field(default_factory=LogFileConfig)
    notify_send: LogNotifyConfig = Field(default_factory=LogNotifyConfig)
