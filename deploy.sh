#!/bin/bash

################################################################################
# 智能部署脚本
# 用途: 前后端代码修改后自动构建和部署
# 作者: factory-droid[bot]
# 日期: 2025-10-14
################################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_ROOT="/home/chenbang/app/netease"
FRONTEND_DIR="${PROJECT_ROOT}/SPlayer"
BACKEND_DIR="${PROJECT_ROOT}/api-enhanced"
BUILD_OUTPUT="${FRONTEND_DIR}/out/renderer"
LOG_FILE="${PROJECT_ROOT}/deploy.log"

# 时间戳
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

################################################################################
# 工具函数
################################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[${TIMESTAMP}] [INFO] $1" >> "${LOG_FILE}"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[${TIMESTAMP}] [WARN] $1" >> "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[${TIMESTAMP}] [ERROR] $1" >> "${LOG_FILE}"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "命令 '$1' 未找到，请先安装"
        exit 1
    fi
}

# 检查目录是否存在
check_directory() {
    if [ ! -d "$1" ]; then
        log_error "目录不存在: $1"
        exit 1
    fi
}

################################################################################
# 前端构建
################################################################################

build_frontend() {
    log_section "前端构建"
    
    log_info "检查前端目录..."
    check_directory "${FRONTEND_DIR}"
    
    log_info "切换到前端目录: ${FRONTEND_DIR}"
    cd "${FRONTEND_DIR}"
    
    # 检查 package.json
    if [ ! -f "package.json" ]; then
        log_error "package.json 不存在"
        exit 1
    fi
    
    # 检查 node_modules
    if [ ! -d "node_modules" ]; then
        log_warn "node_modules 不存在，正在安装依赖..."
        npm install
    fi
    
    log_info "开始构建前端项目..."
    log_info "构建命令: npm run build"
    
    # 记录构建前的时间
    BUILD_START=$(date +%s)
    
    # 执行构建
    if npm run build; then
        BUILD_END=$(date +%s)
        BUILD_TIME=$((BUILD_END - BUILD_START))
        log_info "✅ 前端构建成功！耗时: ${BUILD_TIME}秒"
        
        # 检查构建输出
        if [ -d "${BUILD_OUTPUT}" ]; then
            FILE_COUNT=$(find "${BUILD_OUTPUT}" -type f | wc -l)
            TOTAL_SIZE=$(du -sh "${BUILD_OUTPUT}" | cut -f1)
            log_info "构建输出: ${BUILD_OUTPUT}"
            log_info "文件数量: ${FILE_COUNT}"
            log_info "总大小: ${TOTAL_SIZE}"
            
            # 显示关键文件的时间戳
            if [ -f "${BUILD_OUTPUT}/index.html" ]; then
                INDEX_TIME=$(stat -c %y "${BUILD_OUTPUT}/index.html" | cut -d'.' -f1)
                log_info "index.html 更新时间: ${INDEX_TIME}"
            fi
        else
            log_error "构建输出目录不存在: ${BUILD_OUTPUT}"
            exit 1
        fi
    else
        log_error "❌ 前端构建失败！"
        exit 1
    fi
}

################################################################################
# 后端重启
################################################################################

restart_backend() {
    log_section "后端服务重启"
    
    log_info "检查后端目录..."
    check_directory "${BACKEND_DIR}"
    
    # 查找并停止旧的后端进程
    log_info "查找后端进程..."
    BACKEND_PID=$(ps aux | grep "node app.js" | grep -v grep | grep "${BACKEND_DIR}" | awk '{print $2}')
    
    if [ -n "${BACKEND_PID}" ]; then
        log_info "发现后端进程 PID: ${BACKEND_PID}"
        log_info "停止后端进程..."
        kill -15 "${BACKEND_PID}" 2>/dev/null || true
        sleep 2
        
        # 强制杀死
        if ps -p "${BACKEND_PID}" > /dev/null 2>&1; then
            log_warn "进程未正常退出，强制杀死..."
            kill -9 "${BACKEND_PID}" 2>/dev/null || true
            sleep 1
        fi
        log_info "✅ 后端进程已停止"
    else
        log_info "未发现运行中的后端进程"
    fi
    
    # 启动后端服务
    log_info "启动后端服务..."
    cd "${BACKEND_DIR}"
    
    nohup node app.js > api-3001.log 2>&1 &
    NEW_BACKEND_PID=$!
    
    sleep 3
    
    # 验证后端是否启动成功
    if ps -p "${NEW_BACKEND_PID}" > /dev/null 2>&1; then
        log_info "✅ 后端服务启动成功！PID: ${NEW_BACKEND_PID}"
        
        # 检查端口监听
        if netstat -tuln | grep -q ":3001"; then
            log_info "✅ 端口 3001 监听正常"
        else
            log_warn "⚠️  端口 3001 未检测到监听"
        fi
        
        # 检查日志
        sleep 2
        if tail -10 api-3001.log | grep -q "Server started successfully"; then
            log_info "✅ 后端服务健康检查通过"
        else
            log_warn "后端日志未发现成功启动标记，请检查: ${BACKEND_DIR}/api-3001.log"
        fi
    else
        log_error "❌ 后端服务启动失败！"
        log_error "请检查日志: ${BACKEND_DIR}/api-3001.log"
        tail -20 "${BACKEND_DIR}/api-3001.log"
        exit 1
    fi
}

