#!/usr/bin/python3
# -*- coding: utf-8 -*-

# Copyright: (c) 2024, Your Name
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function

__metaclass__ = type

import os
import platform
import shutil
import tempfile

from ansible.module_utils.basic import AnsibleModule

# pyright: reportMissingImports=false
from ansible.module_utils.downloader import Downloader

DOCUMENTATION = r"""
---
module: install-package
short_description: Install packages from various sources
description:
  - This module installs packages from various sources like GitHub releases.
  - It supports template-based URL construction with placeholders.
  - Can handle different archive formats and extract specific files.
version_added: "1.0.0"
options:
  name:
    description:
      - Name of the package to install
    required: true
    type: str
  template:
    description:
      - Template URL for downloading the package
      - Can contain placeholders in the format <placeholder_name>
    required: false
    type: str
  archives:
    description:
      - List of archive files to download and extract
      - Can be simple strings or full URLs
      - Supports placeholders in the format <placeholder_name>
      - When using full URLs, they override the template URL
    required: false
    type: list
    elements: str
  placeholders:
    description:
      - Dictionary of placeholders to be replaced in template and archive names
      - Values can be strings or shell commands (starting with curl)
      - Placeholders defined earlier can be referenced by later ones
    required: false
    type: dict
  dst:
    description:
      - Destination directory for installation
    required: false
    type: str
  install:
    description:
      - Custom installation script
    required: false
    type: str
  postinstall:
    description:
      - Script to run after installation
    required: false
    type: str
  include:
    description:
      - List of files to include from archive
    required: false
    type: list
    elements: str
  strip:
    description:
      - Number of path components to strip during extraction
    required: false
    type: int
    default: 0
author:
  - Your Name (@yourhandle)
"""

EXAMPLES = r"""
- name: Install nvim
  install-package:
    name: nvim
    placeholders:
      repo: neovim/neovim
    template: "https://github.com/<repo>/releases/latest/download/<archive>"
    archives:
      - nvim-linux-x86_64.tar.gz
      - nvim-linux-aarch64.tar.gz
      - nvim-darwin-x86_64.tar.gz
      - nvim-darwin-arm64.tar.gz
    strip: 1
    dst: "$XDG_DATA_HOME/nvim-latest"
    postinstall: |
      ln -sf $XDG_DATA_HOME/nvim-latest/bin/nvim $XDG_BIN_HOME/nvim

- name: Install go
  install-package:
    name: go
    placeholders:
      version: "curl -s 'https://golang.google.cn/VERSION?m=text' | head -n1"
    archives:
      - https://dl.google.com/go/<version>.linux-amd64.tar.gz
      - https://dl.google.com/go/<version>.darwin-amd64.tar.gz
    strip: 1
    dst: "$XDG_DATA_HOME/go"
    postinstall: |
      ln -sf $XDG_DATA_HOME/go/bin/* $XDG_BIN_HOME

- name: Install gitmux with dynamic version
  install-package:
    name: gitmux
    placeholders:
      repository: arl/gitmux
      api_url: "https://api.github.com/repos/<repository>/releases/latest"
      version: "curl -s <api_url> | grep tag_name | cut -d '\"' -f 4 | sed 's/^v//'"
    template: "https://github.com/<repository>/releases/download/v<version>/<archive>"
    archives:
      - gitmux_<version>_linux_amd64.tar.gz
      - gitmux_<version>_linux_arm64.tar.gz
      - gitmux_<version>_macOS_amd64.tar.gz
      - gitmux_<version>_macOS_arm64.tar.gz
    include:
      - gitmux
    strip: 0
    dst: "$XDG_BIN_HOME"
"""

RETURN = r"""
dest:
  description: The destination directory where the package was installed
  type: str
  returned: success
msg:
  description: The output message that the module generates
  type: str
  returned: always
"""


def get_system_info():
    """获取系统信息：操作系统和CPU架构"""
    system = platform.system().lower()
    machine = platform.machine().lower()

    # 标准化架构名称
    arch_mapping = {
        "x86_64": "x86_64",
        "amd64": "x86_64",
        "arm64": "arm64",
        "aarch64": "arm64",
        "i386": "x86",
        "i686": "x86",
    }

    arch = arch_mapping.get(machine, machine)
    return system, arch


