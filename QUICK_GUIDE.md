# 🚀 网易云音乐服务守护系统 - 快速上手指南

## ✅ 已完成安装

守护系统已成功安装并配置！

### 当前状态

- ✅ **后端API服务**: 运行在 3001 端口
- ✅ **前端Vite服务**: 运行在 6944 端口  
- ✅ **Cron守护任务**: 每3分钟自动检查
- ✅ **自动恢复**: 服务异常时自动重启

### 访问地址

- **本地**: http://localhost:6944
- **局域网**: http://192.168.1.118:6944

---

## 📖 常用命令速查表

### 快速操作

```bash
# 切换到项目目录
cd /home/chenbang/app/netease

# 查看服务状态
./quick-start.sh status

# 启动所有服务
./quick-start.sh start

# 停止所有服务
./quick-start.sh stop

# 重启所有服务
./quick-start.sh restart
```

### 查看日志

```bash
# 查看守护日志（最近50行）
./install-guardian.sh logs

# 查看更多日志
./install-guardian.sh logs 100

# 实时监控日志
tail -f guardian.log

# 查看Cron执行日志
tail -f guardian.log.cron
```

### 守护系统管理

```bash
# 查看守护系统状态
./install-guardian.sh status

# 手动执行一次监控
./service-guardian.sh monitor

# 测试守护脚本
./install-guardian.sh test
```

---

## 🔧 工作原理

### 自动监控流程

```
每3分钟执行
    ↓
检查后端API (3001端口)
    ↓ 异常
自动重启后端
    ↓
检查前端Vite (6944端口)
    ↓ 异常
自动重启前端
    ↓
记录日志
```

### 三重检查机制

1. **端口检查**: 确认端口是否被监听
2. **进程检查**: 确认PID进程是否存在
3. **健康检查**: 通过HTTP验证服务可用性

---

## 📊 监控报告示例

### 正常运行

```log
[2025-10-14 00:36:42] [INFO] 检查后端API服务状态...
[2025-10-14 00:36:43] [INFO] 后端API服务运行正常 (端口: 3001)
[2025-10-14 00:36:43] [INFO] 检查前端Vite服务状态...
[2025-10-14 00:36:45] [INFO] 前端Vite服务运行正常 (端口: 6944)
[2025-10-14 00:36:45] [INFO] ✅ 所有服务运行正常
```

### 自动恢复

```log
[2025-10-14 00:40:00] [WARN] 后端API端口 3001 未被监听
[2025-10-14 00:40:00] [ERROR] 后端API服务异常，尝试重启...
[2025-10-14 00:40:05] [INFO] 后端API服务启动成功 (PID: 123456)
[2025-10-14 00:40:07] [INFO] 后端API端口监听确认成功
[2025-10-14 00:40:10] [INFO] 后端API服务重启成功
```

---

## 🎯 使用场景

### 场景1: 服务崩溃自动恢复

**问题**: 后端API由于内存溢出崩溃  
**守护动作**: 
1. 下次检查时发现服务异常
2. 自动清理旧进程
3. 重新启动服务
4. 验证服务正常
5. 记录日志

**结果**: 最多3分钟内自动恢复

### 场景2: 端口被占用

**问题**: 系统重启后端口被其他进程占用  
**守护动作**:
1. 检测到端口被占用
2. 尝试清理占用端口的node进程
3. 重新启动服务
4. 验证成功

### 场景3: 服务假死

**问题**: 进程存在但无法响应HTTP请求  
**守护动作**:
1. 端口检查通过
2. 进程检查通过
3. 健康检查失败（HTTP超时）
4. 判定为假死，重启服务

---

## 🔍 故障自查

### 问题1: Cron任务未执行

```bash
# 检查Cron服务
sudo systemctl status cron

# 查看Cron日志
cat guardian.log.cron

# 手动测试
./service-guardian.sh monitor
```

### 问题2: 服务无法启动

```bash
# 查看服务日志
tail -100 api-enhanced/api-3001.log
tail -100 SPlayer/vite-simple.log

# 手动测试启动
cd api-enhanced && node app.js
cd SPlayer && npx vite
```

### 问题3: 日志文件过大

```bash
# 守护脚本会自动限制日志大小（保留1000行）
# 如需手动清理：
> guardian.log
> guardian.log.cron
```

---

## 🎨 自定义配置

如需修改监控间隔或其他配置，编辑相应文件：

### 修改监控间隔

```bash
# 编辑Cron任务
crontab -e

# 修改为每5分钟
*/5 * * * * /home/chenbang/app/netease/service-guardian.sh monitor >> ...

# 修改为每1分钟（不建议，可能过于频繁）
*/1 * * * * /home/chenbang/app/netease/service-guardian.sh monitor >> ...
```

### 修改端口配置

编辑 `service-guardian.sh`：

```bash
# 后端API端口
BACKEND_PORT=3001

# 前端Vite端口  
FRONTEND_PORT=6944
```

### 修改重启冷却时间

编辑 `service-guardian.sh`：

```bash
# 重启间隔（秒）
RESTART_COOLDOWN=30  # 改为60秒或其他值
```

---

## 📞 常见问题

### Q1: 如何临时停止守护？

```bash
# 方法1: 临时禁用Cron任务
crontab -e
# 在任务行前添加 # 注释

# 方法2: 完全卸载
./install-guardian.sh uninstall-cron

# 恢复时重新安装
./install-guardian.sh install-cron
```

### Q2: 如何查看历史监控记录？

```bash
# 查看主日志
cat guardian.log

# 查看Cron日志
cat guardian.log.cron

# 按时间段查询
grep "2025-10-14 10:" guardian.log
```

### Q3: 守护任务占用太多资源？

守护任务本身非常轻量：
- 每3分钟执行一次
- 检查耗时: 2-5秒
- 内存占用: <10MB
- CPU占用: 几乎可忽略

如有问题，可能是被监控的服务本身有问题。

### Q4: 可以监控其他服务吗？

可以！编辑 `service-guardian.sh`，参考现有的 `check_backend` 和 `start_backend` 函数，添加新的服务检查逻辑。

---

## 📚 完整文档

详细文档请查看: `GUARDIAN_README.md`

---

## ⚡ 快速命令参考卡

```
查看状态:   ./quick-start.sh status
启动服务:   ./quick-start.sh start
停止服务:   ./quick-start.sh stop
重启服务:   ./quick-start.sh restart
查看日志:   ./install-guardian.sh logs
系统状态:   ./install-guardian.sh status
```

---

**最后更新**: 2025-10-14  
**版本**: 1.0.0  
**状态**: ✅ 运行中
