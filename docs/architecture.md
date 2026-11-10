# 架构重设计方案

> 状态：**提案（RFC）** · 目标读者：仓库维护者
> 范围：`ueaner/dotfiles` 全仓库 —— 部署载荷、Shell 环境、`bin/` 工具集、`bin/setup` 引导框架、`bin/waylaunch` Python 项目、以及缺失的测试与 CI。
> 约束前提：**保留 macOS 支持**（不删除 `@macos` 相关实现，平台抽象必须真实可扩展）。

> **修复记录（2026-11-10，为新 Apple Silicon Mac 初始化扫清阻断）**：以下条目已在现状架构内直接修复，无需等待本 RFC 落地 ——
> P5（`main` 空分支正则，DESKTOP 为空时不再产生空分支）、P6（非法 section 现在 `exit 2`）、
> P9（`lib/init` 为 `GITHUB_PROXY` 提供空默认值，12/21/45 等脚本不再因 `set -u` 中止）、
> P14 中的 `03-hostname.sh` 死分支（未登记型号现在 warn+跳过，不再把主机名置空）与
> `lima-nerdctl-downloader` 的 `$FILE` 未定义（另补 `curl -fsI`）、
> P19 的 `lib/color.sh wc -L`（改用 awk）、
> `52-android.sh` 无平台后缀导致在 macOS 上执行 dnf（已改名 `52-android@fedora.sh`）、
> 弃用 `/opt/local` 自定义前缀，Homebrew 改用 Apple Silicon 标准前缀 `/opt/homebrew`
> （`05-packager@macos.sh` 直接运行官方安装脚本，`04-brew.sh` 移除单 Cellar hack，
> 服务软链与 plist 内嵌路径同步迁移，`05-path.sh` 基础 PATH 同步更新）、
> `05-packager@macos.sh` 增加 CLT 引导、`34-container@macos.sh` 的
> `sort -V`（BSD sort 无 -V，改用主版本号数值比较）、`31-service@macos.sh` 重复重启服务、
> `11-desktop@macos.sh` 在 symbolichotkeys.plist 缺失时中止整个 main、`01/02/32/45/51` 的
> 幂等性缺陷（clone/checkout 状态分离、`-O` 检查目标与 chown 目标一致、补 `mkdir -p`）、
> `22-app@macos.sh` 单个 cask 失败中止整批安装（改为逐个安装）。

---

## 0. 摘要（TL;DR）

本仓库当前把**三种身份**压在一个目录树里：

1. **部署载荷（payload）** —— 必须出现在 `$HOME` 对应路径才能生效的文件（`.bashrc`、`.config/**`、`.local/**`、`bin/**`）。
2. **工程产物（engineering artifacts）** —— 只在开发/维护时被读取的文件（`README.md`、各级 `AGENTS.md`、`Taskfile`、`pyproject.toml`、本该有的 `docs/`、`tests/`、CI）。
3. **软件项目** —— `bin/setup`（4050 行 Bash 框架）与 `bin/waylaunch`（3135 行 Python 包）。

因为仓库采用「bare 仓库 + `work-tree=$HOME`」，仓库根目录**等于** `$HOME`，于是身份 2 被强制部署进家目录（实测 `~/README.md` 已作为部署副本存在于 `$HOME`；根 `AGENTS.md` 尚未提交故 `~/AGENTS.md` 暂不存在，但提交后即会被 checkout 进 `$HOME`），且仓库里**没有位置**容纳 `docs/`、`tests/`、`.github/`。

重设计的核心不是"搬家"，而是引入四个此前缺失的**契约**：

| 契约 | 解决的问题 | 关键交付物 |
|------|-----------|-----------|
| **上下文契约** | 平台/桌面/主机判定被复制 5 份，词表各不相同 | `lib/facts` —— 唯一事实来源，bash/zsh/Python 共用 |
| **载荷契约** | 什么该进 `$HOME`、什么不该、生成物落在哪 | `MANIFEST` + 部署器 + gitignore 规则 |
| **阶段契约** | `bin/setup` 无依赖声明/无幂等声明/无 dry-run/无状态 | 阶段元数据 + 子 shell 隔离 + 执行日志与报告 |
| **质量契约** | 零测试、零 CI、shellcheck 退出码 1、文档与代码漂移 | CI 门禁（shellcheck/shfmt/bats/ruff/mypy/pytest/文档链接校验） |

并据此把仓库重排为五层：**L0 事实层 → L1 载荷层 → L2 工具层 → L3 引导层 → L4 应用层**，外加横切的**契约层**。

---

## 1. 现状诊断

以下每条结论均带可复现证据（`文件:行`）。完整分析基于对 306 个已跟踪文件的逐文件阅读与实测探针。

### 1.1 身份混淆：仓库根 == `$HOME`

`README.md:20-27` 记录了部署方式：`git clone --bare` 到 `$HOME/.dotfiles`，`--work-tree=$HOME` checkout，并设 `status.showUntrackedFiles no`。

后果：

- **工程产物进家目录。** 实测 `~/README.md` 已作为部署副本存在于 `$HOME`（根 `AGENTS.md` 尚未提交，故 `~/AGENTS.md` 尚不存在，但提交后即会被 checkout 进 `$HOME`）。`git ls-files '*.md'` 显示 10 个 Markdown 中有 5 个是纯工程文档：`README.md`、`bin/setup/AGENTS.md`、`bin/setup/README.md`、`bin/waylaunch/README.md`、`bin/waylaunch/README-CN.md`。
- **`docs/`/`tests/`/`.github/` 无处安放。** 实测三者均不存在（`ls -d docs tests .github` → none）。这不是疏忽，而是结构使然：任何新增目录都会出现在 `$HOME`。
- **`showUntrackedFiles no` 掩盖污染。** 运行时新生成的文件在 `dotfiles status` 中不可见，于是下面 1.2 的污染长期未被发现。

### 1.2 部署拓扑冲突：两份 bare 仓库 work-tree 重叠

- `dotfiles` 的 work-tree 是 `$HOME`（`.bashrc:62`），`dotlocal` 的 work-tree 是 `$HOME/.local`（`.bashrc:63`）。
- 但 `git ls-files .local` 显示 **35 个 `.local/**` 文件由 dotfiles 跟踪**（`.local/share/backgrounds/*.jxl`、`.local/share/fcitx5/themes/*`、`.local/share/icons/**`、`.local/share/applications/{satty,yazi}.desktop`、`.local/share/zsh/site-functions/README.md`）。
- 即：**同一批文件被两个 git 仓库同时主张所有权**，任一 `checkout` 都可能静默覆盖另一个。`.gitignore:5` 只排除了 `.local/etc/`。

### 1.3 运行时脚本回写仓库工作树

| 生成物 | 生成者 | 实测状态 |
|--------|--------|---------|
| `.config/environment.d/60-paths.conf` | `.config/shell/env.d/05-path.sh:15` | 未跟踪 + 已 ignore ✅ |
| `.config/environment.d/90-aqua.conf` | `.config/shell/env.d/90-apps.sh:11` | 未跟踪；`.gitignore` 规则已补齐 ✅ |
| `.config/sway/config.d/40-output-background.conf` | `bin/sway-bg:8` | **未跟踪 + 未 ignore**，且落在已跟踪目录内 ❌ |
| `.config/swaylock/config` | `bin/sway-bg:13` | **已跟踪，被 `tee` 截断** ❌❌ |
| `.config/zsh/.zsh_history` | `.config/shell/rc.d/10-history.zsh:4` | 未跟踪 + 未 ignore ⚠️ |

两处实质缺陷：

1. **`bin/sway-bg:13` 用 `tee` 覆写已跟踪的 `.config/swaylock/config`**，抹掉该文件中除 `image`/`scaling` 外的全部设置（如颜色）。这是数据损坏级的 bug。
2. **`bin/sway-bg:8` 生成的配置实际不生效。** sway 通过 `/usr/libexec/sway/layered-include` 按 basename 排序载入 `config.d/*.conf`，`-`(0x2d) < `.`(0x2e)，因此 `40-output-background.conf` 排在 `40-output.conf` **之前**，随后被 `.config/sway/config.d/40-output.conf:22` 的 `output * bg` 覆盖。

~~另有一处**同时被跟踪又被 ignore**：`.config/shell/.localrc` 命中 `.gitignore:3`，但曾被跟踪使忽略规则无效。~~ ✅ 已通过 `git rm --cached` 修复，ignore 规则现已生效。

### 1.4 上下文判定被复制五份

平台/桌面/主机判定在仓库中独立实现了五次，词表互不兼容：

| 位置 | 变量/词表 | 方法 |
|------|----------|------|
| `bin/setup/lib/init:22-35` | `ARCH` / `KERNEL` / `SYSTEM` / `DESKTOP` | `uname`、`/etc/os-release`、`current_desktop()` |
| `bin/setup/lib/platform.sh:7-27` | `gnome`\|`sway`\|`aqua`\|空 | `XDG_CURRENT_DESKTOP` → 小写；否则 `pgrep -ax 'gnome-shell\|sway'` |
| `.config/shell/env.d/90-apps.sh:15-32` | 同上 | **与上一行逐字重复**（连 `compositor_proc` 变量名都一样） |
| `bin/xremap-launcher:7-21` | 同上 | **第三份逐字重复** |
| `bin/waylaunch/src/waylaunch/compositor/detector.py:48-99` | compositor 名 | `pgrep` + `SWAYSOCK` + `XDG_CURRENT_DESKTOP`（此处转**小写**） |

而 `bin/waylaunch/.../xdg_desktop_entry.py:73-77` 又把 `XDG_CURRENT_DESKTOP` 转**大写** —— 同一环境变量两种约定。

主机维度同样各写各的：aqua 用 `$HOSTNAME.yaml`（`.config/shell/env.d/90-apps.sh:36-40`），sway 用 `hostnamectl hostname`（`.config/sway/config:31`）。

