import logging
import sys

from main import main

DEBUG_LOG = "/tmp/sway-launcher-debug.log"

# 日志配置，如果已经有其他地方配置过了，这里只会获取 logger
logging.basicConfig(
    filename=DEBUG_LOG,
    level=logging.INFO,  # 设置日志级别过滤门槛
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    encoding="utf-8",
)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("\nInterrupted")
