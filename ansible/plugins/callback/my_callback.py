from ansible.plugins.callback import CallbackBase
import threading
import http.server
import socketserver
import os
import socket


port = 8123


def get_local_ip():
    sock = None
    try:
        # Create a socket and connect to an external server
        # This will bind the socket to the local interface
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # No physical connection required
        sock.connect(("10.255.255.255", 1))
        local_ip = sock.getsockname()[0]
        return local_ip
    except (OSError, socket.error) as e:
        print(f"Failed to get LAN IP: {e}")
        # Iterate over all network interfaces to find available IP addresses
        for iface in socket.gethostbyname_ex(socket.gethostname())[-1]:
            if not iface.startswith("127."):  # Exclude loopback addresses
                return iface
        # Default to loopback if unable to get ip.
        return "127.0.0.1"
    finally:
        if sock is not None:
            sock.close()


# Defaults env for Ansible controller
def defaults_env():
    home_dir = os.path.expanduser("~")
    if not os.getenv("XDG_CONFIG_HOME"):
        os.environ["XDG_CONFIG_HOME"] = os.path.join(home_dir, ".config")
    if not os.getenv("XDG_CACHE_HOME"):
        os.environ["XDG_CACHE_HOME"] = os.path.join(home_dir, ".cache")
    if not os.getenv("XDG_DATA_HOME"):
        os.environ["XDG_DATA_HOME"] = os.path.join(home_dir, ".local/share")
    if not os.getenv("XDG_STATE_HOME"):
        os.environ["XDG_STATE_HOME"] = os.path.join(home_dir, ".local/state")
    if not os.getenv("XDG_BIN_HOME"):
        os.environ["XDG_BIN_HOME"] = os.path.join(home_dir, ".local/bin")
    if not os.getenv("XDG_BACKUP_DIR"):
        os.environ["XDG_BACKUP_DIR"] = os.path.join(home_dir, ".cache")
    if not os.getenv("GITHUB_PROXY"):
        os.environ["GITHUB_PROXY"] = ""


def get_archives_directory():
    backup_dir = os.environ.get(
        "XDG_BACKUP_DIR", os.path.join(os.path.expanduser("~"), ".cache")
    )

    archives_dir = backup_dir + "/archives"
    os.makedirs(archives_dir, exist_ok=True)

    return archives_dir


class ThreadedHTTPServer(object):
    def __init__(self, host, port, directory):
        Handler = http.server.SimpleHTTPRequestHandler
        self.httpd = socketserver.TCPServer((host, port), Handler)
        os.chdir(directory)
        self.thread = threading.Thread(target=self.httpd.serve_forever)
        # Ensure that when the main thread exits, the child thread also exits
        self.thread.daemon = True

    def start(self):
        self.thread.start()

    def stop(self):
        self.httpd.shutdown()
        self.thread.join()


class CallbackModule(CallbackBase):
    def __init__(self, *args, **kwargs):
        super(CallbackModule, self).__init__(*args, **kwargs)

        self.host = get_local_ip()
        self.port = port
        self.directory = get_archives_directory()  # ensure that this directory exists.

        # self.httpd = ThreadedHTTPServer("", self.port, self.directory)
        self.server = ThreadedHTTPServer(self.host, self.port, self.directory)

    def v2_playbook_on_start(self, playbook):
        _ = playbook
        defaults_env()
        self.server.start()
        os.environ["ANSIBLE_ARCHIVES_SERVER"] = (
            f"http://{self.server.httpd.server_address[0]}:{self.server.httpd.server_address[1]}"
        )
        print(
            f"HTTP server started on {os.environ["ANSIBLE_ARCHIVES_SERVER"]}, root: {self.directory}"
        )

    def v2_playbook_on_stats(self, stats):
        _ = stats
        self.server.stop()
        print("HTTP server stopped")

    def v2_runner_on_failed(self, result, ignore_errors=False):
        _ = result
        if not ignore_errors:
            self.server.stop()
            print("HTTP server stopped due to failure")