### 1.5 平台矩阵与阶段分派靠编码约定，且已证实有两处缺陷

`bin/setup/main:19` 构造 `PLATFORM_PATTERN="@(${KERNEL}|${SYSTEM}|${DESKTOP})"`，`main:129` 用它过滤文件名后缀。

**缺陷 A（空分支，已实测）**：`lib/platform.sh` 在探测不到桌面时 `echo` 空串，于是模式退化为 `@(linux|fedora|)`。正则的空分支使**任何**含 `@` 的文件名都匹配：

```
[[ "./05-packager@macos.sh" =~ @(linux|fedora|) ]]  → MATCH   # 应为 NOMATCH
```

即在 SSH / 无合成器的机器上跑 `main all`，会尝试执行全部 `@macos` 阶段，且本应互斥的 `@gnome` 与 `@sway` 两套会同时命中。

**缺陷 B（非法 section 静默成功，已实测）**：`lib/array.sh:42-45` 在未命中时先 `echo -1` 再 `return 1`；`main:99` 的 `|| true` 吞掉返回值，于是 `SECTION_INDEX="-1"` 非空，`main:101` 的错误分支永不执行，循环里没有任何 `curr_idx` 等于 `-1`，全部脚本被跳过 —— `./main bogus` 打印 `--- bogus done ---` 并以 **exit code 0** 结束。

**结构性局限**：阶段归属只看文件名第一位数字（`main:121` 的 `${filename:0:1}`），导致 `09-intel-based-macbook@fedora.sh`（内核驱动 + systemd 服务）被归入阶段 0 `prelude`。平台变体之间没有共享层，`41-terminal@fedora.sh:13-16` 与 `41-terminal@macos.sh:13-16` 的 nvimrc clone 块**逐字相同**，`16-gsettings-ui@gnome.sh:21-26` 与 `@sway.sh:20-25` 的 4 行 gsettings 也逐字相同。

**平台变体数量**（实测 `ls bin/setup/*@*.sh`）：共 20 个带后缀的阶段文件 —— `@macos` 7 个（合计 437 行）、`@gnome` 6 个、`@fedora` 5 个、`@sway` 2 个。

### 1.6 阶段隔离与可观测性缺失

- **单进程 source。** `bin/setup/main:142` 用 `. "$f"` 把每个阶段 source 进同一 shell。已实证的泄漏：全局 `SCRIPT_DIR` 被每个脚本覆盖；函数 `target_hostname`(`03-hostname.sh:19`)、`install-aqua`(`21-aqua.sh:14`)、`service_restart_or_enable`/`sync_file`(`31-service@fedora.sh:8,22`) 泄漏到后续阶段；`51-rust.sh:22-28` 的 `export CARGO_HOME/RUSTUP_HOME` 影响 `52-android.sh`。
- **无 `--dry-run` / `--only` / `--skip` / `--verbose` / `--yes`。** 全仓库 grep `dry.?run|LOGFILE|DRY_RUN` 只命中两条注释。
- **无日志文件、无状态文件、无运行摘要。** 只有 `main:140` 的 `note "$f"` 一行即时输出。
- **无依赖声明。** 实际外部依赖散落在注释里，且存在**阶段倒置**：`13-extensions@gnome.sh` 与 `52-android.sh` 需要 `jq`，而 `jq` 由 aqua 提供（`.config/aqua/aqua.yaml:28`），aqua 的安装却在**阶段 2**（`21-aqua.sh:14-45`）。同理 `main:75` 的交互入口依赖 `fzf`，`fzf` 也来自 aqua。
- **`GITHUB_PROXY` 未定义。** `12-font.sh:25,40,55`、`21-aqua.sh:31`、`45-man.sh:31,33` 等以 `${GITHUB_PROXY}https://...` 拼接，但仓库内无定义也无模板；它来自 gitignore 的 `~/.local/etc/token.sh:78`，而该文件只在交互式登录 shell 被 `.config/shell/env.d/60-dev.sh:160` source。在 `set -u` 下这会导致 **unbound variable 直接中止**。`05-packager@macos.sh:17` 专门 source 了 token.sh，说明作者知道这个坑，但 `12`/`21`/`45` 没有同样处理。

**具体错误处理缺口（已确证）**：

- `03-hostname.sh:19-47` 的 `target_hostname()` 末句是 `for` 循环，型号不匹配时返回 0，因此 `:49` 的 `if ! hostname_t=$(...)` **永不成立**，`:50-51` 的跳过分支是死代码；随后空值传给 `:68` 的 `sudo hostnamectl set-hostname --static ""`。本机 `MacBookPro12,1` 命中型号表，所以这是**潜伏 bug**。
- `13-extensions@gnome.sh:27` `mkdir -p ~/.cache/archives`，但 `:32` 调用 downloader 时**未传 `--dir`**，downloader 默认 `dir="."`（`libexec/gnome-shell-extensions-downloader:67,122`），而 `:35` 从 `$HOME/.cache/archives/...zip` 安装 —— 只有恰好在该目录下运行 `main` 才成立。
- `13-extensions@gnome.sh:36` 的 `gnome-extensions enable` 失败会经 `errexit` 中止整条 `main all`，而脚本自己在 `:29` 就提示"需要重新登录后才能 enable"。
- `18-lightweight@gnome.sh:73` 与 `:112-113` 重复卸载 `gnome-software`；`:114-120` 的 group remove/autoremove 无守卫。

**安全与可逆性**：`02-system.sh:13-16` 写入 `"$USER ALL=(ALL) NOPASSWD:ALL"`；`05-packager@fedora.sh` → `libexec/dnf-util:50-61,218-223` **整体覆写 `/etc/dnf/dnf.conf`**（无备份，`.bak` 只覆盖 repo 文件）；`31-service@fedora.sh:92-107` 把用户态二进制与配置提升为 `/usr/local/bin`、`/usr/local/etc`、`/etc/systemd/system` 的系统服务。全部无回滚路径。

### 1.7 共享库形同虚设

- `bin/setup/lib/` 只抽象了 UI（`color.sh`）、trap（`trap.sh`）、平台（`platform.sh`）、数组（`array.sh`），**没有**抽象"包管理""服务管理""dotfile 资源解析"。这正是 `05/22/31/41` 的 `@fedora`/`@macos` 变体各自实现平台等价功能、`14/15/16/17` 各自硬编码 gsettings 键、`12/45/52` 各自实现下载的根因。
- `bin/` 下 24 个可执行脚本中，**只有 `mytask:7` source 了 `bin/base.sh`**（`grep -ln 'base\.sh' bin/*` → 仅 `bin/mytask`），且路径硬编码 `~/bin/base.sh`。其余 23 个脚本各自重复依赖检查、参数解析、`$HOME` 路径拼接。
- `bin/base.sh:96` 顶层 `. /etc/os-release` 会污染调用者的 `VERSION_ID`；`require`(`:56`) 与 `xsource`(`:62`) 功能重叠。
- `lib/color.sh:70,81` 使用 `wc -L`（GNU coreutils 扩展），**BSD/macOS 的 `wc` 不支持** —— 一旦 macOS 恢复，UI 库先崩。

### 1.8 Shell 环境层

设计意图清晰（编号目录、`env`/`rc` 分离、`SHELL_ENV_LOADED` guard、`environment.d` 同步），但存在下列问题：

- **`PATH` 被硬编码重置。** `.config/shell/env.d/05-path.sh:27` `PATH="/opt/local/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"` 丢弃 `/etc/profile`、`path_helper`、`/etc/profile.d/*` 注入的一切（如 `/usr/local/sbin`）。
- **每次交互 shell 都发起 dbus/launchd 调用。** `.config/shell/env.d/03-user-environment.sh:41-50` 的 `systemctl --user import-environment` 与 `launchctl setenv` **不在** `:35` 的"内容未变化"判断内。
- **返回值语义混淆。** `03-user-environment.sh:52` `return "$file_updated"` —— 0 表示"文件被更新"，1 表示"未变化 **或** 非交互 **或** 参数非法"。`05-path.sh:16-20` 据此决定是否 `launchctl config user path`，无法区分。
- **非交互 login 会话拿不到 PATH。** `03-user-environment.sh:3` 的 `[[ $- != *i* ]] && return 1` 使 gdm/gnome-session 的非交互 login shell 直接返回；新机器首次登录时 `60-paths.conf` 可能尚未生成，而 `.config/systemd/user/xremap.service:18` 的 `ExecStart` 要运行 `xremap-launcher`，后者依赖 PATH 找到 aqua 提供的 `xremap` 二进制 —— 这条 PATH 正由 `60-paths.conf` 提供（`:14-16` 注释还残留着作者想用 `Environment=` 显式注入 aqua 变量的尝试）。
- **bash/zsh 功能不对等。** zsh 加载 `*.sh` + `*.zsh`，bash 只加载 `*.sh`（`.bashrc:54` vs `.config/zsh/.zshrc:112`）。因此 `.config/shell/rc.d/05-aliases.sh:48,51` 的 `lcp`/`lip` 在 bash 下必然 `command not found`（`clipcopy` 只定义在 zsh 专用的 `10-clipboard.zsh:53-110`）；`30-fzf.sh:65` 还把同名函数变成了字符串变量。
- **幂等性缺陷。** `.bashrc:82` 的 `PROMPT_COMMAND="history -a; $PROMPT_COMMAND"` 每次重 source（如 `reload`）都会再前置一次；`:85-88` 的 `trap cleanup_before_exit EXIT` **覆盖**用户已有 EXIT trap；`00-xdg.sh:9` 在 `XDG_RUNTIME_DIR` 未设时每次 `mktemp -d` 且不清理。
- **缓存无并发保护。** `30-fzf.sh:19-25`、`40-directories.sh:25-31`、`20-completion.zsh:57-59` 直接 `>` 写共享缓存，多 shell 同启会互相截断。
- **`reload` 依赖未声明符号。** `00-functions.sh:7` 调用 `update-zsh-compdump`（定义在 `20-completion.zsh:140`）；`:8` 的 `rm -f ~/.cache/*_init.zsh` 发生在 `:6` 重新 source **之后**，删除的是刚加载的缓存。
- **内联上游代码无版本管理。** `80-autosuggestions.zsh` 是 zsh-autosuggestions **v0.7.1 原样内联（867 行）**；`90-prompt-benchmark.zsh` 同样是内联的上游项目。