################################################################################
# 清理缓存
################################################################################

clear_nginx_cache() {
    log_section "清理Nginx缓存"
    
    if command -v nginx &> /dev/null; then
        log_info "重新加载Nginx配置..."
        if nginx -t 2>&1 | grep -q "syntax is ok"; then
            sudo nginx -s reload && log_info "✅ Nginx已重新加载" || log_warn "Nginx重新加载失败"
        else
            log_warn "Nginx配置测试失败，跳过重新加载"
        fi
    else
        log_info "Nginx未安装，跳过"
    fi
}

################################################################################
# 验证部署
################################################################################

verify_deployment() {
    log_section "部署验证"
    
    # 检查后端API
    log_info "检查后端API..."
    if curl -s http://localhost:3001/queue > /dev/null 2>&1; then
        log_info "✅ 后端API响应正常"
    else
        log_warn "⚠️  后端API无响应"
    fi
    
    # 检查构建文件
    log_info "检查前端构建文件..."
    if [ -f "${BUILD_OUTPUT}/index.html" ]; then
        FILE_AGE=$(($(date +%s) - $(stat -c %Y "${BUILD_OUTPUT}/index.html")))
        if [ ${FILE_AGE} -lt 300 ]; then
            log_info "✅ 构建文件是最新的 (${FILE_AGE}秒前)"
        else
            log_warn "⚠️  构建文件较旧 (${FILE_AGE}秒前)"
        fi
    else
        log_error "❌ index.html 不存在"
    fi
    
    # 检查关键修改是否在构建中
    log_info "验证关键代码..."
    if grep -q "queueMode:!0" "${BUILD_OUTPUT}"/assets/*.js 2>/dev/null; then
        log_info "✅ queueMode默认开启已确认"
    else
        log_warn "⚠️  未在构建文件中找到queueMode修改"
    fi
}

################################################################################
# 显示访问信息
################################################################################

show_access_info() {
    log_section "访问信息"
    
    # 获取IP地址
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${GREEN}✅ 部署完成！${NC}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📱 访问地址${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  🌐 生产环境 (推荐):"
    echo "     https://${LOCAL_IP}:7899"
    echo ""
    echo "  🔧 开发环境 (实时热更新):"
    echo "     http://localhost:6944"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}⚠️  重要提示${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  请在浏览器中按 ${YELLOW}Ctrl+Shift+R${NC} 强制刷新"
    echo "  (Mac 用户按 ${YELLOW}Cmd+Shift+R${NC})"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📝 日志文件${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  部署日志: ${PROJECT_ROOT}/deploy.log"
    echo "  后端日志: ${BACKEND_DIR}/api-3001.log"
    echo "  前端日志: ${FRONTEND_DIR}/vite-web.log"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

################################################################################
# 主函数
################################################################################

main() {
    log_section "开始部署"
    log_info "时间: ${TIMESTAMP}"
    log_info "项目根目录: ${PROJECT_ROOT}"
    
    # 检查必要命令
    check_command "node"
    check_command "npm"
    check_command "netstat"
    
    # 参数解析
    SKIP_FRONTEND=false
    SKIP_BACKEND=false
    SKIP_VERIFY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-frontend)
                SKIP_FRONTEND=true
                shift
                ;;
            --skip-backend)
                SKIP_BACKEND=true
                shift
                ;;
            --skip-verify)
                SKIP_VERIFY=true
                shift
                ;;
            --frontend-only)
                SKIP_BACKEND=true
                shift
                ;;
            --backend-only)
                SKIP_FRONTEND=true
                shift
                ;;
            --help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --frontend-only    仅构建前端"
                echo "  --backend-only     仅重启后端"
                echo "  --skip-frontend    跳过前端构建"
                echo "  --skip-backend     跳过后端重启"
                echo "  --skip-verify      跳过部署验证"
                echo "  --help             显示此帮助信息"
                echo ""
                echo "示例:"
                echo "  $0                      # 完整部署"
                echo "  $0 --frontend-only      # 仅构建前端"
                echo "  $0 --backend-only       # 仅重启后端"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                echo "使用 --help 查看帮助"
                exit 1
                ;;
        esac
    done
    
    # 执行前端构建
    if [ "${SKIP_FRONTEND}" = false ]; then
        build_frontend
    else
        log_info "跳过前端构建"
    fi
    
    # 执行后端重启
    if [ "${SKIP_BACKEND}" = false ]; then
        restart_backend
    else
        log_info "跳过后端重启"
    fi
    
    # 清理Nginx缓存
    clear_nginx_cache
    
    # 验证部署
    if [ "${SKIP_VERIFY}" = false ]; then
        verify_deployment
    else
        log_info "跳过部署验证"
    fi
    
    # 显示访问信息
    show_access_info
    
    log_info "部署完成！"
}

# 执行主函数
main "$@"
