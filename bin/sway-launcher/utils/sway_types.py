from typing import Literal, Required, TypedDict, TypeIs

# TypedDict + Discriminated Union（可辨识联合）+ TypeIs

# --- 定义特定的枚举别名 (PEP 695) ---
type NodeType = Literal["root", "output", "workspace", "con", "floating_con"]
type LayoutType = Literal["splith", "splitv", "stacked", "tabbed", "output", "none"]
type BorderStyle = Literal["normal", "none", "pixel", "csd"]
type Orientation = Literal["none", "horizontal", "vertical"]
type ScratchpadState = Literal["none", "fresh"]
type FullscreenMode = Literal[0, 1, 2]  # 0:None, 1:Workspace, 2:Global
type ShellType = Literal["xdg_shell", "xwayland"]

# Output 相关
type Hinting = Literal["rgb", "bgr", "vrgb", "vbgr", "unknown"]
type Transform = Literal["90", "180", "270", "flipped-90", "flipped-180", "flipped-270", "normal"]


class OutputMode(TypedDict):
    width: int
    height: int
    refresh: int


class Rect(TypedDict):
    x: int
    y: int
    width: int
    height: int


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
    # type_: NodeType

    # 层级与递归
    # nodes: list[Node]
    # floating_nodes: list[Node]
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


class RootNode(Node, total=False):
    type: Required[Literal["root"]]
    nodes: Required[list[Output]]
    floating_nodes: list[Output]  # 空的


class Output(Node, total=False):
    """
    Sway IPC GET_OUTPUTS 输出设备对象定义。
    参考：https://man.archlinux.org/man/sway-ipc.7.en#3._GET_OUTPUTS
    """

    type: Required[Literal["output"]]
    nodes: Required[list[Workspace]]
    floating_nodes: list[Workspace]  # 空的
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


class Workspace(Node, total=False):
    """
    Sway IPC GET_WORKSPACES 工作区对象定义。
    参考：https://man.archlinux.org/man/sway-ipc.7.en#1._GET_WORKSPACES
          https://git.sr.ht/~rkintzi/swayipc/tree/master/item/message.go
    """

    type: Required[Literal["workspace"]]
    nodes: list[ContainerNode]
    floating_nodes: list[ContainerNode]

    # 对于 Scratchpad workspace 没有 num 字段
    num: Required[int]
    visible: bool
    output: str
    # name: str
    # focused: bool
    # urgent: bool
    # rect: Rect

    # Sway IPC GET_TREE 结构的 Only workspaces 字段。
    representation: str


class ContainerNode(Node, total=False):
    """
    Sway IPC GET_TREE 结构的 Only windows 部分。
    参考：https://man.archlinux.org/man/sway-ipc.7.en#4._GET_TREE
    """

    type: Required[Literal["con", "floating_con"]]

    # 窗口与应用标识
    app_id: str
    pid: int
    shell: Required[ShellType]
    foreign_toplevel_identifier: str

    # 状态与布尔值
    visible: bool
    floating: bool

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


# 3. 组合成 Discriminated Union
type SwayNode = RootNode | Output | Workspace | ContainerNode


# 类型收窄，确保具体节点类型中的 type 字段是 Required
def is_root(node: SwayNode) -> TypeIs[RootNode]:
    return node["type"] == "root"


def is_output(node: SwayNode) -> TypeIs[Output]:
    # Output 存在于 RootNode 的 nodes 数组中
    return node["type"] == "output"


def is_workspace(node: SwayNode) -> TypeIs[Workspace]:
    # Workspace 存在于 Output 的 nodes 数组中
    return node["type"] == "workspace"


def is_container(node: SwayNode) -> TypeIs[ContainerNode]:
    """如果返回 True，则 node 的类型在当前作用域被锁定为 ContainerNode"""
    return node["type"] == "con" or node["type"] == "floating_con"


def is_scratchpad_output(node: Output) -> bool:
    return node["name"] == "__i3"


def is_scratchpad_workspace(node: Workspace) -> bool:
    # Scratchpad 的特点：
    # 1. Scratchpad 是一个 name 为 __i3_scratch 的 Workspace，
    #    所在的 Output 节点 name 为 __i3 (为了兼容 i3)
    # 2. Scratchpad 内的窗口，不可见且会被强制设为浮动状态
    return node["name"] == "__i3_scratch"
