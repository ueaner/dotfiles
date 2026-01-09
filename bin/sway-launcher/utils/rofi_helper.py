# utils/rofi_helper.py
import math


def calculate_window_size(count: int, max_cols: int = 5, max_rows: int = 3) -> tuple[int, int, str, str]:
    """
    计算 Rofi 布局。每列最多 max_cols 个，最多 max_rows 行。

    Args:
        count: 工具个数。
    """
    cols = min(count, max_cols)
    rows = min(math.ceil(count / max_cols), max_rows)

    # height (em): 2 + (rows - 1) + 7.3 * rows
    #
    #   2em:           window { padding: 1em }
    #   (rows - 1)em:  listview { spacing: 1em; }
    #   7.3 * rows:
    #     2.3em:       element { padding: 1em; spacing: 0.3em; }
    #     3em:         element-icon { size: 3em; }
    #     2em:         element-text: 1em or 2em (-eh 2)

    width = round(2 + (cols - 1) + 7.3 * cols, 1)
    height = round(2 + (rows - 1) + 7.3 * rows, 1)

    return cols, rows, f"{width}em", f"{height}em"
