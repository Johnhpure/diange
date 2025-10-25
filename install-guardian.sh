#!/bin/bash

################################################################################
# 守护脚本安装工具
# 功能：安装和配置服务守护系统
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARDIAN_SCRIPT="${SCRIPT_DIR}/service-guardian.sh"
GUARDIAN_LOG="${SCRIPT_DIR}/guardian.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_warn "某些操作需要root权限"
        return 1
    fi
    return 0
}

# 赋予执行权限
setup_permissions() {
    print_info "设置脚本执行权限..."
    chmod +x "${GUARDIAN_SCRIPT}"
    print_info "✅ 权限设置完成"
}

# 安装cron任务
install_cron() {
    print_info "安装cron定时任务..."
    
    # 检查cron是否已安装
    if ! command -v crontab &> /dev/null; then
        print_error "crontab未安装，请先安装cron"
        return 1
    fi
    
    # 备份现有crontab
    crontab -l > /tmp/crontab.backup 2>/dev/null || true
    
    # 检查是否已存在
    if crontab -l 2>/dev/null | grep -q "service-guardian.sh"; then
        print_warn "检测到已存在的守护任务，将先移除..."
        crontab -l 2>/dev/null | grep -v "service-guardian.sh" | crontab - || true
    fi
    
    # 添加新任务（每3分钟执行一次）
    (crontab -l 2>/dev/null; echo "*/3 * * * * ${GUARDIAN_SCRIPT} monitor >> ${GUARDIAN_LOG}.cron 2>&1") | crontab -
    
    print_info "✅ Cron任务已安装"
    print_info "   执行频率: 每3分钟"
    print_info "   日志位置: ${GUARDIAN_LOG}.cron"
}

# 安装systemd服务
install_systemd() {
    if ! check_root; then
        print_error "安装systemd服务需要root权限"
        return 1
    fi
    
    print_info "安装systemd服务..."
    
    # 创建服务文件
    cat > /etc/systemd/system/netease-music-guardian.service << EOF
[Unit]
Description=Netease Music Service Guardian
After=network.target

[Service]
Type=oneshot
ExecStart=${GUARDIAN_SCRIPT} monitor
User=${USER}
Group=${USER}
WorkingDirectory=${SCRIPT_DIR}
StandardOutput=append:${GUARDIAN_LOG}
StandardError=append:${GUARDIAN_LOG}

[Install]
WantedBy=multi-user.target
EOF

    # 创建定时器文件
    cat > /etc/systemd/system/netease-music-guardian.timer << EOF
[Unit]
Description=Netease Music Service Guardian Timer
Requires=netease-music-guardian.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=3min
AccuracySec=10s

[Install]
WantedBy=timers.target
EOF

    # 重载systemd
    systemctl daemon-reload
    
    # 启用并启动定时器
    systemctl enable netease-music-guardian.timer
    systemctl start netease-music-guardian.timer
    
    print_info "✅ Systemd服务已安装并启动"
    print_info "   服务名称: netease-music-guardian.service"
    print_info "   定时器: netease-music-guardian.timer"
    print_info "   执行频率: 每3分钟"
}

# 卸载cron任务
uninstall_cron() {
    print_info "卸载cron定时任务..."
    
    if crontab -l 2>/dev/null | grep -q "service-guardian.sh"; then
        crontab -l 2>/dev/null | grep -v "service-guardian.sh" | crontab - || true
        print_info "✅ Cron任务已移除"
    else
        print_warn "未找到cron任务"
    fi
}

# 卸载systemd服务
uninstall_systemd() {
    if ! check_root; then
        print_error "卸载systemd服务需要root权限"
        return 1
    fi
    
    print_info "卸载systemd服务..."
    
    # 停止并禁用服务
    systemctl stop netease-music-guardian.timer 2>/dev/null || true
    systemctl disable netease-music-guardian.timer 2>/dev/null || true
    
    # 删除服务文件
    rm -f /etc/systemd/system/netease-music-guardian.service
    rm -f /etc/systemd/system/netease-music-guardian.timer
    
    # 重载systemd
    systemctl daemon-reload
    
    print_info "✅ Systemd服务已卸载"
}

