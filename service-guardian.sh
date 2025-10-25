#!/bin/bash

################################################################################
# 网易云音乐服务守护脚本
# 功能：监控前后端服务状态，自动重启异常服务
# 作者：AI Assistant
# 更新时间：2024-10-14
################################################################################

# =============================================================================
# 配置部分
# =============================================================================

# 项目根目录
PROJECT_ROOT="/home/chenbang/app/netease"

# 后端API配置
BACKEND_DIR="${PROJECT_ROOT}/api-enhanced"
BACKEND_PORT=3001
BACKEND_CMD="node app.js"
BACKEND_LOG="${BACKEND_DIR}/api-3001.log"
BACKEND_PID_FILE="${BACKEND_DIR}/.backend.pid"

# 前端Vite配置
FRONTEND_DIR="${PROJECT_ROOT}/SPlayer"
FRONTEND_PORT=6944
FRONTEND_CMD="npx vite"
FRONTEND_LOG="${FRONTEND_DIR}/vite-simple.log"
FRONTEND_PID_FILE="${FRONTEND_DIR}/.frontend.pid"

# 守护进程日志
GUARDIAN_LOG="${PROJECT_ROOT}/guardian.log"
MAX_LOG_LINES=1000  # 日志文件最大行数

# 重启间隔（秒），防止频繁重启
RESTART_COOLDOWN=30
LAST_BACKEND_RESTART=0
LAST_FRONTEND_RESTART=0

# =============================================================================
# 工具函数
# =============================================================================

# 记录日志
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${GUARDIAN_LOG}"
    
    # 限制日志文件大小
    if [ -f "${GUARDIAN_LOG}" ]; then
        local line_count=$(wc -l < "${GUARDIAN_LOG}")
        if [ ${line_count} -gt ${MAX_LOG_LINES} ]; then
            tail -n ${MAX_LOG_LINES} "${GUARDIAN_LOG}" > "${GUARDIAN_LOG}.tmp"
            mv "${GUARDIAN_LOG}.tmp" "${GUARDIAN_LOG}"
        fi
    fi
}

# 检查端口是否被监听
check_port() {
    local port=$1
    if lsof -i :${port} -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # 端口正在监听
    else
        return 1  # 端口未监听
    fi
}

# 检查进程是否存在
check_process() {
    local pid=$1
    if [ -z "$pid" ]; then
        return 1
    fi
    if ps -p ${pid} > /dev/null 2>&1; then
        return 0  # 进程存在
    else
        return 1  # 进程不存在
    fi
}

# 获取端口占用的PID
get_port_pid() {
    local port=$1
    lsof -i :${port} -sTCP:LISTEN -t 2>/dev/null | head -1
}

# 检查服务健康状态（通过HTTP请求）
check_service_health() {
    local port=$1
    local endpoint=$2
    local response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://localhost:${port}${endpoint}" 2>/dev/null)
    
    # HTTP 200-399 都认为是正常
    if [ -n "$response" ] && [ "$response" -ge 200 ] && [ "$response" -lt 400 ]; then
        return 0
    else
        return 1
    fi
}

# 读取PID文件
read_pid_file() {
    local pid_file=$1
    if [ -f "${pid_file}" ]; then
        cat "${pid_file}"
    else
        echo ""
    fi
}

# 写入PID文件
write_pid_file() {
    local pid_file=$1
    local pid=$2
    echo "${pid}" > "${pid_file}"
}

# 清理PID文件
clean_pid_file() {
    local pid_file=$1
    rm -f "${pid_file}"
}

# 停止服务
stop_service() {
    local service_name=$1
    local pid=$2
    
    if check_process ${pid}; then
        log "INFO" "正在停止 ${service_name} (PID: ${pid})..."
        kill ${pid} 2>/dev/null
        sleep 2
        
        # 如果进程还在，强制杀死
        if check_process ${pid}; then
            log "WARN" "${service_name} 未响应SIGTERM，使用SIGKILL强制停止"
            kill -9 ${pid} 2>/dev/null
            sleep 1
        fi
        
        if ! check_process ${pid}; then
            log "INFO" "${service_name} 已成功停止"
            return 0
        else
            log "ERROR" "无法停止 ${service_name}"
            return 1
        fi
    else
        log "INFO" "${service_name} 进程不存在，无需停止"
        return 0
    fi
}