### 1.9 `bin/` 工具集的具体缺陷（抽样）

- `sway-recording-stop:30` 使用未定义变量 `$PID`（应为 `:22` 的 `pid`）→ 录制时长恒为空；`:39` `wait` 非子进程；`:74-77` 的管道 `while` 在子 shell 中执行，使 `:89` 的 `wait` 等不到任务。
- `sway-tmux-layout:28` `socket="/tmp/mykitty-$PID"` 用的是**脚本自身** PID 而非 kitty 的，`:29` 回退 `ls -t /tmp/mykitty-*` 可能连错实例（`sway-tmux-navigation:62` 的注释已承认该风险）。
- `sway-workspace:71` 每次调用都 `swaymsg "for_window ..."`，**运行时永久追加**规则并在会话内累积。
- `topmem:209-214` 的 `pcall(tonumber, arg)` **永不失败**（Lua `tonumber` 返回 `nil` 而非抛错），"必须是数字"的分支不可达。
- `lima-nerdctl-downloader:41` 引用未定义的 `$FILE`；`:32` `curl` 无 `--fail`，错误页会被当作缓存写入。
- `plview` 依赖 macOS 专有的 `plutil`，却无平台检查，在主目标 Fedora 上不可用；`:48` 的 `mktemp` 文件从不删除。
- `base.sh:96`（同上）与 `mytask:35-36` 重复 `. /etc/os-release`。
- **没有任何 `bin/` 脚本使用 `set -euo pipefail`** —— 与 `bin/setup/main:4-6` 的严格模式形成反差。
- 日志全部散落在 `/tmp`（`/tmp/xreaker.log`、`/tmp/shell.log`、`/tmp/loadtime.log`、`/tmp/mytask.log`），无轮转、无并发保护。
- `shellcheck` 未通过：`vbox`(26 条)、`sway-tmux-resize`(2)、`plview`(2)、`sway-tmux-layout`(1)、`mytask`(1)。

### 1.10 服务与启动拓扑

- **`~/.config/systemd/system/`（6 个单元）不在 systemd 任何查找路径**（`systemd-analyze unit-paths` 的用户列表只有 `~/.config/systemd/user`）。仅 `frpc.service` 被 `bin/setup/31-service@fedora.sh:98-99` 手工 `sudo cp` 到 `/etc/systemd/system`，其余 5 个（`caddy`、`frpc-tunnel`、`frps`、`shadowsocks-rust-local`、`shadowsocks-rust-server`）永远不生效。文件内混用系统路径（`User=caddy`、`/usr/local/etc/*`）与 XDG 用户树位置。
- **三个用户单元无 `[Install]`**：`cliphist.service`、`xremap.service`、`libinput-gestures.service`。前两者依赖 `~/.config/autostart/*.desktop` 转发（`Exec=systemctl --user start ...`），但 **Sway 默认不处理 `~/.config/autostart`** —— 这两条启动路径在 Sway 会话下可能都失效。
- **`libinput-gestures.service` 是死单元**：无 `[Install]`，也没有对应的 autostart 文件。
- **`waylaunch` 没有任何 systemd 单元或 autostart**，仅由 sway 按键触发：`.config/sway/config.d/60-bindings-00.conf:133`、`host-specific/mac14.conf:14`、`host-specific/mac15.conf:14`。同时 `60-bindings-00.conf:20-25` 仍保留旧的 rofi combi + `sway-workspace switch-to-empty-and-run` 路径 —— **两套并行的启动方案需要同步维护**。
- **悬空引用**：`~/bin/sway-new-workspace`（`host-specific/cb13.conf:16`）、`~/bin/player-mpris-tail.py`（`.config/waybar/config.jsonc:297-300`）、`~/bin/sway-resize-smart`（仅注释 `sway-tmux-resize:72-73`）、`~/bin/kernel-broadcom-wl`（`mytask:55`，实际位于 `bin/setup/libexec/`）。
- 所有 systemd 单元用 `StandardOutput=file:/tmp/...`、`StandardError=file:/tmp/...`（如 `mytask.service:6-7`、`xremap.service:19-20`），**绕过 journal 且无轮转，重启即丢**。

### 1.11 `bin/waylaunch` 内部缺陷

这是一个分层清晰但被三处结构性缺陷拖累的项目：

- **循环导入 + 分层倒置（运行时缺陷）。** `core/protocols.py:9` → `waylaunch.compositor`；`compositor/__init__.py:4` → `detector`；`detector.py:16` → `core.registry`；`registry.py:6` → `core.protocols`。四跳成环。实测 `python -c "import waylaunch.core.protocols"` 直接 `ImportError`；`import waylaunch.cli` 能成功**仅仅因为** `core/launcher.py:9` 先导入了 `compositor` 把环解开 —— import 顺序成了不可见契约。
- **两个配置键永久失效（已实测）。** `cli.py:49` 的 `--prompt` 默认 `"Launcher"`、`cli.py:70` 的 `--provider` 默认 `["window","drun"]`，而 `config.py:62-65` 只跳过 `None` 值。实测：TOML 里的 `provider.plugins` 与 `picker.prompt` **永远被 CLI 默认值覆盖**，而 `picker.layout`（无 CLI 默认值）正常生效。这意味着 `README.md:109-111` 主推的 `plugins = [...]` 写法在**不传 `--provider` 时完全无效**。
- **编排死逻辑。** `launcher.py:76` 的 `if not result:` 恒为假（`show()` 返回 tuple）；`launcher.py:91` 的 `if not selected_text:` 条件写反，导致 `:92-99` 的"按文本回退匹配"整段不可达；`rofi.py:118` 在 `title_max_len < 3` 时产生负索引切片，从**尾部**截断标题。
- **XDG 违规。** `cli.py:42`/`tool.py:16` 硬编码 `~/.config/waylaunch/...`；`drun.py:11-15` 硬编码应用扫描目录，忽略 `$XDG_DATA_HOME`/`$XDG_DATA_DIRS`；`models.py:149`/`logger.py:11` 默认日志写 `/tmp/waylaunch.log`（自带 `noqa: S108`）。
- **死配置项。** `PickerConfig.matching`(`models.py:131`)、`board_max_cols/lines`(`:134-135`)、`LogFileConfig.max_bytes/backup_count`(`:150-151`)、`LoggingConfig.async_enabled`(`:162`)、`LogNotifyConfig.level/timeout`(`:156-157`) 全部**定义后从未被读取**（`rofi.py:151` 硬编码 `-matching fuzzy`，`logger.py:47-54` 硬编码轮转参数）。
- **配置不在版本控制内。** 真正生效的 `~/.config/waylaunch/config.toml` 未被跟踪，仓库只跟踪了 `.config/waylaunch/tools.toml`。
- **语义重复。** `bin/sway-workspace:switch-to-empty*` 按"编号空洞"找空工作区，而 `plugins/compositor/sway/adapter.py:115-143 first_empty_workspace()` 只看"无窗口"的工作区 —— 对工作区 `{1,3}` 均非空的情形，shell 返回 2、Python 返回 4。
- **零测试、无 lock 文件**（无 `tests/`、无 `conftest.py`、无 `uv.lock`）。

### 1.12 质量门禁与文档漂移

- **无 CI、无测试。** `find` 全仓库只匹配到 `bin/setup/Taskfile*.yml` 作为 CI 相关文件。
- **shellcheck 实际退出码为 1。** 用文档给出的命令 `shellcheck -x main lib/*.sh libexec/* [0-9][0-9]-*.sh` 实测：仅 4 条 `SC1091` note（`lib/color_test.sh:7`、`libexec/dnf-util:8`、`libexec/kernel-broadcom-wl:32`、`libexec/pinyin-dict-import:10`），无 warning/error，但**进程退出码为 1**，接入 CI 会被直接判红。
- **文档漂移（均已实测为假）：**

| 文档断言 | 事实 |
|---------|------|
| `bin/setup/AGENTS.md:128`：预期 `SC1091` 由 `lib/init` 引起 | 阶段脚本用变量路径，shellcheck 能解析，该 note 不出现 |
| `sway-tmux-resize:72-73` 引用 `~/bin/sway-resize-smart` | 该文件不存在 |

> 注：根 `AGENTS.md` 初稿中的 4 处错误断言（`.local/` 空占位符、env 防重复加载机制、两个 `environment.d` 生成物的 ignore 状态、`pydantic` 版本）已修正；`90-aqua.conf` 的 ignore 规则与 `.localrc` 的跟踪状态问题（`git rm --cached`）也已修复。

- **根 `AGENTS.md` 本身未被 git 跟踪**（`git status` → `?? AGENTS.md`），`.config/sway/README.md` 同样。

### 1.13 问题清单汇总

