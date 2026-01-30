#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# 1. 引入库文件
if [[ -f "$SCRIPT_DIR/color.sh" ]]; then
    source "$SCRIPT_DIR/color.sh"
else
    # 如果找不到库，显示一个简单的警告并退出
    printf "\e[31m[✘] Error: Cannot find color.sh\e[0m\n"
    exit 1
fi

# 2. 模拟延迟的小函数，让测试演示更真实
wait_briefly() { sleep 0.3; }

# ==========================================
# 场景1：自动化服务器环境检查与部署
# ==========================================
heading "场景1：自动化服务器环境检查与部署"

# --- 模块展示 ---
module "1. 系统预检阶段"
wait_briefly

info "正在探测硬件架构..."
success "CPU 兼容性检查通过 (x86_64)"
wait_briefly

info "正在连接远程仓库..."
success "网络连接正常 (延迟: 15ms)"

warn "检测到当前内存剩余不足 2GB，可能会影响构建速度。"

paragraph "以下组件将被自动安装，请确保您有足够的磁盘空间。安装过程大约需要 5 分钟，具体取决于带宽。"
item "Node.js 运行时 (v18.x)"
item "Redis 缓存服务"
item "Nginx 反向代理"

note "默认安装路径为 /usr/local/bin，您可以通过修改 CONFIG_PATH 变量来更改。"
wait_briefly

# --- 模块展示：第二阶段 ---
module "2. 执行部署任务"
debug "当前进程 ID (PID): $$"
debug "正在解析配置文件: /etc/app/config.yaml"

notice "正在迁移生产环境数据库，请勿在此期间强制退出 (Ctrl+C)！"
wait_briefly

# 模拟错误处理
CHECK_DB=0
if [ $CHECK_DB -eq 0 ]; then
    error "数据库服务响应超时：无法验证用户表结构。"
    note "请尝试运行 'systemctl status mariadb' 检查服务状态。"
fi

# --- 结尾总结 ---
printf "\n"
module "部署报告总结"
paragraph "本次部署于 $(date '+%Y-%m-%d %H:%M:%S') 结束。"
success "预检任务全部完成。"
warn "系统稳定性评估：中等。"

# ==========================================
# 场景2：系统环境初始化 (更紧凑的流水线风格)
# ==========================================
heading "场景2：系统环境初始化"

module "网络模块配置"
step "检查防火墙状态"
success "防火墙已开启"
step "配置代理服务器"
info "跳过代理，使用直接连接"

module "数据库模块配置"
step "验证 Root 权限"
note "当前用户拥有管理员权限"
success "验证通过"

# ==========================================
# 场景3：备份系统，带进度条
# ==========================================
title "BACKUP SYSTEM v2.0"

heading "初始化环境"
info "检测到生产环境..."
notice "备份期间请勿关闭终端"
module "数据打包"
for i in $(seq 0 10 100); do
    progress "$i" 100 "Compressing"
    sleep 0.2
done
success "数据压缩完成"

heading "上传至云端"
item "Server: AWS-S3"
item "Region: us-east-1"
for ((i = 0; i <= 100; i += 10)); do
    progress "$i" 100 "Uploading"
    sleep 0.3
done

success "任务全部完成！"

echo -e "\n${C_DIM}--- 演示结束 ---${C_RESET}"
