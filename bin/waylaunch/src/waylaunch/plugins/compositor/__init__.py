"""Compositor abstraction layer for Wayland compositors."""

from .sway.adapter import SwayAdapter

__all__ = ["SwayAdapter"]