| ID | 问题 | 严重度 | 证据 |
|----|------|--------|------|
| P1 | 仓库根 == `$HOME`，工程产物被部署，`docs/`/`tests/`/CI 无处安放 | 高 | 1.1 |
| P2 | dotfiles 与 dotlocal 的 work-tree 重叠，35 个文件双主人 | 高 | 1.2 |
| P3 | 运行时脚本回写工作树，含截断已跟踪文件 | 高 | 1.3 |
| P4 | 上下文判定重复 5 份，词表不一致 | 高 | 1.4 |
| P5 | 平台过滤正则空分支 → 跨平台误执行 | 高 | 1.5-A |
| P6 | 非法 section 静默成功（exit 0） | 中 | 1.5-B |
| P7 | 阶段共享 shell，状态与函数泄漏 | 中 | 1.6 |
| P8 | 无 dry-run / 日志 / 状态 / 依赖声明 / 摘要 | 高 | 1.6 |
| P9 | `GITHUB_PROXY` 未定义，`set -u` 下致命 | 高 | 1.6 |
| P10 | 共享库缺口：无 pkg/service 抽象，`bin/` 仅 1/24 复用 | 高 | 1.7 |
| P11 | `PATH` 硬编码重置，丢失系统注入 | 中 | 1.8 |
| P12 | `environment.d` 同步无条件执行 + 返回值语义混淆 | 中 | 1.8 |
| P13 | bash/zsh 功能不对等（`lcp`/`lip` 在 bash 下必失败） | 中 | 1.8 |
| P14 | 具体编码 bug（`sway-recording-stop:$PID`、`topmem:pcall`、`03-hostname` 死分支等） | 中 | 1.6/1.9 |
| P15 | systemd 单元位置错误 / 无 `[Install]` / 日志绕过 journal | 中 | 1.10 |
| P16 | waylaunch 循环导入 + 配置优先级失效 + XDG 违规 | 高 | 1.11 |
| P17 | 零测试、零 CI、shellcheck 退出码 1、文档与代码漂移 | 高 | 1.12 |
| P18 | 系统改动无回滚（NOPASSWD sudoers、覆写 `/etc/dnf/dnf.conf`） | 中 | 1.6 |
| P19 | 内联上游代码无版本管理（867 行 autosuggestions） | 低 | 1.8 |

---

## 2. 设计目标与原则

### 2.1 目标

| 编号 | 目标 | 可验证的验收标准 |
|------|------|-----------------|
| G1 | **单一上下文来源** | 全仓库只有一处实现 OS/桌面/主机判定；`grep -rn 'XDG_CURRENT_DESKTOP'` 只命中 `lib/facts` |
| G2 | **载荷与工程产物分离** | `docs/`、`tests/`、`.github/` 不被部署到 `$HOME`；`$HOME` 里不再出现 `README.md`/`AGENTS.md` |
| G3 | **幂等且可预演** | `setup --plan` 可在不修改系统的前提下输出完整执行计划；重复运行 `setup all` 的结果与首次一致 |
| G4 | **可观测** | 每次引导产出结构化运行报告（JSON）与日志；失败可定位到阶段与命令 |
| G5 | **质量门禁** | CI 对 shellcheck/shfmt/bats/ruff/mypy/pytest 全绿；文档中引用的路径全部存在 |
| G6 | **平台可扩展** | 新增一个发行版或桌面 = 新增一个适配器实现 + 一行配置，不改动阶段脚本 |
| G7 | **macOS 保持一等公民** | 平台适配层有 `linux`/`darwin` 两套真实实现；纯逻辑库在 macOS runner 上通过测试 |
| G8 | **零隐蔽耦合** | `bin/` 脚本可独立执行（自带严格模式），不依赖"被 source 时才正确" |

### 2.2 原则

1. **数据与逻辑分离。** 配置集合（gsettings 键、包清单、字体列表）应是数据文件，逻辑是通用 applier。当前 `14-gsettings-macos-ish@gnome.sh` 的 79 条 `gsettings set` 是反例。
2. **契约优于约定。** "文件名第一位数字是阶段""`@` 后缀是平台"这类隐式约定，升级为显式元数据；约定可以保留为**书写糖**，但必须由机器校验。
3. **失败要响，且可恢复。** 现状是"失败即静默停止且无痕迹"与"报错但退出码 0"（`lib/color.sh:217` 的 `error()`）并存。统一为：可忽略的失败显式标注，其余失败记录并汇总。
4. **一处定义，多处消费。** 事实、清单、版本号、日志格式，都只能定义一次。
5. **渐进迁移，每步可独立交付。** 任一阶段完成后仓库都应处于可用状态，且可回滚。

### 2.3 非目标

- 不追求"跨发行版通用"。目标是 Fedora + macOS 两条真实路径，其他发行版通过适配器**可扩展**即可。
- 不引入 Ansible/Nix/chezmoi 等外部工具重写现有逻辑；本方案只重组本仓库。
- 不为 `bin/` 的每个脚本补齐测试，只覆盖纯函数与关键路径。

---

## 3. 目标架构

### 3.1 分层总览

```
┌─────────────────────────────────────────────────────────────┐
│ L4 应用层   packages/waylaunch     独立 Python 包 + 独立 CI  │
├─────────────────────────────────────────────────────────────┤
│ L3 引导层   bootstrap/             manifest 驱动的阶段模型   │
├─────────────────────────────────────────────────────────────┤
│ L2 工具层   bin/                   ~/bin 用户命令（分组）    │
├─────────────────────────────────────────────────────────────┤
│ L1 载荷层   payload/ → $HOME       声明式配置，零/少逻辑     │
├─────────────────────────────────────────────────────────────┤
│ L0 事实层   lib/facts + lib/shell  唯一上下文来源 + 共享库   │
└─────────────────────────────────────────────────────────────┘
      ▲ 横切契约：MANIFEST · 部署器 · 日志/报告 · CI · 密钥
```

**依赖方向严格向下**：L1 可依赖 L0；L2 可依赖 L0；L3 可依赖 L0/L2；L4 只依赖 L0 的 facts CLI（通过子进程或共享的环境文件），不 import 仓库其他部分。

### 3.2 L0 事实层：`lib/facts`

**唯一上下文来源**，替代 1.4 中列举的五份实现。

```sh
# lib/shell/facts.sh  —— POSIX sh，无副作用，可被 bash/zsh 直接 source
# 同时暴露为 CLI：dotfiles-facts [--format=sh|json|env] [--field=KEY]
OS_FAMILY=linux          # linux | darwin
OS_ID=fedora             # fedora | macos | ...
OS_VERSION=44
DESKTOP=sway             # gnome | sway | aqua | none
SESSION_TYPE=wayland     # wayland | x11 | none
HOST=mac14
HOST_MODEL=MacBookPro12,1
ARCH=x86_64
ARCH_FAMILY=amd64        # amd64 | arm64
IS_WSL=0
IS_CONTAINER=0
HAS_SYSTEMD=1
IS_INTERACTIVE=1
IS_HEADLESS=0
SECRETS_FILE=$HOME/.config/dotfiles/secrets.env
```

设计要点：

- **纯函数**：不写文件、不设 trap、不做 `mkdir`；可用任意用户执行。
- **缓存**：结果缓存到 `$XDG_CACHE_HOME/dotfiles/facts.env`，缓存键为 `(hostname, XDG_CURRENT_DESKTOP, boot_id)`，使热路径（每个交互 shell、每次 sway 按键）零额外子进程。
- **可覆盖**：`DOTFILES_FACTS_OVERRIDE=<file>` 用于测试与 CI，使"Fedora+GNOME"这类组合可在任意机器上模拟。
- **明确降级**：探测不到桌面时 `DESKTOP=none`，**绝不为空串**（这是 1.5-A 的根因）。
- **匹配语法**：统一为 `os:fedora`、`desktop:sway`、`host:mac14`、`linux|darwin`，由 `facts_match` 求值。

**消费方改造**：

| 当前位置 | 改造为 |
|---------|--------|
| `bin/setup/lib/platform.sh:7-27` | 删除，改调 `facts` |
| `.config/shell/env.d/90-apps.sh:15-32` | 删除，改调 `facts` |
| `bin/xremap-launcher:7-21` | 删除，改调 `facts` |
| `bin/waylaunch/.../detector.py` | 读取 `dotfiles-facts --format=json`，失败再自行探测 |
| `.config/sway/config:31` 的 `hostnamectl hostname` | 由引导阶段把 host-specific include 生成/校验为 `$HOST.conf` |
| aqua 的 `<desktop>.yaml` / `$HOSTNAME.yaml` 拼接 | 由 `facts` 输出 + 统一的配置合成器 |

### 3.3 L1 载荷层：分层配置合成 + 生成物契约

#### 3.3.1 三层配置合成

现状中"基础 + 桌面 + 主机"的叠加只存在于 aqua（`90-apps.sh:34-40`）与 sway（`config:30-31`），且实现方式完全不同。统一为：

```
payload/config/<app>/base.<ext>
payload/config/<app>/desktop/<gnome|sway|aqua>.<ext>
payload/config/<app>/host/<host>.<ext>
```

每种格式由**一个**合成器负责，优先级 `base < desktop < host`：

| 格式 | 合成机制 |
|------|---------|
| aqua YAML | 已有：`AQUA_GLOBAL_CONFIG` 冒号列表（保留） |
| sway | 已有：`include` + `layered-include`（保留，但改为生成稳定文件名） |
| git config | `[include]` 链 |
| 其他（TOML/JSON/ini） | 构建期生成到 `$XDG_STATE_HOME/dotfiles/generated/`，由载荷文件 include |

#### 3.3.2 生成物契约

**规则**：任何运行时生成的文件，必须满足三条之一：

1. 落在 `$XDG_STATE_HOME/dotfiles/generated/`（首选，永不进仓库工作树）；
2. 落在仓库工作树内，且**在 `.gitignore` 中**（如 `60-paths.conf`、`90-aqua.conf`）；
3. 落点由 `MANIFEST` 显式声明为 `generated: true`，并由 CI 校验 `.gitignore` 覆盖。

**立即修复（P3）**：

- `bin/sway-bg` 改为写入 `$XDG_STATE_HOME/dotfiles/generated/sway/bg.conf`，由 `payload/config/sway/config` 以 `include` 引入；**不再 `tee` 覆写 `.config/swaylock/config`**，改为生成 `swaylock.d/bg.conf`。
- `.gitignore` 补齐：`.config/environment.d/90-aqua.conf`（✅ 已补）、`.config/sway/config.d/*-background.conf`、`.config/zsh/.zsh_history`。
- ~~移除 `.config/shell/.localrc` 的跟踪状态：`git rm --cached`，保留 ignore 规则~~ ✅ 已完成；可选：提供 `.localrc.example` 作为模板。

