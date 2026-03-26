import logging
import shutil
import subprocess


class NotifySendHandler(logging.Handler):
    """
    自定义日志处理器：将日志通过 notify-send 发送到桌面通知。
    """

    def __init__(self, level: int = logging.ERROR) -> None:
        super().__init__(level)
        self.executable = shutil.which("notify-send")

    def emit(self, record: logging.LogRecord) -> None:
        if not self.executable:
            return

        try:
            # 格式化消息内容
            msg = self.format(record)
            title = f"Waylaunch {record.levelname.capitalize()}"

            # 映射日志级别到通知图标强度
            urgency = "normal"
            if record.levelno >= logging.CRITICAL:
                urgency = "critical"
            elif record.levelno <= logging.INFO:
                urgency = "low"

            # 执行系统命令
            subprocess.run(  # noqa: S603
                [self.executable, "-u", urgency, title, msg],
                check=False,
                capture_output=True,
                timeout=1,
            )
        except Exception:
            self.handleError(record)
