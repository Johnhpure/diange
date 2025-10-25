#!/bin/bash

################################################################################
# 快速启动脚本
# 用于手动快速启动/停止/重启服务
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARDIAN="${SCRIPT_DIR}/service-guardian.sh"

# 确保守护脚本可执行
if [ ! -x "${GUARDIAN}" ]; then
    chmod +x "${GUARDIAN}"
fi

# 转发到守护脚本
exec "${GUARDIAN}" "$@"
