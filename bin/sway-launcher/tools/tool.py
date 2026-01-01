from typing import Protocol, runtime_checkable


@runtime_checkable  # 允许在运行时使用 isinstance(obj, Tool) 检查
class Tool(Protocol):
    def name(self) -> str: ...

    def icon(self) -> str: ...

    def run(self):
        """执行工具的具体逻辑"""
        ...
