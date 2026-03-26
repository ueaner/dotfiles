from dataclasses import dataclass
from enum import IntEnum, StrEnum
from typing import Literal, Required, TypedDict, TypeGuard

# TypedDict + Discriminated Union（可辨识联合）+ TypeGuard

# 定义特定的类型别名
type NodeType = Literal["root", "output", "workspace", "con", "floating_con"]
type LayoutType = Literal["splith", "splitv", "stacked", "tabbed", "output", "none"]
type BorderStyle = Literal["normal", "none", "pixel", "csd"]
type Orientation = Literal["none", "horizontal", "vertical"]
type ScratchpadState = Literal["none", "fresh"]
type ShellType = Literal["xdg_shell", "xwayland"]
type Floating = Literal["auto_off", "user_on"]


# Only containers and windows
class FullscreenMode(IntEnum):
    NONE = 0
    WORKSPACE = 1
    GLOBAL = 2


# Output 相关
type Hinting = Literal["rgb", "bgr", "vrgb", "vbgr", "unknown"]
type Transform = Literal["90", "180", "270", "flipped-90", "flipped-180", "flipped-270", "normal"]


class OutputMode(TypedDict):
    width: int
    height: int
    refresh: int


@dataclass(frozen=True, slots=True)
class Rect:
    """矩形区域定义 (Logical pixels)"""

    x: int
    y: int
    width: int
    height: int

    def __contains__(self, point: tuple[int, int]) -> bool:
        """
        检查点是否在矩形区域内。

        示例:
            if (10, 20) in rect:
                ...
        """
        px, py = point
        return self.x <= px < self.x + self.width and self.y <= py < self.y + self.height


class IdleInhibitors(TypedDict):
    application: Literal["none", "enabled"]
    user: Literal["none", "focus", "fullscreen", "open", "visible"]


X11Window = TypedDict(
    "X11Window",
    {
        # 使用函数式定义，键名可以包含关键字 (class)
        "class": str,
        "title": str,
        "instance": str,
        "window_role": str,
        "window_type": str,
        "transient_for": str,
    },
    total=False,
)


class Node(TypedDict, total=False):
    """
    Sway IPC GET_TREE 结构的完整定义。
    参考：https://man.archlinux.org/man/sway-ipc.7.en#4._GET_TREE
    """

    # 基础识别
    id: Required[int]
    name: Required[str]
    # _type: NodeType

    # 层级与递归
    # nodes: list[SwayNode]
    # floating_nodes: list[SwayNode]
    focus: list[int]
    marks: list[str]

    # 状态与布尔值
    focused: bool
    urgent: bool
    sticky: bool

    # 几何位置
    rect: Rect
    window_rect: Rect
    deco_rect: Rect
    geometry: Rect

    # 布局相关
    layout: LayoutType
    orientation: Orientation
    border: BorderStyle
    current_border_width: int
    percent: float


class ContainerNode(Node, total=False):
    """
    Sway IPC GET_TREE 结构的 Only windows 部分。
    参考：https://man.archlinux.org/man/sway-ipc.7.en#4._GET_TREE
    """

    type: Required[Literal["con", "floating_con"]]

    # 窗口与应用标识
    app_id: str
    pid: int
    shell: ShellType
    foreign_toplevel_identifier: str

    # 状态与布尔值
    visible: bool
    floating: Floating

    # 闲置处理
    idle_inhibitors: IdleInhibitors
    inhibit_idle: bool

    # 其他特殊状态
    fullscreen_mode: FullscreenMode
    scratchpad_state: ScratchpadState

    # 沙箱环境 (Flatpak 等)
    sandbox_app_id: str
    sandbox_engine: str
    sandbox_instance_id: str

    # Only xwayland windows, shell == "xwayland"
    window: int
    window_properties: X11Window


class WorkspaceNode(Node, total=False):
    """
    Sway IPC GET_WORKSPACES 工作区对象定义。
    参考：https://man.archlinux.org/man/sway-ipc.7.en#1._GET_WORKSPACES
          https://git.sr.ht/~rkintzi/swayipc/tree/master/item/message.go
    """

    type: Required[Literal["workspace"]]
    nodes: list[ContainerNode]
    floating_nodes: list[ContainerNode]

    num: int  # 对于 Scratchpad workspace 可能没有 num 字段
    visible: bool
    output: str
    # name: str
    # focused: bool
    # urgent: bool
    # rect: Rect

    representation: str  # Sway IPC GET_TREE 结构的 Only workspaces 字段


class OutputNode(Node, total=False):
    """
    Sway IPC GET_OUTPUTS 输出设备对象定义。
    参考：https://man.archlinux.org/man/sway-ipc.7.en#3._GET_OUTPUTS
    """

    type: Required[Literal["output"]]
    nodes: Required[list[WorkspaceNode]]
    floating_nodes: list[WorkspaceNode]  # 通常是空的
    # name: str
    # rect: Rect

    make: str
    model: str
    serial: str
    active: bool
    dpms: bool
    power: bool
    primary: bool
    scale: float
    subpixel_hinting: Hinting
    transform: Transform
    current_workspace: str
    modes: list[OutputMode]
    current_mode: OutputMode


class RootNode(Node, total=False):
    type: Required[Literal["root"]]
    nodes: Required[list[OutputNode]]
    floating_nodes: list[OutputNode]  # 通常是空的


# Discriminated Union
type SwayNode = RootNode | OutputNode | WorkspaceNode | ContainerNode


# 类型收窄，确保具体节点类型中的 type 字段是 Required
def is_root(node: SwayNode) -> TypeGuard[RootNode]:
    return node["type"] == "root"


def is_output(node: SwayNode) -> TypeGuard[OutputNode]:
    # Output 存在于 RootNode 的 nodes 数组中
    return node["type"] == "output"


def is_workspace(node: SwayNode) -> TypeGuard[WorkspaceNode]:
    # Workspace 存在于 Output 的 nodes 数组中
    return node["type"] == "workspace"


def is_container(node: SwayNode) -> TypeGuard[ContainerNode]:
    """如果返回 True，则 node 的类型在当前作用域被锁定为 ContainerNode"""
    return node["type"] in ("con", "floating_con")


def is_scratchpad_output(node: OutputNode) -> bool:
    return node["name"] == "__i3"


def is_scratchpad_workspace(node: WorkspaceNode) -> bool:
    # Scratchpad 的特点：
    # 1. Scratchpad 是一个 name 为 __i3_scratch 的 Workspace，
    #    所在的 Output 节点 name 为 __i3 (为了兼容 i3)
    # 2. Scratchpad 内的窗口，不可见且会被强制设为浮动状态
    return node["name"] == "__i3_scratch"


class WindowChangeType(StrEnum):
    NEW = "new"
    CLOSE = "close"
    FOCUS = "focus"
    TITLE = "title"
    FULLSCREEN_MODE = "fullscreen_mode"
    MOVE = "move"
    FLOATING = "floating"
    URGENT = "urgent"
    MARK = "mark"


class WorkspaceChangeType(StrEnum):
    INIT = "init"
    EMPTY = "empty"
    FOCUS = "focus"
    MOVE = "move"
    RENAME = "rename"
    URGENT = "urgent"
    RELOAD = "reload"


class WindowEvent(TypedDict, total=False):
    change: Required[WindowChangeType]
    container: Required[ContainerNode]


class WorkspaceEvent(TypedDict, total=False):
    change: Required[WorkspaceChangeType]
    current: Required[WorkspaceNode]
    old: WorkspaceNode