### 3.4 L2 工具层：脚本骨架与分组

#### 3.4.1 统一骨架

```bash
#!/usr/bin/env bash
# @name    sway-screenshot
# @group   sway
# @summary 截图并预览
# @requires dunstify grimshot wl-copy
# @platforms linux desktop:sway
set -euo pipefail

source "${DOTFILES_LIB:-$HOME/.local/lib/dotfiles}/shell/init.sh"
```

`lib/shell/` 提供：

| 文件 | 职责 |
|------|------|
| `facts.sh` | L0 事实层 |
| `log.sh` | 统一日志：`$XDG_STATE_HOME/dotfiles/log/<name>.log`，带轮转与 level |
| `require.sh` | `require_cmd` / `require_env`，失败时输出可操作的安装提示 |
| `runtime.sh` | `xdg_state_dir`、`tmpdir`、`atomic_write`（`mktemp` + `mv`，消灭 `tee` 截断类 bug） |
| `sway.sh` | `sway_msg`、`sway_find_window`、`sway_empty_workspace`（**与 waylaunch 共用同一语义**） |

#### 3.4.2 分组

```
bin/
├── sway/     sway-bg  sway-cursor-center  sway-screenshot  sway-recording*
│             sway-workspace  sway-tmux-*  xremap-launcher
├── dev/      git-sparse-checkout  git-ls-files-x  plantuml  topmem  vbox
├── net/      sendmail  lima-nerdctl-downloader  kernel-rpm-downloader
└── mytask
```

**兼容性**：`~/bin/foo` 是既有外部契约（sway 配置、waybar、tmux 都按路径引用）。两种做法二选一：

- **(a) 部署期展平**：部署器把 `bin/sway/sway-bg` 链接为 `~/bin/sway-bg`（推荐，路径契约不变，`PATH` 不变）。
- **(b) `PATH` 增加子目录**：需要改 `05-path.sh` 与所有 systemd 单元，改动面更大。

采用 (a)。

#### 3.4.3 `dotfiles doctor`

新增只读自检命令，消费脚本头部的 `@requires` 与 `MANIFEST`：

```
$ dotfiles doctor
✗ sway-screenshot   missing: grimshot        → sudo dnf install grimshot
✗ mytask            missing: GITHUB_PROXY    → 定义于 ~/.config/dotfiles/secrets.env
✗ dangling ref      ~/bin/player-mpris-tail.py  (waybar/config.jsonc:299)
```

这一条同时解决 P9（`GITHUB_PROXY` 未定义）、P14 的一类悬空引用，以及 1.10 的悬空引用清单。

### 3.5 L3 引导层：manifest 驱动的阶段模型

#### 3.5.1 阶段元数据契约

保留 `NN-purpose@platform.sh` 的**书写形式**（可读性好、diff 清晰），但把语义从文件名搬进文件头的结构化块，由 runner 解析：

```bash
#!/usr/bin/env bash
# --- stage ---
# id:        12-font
# section:   desktop
# platforms: linux|darwin          # 事实层词表，no 空分支
# requires:  curl unzip fc-cache
# sudo:      no
# network:   yes
# idempotent: yes
# after:     10-xdg
# provides:  fonts
# --- /stage ---
```

`bootstrap/stages` 的完整 DAG 可在**不执行任何脚本**的前提下由 CI 校验：id 唯一、`after` 无环、`requires` 中的命令至少在某阶段的 `provides` 或系统包清单里出现。

#### 3.5.2 执行模型

| 现状 | 目标 |
|------|------|
| `. "$f"` 在同一 shell（`main:142`） | **每个阶段一个子 shell**：`( set -euo pipefail; . "$LIB"; . "$f" )`，消除 P7 |
| 文件名第一位数字定阶段 | 元数据 `section` 字段 |
| `PLATFORM_PATTERN` 正则（P5） | `facts_match` 求值，词表非空 |
| 未知 section 静默成功（P6） | 参数校验失败即 `exit 2` 并列出合法值 |
| 无 dry-run | `--plan` 打印计划；`--dry-run` 设 `DOTFILES_DRY_RUN=1`，阶段中的写操作走 `atomic_write`/`pkg_install` 等可拦截封装 |
| 无日志/状态 | journal：`$XDG_STATE_HOME/dotfiles/bootstrap/run-<ts>.json` + 人类可读摘要 |
| 失败即整体退出 | 默认 fail-fast；`--continue` 记录失败并继续，末尾统一报告非零 |

新增命令：

```
setup --plan                        # 只输出计划
setup --plan --json                 # 供 CI/工具消费
setup all --continue --report       # 全量执行，失败不中断，产出报告
setup --only 12-font,21-aqua        # 按 id 选择
setup --skip 18-lightweight         # 按 id 排除
setup --from 21-aqua                # 从某阶段起
```

#### 3.5.3 平台适配器（消除 `@fedora`/`@macos` 逐字重复）

`bootstrap/lib/` 新增抽象层，把"平台等价功能"收进接口：

| 接口 | linux 实现 | darwin 实现 |
|------|-----------|------------|
| `pkg_install` / `pkg_remove` / `pkg_query` | `dnf-util` | `brew` |
| `svc_enable` / `svc_start` / `svc_user_unit` | systemd | launchd (`launchctl`) |
| `desktop_set`（gsettings/defaults） | `gsettings` applier | `defaults write` applier |
| `font_install` | `~/.local/share/fonts` + `fc-cache` | `~/Library/Fonts` |
| `shell_default` | `chsh` | `dscl`/`chsh` |
| `proxy_url` | `${GITHUB_PROXY:-}`（**带默认值**） | 同 |

阶段脚本据此写成平台无关形式，带平台后缀的阶段文件从 20 个减少到约 6 个真正平台特有的（如 `02-system.sh` 的 sudoers/udev、`05-packager` 的镜像源、`11-desktop@macos.sh` 的 `defaults`、`33`/`34` 的 macOS 专属虚拟化）。

#### 3.5.4 配置即数据

`14-gsettings-macos-ish@gnome.sh`（264 行、79 条 `gsettings set`）拆为：

```
bootstrap/data/gsettings/gnome/keybindings.tsv
bootstrap/data/gsettings/gnome/wm.tsv
bootstrap/data/gsettings/gnome/touchpad.tsv
bootstrap/data/gsettings/gnome/screenshot.tsv
bootstrap/data/gsettings/libpinyin.tsv
```

每行 `schema<TAB>key<TAB>value<TAB># 注释`，由 `desktop_set` applier 消费，天然获得：

- **`--dry-run`**：只打印 `gsettings get` 与期望值的差异；
- **schema 存在性检查**：整组跳过而非中途 `errexit`（修复 `15-gsettings-libpinyin@gnome.sh:22-36` 在未装 `ibus-libpinyin` 时中止的问题）；
- **分组开关**：`setup desktop --gsettings keybindings,touchpad`；
- **可审计 diff**：配置文件变更即 gsettings 变更。

**包清单同理**：`22-app@fedora.sh:13-43` 的 DNF 列表 → `bootstrap/data/packages/fedora/base.txt`、`desktop/gnome.txt`、`desktop/sway.txt`、`host/mac14.txt`，由 `pkg_install` 按 facts 叠加。macOS 用 `Brewfile` 形式。

#### 3.5.5 立即修复的具体缺陷

| 缺陷 | 修复 |
|------|------|
| `main` 空分支正则（P5） | 由 `facts_match` 替代，`DESKTOP` 永不空 |
| `main` 非法 section 静默成功（P6） | 参数校验前置，未知值 `exit 2` |
| `03-hostname.sh` 死分支 + 空值写入 | `target_hostname` 显式 `return 1`；未命中型号时 `info "skip"` 并 `return 0` |
| `13-extensions@gnome.sh` cwd 依赖 | downloader 调用补 `--dir "$XDG_CACHE_HOME/archives"` |
| `18-lightweight@gnome.sh` 重复卸载 | 去重；`autoremove` 改为显式包列表 |
| `GITHUB_PROXY`（P9） | `facts` 提供带默认值的 `proxy_url`；secrets 文件缺失不致命 |
| `lib/color.sh` `wc -L`（P7/macOS） | 改用可移植的最大行长度统计（`awk`） |
| `lib/color.sh` 退出码 | `error()` 返回非零，或在需要"报错但继续"处显式 `\|\| true` |

### 3.6 L4 应用层：`packages/waylaunch`

#### 3.6.1 分层重构（修 P16 的循环导入）

```
waylaunch/
├── kernel/          # 零内部依赖：协议 + 领域模型 + 错误类型
│   ├── protocols.py     # Compositor / Picker / ItemProvider / Item（全部在此）
│   ├── models.py        # Window / Workspace / Entry / WindowState
│   ├── errors.py        # AppError 体系
│   └── context.py       # XDG 路径 + facts 读取（唯一环境依赖点）
├── config/          # pydantic 配置模型 + TOML/CLI 合并（含优先级修复）
├── runtime/         # registry（无单例，改为显式 container）、日志、异常边界
├── compositors/     # detector + sway 适配器 + null
├── pickers/         # rofi
├── providers/       # drun / tool / window + xdg_desktop_entry
└── cli.py
```

**依赖方向**：`kernel` ← 所有层；`runtime` ← `compositors/pickers/providers` ← `cli`。`kernel` **不 import 任何其他内部模块**，环被打断。

**registry 去单例**：`registry.py:61` 的模块级单例 + import 副作用改为显式 `Container` 对象，由组合根注入。这使测试可隔离（当前无法），也能为同一实现注册多个名字。

#### 3.6.2 立即修复的行为缺陷

