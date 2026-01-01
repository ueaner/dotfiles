import subprocess


def run_commands(commands: list[str] | list[list[str]], bg_tools={"wl-copy"}) -> tuple[str, str, int]:
    """通用的管道命令执行函数"""
    if not commands:
        return "No Command", "", 1

    if isinstance(commands[0], str):
        commands = [commands]

    # 0. 定义不需要等待其完全退出的特殊工具

    processes: list[subprocess.Popen] = []
    prev_pipe = None

    # 1. 启动进程链
    for i, cmd in enumerate(commands):
        # 如果最后一个进程是后台工具，不需要捕获其 stdout
        is_last = i == len(commands) - 1
        pipe_dest = subprocess.DEVNULL if (is_last and cmd[0] in bg_tools) else subprocess.PIPE

        p = subprocess.Popen(cmd, stdin=prev_pipe, stdout=pipe_dest, stderr=pipe_dest, text=True)
        processes.append(p)
        # 在父进程中关闭上一个进程的输出句柄，允许其被回收
        if prev_pipe:
            prev_pipe.close()
        prev_pipe = p.stdout

    # 2. 阻塞等待最后一个进程完成并捕获输出
    stdout, stderr = processes[-1].communicate()
    return (stdout or "").strip(), (stderr or "").strip(), processes[-1].returncode
