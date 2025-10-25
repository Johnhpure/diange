#!/bin/bash

#=============================================================================
# 自动构建脚本 - 确保前后端代码修改后正确重新构建
# 用途: 在Nginx生产环境下，确保代码修改后用户能访问到最新版本
#=============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="/home/chenbang/app/netease"
LOG_FILE="${PROJECT_ROOT}/build.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[${TIMESTAMP}] [INFO] $1" >> "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[${TIMESTAMP}] [SUCCESS] $1" >> "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[${TIMESTAMP}] [WARNING] $1" >> "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[${TIMESTAMP}] [ERROR] $1" >> "${LOG_FILE}"
}

# 检查目录是否存在
check_directory() {
    local dir=$1
    if [ ! -d "${dir}" ]; then
        log_error "目录不存在: ${dir}"
        return 1
    fi
    return 0
}

# 检查 node_modules 是否存在
check_dependencies() {
    local dir=$1
    if [ ! -d "${dir}/node_modules" ]; then
        log_warning "${dir} 的依赖未安装，正在安装..."
        cd "${dir}"
        npm install
        if [ $? -eq 0 ]; then
            log_success "依赖安装成功"
        else
            log_error "依赖安装失败"
            return 1
        fi
    fi
    return 0
}

# 构建前端 (SPlayer)
build_frontend() {
    log_info "========================================="
    log_info "开始构建前端 (SPlayer)"
    log_info "========================================="
    
    local frontend_dir="${PROJECT_ROOT}/SPlayer"
    
    if ! check_directory "${frontend_dir}"; then
        return 1
    fi
    
    cd "${frontend_dir}"
    
    # 检查依赖
    if ! check_dependencies "${frontend_dir}"; then
        return 1
    fi
    
    # 执行构建
    log_info "正在执行: npm run build"
    if npm run build 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "前端构建完成！"
        log_info "构建产物位置: ${frontend_dir}/out"
        return 0
    else
        log_error "前端构建失败！"
        return 1
    fi
}

# 构建后端 (server)
build_backend() {
    log_info "========================================="
    log_info "开始构建后端 (server)"
    log_info "========================================="
    
    local backend_dir="${PROJECT_ROOT}/server"
    
    if ! check_directory "${backend_dir}"; then
        return 1
    fi
    
    cd "${backend_dir}"
    
    # 检查依赖
    if ! check_dependencies "${backend_dir}"; then
        return 1
    fi
    
    # 执行构建
    log_info "正在执行: npm run build"
    if npm run build 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "后端构建完成！"
        return 0
    else
        log_error "后端构建失败！"
        return 1
    fi
}

# 构建 API Enhanced
build_api() {
    log_info "========================================="
    log_info "检查 API Enhanced"
    log_info "========================================="
    
    local api_dir="${PROJECT_ROOT}/api-enhanced"
    
    if ! check_directory "${api_dir}"; then
        return 1
    fi
    
    cd "${api_dir}"
    
    # API Enhanced 主要是运行时服务，检查依赖即可
    if ! check_dependencies "${api_dir}"; then
        return 1
    fi
    
    log_success "API Enhanced 依赖检查完成"
    return 0
}

# 重启服务（可选）
restart_services() {
    log_info "========================================="
    log_info "检查是否需要重启服务"
    log_info "========================================="
    
    # 检查 service-guardian.sh 是否存在
    if [ -f "${PROJECT_ROOT}/service-guardian.sh" ]; then
        log_info "发现守护进程脚本，建议手动重启服务"
        log_warning "请手动执行: bash ${PROJECT_ROOT}/service-guardian.sh restart"
    fi
    
    # 检查 Nginx 配置
    if command -v nginx &> /dev/null; then
        log_info "检测到 Nginx，重载配置..."
        if sudo nginx -t 2>&1 | tee -a "${LOG_FILE}"; then
            sudo nginx -s reload
            log_success "Nginx 配置已重载"
        else
            log_error "Nginx 配置测试失败，请检查配置"
        fi
    fi
}

# 清理旧的构建产物
clean_build() {
    log_info "========================================="
    log_info "清理旧的构建产物"
    log_info "========================================="
    
    # 清理前端构建产物
    if [ -d "${PROJECT_ROOT}/SPlayer/out" ]; then
        log_info "清理 SPlayer/out"
        rm -rf "${PROJECT_ROOT}/SPlayer/out"
    fi
    
    # 清理后端构建产物
    if [ -d "${PROJECT_ROOT}/server/dist" ]; then
        log_info "清理 server/dist"
        rm -rf "${PROJECT_ROOT}/server/dist"
    fi
    
    log_success "清理完成"
}

# 显示帮助信息
show_help() {
    cat << EOF
${GREEN}自动构建脚本 - 使用说明${NC}

用法: bash auto-build.sh [选项]

选项:
    all         构建所有项目（前端 + 后端 + API）【默认】
    frontend    仅构建前端 (SPlayer)
    backend     仅构建后端 (server)
    api         仅检查 API Enhanced
    clean       清理所有构建产物
    restart     重启相关服务
    help        显示此帮助信息

示例:
    bash auto-build.sh              # 构建所有项目
    bash auto-build.sh frontend     # 仅构建前端
    bash auto-build.sh clean all    # 清理后构建所有

注意:
    - 构建日志保存在: ${LOG_FILE}
    - 确保已安装 Node.js 和 npm
    - 前端构建产物: SPlayer/out
    - 构建完成后建议重启服务使更改生效

EOF
}

# 主函数
main() {
    log_info "========================================="
    log_info "自动构建脚本启动"
    log_info "时间: ${TIMESTAMP}"
    log_info "========================================="
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "未检测到 Node.js，请先安装"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "未检测到 npm，请先安装"
        exit 1
    fi
    
    log_info "Node 版本: $(node --version)"
    log_info "npm 版本: $(npm --version)"
    
    # 解析命令行参数
    local action="${1:-all}"
    local build_success=true
    
    case "${action}" in
        help|--help|-h)
            show_help
            exit 0
            ;;
        clean)
            clean_build
            # 如果有第二个参数，继续执行构建
            if [ -n "$2" ]; then
                action="$2"
            else
                exit 0
            fi
            ;;
    esac
    
    # 执行构建
    case "${action}" in
        all)
            build_frontend || build_success=false
            echo ""
            build_backend || build_success=false
            echo ""
            build_api || build_success=false
            ;;
        frontend)
            build_frontend || build_success=false
            ;;
        backend)
            build_backend || build_success=false
            ;;
        api)
            build_api || build_success=false
            ;;
        restart)
            restart_services
            exit 0
            ;;
        *)
            log_error "未知选项: ${action}"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    log_info "========================================="
    
    if [ "${build_success}" = true ]; then
        log_success "✓ 所有构建任务已完成！"
        log_info "构建日志: ${LOG_FILE}"
        echo ""
        log_warning "重要提示："
        log_warning "1. 前端已重新构建，Nginx会自动提供新版本"
        log_warning "2. 如修改了后端代码，请重启后端服务："
        log_warning "   bash ${PROJECT_ROOT}/service-guardian.sh restart"
        echo ""
        
        # 询问是否重启服务
        if [ -t 0 ]; then  # 检查是否在交互式终端
            read -p "$(echo -e ${YELLOW}是否现在重启服务？[y/N]: ${NC})" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                restart_services
            fi
        fi
        
        exit 0
    else
        log_error "✗ 构建过程中出现错误，请查看日志"
        log_error "日志文件: ${LOG_FILE}"
        exit 1
    fi
}

# 脚本入口
main "$@"