# =============================================================================
# 后端API服务管理
# =============================================================================

check_backend() {
    log "INFO" "检查后端API服务状态..."
    
    # 1. 检查端口监听
    if ! check_port ${BACKEND_PORT}; then
        log "WARN" "后端API端口 ${BACKEND_PORT} 未被监听"
        return 1
    fi
    
    # 2. 检查PID文件
    local saved_pid=$(read_pid_file "${BACKEND_PID_FILE}")
    if [ -n "$saved_pid" ]; then
        if ! check_process ${saved_pid}; then
            log "WARN" "后端API进程 (PID: ${saved_pid}) 不存在"
            clean_pid_file "${BACKEND_PID_FILE}"
            return 1
        fi
    fi
    
    # 3. 健康检查
    if ! check_service_health ${BACKEND_PORT} "/login/status"; then
        log "WARN" "后端API健康检查失败"
        return 1
    fi
    
    log "INFO" "后端API服务运行正常 (端口: ${BACKEND_PORT})"
    return 0
}

start_backend() {
    local current_time=$(date +%s)
    
    # 检查冷却时间
    if [ $((current_time - LAST_BACKEND_RESTART)) -lt ${RESTART_COOLDOWN} ]; then
        log "WARN" "后端API重启过于频繁，跳过本次重启（冷却中）"
        return 1
    fi
    
    log "INFO" "正在启动后端API服务..."
    
    # 停止旧进程
    local old_pid=$(read_pid_file "${BACKEND_PID_FILE}")
    if [ -n "$old_pid" ]; then
        stop_service "后端API" ${old_pid}
        clean_pid_file "${BACKEND_PID_FILE}"
    fi
    
    # 清理可能占用端口的进程
    local port_pid=$(get_port_pid ${BACKEND_PORT})
    if [ -n "$port_pid" ]; then
        log "WARN" "端口 ${BACKEND_PORT} 被进程 ${port_pid} 占用，尝试清理..."
        # 检查是否是我们的服务
        local cmd=$(ps -p ${port_pid} -o comm= 2>/dev/null)
        if [[ "$cmd" == "node" ]] || [[ "$cmd" == "nodejs" ]]; then
            kill ${port_pid} 2>/dev/null
            sleep 2
        fi
    fi
    
    # 启动新进程
    cd "${BACKEND_DIR}" || {
        log "ERROR" "无法进入后端目录: ${BACKEND_DIR}"
        return 1
    }
    
    # 使用nohup启动，并捕获PID
    nohup ${BACKEND_CMD} > "${BACKEND_LOG}" 2>&1 &
    local new_pid=$!
    
    # 等待服务启动
    sleep 3
    
    # 验证启动
    if check_process ${new_pid}; then
        write_pid_file "${BACKEND_PID_FILE}" ${new_pid}
        LAST_BACKEND_RESTART=${current_time}
        log "INFO" "后端API服务启动成功 (PID: ${new_pid}, 端口: ${BACKEND_PORT})"
        
        # 额外等待并检查端口
        sleep 2
        if check_port ${BACKEND_PORT}; then
            log "INFO" "后端API端口监听确认成功"
            return 0
        else
            log "WARN" "后端API进程启动但端口未监听，可能需要更多时间"
            return 0
        fi
    else
        log "ERROR" "后端API服务启动失败，请检查日志: ${BACKEND_LOG}"
        clean_pid_file "${BACKEND_PID_FILE}"
        return 1
    fi
}

# =============================================================================
# 前端Vite服务管理
# =============================================================================

