"""Compositor abstraction layer for Wayland compositors."""

from .compositor import Compositor
from .detector import detect
from .models import Window, Workspace
from .null_adapter import NullAdapter

__all__ = ["Compositor", "Window", "Workspace", "detect", "NullAdapter"]