def atomic_replace(src_path, dest_path):
    """使用原子操作替换文件或目录"""
    temp_dest_path = dest_path + ".new"

    # 删除已存在的临时目标
    if os.path.exists(temp_dest_path):
        if os.path.isdir(temp_dest_path):
            shutil.rmtree(temp_dest_path)
        else:
            os.remove(temp_dest_path)

    # 复制源到临时目标
    if os.path.isfile(src_path):
        shutil.copy2(src_path, temp_dest_path)
    else:  # src_path is a directory
        shutil.copytree(src_path, temp_dest_path)

    # 删除已存在的最终目标
    if os.path.exists(dest_path):
        if os.path.isdir(dest_path):
            shutil.rmtree(dest_path)
        else:
            os.remove(dest_path)

    # 重命名临时目标为最终目标
    os.rename(temp_dest_path, dest_path)


def match_archive(archives, system, arch):
    """匹配适合当前系统和架构的归档文件"""
    # 标准化系统和架构名称
    system = system.lower()
    arch = arch.lower()

    # 系统映射
    system_mapping = {"darwin": "macos"}

    # 架构映射
    arch_mapping = {
        "x86_64": ["x86_64", "amd64", "x64"],
        "amd64": ["x86_64", "amd64", "x64"],
        "x64": ["x86_64", "amd64", "x64"],
        "aarch64": ["aarch64", "arm64"],
        "arm64": ["aarch64", "arm64"],
    }

    # 获取映射后的系统名
    mapped_system = system_mapping.get(system, system)

    # 获取映射后的架构列表
    architectures = arch_mapping.get(arch, [arch])

    matched_archives = []

    for archive_item in archives:
        if isinstance(archive_item, str):
            # 简化处理 - 直接使用字符串作为本地和远程文件名
            archive_name = archive_item
            remote_name = archive_item
        elif isinstance(archive_item, dict):
            # 处理实际的字典类型
            # 格式: {'local_name': 'remote_name'}
            archive_name, remote_name = next(iter(archive_item.items()))
        else:
            # 其他情况回退到字符串处理
            archive_name = str(archive_item)
            remote_name = archive_name

        # 检查是否匹配当前系统和架构
        archive_name_lower = archive_name.lower()

        # 系统匹配检查
        system_matches = (
            mapped_system in archive_name_lower
            or system in archive_name_lower
            or
            # 如果没有指定系统信息，则匹配所有
            not any(
                sys in archive_name_lower
                for sys in ["linux", "darwin", "macos", "windows"]
            )
        )

        # 架构匹配检查
        arch_matches = (
            any(arch in archive_name_lower for arch in architectures)
            or
            # 如果没有指定架构信息，则匹配所有
            not any(
                arch_str in archive_name_lower
                for arch_str in [
                    "x86_64",
                    "amd64",
                    "x64",
                    "aarch64",
                    "arm64",
                    "i386",
                    "i686",
                ]
            )
        )

        if system_matches and arch_matches:
            matched_archives.append((archive_name, remote_name))

    # 如果找到多个匹配项，优先选择同时匹配系统和架构的
    if len(matched_archives) > 1:
        specific_matches = []
        for archive_name, remote_name in matched_archives:
            archive_name_lower = archive_name.lower()
            if any(
                sys in archive_name_lower for sys in [system, mapped_system]
            ) and any(arch in archive_name_lower for arch in architectures):
                specific_matches.append((archive_name, remote_name))

        if specific_matches:
            return specific_matches[0]
        else:
            # 如果没有特别匹配的，返回第一个通用匹配
            return matched_archives[0]
    elif len(matched_archives) == 1:
        return matched_archives[0]
    else:
        # 没有找到匹配项时，尝试返回不区分系统架构的通用项
        for archive_item in archives:
            if isinstance(archive_item, str):
                archive_name = archive_item
            elif isinstance(archive_item, dict):
                archive_name, remote_name = next(iter(archive_item.items()))
            else:
                archive_name = str(archive_item)

            # 如果文件名中不包含任何系统或架构信息，则认为是通用的
            archive_name_lower = archive_name.lower()
            if not any(
                keyword in archive_name_lower
                for keyword in [
                    "linux",
                    "darwin",
                    "macos",
                    "windows",
                    "x86_64",
                    "amd64",
                    "x64",
                    "aarch64",
                    "arm64",
                    "i386",
                    "i686",
                ]
            ):
                return archive_name, archive_name

    return None, None


