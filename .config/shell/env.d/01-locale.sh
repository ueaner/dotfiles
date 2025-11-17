# locale
# 本地化编码名称由三部分组成：语言代码[_国家代码[.编码]]，如 zh_CN.UTF-8
# a. 语言代码 (Language Code)
# b. 国家代码 (Country Code)
# c. 编码 (Encoding)
if [[ "${OSTYPE}" == darwin* ]]; then
    export LANG=zh_CN.UTF-8
    export LC_CTYPE=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
fi
