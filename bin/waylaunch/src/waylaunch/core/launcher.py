"""Launcher 流程方法。

提供统一的模板抽象层。
"""

from types import TracebackType
from typing import Self

from waylaunch.compositor import Compositor
from waylaunch.core.config import Config
from waylaunch.core.logger import logger
from waylaunch.core.protocols import Entry, Item, ItemProvider, Picker


class Launcher[T: Item]:
    """Launcher 基础类，依赖于选择器接口"""

    config: Config
    picker: Picker
    item_providers: list[ItemProvider[T]]
    compositor: Compositor

    def __init__(
        self,
        config: Config,
        picker: Picker,
        item_providers: list[ItemProvider[T]],
        compositor: Compositor,
    ):
        self.config = config
        self.picker = picker
        self.item_providers = item_providers
        self.compositor = compositor

    async def __aenter__(self) -> Self:
        await self.compositor.start()
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> None:
        await self.compositor.stop()

    async def handle_selection(self, selected_item: T, returncode: int = 0) -> None:
        """处理用户选择的条目

        子类可以覆盖此方法，扩展选中后要执行的动作
        """
        await selected_item.run(self.compositor, returncode)

    async def launch(self) -> None:
        """启动 launcher 的主要流程"""

        # 1. 存储 (Item, Entry) 的对应关系
        contexts: list[tuple[T, Entry]] = []

        for provider in self.item_providers:
            raw_items = await provider.items(self.config, self.compositor)
            contexts.extend([(item, provider.to_entry(item)) for item in raw_items])

        if not contexts:
            logger.error(
                f"The items data is empty. (--provider {','.join(self.config.provider.plugins)})"
            )
            return

        # 2. 提取用于给 Picker 显示的 Entry 列表
        entries = [ctx[1] for ctx in contexts]

        # 3. 显示并获取选择结果
        result = await self.picker.show(entries, self.config)

        if not result:
            return

        selected_idx, selected_text, returncode = result

        # 用户是否取消
        if self.picker.is_cancelled(returncode):
            return

        # 4. 匹配选中项并处理（优先匹配索引，然后匹配文本）
        if 0 <= selected_idx < len(contexts):
            item, entry = contexts[selected_idx]
            await self.handle_selection(item, returncode)
            return

        if not selected_text:
            for item, entry in contexts:
                texts = {entry.title}
                if entry.subtitle:
                    texts.add(f"{entry.title} {entry.subtitle}")

                if selected_text in texts:
                    await self.handle_selection(item, returncode)
                    return

        # 如果没有找到匹配项，进行错误处理
        logger.error(f"No match for index ({selected_idx}) and text ({selected_text})")