| 缺陷 | 修复 | 影响 |
|------|------|------|
| 配置优先级失效（1.11） | `--provider`/`--prompt` 改 `default=None`，合并后回落模型默认值 | 恢复文档承诺的 CLI > TOML > 默认 |
| `launcher.py:76` 死分支 | 改为 `if result is None:` | 空结果路径可达 |
| `launcher.py:91` 条件写反 | 改为 `if selected_text:` | 文本回退匹配生效 |
| `rofi.py:118` 负索引 | `align_len < 4` 时不做省略 | 短标题不再被截尾 |
| `PickerConfig.matching` / `board_max_*` 死配置 | 接线到 `build_command` | 配置生效 |
| `LogFileConfig.max_bytes/backup_count` / `notify_send.level/timeout` 死配置 | 接线到 `logger.py` | 配置生效 |
| `NullAdapter.exec()` 静默成功 | 降级为直接 `gio launch`/`subprocess` 起进程 | 非 sway 环境不再"什么都不发生" |
| `exception_handler.py` 不支持 async | 改为同时支持 sync/async，或删除 | 兜底真正生效 |
| 顶层无异常边界 | `cli.main()` 包 `try/except AppError`；日志初始化前置于 `Config.load` | 非法枚举值不再喷 pydantic 栈 |
| XDG 违规 | `kernel/context.py` 统一解析 `XDG_CONFIG_HOME`/`XDG_DATA_HOME`/`XDG_DATA_DIRS`/`XDG_STATE_HOME` | 不再硬编码 `~/.config` |
| 日志默认写 `/tmp` | 默认 `$XDG_STATE_HOME/waylaunch/waylaunch.log` | 消除 `noqa: S108` |
| 空工作区语义重复 | `first_empty_workspace` 与 `bin/sway/…` 共用"编号空洞"语义 | shell 与 Python 结果一致 |
| `config.toml` 不在版本控制 | 纳入 `payload/config/waylaunch/config.toml` | 配置即代码 |

#### 3.6.3 测试基线

```
packages/waylaunch/tests/
├── test_config.py         # 三态 plugins 解析 + CLI/TOML 优先级（覆盖已修的 bug）
├── test_registry.py       # 显式容器分桶、重名、未知类型
├── test_launcher.py       # 回选、取消、文本回退（覆盖已修的两个死分支）
├── test_rofi_command.py   # build_command 是纯函数，断言 argv
├── test_xdg_entry.py      # 本地化键、OnlyShowIn/NotShowIn/TryExec
└── test_sway_adapter.py   # 注入假 SwayClient，验证事件缓存与竞态
```

### 3.7 横切契约

#### 3.7.1 `MANIFEST`：载荷的单一事实来源

```yaml
# dotfiles.manifest.yaml
version: 1
payload:
  - from: payload/home
    to: $HOME
    strategy: link            # link | copy
    exclude: ["**/README.md"] # 文档不部署
  - from: payload/xdg-bin
    to: ~/.local/bin
    strategy: link
  - from: bin
    to: $HOME/bin
    strategy: link
    flatten: true             # bin/sway/sway-bg → ~/bin/sway-bg
generated:
  - .config/environment.d/60-paths.conf
  - .config/environment.d/90-aqua.conf
  - .config/sway/config.d/*-background.conf
secrets:
  - $XDG_CONFIG_HOME/dotfiles/secrets.env
```

同一份清单被三方消费：

1. **部署器** `dotfiles deploy`（决定链什么、拷什么）；
2. **CI**（校验每个 `from` 存在、每个 `generated` 被 `.gitignore` 覆盖、`secrets` 不被跟踪）；
3. **`dotfiles doctor`**（校验部署状态是否与清单一致）。

#### 3.7.2 CI 门禁

| 检查 | 命令 | 覆盖 |
|------|------|------|
| Shell 静态检查 | `shellcheck -x`（含基线白名单，逐步缩小） | P17 |
| Shell 格式化 | `shfmt -d` | — |
| Shell 单测 | `bats tests/shell/` | `facts`、`array`、`color`、`pkg_*` 适配器 |
| Python | `ruff check` + `mypy --strict` + `pytest` | P16 |
| 清单一致性 | `dotfiles manifest verify` | P1、P3 |
| 文档链接 | 扫描 `docs/**`、`AGENTS.md` 中的仓库路径引用并断言存在 | P17 的文档漂移 |
| 元数据 | 解析全部 stage 头部，校验 id 唯一、`after` 无环、依赖可满足 | P8 |
| macOS | 在 `macos-latest` 上跑 `bats tests/shell/` | G7、`wc -L` 一类问题 |
| 依赖锁 | `uv lock --check`（waylaunch） | 1.11 |

**关键**：`dotfiles doctor` 的悬空引用检查应作为 CI 步骤，这会一次性消灭 1.10 中列举的全部悬空引用与文档漂移。

#### 3.7.3 日志与可观测性

- 统一到 `$XDG_STATE_HOME/dotfiles/log/`，按 `logrotate` 式阈值切分。
- systemd 单元改为 `StandardOutput=journal`、`StandardError=journal`，移除 `/tmp/*.log`。可观测性交给 journald，不再手工管理。
- `bin/setup` 产出 JSON 运行报告，字段：`stage_id`、`started_at`、`duration_ms`、`result`（ok/skip/fail/dry）、`changed`、`error`。

#### 3.7.4 密钥

- 路径统一为 `$XDG_CONFIG_HOME/dotfiles/secrets.env`（默认 `~/.config/dotfiles/secrets.env`），由 `facts` 暴露 `SECRETS_FILE`。
- **缺失不致命**：`facts` 加载时 `set +u` 包裹，并为所有需要的变量提供空默认值（修复 P9）。
- 提供 `secrets.env.example` 入版本控制，列出可用键（`GITHUB_PROXY`、`MAIL_QQ_*`、`MAIL_163_*` 等）。
- 迁移：`.config/shell/env.d/60-dev.sh:160` 与 `mytask:40,131` 改为统一入口。

---

## 4. 目标目录结构

```text
dotfiles/
├── .github/workflows/ci.yml          # 新增：质量门禁
├── .editorconfig  .gitignore  .shellcheckrc  .shfmt.toml
├── dotfiles.manifest.yaml            # 新增：载荷清单（契约）
├── AGENTS.md                         # 保留：Agent 操作指南（不再部署）
├── README.md                         # 保留：用户文档（不再部署）
├── docs/                             # 新增：工程文档（不再部署）
│   ├── architecture.md               #   本文件
│   ├── adr/0001-deployment-model.md
│   ├── bootstrap.md                  #   原 bin/setup/README.md + AGENTS.md
│   └── config/                       #   原 .config/*/README.md
├── lib/shell/                        # 新增：L0 共享库（部署到 ~/.local/lib/dotfiles）
│   ├── facts.sh  init.sh  log.sh  require.sh  runtime.sh  sway.sh
│   └── pkg/linux.sh  pkg/darwin.sh  svc/linux.sh  svc/darwin.sh
├── payload/                          # 新增：L1，唯一会被部署的树
│   ├── home/                         #   → $HOME
│   │   ├── .bashrc  .bash_profile  .zshenv
│   │   ├── .cargo/  .gradle/
│   │   └── .config/**                #   （现状 .config/ 全量，路径不变）
│   └── local/                        #   → $HOME/.local（从 dotlocal 收回所有权）
├── bin/                              # L2：~/bin 用户命令
│   ├── sway/  dev/  net/  mytask
│   └── setup → ../bootstrap          #   兼容入口（软链）
├── bootstrap/                        # L3：原 bin/setup
│   ├── main
│   ├── stages/NN-*.sh                #   带元数据头
│   ├── data/                         #   新增：gsettings / packages 数据
│   ├── lib/  libexec/  files/
│   └── Taskfile.yml
├── packages/waylaunch/               # L4：原 bin/waylaunch
│   ├── pyproject.toml  uv.lock  src/waylaunch/**
│   └── tests/
└── tests/                            # 新增：跨层测试
    ├── shell/                        #   bats
    └── manifest/                     #   清单与元数据一致性
```

**说明**：`payload/` 是「方案 A（彻底解耦）」的产物。若采用「方案 B」（保留 bare 仓库，见第 5 章 ADR），则 `payload/home/**` 与 `payload/local/**` 回落为仓库根，`bin/`、`bootstrap/`、`packages/`、`docs/`、`lib/`、`tests/` 保持上述位置。

---

## 5. 拆分对照表：哪些拆、哪些留

这是本次重设计的核心决策表。列为「现状路径 → 性质 → 目标位置 → 理由」。

**性质图例**：**P** = 部署载荷（必须进 `$HOME`）· **E** = 工程产物（不应进 `$HOME`）· **P+E** = 既被运行时消费又有工程侧内容。