check_frontend() {
    log "INFO" "检查前端Vite服务状态..."
    
    # 1. 检查端口监听
    if ! check_port ${FRONTEND_PORT}; then
        log "WARN" "前端Vite端口 ${FRONTEND_PORT} 未被监听"
        return 1
    fi
    
    # 2. 检查PID文件
    local saved_pid=$(read_pid_file "${FRONTEND_PID_FILE}")
    if [ -n "$saved_pid" ]; then
        if ! check_process ${saved_pid}; then
            log "WARN" "前端Vite进程 (PID: ${saved_pid}) 不存在"
            clean_pid_file "${FRONTEND_PID_FILE}"
            return 1
        fi
    fi
    
    # 3. 健康检查（检查首页）
    if ! check_service_health ${FRONTEND_PORT} "/"; then
        log "WARN" "前端Vite健康检查失败"
        return 1
    fi
    
    log "INFO" "前端Vite服务运行正常 (端口: ${FRONTEND_PORT})"
    return 0
}

start_frontend() {
    local current_time=$(date +%s)
    
    # 检查冷却时间
    if [ $((current_time - LAST_FRONTEND_RESTART)) -lt ${RESTART_COOLDOWN} ]; then
        log "WARN" "前端Vite重启过于频繁，跳过本次重启（冷却中）"
        return 1
    fi
    
    log "INFO" "正在启动前端Vite服务..."
    
    # 停止旧进程
    local old_pid=$(read_pid_file "${FRONTEND_PID_FILE}")
    if [ -n "$old_pid" ]; then
        stop_service "前端Vite" ${old_pid}
        clean_pid_file "${FRONTEND_PID_FILE}"
    fi
    
    # 清理可能占用端口的进程
    local port_pid=$(get_port_pid ${FRONTEND_PORT})
    if [ -n "$port_pid" ]; then
        log "WARN" "端口 ${FRONTEND_PORT} 被进程 ${port_pid} 占用，尝试清理..."
        local cmd=$(ps -p ${port_pid} -o comm= 2>/dev/null)
        if [[ "$cmd" == "node" ]] || [[ "$cmd" == "nodejs" ]]; then
            kill ${port_pid} 2>/dev/null
            sleep 2
        fi
    fi
    
    # 启动新进程
    cd "${FRONTEND_DIR}" || {
        log "ERROR" "无法进入前端目录: ${FRONTEND_DIR}"
        return 1
    }
    
    # 使用nohup启动，并捕获PID
    nohup ${FRONTEND_CMD} > "${FRONTEND_LOG}" 2>&1 &
    local new_pid=$!
    
    # 等待服务启动
    sleep 5
    
    # 验证启动
    if check_process ${new_pid}; then
        write_pid_file "${FRONTEND_PID_FILE}" ${new_pid}
        LAST_FRONTEND_RESTART=${current_time}
        log "INFO" "前端Vite服务启动成功 (PID: ${new_pid}, 端口: ${FRONTEND_PORT})"
        
        # 额外等待并检查端口
        sleep 3
        if check_port ${FRONTEND_PORT}; then
            log "INFO" "前端Vite端口监听确认成功"
            return 0
        else
            log "WARN" "前端Vite进程启动但端口未监听，可能需要更多时间"
            return 0
        fi
    else
        log "ERROR" "前端Vite服务启动失败，请检查日志: ${FRONTEND_LOG}"
        clean_pid_file "${FRONTEND_PID_FILE}"
        return 1
    fi
}

# =============================================================================
# 主守护逻辑
# =============================================================================

monitor_services() {
    log "INFO" "========== 开始服务监控 =========="
    
    local backend_status=0
    local frontend_status=0
    
    # 检查后端
    if ! check_backend; then
        backend_status=1
        log "ERROR" "后端API服务异常，尝试重启..."
        if start_backend; then
            log "INFO" "后端API服务重启成功"
            backend_status=0
        else
            log "ERROR" "后端API服务重启失败"
        fi
    fi
    
    # 检查前端
    if ! check_frontend; then
        frontend_status=1
        log "ERROR" "前端Vite服务异常，尝试重启..."
        if start_frontend; then
            log "INFO" "前端Vite服务重启成功"
            frontend_status=0
        else
            log "ERROR" "前端Vite服务重启失败"
        fi
    fi
    
    # 总结
    if [ ${backend_status} -eq 0 ] && [ ${frontend_status} -eq 0 ]; then
        log "INFO" "✅ 所有服务运行正常"
    else
        log "WARN" "⚠️  部分服务存在问题"
    fi
    
    log "INFO" "========== 监控周期结束 ==========\n"
}

