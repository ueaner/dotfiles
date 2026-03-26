"""Compositor abstraction layer for Wayland compositors."""

from .compositor import Compositor
from .detector import detect
from .models import DiscoveryMeta, Window, WindowState, Workspace, WorkspaceState
from .null_adapter import NullAdapter

__all__ = [
    "Compositor",
    "DiscoveryMeta",
    "NullAdapter",
    "Window",
    "WindowState",
    "Workspace",
    "WorkspaceState",
    "detect",
]
