"""Launcher 流程方法。

提供统一的模板抽象层。
"""

from core.contract import Config, Entry, Item, ItemProvider, Picker
from utils.exception_handler import report_exception


class Launcher[T: Item]:
    """Launcher 基础类，依赖于选择器接口"""

    config: Config
    picker: Picker
    item_providers: list[ItemProvider[T]]

    def __init__(self, config: Config, picker: Picker, item_providers: list[ItemProvider[T]]):
        self.config = config
        self.picker = picker
        self.item_providers = item_providers

    def handle_selection(self, selected_item: T, returncode: int = 0) -> None:
        """处理用户选择的条目

        子类可以覆盖此方法，扩展选中后要执行的动作
        """
        selected_item.run(returncode)

    def launch(self) -> None:
        """启动 launcher 的主要流程"""

        # 1. 存储 (Item, Entry) 的对应关系
        contexts: list[tuple[T, Entry]] = []

        for provider in self.item_providers:
            raw_items = provider.items(self.config)
            contexts.extend([(item, provider.to_entry(item)) for item in raw_items])

        if not contexts:
            report_exception(
                error=Exception(f"The items data is empty. (-show {','.join(self.config.show_types)})"),
                notify=True,
            )
            return

        # 2. 提取用于给 Picker 显示的 Entry 列表
        entries = [ctx[1] for ctx in contexts]

        # 3. 显示并获取选择结果
        result = self.picker.show(entries, self.config)

        if not result:
            return

        selected_text, returncode = result

        # 用户是否取消
        if self.picker.is_cancelled(returncode):
            return

        # 4. 匹配选中项并处理
        for item, entry in contexts:
            if entry.text == selected_text:
                self.handle_selection(item, returncode)
                return

        # 如果没有找到匹配项，进行错误处理
        report_exception(
            error=Exception(f"No match item: {selected_text}"),
            notify=True,
        )
