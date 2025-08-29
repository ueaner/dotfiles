import hashlib
import json
import os
import shutil
from urllib.parse import urlparse
from urllib.request import Request, urlopen

github_proxy = os.environ.get("GITHUB_PROXY", "")


class Downloader:
    def __init__(self, cache_dir=None):
        """
        初始化下载器

        Args:
            cache_dir (str): 缓存目录路径，默认为 ~/.cache/archives
        """
        if cache_dir is None:
            self.cache_dir = os.path.expanduser("~/.cache/archives")
        else:
            self.cache_dir = cache_dir

        # 确保缓存目录存在
        os.makedirs(self.cache_dir, exist_ok=True)

    def _get_cache_path(self, url):
        """
        根据URL生成缓存文件路径

        Args:
            url (str): 文件URL

        Returns:
            str: 缓存文件路径
        """
        # 使用URL的hash值作为文件名，避免特殊字符问题
        # 对于GitHub URL，使用原始URL计算哈希值，避免GITHUB_PROXY影响
        if github_proxy and url.startswith(github_proxy):
            url = url[len(github_proxy) :]

        url_hash = hashlib.md5(url.encode()).hexdigest()

        # 从URL中提取文件扩展名，正确处理复合扩展名如 .tar.gz, .tar.xz 等
        parsed_url = urlparse(url)
        filename = os.path.basename(parsed_url.path)

        extension = ""
        # 检查是否以 .tar. 开头的复合扩展名
        if ".tar." in filename:
            # 找到最后一个 .tar. 的位置
            last_tar_index = filename.rfind(".tar.")
            # 提取 .tar. 及其后面的部分作为扩展名
            extension = filename[last_tar_index:]
        else:
            # 如果不是复合扩展名，则使用传统的单扩展名提取方法
            if "." in filename:
                extension = "." + filename.split(".")[-1]

        return os.path.join(self.cache_dir, url_hash + extension)

    def _get_metadata_path(self, cache_file_path):
        """
        获取元数据文件路径

        Args:
            cache_file_path (str): 缓存文件路径

        Returns:
            str: 元数据文件路径
        """
        return cache_file_path + ".metadata"

    def _load_metadata(self, cache_file_path):
        """
        加载缓存文件的元数据

        Args:
            cache_file_path (str): 缓存文件路径

        Returns:
            dict: 元数据字典
        """
        metadata_path = self._get_metadata_path(cache_file_path)
        if os.path.exists(metadata_path):
            try:
                with open(metadata_path, "r") as f:
                    return json.load(f)
            except:
                return {}
        return {}

    def _save_metadata(self, cache_file_path, metadata):
        """
        保存缓存文件的元数据

        Args:
            cache_file_path (str): 缓存文件路径
            metadata (dict): 元数据字典
        """
        metadata_path = self._get_metadata_path(cache_file_path)
        try:
            with open(metadata_path, "w") as f:
                json.dump(metadata, f)
        except:
            pass  # 忽略元数据保存失败

    def _is_remote_file_updated(self, url, cache_metadata):
        """
        检查远程文件是否更新

        Args:
            url (str): 文件URL
            cache_metadata (dict): 缓存元数据

        Returns:
            bool: 如果远程文件已更新返回True，否则返回False
        """
        try:
            # 发送HEAD请求检查文件状态
            request = Request(url, method="HEAD")
            request.add_header("User-Agent", "Downloader")
            response = urlopen(request)

            # 检查Last-Modified
            remote_last_modified = response.headers.get("Last-Modified")
            if remote_last_modified:
                cached_last_modified = cache_metadata.get("last_modified")
                # 如果远程文件的最后修改时间与缓存的不同，则文件已更新
                if (
                    cached_last_modified
                    and remote_last_modified != cached_last_modified
                ):
                    return True
                # 保存新的Last-Modified
                cache_metadata["last_modified"] = remote_last_modified
                return False

            # 如果没有Last-Modified，无法判断是否更新，默认返回False
            return False
        except:
            # 如果检查失败，默认不更新缓存
            return False

    def download(self, url, dest):
        """
        带缓存功能的下载函数

        Args:
            url (str): 文件下载URL
            dest (str): 目标文件路径

        Returns:
            tuple: (success: bool, error: str or None)
        """
        # 获取缓存路径
        cache_path = self._get_cache_path(url)

        # 检查是否有缓存
        if os.path.exists(cache_path):
            # 获取缓存元数据
            cache_metadata = self._load_metadata(cache_path)

            # 检查远程文件是否已更新
            if not self._is_remote_file_updated(url, cache_metadata):
                # 使用缓存文件
                try:
                    shutil.copy2(cache_path, dest)
                    return (True, f"Cache hit, {cache_path}")
                except Exception:
                    # 如果复制缓存文件失败，则继续下载
                    pass
            else:
                # 如果文件已更新，保存更新后的元数据
                self._save_metadata(cache_path, cache_metadata)

        # 执行实际下载
        success, error, last_modified = self._download_file(url, cache_path)
        if not success:
            return (False, error)

        # 复制缓存文件到目标位置
        shutil.copy2(cache_path, dest)

        # 保存元数据
        cache_metadata = {}
        if last_modified:
            cache_metadata["last_modified"] = last_modified
        self._save_metadata(cache_path, cache_metadata)

        return (True, None)

    def _download_file(self, url, dest):
        """
        实际下载文件的内部方法

        Args:
            url (str): 文件下载URL
            dest (str): 目标文件路径

        Returns:
            tuple: (success: bool, error: str or None)
        """
        try:
            # 只有当 URL 是 GitHub 下载链接且未包含代理时才添加代理
            if url.startswith("https://github.com/"):
                # 处理 GITHUB_PROXY 环境变量
                url = github_proxy + url

            request = Request(url, headers={"User-Agent": "Downloader"})
            response = urlopen(request)

            with open(dest, "wb") as f:
                while True:
                    chunk = response.read(1024 * 1024)  # 1MB chunks
                    if not chunk:
                        break
                    f.write(chunk)

            # 返回成功状态和响应头信息，用于获取Last-Modified
            last_modified = response.headers.get("Last-Modified")
            return (True, None, last_modified)
        except Exception as e:
            # 更详细的错误信息
            import traceback

            return (False, str(e) + "\n" + traceback.format_exc(), None)
