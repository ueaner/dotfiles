import atexit
import logging
import logging.config
import logging.handlers
from pathlib import Path

from waylaunch.core.models import LogLevel

logger = logging.getLogger("waylaunch")

WAYLAUNCH_LOG_FILE = "/tmp/waylaunch.log"  # noqa: S108

# type LogLevel = (
#     Literal[0, 10, 20, 30, 40, 50]
#     | Literal["NOTSET", "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
# )


def setup_logging(
    filename: str | None = None,
    handlers: list[str] | None = None,
    use_async: bool = False,
    level: LogLevel = LogLevel.INFO,
) -> None:
    """日志系统, 支持异步"""

    if not filename:
        filename = WAYLAUNCH_LOG_FILE
    if not handlers:
        handlers = ["file", "notify_send"]
    if not level:
        level = LogLevel.INFO

    config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": "%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s"
            },
            "notify": {"format": "%(message)s"},
        },
        "handlers": {
            "file": {
                "class": "logging.handlers.RotatingFileHandler",
                "filename": Path(filename).expanduser(),
                "maxBytes": 10 * 1024 * 1024,
                "backupCount": 5,
                "formatter": "default",
                "encoding": "utf-8",
            },
            "notify_send": {
                "class": "waylaunch.core.notify_send_handler.NotifySendHandler",
                "level": "ERROR",
                "formatter": "notify",
            },
            "async_queue": {
                "class": "logging.handlers.QueueHandler",
                "handlers": handlers,
                "respect_handler_level": True,
            },
        },
        "root": {"level": level, "handlers": ["async_queue"] if use_async else handlers},
    }

    logging.config.dictConfig(config)

    q_handler = logging.getHandlerByName("async_queue")

    if isinstance(q_handler, logging.handlers.QueueHandler) and q_handler.listener:
        q_handler.listener.start()
        _ = atexit.register(q_handler.listener.stop)
