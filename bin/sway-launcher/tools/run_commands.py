import subprocess
from typing import IO, cast


def run_commands(commands: list[list[str]] | list[str], bg_tools: set[str] | None = None) -> tuple[str, str, int]:
    """通用的管道命令执行函数"""
    if not commands:
        return "No Command", "", 1

    # 0. 定义不需要等待其完全退出的特殊工具
    if bg_tools is None:
        bg_tools = {"wl-copy"}

    # 变量类型收窄
    actual_commands: list[list[str]]

    if isinstance(commands[0], str):
        # 如果是 list[str]，将其包装为 list[list[str]]
        actual_commands = [cast(list[str], commands)]
    else:
        actual_commands = cast(list[list[str]], commands)

    # Popen 明确标注类型为 str (由于设置了 text=True)
    processes: list[subprocess.Popen[str]] = []
    prev_pipe: IO[str] | int | None = None

    try:
        # 1. 启动进程链
        for i, cmd in enumerate(actual_commands):
            is_last = i == len(actual_commands) - 1

            # 确定输出目标
            pipe_dest = subprocess.DEVNULL if (is_last and cmd[0] in bg_tools) else subprocess.PIPE

            # 启动进程
            p = subprocess.Popen(cmd, stdin=prev_pipe, stdout=pipe_dest, stderr=pipe_dest, text=True)
            processes.append(p)

            # 在父进程中关闭上一个进程的输出句柄，允许其被回收
            if isinstance(prev_pipe, IO):
                prev_pipe.close()

            prev_pipe = p.stdout

        # 2. 阻塞等待最后一个进程完成并捕获输出
        last_process = processes[-1]
        stdout, stderr = last_process.communicate()

        return (stdout or "").strip(), (stderr or "").strip(), last_process.returncode

    except Exception:
        # 发生异常时清理所有进程
        for p in processes:
            if p.poll() is None:
                p.kill()
        raise
