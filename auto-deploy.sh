#!/bin/bash

################################################################################
# 自动监控部署脚本
# 用途: 监控源代码变化，自动触发构建和部署
# 作者: factory-droid[bot]
# 日期: 2025-10-14
################################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目路径
PROJECT_ROOT="/home/chenbang/app/netease"
FRONTEND_SRC="${PROJECT_ROOT}/SPlayer/src"
BACKEND_SRC="${PROJECT_ROOT}/api-enhanced"
DEPLOY_SCRIPT="${PROJECT_ROOT}/deploy.sh"
CHECKSUM_FILE="${PROJECT_ROOT}/.deploy_checksum"

# 监控间隔（秒）
CHECK_INTERVAL=10

log_info() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $1"
}

# 计算目录的MD5校验和
calculate_checksum() {
    find "$1" -type f \( -name "*.js" -o -name "*.vue" -o -name "*.ts" \) -exec md5sum {} + 2>/dev/null | sort | md5sum | cut -d' ' -f1
}

# 检查是否有变化
check_changes() {
    local current_frontend=$(calculate_checksum "${FRONTEND_SRC}")
    local current_backend=$(calculate_checksum "${BACKEND_SRC}")
    local current="${current_frontend}:${current_backend}"
    
    if [ -f "${CHECKSUM_FILE}" ]; then
        local previous=$(cat "${CHECKSUM_FILE}")
        if [ "${current}" != "${previous}" ]; then
            echo "${current}" > "${CHECKSUM_FILE}"
            return 0  # 有变化
        else
            return 1  # 无变化
        fi
    else
        echo "${current}" > "${CHECKSUM_FILE}"
        return 0  # 首次运行，视为有变化
    fi
}

# 触发部署
trigger_deploy() {
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "检测到代码变化，触发自动部署..."
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -x "${DEPLOY_SCRIPT}" ]; then
        bash "${DEPLOY_SCRIPT}"
        local result=$?
        if [ ${result} -eq 0 ]; then
            log_info "✅ 自动部署完成"
        else
            log_error "❌ 自动部署失败，退出码: ${result}"
        fi
    else
        log_error "部署脚本不存在或不可执行: ${DEPLOY_SCRIPT}"
        exit 1
    fi
}

# 主循环
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       自动监控部署脚本已启动                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "监控目录:"
    log_info "  前端: ${FRONTEND_SRC}"
    log_info "  后端: ${BACKEND_SRC}"
    log_info "检查间隔: ${CHECK_INTERVAL}秒"
    log_info "按 Ctrl+C 停止监控"
    echo ""
    
    # 首次运行时触发一次部署
    log_info "执行首次部署..."
    trigger_deploy
    
    # 开始监控
    while true; do
        sleep ${CHECK_INTERVAL}
        
        if check_changes; then
            log_warn "⚠️  检测到文件变化！"
            trigger_deploy
        else
            log_info "✓ 无变化，继续监控..."
        fi
    done
}

# 捕获Ctrl+C
trap 'echo ""; log_info "监控已停止"; exit 0' INT TERM

# 执行主函数
main "$@"
