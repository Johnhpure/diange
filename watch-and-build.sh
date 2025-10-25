#!/bin/bash

#=============================================================================
# 文件监听与自动构建脚本
# 功能: 监听前后端代码变化，自动触发构建
#=============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/home/chenbang/app/netease"
WATCH_LOG="${PROJECT_ROOT}/watch-build.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 监听配置
FRONTEND_DIR="${PROJECT_ROOT}/SPlayer/src"
BACKEND_DIR="${PROJECT_ROOT}/server/src"
API_DIR="${PROJECT_ROOT}/api-enhanced"

# 防抖时间（秒）- 避免频繁构建
DEBOUNCE_TIME=3
LAST_BUILD_TIME=0

# 日志函数
log_info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $1"
}

# 检查 inotify-tools
check_inotifywait() {
    if ! command -v inotifywait &> /dev/null; then
        log_error "未安装 inotify-tools"
        log_info "请执行安装: sudo apt-get install -y inotify-tools"
        exit 1
    fi
}

# 检查是否需要构建（防抖）
should_build() {
    local current_time=$(date +%s)
    local time_diff=$((current_time - LAST_BUILD_TIME))
    
    if [ ${time_diff} -lt ${DEBOUNCE_TIME} ]; then
        return 1
    fi
    
    LAST_BUILD_TIME=${current_time}
    return 0
}

# 触发构建
trigger_build() {
    local build_type=$1
    local changed_file=$2
    
    if ! should_build; then
        log_info "构建防抖中，跳过..."
        return
    fi
    
    log_warning "========================================="
    log_warning "检测到文件变化: ${changed_file}"
    log_warning "触发${build_type}构建..."
    log_warning "========================================="
    
    # 执行构建
    bash "${PROJECT_ROOT}/auto-build.sh" "${build_type}"
    
    if [ $? -eq 0 ]; then
        log_success "✓ 构建完成"
    else
        log_error "✗ 构建失败，请检查日志"
    fi
    
    echo ""
}

# 监听前端变化
watch_frontend() {
    log_info "开始监听前端文件: ${FRONTEND_DIR}"
    
    inotifywait -m -r -e modify,create,delete,move \
        --exclude '(node_modules|\.git|out|dist)' \
        --format '%w%f' \
        "${FRONTEND_DIR}" 2>/dev/null | while read file
    do
        # 只监听源代码文件
        if [[ "${file}" =~ \.(vue|js|ts|jsx|tsx|css|scss|sass|html)$ ]]; then
            trigger_build "frontend" "${file}"
        fi
    done
}

# 监听后端变化
watch_backend() {
    log_info "开始监听后端文件: ${BACKEND_DIR}"
    
    inotifywait -m -r -e modify,create,delete,move \
        --exclude '(node_modules|\.git|out|dist)' \
        --format '%w%f' \
        "${BACKEND_DIR}" 2>/dev/null | while read file
    do
        # 只监听源代码文件
        if [[ "${file}" =~ \.(js|ts|json)$ ]]; then
            trigger_build "backend" "${file}"
        fi
    done
}

# 手动模式
manual_mode() {
    log_info "========================================="
    log_info "手动构建模式"
    log_info "========================================="
    
    cat << EOF
${GREEN}可用命令:${NC}
  1 - 构建前端
  2 - 构建后端
  3 - 构建全部
  q - 退出

EOF
    
    while true; do
        read -p "$(echo -e ${BLUE}请选择操作 [1/2/3/q]: ${NC})" choice
        
        case ${choice} in
            1)
                bash "${PROJECT_ROOT}/auto-build.sh" frontend
                ;;
            2)
                bash "${PROJECT_ROOT}/auto-build.sh" backend
                ;;
            3)
                bash "${PROJECT_ROOT}/auto-build.sh" all
                ;;
            q|Q)
                log_info "退出..."
                exit 0
                ;;
            *)
                log_error "无效选项，请重新选择"
                ;;
        esac
        echo ""
    done
}

# 显示帮助
show_help() {
    cat << EOF
${GREEN}文件监听与自动构建脚本 - 使用说明${NC}

用法: bash watch-and-build.sh [模式]

模式:
    auto        自动监听模式（监听文件变化自动构建）
    manual      手动构建模式（交互式选择）【默认】
    help        显示此帮助信息

示例:
    bash watch-and-build.sh auto      # 启动自动监听
    bash watch-and-build.sh manual    # 手动构建模式

注意:
    - 自动模式需要安装 inotify-tools
    - 安装命令: sudo apt-get install -y inotify-tools
    - 防抖时间: ${DEBOUNCE_TIME} 秒
    - Ctrl+C 停止监听

EOF
}

# 主函数
main() {
    local mode="${1:-manual}"
    
    log_info "========================================="
    log_info "文件监听与自动构建脚本"
    log_info "时间: ${TIMESTAMP}"
    log_info "========================================="
    
    case "${mode}" in
        auto)
            # 检查依赖
            check_inotifywait
            
            # 检查目录
            if [ ! -d "${FRONTEND_DIR}" ]; then
                log_error "前端目录不存在: ${FRONTEND_DIR}"
                exit 1
            fi
            
            if [ ! -d "${BACKEND_DIR}" ]; then
                log_warning "后端目录不存在: ${BACKEND_DIR}"
            fi
            
            log_success "自动监听模式已启动"
            log_info "监听前端: ${FRONTEND_DIR}"
            log_info "监听后端: ${BACKEND_DIR}"
            log_warning "按 Ctrl+C 停止监听"
            echo ""
            
            # 同时监听前后端（使用后台任务）
            watch_frontend &
            PID1=$!
            
            if [ -d "${BACKEND_DIR}" ]; then
                watch_backend &
                PID2=$!
            fi
            
            # 等待任意一个进程结束
            wait
            ;;
            
        manual)
            manual_mode
            ;;
            
        help|--help|-h)
            show_help
            exit 0
            ;;
            
        *)
            log_error "未知模式: ${mode}"
            show_help
            exit 1
            ;;
    esac
}

# 清理函数
cleanup() {
    log_warning "正在停止监听..."
    kill ${PID1} 2>/dev/null || true
    kill ${PID2} 2>/dev/null || true
    log_info "已停止"
    exit 0
}

# 捕获 Ctrl+C
trap cleanup SIGINT SIGTERM

# 脚本入口
main "$@"
