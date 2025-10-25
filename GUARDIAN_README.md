# 网易云音乐服务守护系统

## 📋 功能概述

这是一个完整的服务守护系统，用于自动监控和恢复网易云音乐的前后端服务。

### 主要特性

- ✅ **自动监控**: 每3分钟自动检查服务状态
- ✅ **智能重启**: 服务异常时自动重启
- ✅ **健康检查**: 端口监听 + HTTP健康检查
- ✅ **防抖保护**: 防止频繁重启（30秒冷却）
- ✅ **完整日志**: 记录所有监控和重启操作
- ✅ **多种方式**: 支持Cron/Systemd/手动运行

## 📦 文件结构

```
/home/chenbang/app/netease/
├── service-guardian.sh      # 核心守护脚本
├── install-guardian.sh      # 安装配置工具
├── quick-start.sh           # 快速启动脚本
├── guardian.log             # 守护日志
├── guardian.log.cron        # Cron执行日志
└── GUARDIAN_README.md       # 本文档
```

## 🚀 快速开始

### 方式一：使用Cron（推荐）

**优点**: 不需要root权限，简单可靠

```bash
# 1. 安装Cron任务
cd /home/chenbang/app/netease
bash install-guardian.sh install-cron

# 2. 验证安装
crontab -l | grep guardian

# 3. 查看状态
bash install-guardian.sh status
```

### 方式二：使用Systemd

**优点**: 更好的系统集成，开机自启

```bash
# 1. 安装Systemd服务（需要root）
cd /home/chenbang/app/netease
sudo bash install-guardian.sh install-systemd

# 2. 查看状态
systemctl status netease-music-guardian.timer

# 3. 查看日志
sudo journalctl -u netease-music-guardian.service -f
```

### 方式三：手动运行

```bash
# 查看服务状态
./quick-start.sh status

# 启动所有服务
./quick-start.sh start

# 停止所有服务
./quick-start.sh stop

# 重启所有服务
./quick-start.sh restart

# 执行一次监控
./quick-start.sh monitor
```

## 📊 监控内容

### 后端API服务
- **端口**: 3001
- **目录**: `/home/chenbang/app/netease/api-enhanced`
- **命令**: `node app.js`
- **健康检查**: `GET /login/status`

### 前端Vite服务
- **端口**: 6944
- **目录**: `/home/chenbang/app/netease/SPlayer`
- **命令**: `npx vite`
- **健康检查**: `GET /`

## 🔧 常用命令

### 守护脚本命令

```bash
# 查看所有服务状态
./service-guardian.sh status

# 启动所有服务
./service-guardian.sh start

# 停止所有服务
./service-guardian.sh stop

# 重启所有服务
./service-guardian.sh restart

# 执行一次监控检查
./service-guardian.sh monitor

# 查看帮助
./service-guardian.sh help
```

### 安装工具命令

```bash
# 查看守护系统状态
./install-guardian.sh status

# 查看最近50行日志
./install-guardian.sh logs

# 查看最近100行日志
./install-guardian.sh logs 100

# 测试守护脚本
./install-guardian.sh test

# 卸载Cron任务
./install-guardian.sh uninstall-cron

# 卸载Systemd服务
sudo ./install-guardian.sh uninstall-systemd
```

## 📝 日志管理

### 日志文件位置

- **守护主日志**: `/home/chenbang/app/netease/guardian.log`
- **Cron日志**: `/home/chenbang/app/netease/guardian.log.cron`
- **后端日志**: `/home/chenbang/app/netease/api-enhanced/api-3001.log`
- **前端日志**: `/home/chenbang/app/netease/SPlayer/vite-simple.log`

### 查看日志

```bash
# 查看守护日志（最近50行）
tail -50 guardian.log

# 实时查看日志
tail -f guardian.log

# 查看Cron日志
tail -50 guardian.log.cron

# 查看后端日志
tail -50 api-enhanced/api-3001.log

# 查看前端日志
tail -50 SPlayer/vite-simple.log
```

### 日志自动清理

守护脚本会自动限制日志大小，保留最近1000行记录。

## 🛠️ 故障排查

### 问题1: Cron任务未执行

```bash
# 检查Cron服务状态
sudo systemctl status cron

# 检查Cron任务列表
crontab -l

# 查看Cron执行日志
tail -100 guardian.log.cron

# 重新安装
./install-guardian.sh uninstall-cron
./install-guardian.sh install-cron
```

### 问题2: 服务频繁重启

守护脚本有30秒的重启冷却时间，如果看到"冷却中"提示，说明服务可能存在问题：

```bash
# 查看服务日志
tail -100 api-enhanced/api-3001.log
tail -100 SPlayer/vite-simple.log

# 手动测试服务
cd api-enhanced && node app.js
cd SPlayer && npx vite
```

### 问题3: 端口被占用

```bash
# 查看端口占用
lsof -i :3001
lsof -i :6944

# 清理僵尸进程
./service-guardian.sh stop
sleep 5
./service-guardian.sh start
```

### 问题4: 权限问题

```bash
# 确保脚本有执行权限
chmod +x service-guardian.sh
chmod +x install-guardian.sh
chmod +x quick-start.sh

# 确保PID文件目录可写
chmod 755 api-enhanced
chmod 755 SPlayer
```

## 🔔 监控逻辑

守护脚本采用三级检查机制：

1. **端口检查**: 检查服务端口是否被监听
2. **进程检查**: 检查PID文件中的进程是否存在
3. **健康检查**: 通过HTTP请求验证服务功能

只有当所有检查都通过时，才认为服务正常。

## ⚙️ 自定义配置

如需修改配置，编辑 `service-guardian.sh` 文件的配置部分：

```bash
# 后端API配置
BACKEND_DIR="${PROJECT_ROOT}/api-enhanced"
BACKEND_PORT=3001
BACKEND_CMD="node app.js"

# 前端Vite配置
FRONTEND_DIR="${PROJECT_ROOT}/SPlayer"
FRONTEND_PORT=6944
FRONTEND_CMD="npx vite"

# 监控间隔（修改Cron表达式）
# */3 * * * * 表示每3分钟
```

## 📱 访问地址

安装成功后，可通过以下地址访问：

- **本地访问**: http://localhost:6944
- **局域网访问**: http://YOUR_IP:6944

## 🔄 更新守护脚本

```bash
# 1. 停止定时任务
./install-guardian.sh uninstall-cron
# 或
sudo ./install-guardian.sh uninstall-systemd

# 2. 更新脚本文件
# （替换 service-guardian.sh）

# 3. 重新安装
./install-guardian.sh install-cron
# 或
sudo ./install-guardian.sh install-systemd
```

## 📞 技术支持

如遇到问题，请检查：

1. 守护日志: `guardian.log`
2. 服务日志: `api-3001.log` 和 `vite-simple.log`
3. 系统日志: `/var/log/syslog` (Ubuntu) 或 `journalctl`

## 📄 许可证

本守护系统与主项目保持一致的许可证。

---

**最后更新**: 2024-10-14
**版本**: 1.0.0
