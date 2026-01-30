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
# 场景 1：自动化服务器环境检查与部署
# ==========================================
title "自动化服务器环境检查与部署"

section "自动化环境检查"

task "系统架构预检"
step "正在探测硬件架构..."
success "CPU 兼容性检查通过 (x86_64)"
wait_briefly

step "正在连接远程仓库..."
success "网络连接正常 (延迟: 15ms)"
warn "当前剩余内存 < 2GB，构建过程可能较慢。"

task "依赖组件确认"
paragraph "以下组件将被自动安装，请确保磁盘空间充足。安装过程大约需要 5 分钟。"
items "Node.js 运行时 (v18.x)" "Redis 缓存服务" "Nginx 反向代理"
note "默认安装路径为 /usr/local/bin，可修改 CONFIG_PATH 变量。"
wait_briefly

task "生产环境数据库迁移"
debug "当前进程 ID (PID): $$"
# Notice 与 Title 同级蓝色，提醒关键风险
notice "正在迁移生产数据库，请勿强制退出 (Ctrl+C)！"
wait_briefly

# 模拟错误处理逻辑
step "校验用户表结构"
error "数据库服务响应超时：无法验证结构。"
note "建议运行 'systemctl status mariadb' 检查服务状态。"

task "部署报告总结"
paragraph "本次部署任务于 $(date '+%Y-%m-%d %H:%M:%S') 结束。"
success "预检任务全部完成。"
warn "系统稳定性评估：中等。"

# ==========================================
# 场景2：系统环境初始化 (更紧凑的流水线风格)
# ==========================================
section "系统环境初始化"

task "网络模块配置"
step "检查防火墙状态"
success "防火墙已开启"
step "配置代理服务器"
info "检测到内网环境，自动跳过代理"

task "权限模块验证"
step "验证 Root 权限"
note "当前用户已处于 sudoers 列表"
success "验证通过"

# ==========================================
# 场景 3：带进度条的备份系统
# ==========================================
title "BACKUP SYSTEM v2.0"

# --- 第一阶段：初始化 ---
section "1. 备份环境准备"

task "初始化备份环境"
step "探测生产节点状态"
info "已识别节点: Node-01 (IP: 192.168.1.10)"

# Notice 属于 Task 下的高级警示
notice "备份期间请勿关闭终端，避免产生碎片文件！"

step "检查本地磁盘空间"
success "空间充足 (可用: 256GB)"

# --- 第二阶段：本地处理 ---
section "2. 数据打包阶段"

task "本地数据压缩"
step "执行数据打包压缩"
# 进度条与 step 保持 4 格缩进对齐
for i in $(seq 0 25 100); do
    progress "$i" 100 "Compressing Data"
    sleep 0.2
done
success "镜像 [backup_v2.tar.gz] 已生成"

# --- 第三阶段：远程同步 ---
section "3. 云端同步阶段"

task "同步任务预检"
step "同步任务已就绪，配置确认"
# item 属于 step 后的详细补充，缩进 6 格
items "Target: AWS-S3" "Region: us-east-1" "Bucket: prod-backup-bucket"

task "执行远程数据推送"
for i in $(seq 0 10 100); do
    progress "$i" 100 "Uploading to S3"
    sleep 0.1
done
success "所有远程同步任务已完成！"

# --- 结束语 ---
# note 作为结尾的补充说明
note "备份日志已保存至 /var/log/backup.log，保留周期为 30 天。"

# ==========================================
# 场景 4: Infrastructure Deployer
# ==========================================

title "Infrastructure Deployer"

echo
notice "Critical: Remote production server will be modified."

section "1. Pre-flight Check"
task "Resource Validation"
step "Checking disk space"
success "1.2 TB available"
step "Checking network latency"
info "Latency to AWS-East: 15ms"

section "2. Environment Setup"
task "Installing Dependencies"
paragraph "The following core libraries are required for the compilation of the microservices architecture."
items "Docker CE" "Kubernetes CLI" "Helm v3"
note "You can skip these if --fast-mode is enabled."

section "3. Deployment"
task "Uploading Assets"
for i in {1..5}; do
    progress $i 5 "Transferring chunk-$i"
    sleep 0.2
done
success "All chunks uploaded"

section "4. Finalization"
task "Sanity Check"
step "Verifying checksums"
success "Checksum match"
notice "Deployment finished. Check logs for details."

echo -e "\n${C_DIM}--- 演示结束 ---${C_RESET}"