| # | 现状路径 | 性质 | 处理 | 目标位置 | 理由 / 备注 |
|---|---------|------|------|---------|------------|
| 1 | `.bashrc` `.bash_profile` `.zshenv` | P | **保留原位** | `payload/home/`（方案 B 则原位） | 启动文件必须落在 `$HOME` 根；内容拆分见下 |
| 2 | `.cargo/config.toml` `.gradle/**` | P | **保留** | 同上 | 工具按固定路径读取 |
| 3 | `.config/**`（应用配置，约 100 文件） | P | **保留** | `payload/home/.config/**` | 路径即契约，**不改** |
| 4 | `.config/environment.d/10-wayland.conf` | P | **保留** | 同上 | 静态载荷 |
| 5 | `.config/*/README.md`（`alacritty`、`xremap`） | E | **拆分** | `docs/config/` | 文档不部署；`sway/README.md` 内容最有价值，一并迁 `docs/config/sway.md` |
| 6 | `.config/alacritty/launcher.md` | E | **拆分** | `docs/config/alacritty-launcher.md` | 同上 |
| 7 | `.config/shell/**`（27 文件） | P | **保留路径，重构内容** | 原位 | 见 3.2/3.3：`facts` 化、`PATH` 不再重置、生成物落 `$XDG_STATE_HOME` |
| 8 | `.config/shell/.localrc` | P（本地私有） | **`git rm --cached`** ✅ 已完成 | 保持 ignore；可选新增 `.localrc.example` | 原「既跟踪又 ignore」导致规则失效，已修复 |
| 9 | `.config/zsh/80-autosuggestions` 等内联上游 | P | **改为构建期拉取** | `payload/…` + `.gitmodules` 或 vendored 目录 + 版本文件 | 867 行内联，无版本、无更新通道 |
| 10 | `.config/sway/**` | P | **保留路径，修生成物** | 原位 | 见 1.3：`40-output-background.conf` 移出工作树 |
| 11 | `.config/systemd/user/**`（11 单元） | P | **保留，补 `[Install]`** | 原位 | 见 1.10；定义按桌面分发机制 |
| 12 | `.config/systemd/system/**`（6 单元） | **错误位置** | **拆分**：`frpc` → `bootstrap/files/systemd/`；其余评估后删除或同样下发 | `bootstrap/files/systemd/` | 该目录不在 systemd 查找路径，5 个单元永不生效 |
| 13 | `.config/autostart/*.desktop` | P | **保留，但补 sway 路径** | 原位 | Sway 不读 XDG autostart；需在 sway `exec` 中显式启动或改用 `dex` |
| 14 | `.local/**`（35 文件） | P | **收归单一所有者** | `payload/local/` | P2：与 dotlocal work-tree 重叠；`.local/etc/` 仍归 dotlocal（密钥） |
| 15 | `bin/*`（24 个脚本） | P | **分组重组** | `bin/sway/`、`bin/dev/`、`bin/net/` | 部署期展平回 `~/bin/*`，路径契约不变 |
| 16 | `bin/base.sh` | P（库） | **拆分** | `lib/shell/` → 部署为 `~/.local/lib/dotfiles/` | 现状仅 1/24 脚本使用，且污染调用者命名空间 |
| 17 | `bin/setup/**`（51 文件） | **P+E** | **拆分** | 见 #18–#22 | 运行时代码 vs 工程文档分离 |
| 18 | `bin/setup/main` + `[0-9][0-9]-*.sh` + `lib/` + `libexec/` + `files/` | P | **保留（迁目录）** | `bootstrap/` | 入口不变：`~/bin/setup/main`（软链） |
| 19 | `bin/setup/AGENTS.md` | E | **拆分** | `docs/bootstrap.md`（与 `README.md` 合并） | 工程文档；合并可消除两份漂移源 |
| 20 | `bin/setup/README.md` | E | **拆分** | `docs/bootstrap.md` | 同上 |
| 21 | `bin/setup/Taskfile.yml` | E | **保留在 `bootstrap/`** | `bootstrap/Taskfile.yml` | 开发期使用，不部署 |
| 22 | `bin/setup/Taskfile-v1.yml` | E（废弃） | **删除** | — | 文档已标注废弃 |
| 23 | `bin/setup/lib/color_test.sh` | E（演示） | **转为测试** | `tests/shell/color.bats` | 手工演示 → 自动化断言 |
| 24 | `bin/waylaunch/**`（36 文件） | **P+E** | **拆分** | `packages/waylaunch/` | 运行时是 uv tool，源码位置无关 |
| 25 | `bin/waylaunch/README.md` / `README-CN.md` | E | **拆分** | `docs/waylaunch.md` | 两份重复，合并 |
| 26 | `bin/waylaunch/pyproject.toml` + `src/` | P（构建输入） | **保留** | `packages/waylaunch/` | 独立 CI job |
| 27 | `bin/waylaunch/.../example-swaymsg_t_get_tree.yml` | E（样例） | **转为 fixture** | `packages/waylaunch/tests/fixtures/` | 57 行手工样例 → 测试数据 |
| 28 | `bin/git-sparse-checkout` `git-ls-files-x` | P | **保留（迁 `bin/dev/`）** | 展平回 `~/bin/` | 仍被 `41-terminal@fedora.sh:37` 等调用 |
| 29 | `README.md`（根） | E | **保留，但不再部署** | 原位 + `MANIFEST` 排除 | 用户文档应在仓库根（GitHub 展示），但不应进 `$HOME` |
| 30 | `AGENTS.md`（根） | E | **保留，纳入版本控制** | 原位 + 排除 | 当前**未被跟踪** |
| 31 | `.editorconfig` `.gitignore` | E | **保留** | 原位 | 工程配置 |
| 32 | 新增 `docs/` `tests/` `.github/` | E | **新增** | 原位 | P1：现状无处安放 |
| 33 | 新增 `dotfiles.manifest.yaml` | E | **新增** | 原位 | 载荷契约 |
| 34 | 新增 `lib/shell/` | P（库） | **新增** | 部署到 `~/.local/lib/dotfiles/` | L0 层 |
| 35 | 新增 `bootstrap/data/` | P | **新增** | `bootstrap/data/` | gsettings/包清单数据化 |

### 5.1 「保留」的清单（明确不动）

以下路径**路径与文件名保持不变**，因为它们是跨工具的外部契约：

- `$HOME/.config/**` 下的所有应用配置路径（sway `config.d/*`、rofi 主题名 `menu`/`board`/`launchpad`、tmux、waybar、git…）。
- `~/bin/<name>` 下的所有脚本名（sway 配置、waybar `config.jsonc:280,282`、`tmux.conf:191`、systemd `ExecStart` 都按此引用）。
- `~/bin/setup/main` 入口与 `./main <section>` / `main all` 命令行。
- `waylaunch` 的 CLI 六个 flag 与语义（`--config`/`--prompt`/`--layout`/`--picker`/`--provider`/`--compositor`）、rofi 返回码语义（`1`=取消、`10+N`=自定义键）。
- `config.toml` 与 `tools.toml` 的全部既有键（含 `_`/`-` 双写、list/dict/`name:groups` 三态语法）。
- `$HOME/.dotfiles` 与 `$HOME/.dotlocal` 的 bare 仓库机制（若采用方案 B）。

### 5.2 「拆分」的判据

一条路径应当被拆出 `$HOME`，当且仅当满足以下**任一**条件：

1. **只有人或 Agent 会读它**（文档、AGENTS、Taskfile、样例数据）；
2. **只有构建/测试会读它**（`pyproject.toml`、`tests/`、CI 配置）；
3. **它不是任何运行时工具的输入**（`docs/`、`.github/`、`README.md`）。

反之，留在 `$HOME` 当且仅当**某个运行时进程按绝对/固定路径读取它**。

`MANIFEST` 的 `exclude` 与 CI 的清单校验把这条判据变成可执行的规则，而不是靠记忆。

---

## 6. ADR-0001：部署模型

### 6.1 背景

`payload` 与 `$HOME` 的映射方式决定了仓库目录结构的自由度、多主机/多桌面能力，以及能否容纳测试与 CI。当前为「bare 仓库 + `work-tree=$HOME`」，即仓库根 == `$HOME`。

### 6.2 选项

| 选项 | 机制 | 优点 | 缺点 |
|------|------|------|------|
| **A. 普通 clone + 声明式部署** | clone 到 `~/.local/share/dotfiles`，`dotfiles deploy` 按 `MANIFEST` 建立符号链接（默认）或拷贝（可逐项声明） | 目录结构完全自由；按 profile 选择性部署；`docs/`/`tests/`/CI 自然归位；解决 P2 的双主人问题；编辑即生效（链接模式） | 一次性迁移；`$HOME` 出现符号链接；**少数应用（如 VS Code 写 `settings.json`）用原子写会替换掉符号链接** → 需逐项 `strategy: copy`；失去 `dotfiles status` 一览工作树变更的体验 |
| **B. 保留 bare 仓库 + 清单 + 稀疏检出** | 保持 `work-tree=$HOME`；用 `MANIFEST` 声明载荷；在目标机用稀疏检出排除工程产物 | 迁移量小；保留 `dotfiles status`/`dotfiles add` 工作流；`git push` 流程不变 | 仓库根仍 == `$HOME`；稀疏检出在 **bare 仓库上需 `core.bare=false` + `core.worktree` 才可用**，属非标准用法；工程产物仍在仓库树中，误 `add` 风险不减；`$HOME` 里仍可能出现 `docs/` 等目录 |
| **C. 保持现状** | 不变 | 零风险 | P1/P2/P3 全部保留，`docs/`/CI 无处安放 |

### 6.3 决策

**推荐 A，但按第 7 章分阶段推进。** 理由：

1. 只有 A 能**同时**解决 P1（身份混淆）、P2（work-tree 重叠）、P3（回写工作树）与"无处放测试/CI"。
2. A 的 `strategy: copy` 逃生舱直接覆盖了"原子写破坏符号链接"的风险 —— 这是 B 不具备的能力。
3. A 让"按主机/桌面选择性部署"成为清单里的一个字段，这是当前完全缺失的能力（现在只能靠 `git-sparse-checkout` 这一独立脚本手工处理）。
4. 迁移可分阶段：**阶段 1–2 不改变部署方式**，即可交付本方案约 70% 的收益；部署方式切换（阶段 3）单独决策、可回滚。

**若在阶段 1–2 结束时评估认为符号链接风险不可接受**，则降级为 B，此时 `lib/shell`、`bootstrap/`、`packages/`、`docs/`、`tests/` 的位置与内容全部不变，仅 `payload/` 一层的映射方式不同 —— 这正是第 4 章「说明」段落所预留的兼容性。

### 6.4 后果

- 需要一次性迁移脚本 `dotfiles migrate-from-bare`：比对 bare 仓库工作树与部署清单，对每个条目判断「链接」或「拷贝」，并把 `$HOME` 中与清单不一致的文件备份到 `$XDG_STATE_HOME/dotfiles/migrate-backup/`。
- `README.md` 的「快速开始」需要改写为 `git clone` + `dotfiles deploy`。
- 需要为 `$HOME` 中**不属于本仓库**的文件建立白名单，避免部署器误删（部署器默认**只增不删**，删除必须显式 `--prune`）。