# =============================================================================
# 命令处理
# =============================================================================

show_status() {
    echo "================================"
    echo "服务状态监控"
    echo "================================"
    echo ""
    
    # 后端状态
    echo "【后端API服务】"
    echo "  端口: ${BACKEND_PORT}"
    echo "  目录: ${BACKEND_DIR}"
    if check_port ${BACKEND_PORT}; then
        local pid=$(get_port_pid ${BACKEND_PORT})
        echo "  状态: ✅ 运行中"
        echo "  PID: ${pid}"
        if check_service_health ${BACKEND_PORT} "/login/status"; then
            echo "  健康: ✅ 正常"
        else
            echo "  健康: ⚠️  异常"
        fi
    else
        echo "  状态: ❌ 未运行"
    fi
    echo ""
    
    # 前端状态
    echo "【前端Vite服务】"
    echo "  端口: ${FRONTEND_PORT}"
    echo "  目录: ${FRONTEND_DIR}"
    if check_port ${FRONTEND_PORT}; then
        local pid=$(get_port_pid ${FRONTEND_PORT})
        echo "  状态: ✅ 运行中"
        echo "  PID: ${pid}"
        if check_service_health ${FRONTEND_PORT} "/"; then
            echo "  健康: ✅ 正常"
        else
            echo "  健康: ⚠️  异常"
        fi
    else
        echo "  状态: ❌ 未运行"
    fi
    echo ""
    
    # 访问地址
    echo "【访问地址】"
    echo "  前端: http://localhost:${FRONTEND_PORT}"
    local ip=$(hostname -I | awk '{print $1}')
    if [ -n "$ip" ]; then
        echo "  局域网: http://${ip}:${FRONTEND_PORT}"
    fi
    echo ""
    
    echo "【日志文件】"
    echo "  守护日志: ${GUARDIAN_LOG}"
    echo "  后端日志: ${BACKEND_LOG}"
    echo "  前端日志: ${FRONTEND_LOG}"
    echo "================================"
}

start_all() {
    log "INFO" "启动所有服务..."
    start_backend
    sleep 2
    start_frontend
    echo ""
    show_status
}

stop_all() {
    log "INFO" "停止所有服务..."
    
    # 停止后端
    local backend_pid=$(read_pid_file "${BACKEND_PID_FILE}")
    if [ -n "$backend_pid" ]; then
        stop_service "后端API" ${backend_pid}
        clean_pid_file "${BACKEND_PID_FILE}"
    fi
    
    # 停止前端
    local frontend_pid=$(read_pid_file "${FRONTEND_PID_FILE}")
    if [ -n "$frontend_pid" ]; then
        stop_service "前端Vite" ${frontend_pid}
        clean_pid_file "${FRONTEND_PID_FILE}"
    fi
    
    log "INFO" "所有服务已停止"
}

restart_all() {
    log "INFO" "重启所有服务..."
    stop_all
    sleep 2
    start_all
}

show_help() {
    cat << EOF
网易云音乐服务守护脚本

用法: $0 [命令]

命令:
  monitor         执行一次监控检查（默认）
  start           启动所有服务
  stop            停止所有服务  
  restart         重启所有服务
  status          显示服务状态
  help            显示此帮助信息

守护模式（使用cron）:
  # 每3分钟检查一次
  */3 * * * * /home/chenbang/app/netease/service-guardian.sh monitor >> /home/chenbang/app/netease/guardian-cron.log 2>&1

示例:
  $0 status       # 查看服务状态
  $0 start        # 启动所有服务
  $0 monitor      # 执行监控检查

EOF
}

# =============================================================================
# 主入口
# =============================================================================

main() {
    # 确保日志目录存在
    mkdir -p "$(dirname "${GUARDIAN_LOG}")"
    
    # 处理命令
    case "${1:-monitor}" in
        monitor)
            monitor_services
            ;;
        start)
            start_all
            ;;
        stop)
            stop_all
            ;;
        restart)
            restart_all
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "错误: 未知命令 '$1'"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
