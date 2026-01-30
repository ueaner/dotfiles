#!/usr/bin/env bash

# 查找数组中特定元素的索引（索引从 0 开始）
# Usage Example:
#   fruits=("apple" "banana" "cherry")
#   index=$(array_index_of "banana" "${fruits[@]}")
array_index_of() {
    # 至少需要 2 个参数：目标值 和 数组中的至少一个元素
    if [[ $# -lt 2 ]]; then
        echo "Usage: array_index_of <target> <element1> [element2 ...]" >&2
        return 2 # 使用特定的错误码表示参数不足
    fi

    local target="$1"
    shift # 移除第一个参数（目标值），余下的 $@ 即为数组内容

    # 接收所有参数并组装成数组
    local arr=("$@")
    local idx=

    # 0-based indexing
    local index_offset=0
    if [[ -n "${ZSH_VERSION:-}" && ! -o KSH_ARRAYS ]]; then
        # 1-based indexing
        index_offset=1
    fi

    # Arrays in bash are 0-indexed;
    # Arrays in  zsh are 1-indexed.
    for ((i = 0; i < ${#arr[@]}; i++)); do
        local real_index=$((i + index_offset))
        if [[ "${arr[$real_index]}" == "$target" ]]; then
            idx=$real_index
            break
        fi
    done

    if [[ -z "$idx" ]]; then
        echo -1
        return 1
    fi

    # 统一转换回 0-based 索引并输出
    echo $((idx - index_offset))
}

# 获取数组中指定索引的元素，支持负数索引（-1 表示最后一个）
# Usage Example:
#   fruits=("apple" "banana" "cherry")
#   item=$(array_get_at 1 "${fruits[@]}") # 输出 banana
#   item=$(array_get_at -1 "${fruits[@]}") # 输出 cherry
array_get_at() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: array_get_at <index> <element1> [element2 ...]" >&2
        return 2
    fi

    local target_idx="$1"
    shift
    local arr=("$@")
    local len=${#arr[@]}

    # 1. 处理负数索引逻辑 (例如: -1 变为 len-1)
    if [[ $target_idx -lt 0 ]]; then
        target_idx=$((len + target_idx))
    fi

    # 2. 严谨的边界检查
    if [[ $target_idx -lt 0 ]] || [[ $target_idx -ge $len ]]; then
        # 如果你想支持默认值，可以在这里 echo "${DEFAULT_VAL:-}"
        return 1
    fi

    # 3. 处理 Zsh 偏移量 (复用你之前的逻辑)
    local index_offset=0
    if [[ -n "${ZSH_VERSION:-}" && ! -o KSH_ARRAYS ]]; then
        index_offset=1
    fi

    local real_index=$((target_idx + index_offset))
    echo "${arr[$real_index]}"
}