---

## 7. 迁移路线图

每个阶段独立可交付、可回滚。验收标准均可在 CI 中自动化。

### 阶段 0：止血（不需要任何结构变更）

| 任务 | 修复 | 验收 |
|------|------|------|
| 停止 `sway-bg` 截断 `swaylock/config`，改生成到 `$XDG_STATE_HOME` | P3 | 重复运行 10 次后 `git status` 无变化 |
| `.gitignore` 补齐生成物规则（`90-aqua.conf` ✅ 已补，其余待办） | P3 | `dotfiles manifest verify` 通过（可先用脚本近似） |
| `.config/shell/.localrc` `git rm --cached` ✅ 已完成（`.example` 模板可选） | 1.3 | `git check-ignore` 与实际跟踪状态一致 |
| 修 `sway-recording-stop:30` 的 `$PID`、`lima-nerdctl-downloader:41` 的 `$FILE` | P14 | 手工验证 |
| `lib/color.sh` 的 `wc -L` 改为可移植实现 | P19/G7 | `bats tests/shell/color.bats` |
| 根 `AGENTS.md` 纳入跟踪 | P17 | 文档链接检查通过 |

### 阶段 1：上下文与质量地基（不改变部署方式）

| 任务 | 修复 | 验收 |
|------|------|------|
| 实现 `lib/shell/facts.sh` + `dotfiles-facts` CLI | P4 | `grep -rn 'XDG_CURRENT_DESKTOP'` 只命中 `facts.sh`；bats 覆盖 6 组模拟 facts |
| 三处重复的桌面探测改为调用 `facts` | P4 | 同上 |
| 建立 GitHub Actions：shellcheck（含基线白名单）、shfmt、bats、文档链接检查 | P17 | CI 全绿 |
| 建立 `packages/waylaunch` 的 ruff/mypy/pytest job | P16 | CI 全绿 |
| 修 waylaunch 循环导入（`kernel/` 分层） | P16 | `python -c "import waylaunch.kernel.protocols"` 成功 |
| 修 waylaunch 配置优先级（`default=None`） | 1.11 | `test_config.py` 断言 TOML `provider.plugins` 生效 |
| 修 `launcher.py:76`/`:91` 两个死分支 | 1.11 | 单测覆盖空结果与文本回退 |
| 修 `bin/setup` 的 P5/P6 两个静默缺陷 | P5/P6 | `./main bogus` → `exit 2`；无桌面环境下 `--plan` 不列 `@macos` 阶段 |
| 把 `bin/setup` 阶段改为子 shell 执行 | P7 | 阶段间变量不再泄漏（bats 断言） |

**这是收益最高的一步**：不触碰部署方式，却解决了平台判定、静默失败、测试与 CI 四类核心问题。

### 阶段 2：契约落地（仍不改变部署方式）

| 任务 | 修复 | 验收 |
|------|------|------|
| 引入 `dotfiles.manifest.yaml` | P1 | CI 校验 `generated` 全被 ignore、`secrets` 未被跟踪 |
| 引入 stage 元数据头 + `setup --plan/--only/--skip/--continue` | P8 | `--plan --json` 输出可被 CI 校验；DAG 无环 |
| 引入 `pkg_*`/`svc_*`/`desktop_set` 适配器 | P10 | 带平台后缀的阶段文件从 20 降到约 6 |
| gsettings 与包清单数据化 | P10 | `setup desktop --dry-run` 输出差异而非执行 |
| 引入 `dotfiles doctor` | P9/P14 | CI 中悬空引用数为 0 |
| 统一日志到 `$XDG_STATE_HOME`，systemd 改 journal | P15 | `/tmp/*.log` 引用数为 0 |
| `bin/` 分组 + 统一骨架 + `lib/shell` 共享 | P10 | shellcheck 全绿；`bin/` 中 `set -euo pipefail` 覆盖率 100% |
| 工程文档迁入 `docs/` | P1 | `docs/` 建立；`bin/setup/AGENTS.md`、`bin/waylaunch/README*.md` 被合并后删除 |

### 阶段 3：部署解耦（ADR-0001 决策点）

| 任务 | 修复 | 验收 |
|------|------|------|
| 实现 `dotfiles deploy`（`link`/`copy` 双策略，默认只增不删） | P1/P2 | 在全新虚拟机上一次通过 |
| `dotfiles migrate-from-bare` + 备份 | P2 | 迁移后 `$HOME` 与迁移前逐文件内容一致 |
| `payload/home` + `payload/local` 归位；`.local/**` 收归单一所有者 | P2 | `git ls-files .local` 与 dotlocal 的所有权无交集 |
| `bin/setup → bootstrap/`、`bin/waylaunch → packages/waylaunch` 迁目录 | P1 | `~/bin/setup/main` 与 `waylaunch` 命令行为不变 |
| 改写 `README.md` 快速开始 | P1 | 在干净虚拟机按文档可完成部署 |

### 阶段 4：收敛与清理

- 删除 `Taskfile-v1.yml`、`libexec/install-dmg`（当前无调用方）、waylaunch 的死代码清单（`is_*` 访问器、`_scratchpad_cache`、`tool.exec`、`SwayClient.unsubscribe/get_event` 等）。
- 内联上游代码改为 vendored + 版本文件（或 submodule）。
- 将 shellcheck 基线白名单逐步缩小到 0。
- `dotfiles doctor --fix`（可选）：自动修复悬空引用与生成物漂移。

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| **符号链接被原子写替换**（VS Code 等） | 部署漂移 | `MANIFEST` 逐项 `strategy: copy`；`dotfiles doctor` 检测"应为链接却是普通文件" |
| **`$HOME` 是活配置，迁移出错即丢配置** | 高 | 阶段 3 前全量备份；部署器默认只增不删；`--prune` 需显式；迁移脚本产出 diff 供人工确认 |
| **阶段 2 的 stage 元数据与脚本行为漂移** | 计划不准 | CI 解析元数据并断言（id 唯一、`after` 无环、`requires` 可满足） |
| **macOS 无日常验证环境** | 回归不易发现 | GitHub Actions `macos-latest` 跑纯逻辑库测试；平台适配器接口用 bats 打桩测试两套实现 |
| **`04-brew.sh:7` 的 `rm -rf /opt/local/Homebrew/Cellar` 等破坏性操作** | 数据丢失 | 阶段 2 中为所有破坏性操作加 `--dry-run` 拦截与显式确认 |
| **`facts` 缓存失效导致误判** | 跨平台误执行 | 缓存键含 `boot_id` + `XDG_CURRENT_DESKTOP`；提供 `dotfiles-facts --refresh` |
| **过度设计**（个人仓库引入过重流程） | 维护负担 | 阶段 1 只引入 3 个工具（shellcheck/shfmt/bats）与 1 个 CI 文件；数据化只覆盖 gsettings 与包清单两处 |

---

## 9. 待决问题

1. **ADR-0001 的最终选择**：阶段 1–2 完成后是否执行阶段 3？建议先完成阶段 0–2 再评估。
2. **`.local/**` 的最终归属**：35 个文件收归 dotfiles，还是迁给 dotlocal？取决于是否希望 `dotlocal` 只承担"密钥 + 机器私有数据"。
3. **`~/.config/systemd/system/` 的 6 个单元**：删除不再使用的，还是全部改由 bootstrap 下发到 `/etc/systemd/system`？
4. **`$HOSTNAME.yaml` 之外的主机标识**：是否统一用 `facts` 的 `HOST`，并保留一个显式的 `HOST_CLASS`（如 `macbook12-1`）用于同类机型共享配置？
5. **内联上游代码的更新通道**：submodule、vendored + 版本文件 + 更新脚本，还是改由包管理器提供？
6. **`setup` 是否需要支持"仅检查"模式**（`setup --check`：只验证系统是否处于期望状态，不修改）？这是 `--dry-run` 之上的能力，对多机一致性有实际价值。

---

## 附录 A：证据索引

本文所有 `文件:行` 引用均来自对以下范围的实测阅读与探针：

- `bin/setup/`：31 个阶段脚本 + `main` + 2 个 Taskfile + `lib/`(5) + `libexec/`(6) + `files/`(2)
- `bin/`：24 个可执行脚本（含 `sendmail.go`、`topmem`）+ `base.sh` 库
- `bin/waylaunch/`：`pyproject.toml` + `src/waylaunch/` 全部 31 个 `.py`（23 个非 `__init__` 模块）+ `.config/waylaunch/tools.toml`
- `.config/shell/`：`env` + `env.d/`(9) + `rc.d/`(15)
- `.config/`：sway、systemd、autostart、aqua、rofi、zsh、tmux、waybar 等
- 仓库级别：`git ls-files`(306)、`git check-ignore --no-index`、`systemd-analyze unit-paths`

关键实测：`./bin/setup/main bogus` → exit 0；`[[ "./05-packager@macos.sh" =~ @(linux|fedora|) ]]` → MATCH；`python -c "import waylaunch.core.protocols"` → ImportError；`shellcheck -x main lib/*.sh libexec/* [0-9][0-9]-*.sh` → 4 note + exit 1；`git check-ignore --no-index .config/environment.d/90-aqua.conf` → NOT IGNORED（撰写时；ignore 规则已于后续补齐）。

## 附录 B：术语

| 术语 | 含义 |
|------|------|
| **载荷（payload）** | 必须出现在 `$HOME` 对应路径才能生效的文件 |
| **工程产物（engineering artifacts）** | 只在开发/维护/构建时被读取的文件（文档、测试、CI 配置、构建清单） |
| **事实层（facts）** | 对当前运行上下文的客观描述：OS、桌面、主机、架构、是否交互式等 |
| **阶段（stage）** | 引导框架中一个可独立选择、执行的配置单元 |
| **profile** | 一组 facts 匹配规则 + 对应的载荷子集 |
| **生成物（generated）** | 运行时产生、不应进入版本控制工作树的文件 |