def execute_command(command, module):
    """执行命令"""
    if not command:
        return True, ""

    try:
        import subprocess

        # 展开环境变量
        command = os.path.expandvars(command)
        # 直接执行命令并显示输出
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            env=dict(
                os.environ, PACKAGE_ARCHIVE_NAME=module.params.get("local_archive", "")
            ),
        )
        # 如果命令执行失败，中断执行
        if result.returncode != 0:
            module.fail_json(
                msg=f"Command failed: {command}, return code: {result.returncode}",
                stdout=result.stdout,
                stderr=result.stderr,
            )
        return True, result.stdout
    except Exception as e:
        module.fail_json(msg=f"Failed to execute command: {command}, error: {str(e)}")


def extract_with_strip(
    archive_path, extract_dir, strip_components=0, include_files=None
):
    """解压文件并去除路径前缀"""
    if (
        archive_path.endswith(".tar.gz")
        or archive_path.endswith(".tar.xz")
        or archive_path.endswith(".tar.bz2")
        or archive_path.endswith(".tgz")
    ):
        import tarfile

        with tarfile.open(archive_path, "r") as tar:
            if strip_components == 0:
                tar.extractall(path=extract_dir)
            else:
                for member in tar.getmembers():
                    parts = member.path.split("/")
                    if len(parts) > strip_components:
                        member.path = "/".join(parts[strip_components:])
                        tar.extract(member, path=extract_dir)
                    elif len(parts) == strip_components and not member.path.endswith(
                        "/"
                    ):
                        # 处理文件在strip层级的情况
                        member.path = os.path.basename(member.path)
                        if member.path:  # 确保不是空字符串
                            tar.extract(member, path=extract_dir)
    elif archive_path.endswith(".zip"):
        import zipfile

        with zipfile.ZipFile(archive_path, "r") as zip_ref:
            if strip_components == 0:
                zip_ref.extractall(extract_dir)
            else:
                for member in zip_ref.infolist():
                    # 确保member.filename不为空
                    if member.filename and len(member.filename) > 0:
                        parts = member.filename.split("/")
                        if len(parts) > strip_components:
                            member.filename = "/".join(parts[strip_components:])
                            # 确保filename不为空
                            if member.filename:
                                zip_ref.extract(member, extract_dir)
    elif archive_path.endswith(".gz"):
        # 处理 .gz 文件 (单独的 gzip 文件)
        import gzip
        import shutil

        # 对于 .gz 文件，我们直接解压到目标目录
        # 如果指定了include_files且只有一个文件，则使用该文件名
        if include_files and len(include_files) == 1:
            extracted_filename = include_files[0]
        else:
            # 默认行为：生成解压后的文件名（移除 .gz 扩展名）
            extracted_filename = os.path.basename(archive_path)
            if extracted_filename.endswith(".gz"):
                extracted_filename = extracted_filename[:-3]  # 移除 .gz 后缀

        extracted_file_path = os.path.join(extract_dir, extracted_filename)

        # 解压 .gz 文件
        with gzip.open(archive_path, "rb") as gz_file:
            with open(extracted_file_path, "wb") as output_file:
                shutil.copyfileobj(gz_file, output_file)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type="str", required=True),
            template=dict(type="str", required=False),
            archives=dict(type="list", elements="str", required=False),
            placeholders=dict(type="dict", required=False),
            dst=dict(type="str", required=False),
            install=dict(type="str", required=False),
            postinstall=dict(type="str", required=False),
            include=dict(type="list", elements="str", required=False),
            strip=dict(type="int", required=False, default=0),
        ),
        supports_check_mode=True,
    )

    name = module.params["name"]
    template = module.params.get("template")
    archives = module.params.get("archives", [])
    placeholders = module.params.get("placeholders", {})
    # 确保placeholders不为None
    if placeholders is None:
        placeholders = {}

    dst = module.params.get("dst")
    install_script = module.params.get("install")
    postinstall_script = module.params.get("postinstall")
    include_files = module.params.get("include", [])
    strip_components = module.params.get("strip", 0)

    if module.check_mode:
        module.exit_json(changed=False, msg=f"Would install package {name}")

    # 如果提供了install脚本，则直接使用它
    if install_script:
        success, output = execute_command(install_script, module)
        if success:
            module.exit_json(
                changed=True,
                msg=f"Successfully installed {name} using custom script",
                stdout=output,
            )
        else:
            module.fail_json(
                msg=f"Failed to install {name} using custom script", stdout=output
            )

    # 如果没有install脚本，则必须提供archives
    if not archives:
        module.fail_json(msg=f"No archives defined for package {name}")

    # 检查archives中的条目是否为完整URL或者是否提供了template
    has_full_urls = any(
        isinstance(archive_item, str)
        and (archive_item.startswith("http://") or archive_item.startswith("https://"))
        for archive_item in archives
    )

    if not has_full_urls and not template:
        module.fail_json(
            msg=f"Either install script or both template and archives (with placeholders) must be provided for package {name}"
        )

    # 获取系统信息
    system, arch = get_system_info()

    # 查找匹配的归档文件
    if not archives:
        module.fail_json(msg=f"No archives defined for package {name}")

    local_archive, remote_archive = match_archive(archives, system, arch)
    if not local_archive:
        module.fail_json(
            msg=f"No matching archive found for {system}-{arch} in package {name}"
        )

    # 将local_archive添加到模块参数中，供execute_command函数使用
    module.params["local_archive"] = local_archive

    # 处理占位符
    # 首先处理需要执行shell命令的占位符（如以curl开头的）
    processed_placeholders = {}
    # 按顺序处理占位符，确保前面解析的占位符可以被后面的引用
    for placeholder_name, placeholder_value in placeholders.items():
        # 先替换已处理的占位符
        if isinstance(placeholder_value, str):
            # 替换已经处理过的占位符
            for processed_name, processed_value in processed_placeholders.items():
                placeholder = f"<{processed_name}>"
                if placeholder in placeholder_value:
                    placeholder_value = placeholder_value.replace(
                        placeholder, str(processed_value)
                    )

            # 处理需要执行命令的占位符
            if isinstance(placeholder_value, str):
                # 判断是否为 shell 命令
                command = placeholder_value.split()[0] if placeholder_value else ""
                if shutil.which(command):
                    # 执行 shell 命令获取值
                    import subprocess

                    try:
                        result = subprocess.run(
                            placeholder_value,
                            shell=True,
                            capture_output=True,
                            text=True,
                        )
                        processed_placeholders[placeholder_name] = result.stdout.strip()
                    except Exception:
                        processed_placeholders[placeholder_name] = placeholder_value
                else:
                    processed_placeholders[placeholder_name] = placeholder_value
            else:
                processed_placeholders[placeholder_name] = placeholder_value
        else:
            processed_placeholders[placeholder_name] = placeholder_value

    # 构建下载URL
    # 如果remote_archive已经是完整URL，则直接使用它
    if remote_archive.startswith("http://") or remote_archive.startswith("https://"):
        download_url = remote_archive
        # 替换URL中的占位符
        for placeholder_name, placeholder_value in processed_placeholders.items():
            placeholder = f"<{placeholder_name}>"
            download_url = download_url.replace(placeholder, str(placeholder_value))
    else:
        # 否则使用template并替换占位符
        download_url = template
        # 替换模板中的占位符
        for placeholder_name, placeholder_value in processed_placeholders.items():
            placeholder = f"<{placeholder_name}>"
            download_url = download_url.replace(placeholder, str(placeholder_value))

        # 处理归档文件名中的占位符
        final_remote_archive = remote_archive
        for placeholder_name, placeholder_value in processed_placeholders.items():
            placeholder = f"<{placeholder_name}>"
            final_remote_archive = final_remote_archive.replace(
                placeholder, str(placeholder_value)
            )

        # 替换归档文件名
        download_url = download_url.replace("<archive>", final_remote_archive)

    # 创建临时目录
    temp_dir = tempfile.mkdtemp()
    try:
        # 确定本地文件路径
        # 如果 remote_archive 是完整 URL，则从 URL 中提取文件名
        if remote_archive.startswith("http://") or remote_archive.startswith(
            "https://"
        ):
            # 从 URL 中提取文件名
            import urllib.parse

            parsed_url = urllib.parse.urlparse(remote_archive)
            url_filename = os.path.basename(parsed_url.path)
            local_file_path = os.path.join(temp_dir, url_filename)
        else:
            local_file_path = os.path.join(temp_dir, local_archive)

        # 下载文件
        success, download_info = Downloader().download(download_url, local_file_path)
        if not success:
            module.fail_json(msg=f"Failed to download {download_url}: {download_info}")

        # 设置目标路径
        if not dst:
            dest = os.path.join(os.environ.get("HOME", "/tmp"), ".local", "bin")
        else:
            dest = os.path.expandvars(dst)
            dest = os.path.expanduser(dest)

        # 创建目标目录
        try:
            if not os.path.exists(dest):
                os.makedirs(dest, mode=0o755, exist_ok=True)
        except Exception as e:
            module.fail_json(
                msg=f"Failed to create destination directory {dest}: {str(e)}"
            )

        # 解压或移动文件
        if local_archive.endswith(
            (".tar.gz", ".tar.xz", ".tar.bz2", ".zip", ".gz", ".tgz")
        ):
            # 创建临时解压目录
            temp_extract_dir = os.path.join(temp_dir, "extracted")
            os.makedirs(temp_extract_dir)

            # 解压文件
            extract_with_strip(
                local_file_path, temp_extract_dir, strip_components, include_files
            )

            # 如果指定了要包含的文件，则只复制这些文件
            if include_files:
                for include_file in include_files:
                    src_path = os.path.join(temp_extract_dir, include_file)
                    dest_path = os.path.join(dest, os.path.basename(include_file))
                    if os.path.exists(src_path):
                        # 使用原子操作替换文件，避免 "Text file busy" 错误
                        atomic_replace(src_path, dest_path)
            else:
                # 整体替换整个目录，保持包的完整性
                # 使用原子操作替换文件，避免 "Text file busy" 错误
                atomic_replace(temp_extract_dir, dest)

        else:
            # 直接移动文件
            dest_path = os.path.join(dest, os.path.basename(local_archive))
            # 使用原子操作替换文件，避免 "Text file busy" 错误
            temp_dest_path = dest_path + ".new"
            shutil.copy2(local_file_path, temp_dest_path)
            # 直接使用原子操作替换目标文件
            os.rename(temp_dest_path, dest_path)

        # 执行安装后脚本
        postinstall_result = None
        if postinstall_script:
            success, output = execute_command(postinstall_script, module)
            postinstall_result = output
            # 如果命令执行失败，记录警告信息
            if not success:
                module.warn(f"Install post script failed: {postinstall_script}")

        module.exit_json(
            changed=True,
            msg=f"Successfully installed {name}",
            dest=dest,
            download_url=download_url,
            download_info=download_info,
            postinstall_result=postinstall_result.rstrip("\n")
            if postinstall_result
            else None,
        )

    except Exception as e:
        # 确保任何异常都能以正确的JSON格式返回
        import traceback

        module.fail_json(
            msg=f"Failed to install package {name}: {str(e)}",
            exception=str(e),
            traceback=traceback.format_exc(),
        )
    finally:
        # 清理临时目录
        shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