# 测试脚本
test_guardian() {
    print_info "测试守护脚本..."
    "${GUARDIAN_SCRIPT}" status
    echo ""
    print_info "执行一次监控检查..."
    "${GUARDIAN_SCRIPT}" monitor
    print_info "✅ 测试完成"
}

# 显示状态
show_status() {
    echo "======================================"
    echo "守护系统状态"
    echo "======================================"
    echo ""
    
    # 检查脚本
    if [ -x "${GUARDIAN_SCRIPT}" ]; then
        echo "✅ 守护脚本: 已安装且可执行"
    else
        echo "❌ 守护脚本: 未安装或无执行权限"
    fi
    echo ""
    
    # 检查cron
    echo "【Cron任务】"
    if crontab -l 2>/dev/null | grep -q "service-guardian.sh"; then
        echo "✅ 状态: 已安装"
        echo "   任务:"
        crontab -l 2>/dev/null | grep "service-guardian.sh" | sed 's/^/   /'
    else
        echo "❌ 状态: 未安装"
    fi
    echo ""
    
    # 检查systemd
    echo "【Systemd服务】"
    if systemctl list-unit-files 2>/dev/null | grep -q "netease-music-guardian"; then
        echo "✅ 状态: 已安装"
        echo "   服务状态:"
        systemctl status netease-music-guardian.timer --no-pager 2>/dev/null | head -5 | sed 's/^/   /'
    else
        echo "❌ 状态: 未安装"
    fi
    echo ""
    
    # 日志文件
    echo "【日志文件】"
    if [ -f "${GUARDIAN_LOG}" ]; then
        local size=$(du -h "${GUARDIAN_LOG}" | cut -f1)
        local lines=$(wc -l < "${GUARDIAN_LOG}")
        echo "  主日志: ${GUARDIAN_LOG} (${size}, ${lines} 行)"
    else
        echo "  主日志: 未生成"
    fi
    
    if [ -f "${GUARDIAN_LOG}.cron" ]; then
        local size=$(du -h "${GUARDIAN_LOG}.cron" | cut -f1)
        local lines=$(wc -l < "${GUARDIAN_LOG}.cron")
        echo "  Cron日志: ${GUARDIAN_LOG}.cron (${size}, ${lines} 行)"
    fi
    echo ""
    
    echo "======================================"
}

# 查看日志
view_logs() {
    local lines=${1:-50}
    
    echo "======================================"
    echo "最近 ${lines} 行守护日志"
    echo "======================================"
    
    if [ -f "${GUARDIAN_LOG}" ]; then
        tail -n ${lines} "${GUARDIAN_LOG}"
    else
        print_warn "日志文件不存在: ${GUARDIAN_LOG}"
    fi
}

# 显示帮助
show_help() {
    cat << EOF
守护脚本安装工具

用法: $0 [命令]

命令:
  install-cron      安装Cron定时任务（推荐，无需root）
  install-systemd   安装Systemd服务（需要root权限）
  uninstall-cron    卸载Cron定时任务
  uninstall-systemd 卸载Systemd服务
  test              测试守护脚本
  status            显示守护系统状态
  logs [行数]       查看守护日志（默认50行）
  help              显示此帮助信息

推荐安装方式（Cron）:
  1. bash install-guardian.sh install-cron
  2. 验证安装: crontab -l

Systemd方式（可选）:
  1. sudo bash install-guardian.sh install-systemd
  2. 查看状态: systemctl status netease-music-guardian.timer

手动使用守护脚本:
  ./service-guardian.sh status    # 查看服务状态
  ./service-guardian.sh start     # 启动所有服务
  ./service-guardian.sh monitor   # 执行一次监控

EOF
}

# 主函数
main() {
    case "${1:-help}" in
        install-cron)
            setup_permissions
            install_cron
            echo ""
            show_status
            ;;
        install-systemd)
            setup_permissions
            install_systemd
            echo ""
            show_status
            ;;
        uninstall-cron)
            uninstall_cron
            ;;
        uninstall-systemd)
            uninstall_systemd
            ;;
        test)
            setup_permissions
            test_guardian
            ;;
        status)
            show_status
            ;;
        logs)
            view_logs "${2:-50}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
