# 部署脚本使用指南

生成时间: 2025-10-14 14:15

---

## 📦 脚本列表

### 1. `deploy.sh` - 手动部署脚本（推荐）
**用途**: 修改代码后手动触发一次完整部署

**特点**:
- ✅ 可控性强，按需执行
- ✅ 支持灵活参数
- ✅ 详细日志输出
- ✅ 部署验证

### 2. `auto-deploy.sh` - 自动监控部署脚本
**用途**: 后台持续监控源代码变化，自动触发部署

**特点**:
- ✅ 自动检测文件变化
- ✅ 10秒检查一次
- ✅ 无需手动干预
- ⚠️  需要后台运行

### 3. `service-guardian.sh` - 服务守护脚本
**用途**: 管理前后端服务的启动、停止、重启

**特点**:
- ✅ 服务进程管理
- ✅ 健康检查
- ✅ 状态监控

---

## 🚀 快速开始

### 场景1：修改代码后手动部署（最常用）

```bash
# 修改完代码后，执行一条命令完成部署
cd /home/chenbang/app/netease
./deploy.sh
```

**执行流程**:
1. 构建前端项目（npm run build）
2. 重启后端服务（杀死旧进程，启动新进程）
3. 重新加载Nginx配置
4. 验证部署状态
5. 显示访问地址

### 场景2：仅构建前端

```bash
cd /home/chenbang/app/netease
./deploy.sh --frontend-only
```

**适用于**: 只修改了前端代码，不需要重启后端

### 场景3：仅重启后端

```bash
cd /home/chenbang/app/netease
./deploy.sh --backend-only
```

**适用于**: 只修改了后端代码，前端不需要重新构建

### 场景4：自动监控部署（高级）

```bash
# 启动自动监控
cd /home/chenbang/app/netease
./auto-deploy.sh

# 在另一个终端修改代码
vim SPlayer/src/xxx.vue

# 脚本会自动检测变化并触发部署
# 按 Ctrl+C 停止监控
```

---

## 📋 命令参数详解

### deploy.sh 参数

| 参数 | 说明 | 示例 |
|------|------|------|
| (无参数) | 完整部署：前端构建+后端重启 | `./deploy.sh` |
| `--frontend-only` | 仅构建前端，跳过后端重启 | `./deploy.sh --frontend-only` |
| `--backend-only` | 仅重启后端，跳过前端构建 | `./deploy.sh --backend-only` |
| `--skip-frontend` | 跳过前端构建 | `./deploy.sh --skip-frontend` |
| `--skip-backend` | 跳过后端重启 | `./deploy.sh --skip-backend` |
| `--skip-verify` | 跳过部署验证 | `./deploy.sh --skip-verify` |
| `--help` | 显示帮助信息 | `./deploy.sh --help` |

---

## 📊 典型工作流程

### 开发流程A：使用Vite开发服务器（推荐开发时使用）

```bash
# 1. 启动Vite开发服务器
cd /home/chenbang/app/netease
./service-guardian.sh start

# 2. 访问开发环境
浏览器打开: http://localhost:6944

# 3. 修改代码
vim SPlayer/src/xxx.vue

# 4. 保存后自动热更新
# Vite会自动刷新浏览器，无需构建！✓

# 优点：
- 修改立即生效（热更新）
- 无需重新构建
- 开发效率高
```

### 开发流程B：使用Nginx生产环境（需要构建）

```bash
# 1. 修改代码
vim SPlayer/src/xxx.vue

# 2. 执行部署脚本
./deploy.sh

# 3. 浏览器强制刷新
Ctrl+Shift+R

# 4. 访问生产环境
浏览器打开: https://192.168.1.118:7899

# 缺点：
- 每次修改都要构建（耗时30-40秒）
- 需要手动执行部署脚本

# 优点：
- 生产环境测试
- 多设备访问（局域网）
- HTTPS安全连接
```

---

## 🎯 最佳实践

### 开发阶段
```bash
# 1. 使用Vite开发服务器
访问: http://localhost:6944

# 2. 修改代码后自动生效
无需执行任何命令！

# 3. 开发完成后，执行一次完整部署
./deploy.sh
```

### 生产测试
```bash
# 1. 确保所有修改已完成
# 2. 执行部署
./deploy.sh

# 3. 访问生产环境测试
访问: https://192.168.1.118:7899

# 4. 浏览器强制刷新
Ctrl+Shift+R
```

### 团队协作
```bash
# 场景：团队成员A修改了代码，团队成员B需要测试

# 成员A执行：
git pull
./deploy.sh
git add .
git commit -m "feat: 优化队列逻辑"
git push

# 成员B执行：
git pull
./deploy.sh
# 浏览器强制刷新测试
```

---

## 🛠️ 高级用法

### 1. 后台运行自动监控

```bash
# 启动自动监控（后台运行）
nohup ./auto-deploy.sh > auto-deploy.log 2>&1 &
echo $! > .auto-deploy.pid

# 查看监控日志
tail -f auto-deploy.log

# 停止自动监控
kill $(cat .auto-deploy.pid)
rm .auto-deploy.pid
```

### 2. 定时部署（Crontab）

```bash
# 编辑crontab
crontab -e

# 添加定时任务（每小时执行一次部署）
0 * * * * cd /home/chenbang/app/netease && ./deploy.sh --skip-verify >> deploy-cron.log 2>&1

# 或每天凌晨3点部署一次
0 3 * * * cd /home/chenbang/app/netease && ./deploy.sh >> deploy-cron.log 2>&1
```

### 3. Git Hook 自动部署

```bash
# 创建 .git/hooks/post-merge
cat > /home/chenbang/app/netease/.git/hooks/post-merge << 'EOF'
#!/bin/bash
echo "代码已更新，触发自动部署..."
cd /home/chenbang/app/netease
./deploy.sh
EOF

chmod +x /home/chenbang/app/netease/.git/hooks/post-merge

# 效果：git pull 后自动触发部署
```

---

## 📝 日志文件说明

| 日志文件 | 说明 | 位置 |
|---------|------|------|
| `deploy.log` | 手动部署日志 | `/home/chenbang/app/netease/deploy.log` |
| `auto-deploy.log` | 自动监控日志 | `/home/chenbang/app/netease/auto-deploy.log` |
| `api-3001.log` | 后端API日志 | `/home/chenbang/app/netease/api-enhanced/api-3001.log` |
| `vite-web.log` | Vite开发服务器日志 | `/home/chenbang/app/netease/SPlayer/vite-web.log` |
| `guardian.log` | 服务守护日志 | `/home/chenbang/app/netease/guardian.log` |

### 查看日志

```bash
# 查看最近的部署日志
tail -50 /home/chenbang/app/netease/deploy.log

# 实时监控后端日志
tail -f /home/chenbang/app/netease/api-enhanced/api-3001.log

# 查看构建过程
tail -f /home/chenbang/app/netease/SPlayer/vite-web.log
```

---

## 🔍 故障排查

### 问题1：部署后修改未生效

**检查步骤**:
```bash
# 1. 确认构建文件时间
ls -la /home/chenbang/app/netease/SPlayer/out/renderer/index.html

# 2. 确认构建是否成功
tail -30 /home/chenbang/app/netease/deploy.log | grep "构建成功"

# 3. 确认浏览器已强制刷新
# 按 Ctrl+Shift+R，不是普通刷新

# 4. 确认访问正确地址
# https://192.168.1.118:7899（生产环境）
# http://localhost:6944（开发环境）
```

### 问题2：构建失败

**可能原因**:
- Node.js内存不足
- 依赖包缺失
- 语法错误

**解决方法**:
```bash
# 查看构建日志
tail -100 /home/chenbang/app/netease/deploy.log

# 重新安装依赖
cd /home/chenbang/app/netease/SPlayer
rm -rf node_modules package-lock.json
npm install

# 再次尝试构建
./deploy.sh --frontend-only
```

### 问题3：后端启动失败

**检查步骤**:
```bash
# 查看后端日志
tail -50 /home/chenbang/app/netease/api-enhanced/api-3001.log

# 检查端口占用
netstat -tuln | grep 3001

# 手动启动后端
cd /home/chenbang/app/netease/api-enhanced
node app.js
```

### 问题4：Nginx问题

**检查配置**:
```bash
# 测试Nginx配置
nginx -t

# 重新加载Nginx
sudo nginx -s reload

# 查看Nginx日志
tail -50 /var/log/nginx/splayer_error.log
```

---

## 🎯 推荐工作流程

### 日常开发（推荐）

```bash
# 1. 启动服务
./service-guardian.sh start

# 2. 访问Vite开发服务器
http://localhost:6944

# 3. 开始开发
# 修改代码后Vite自动热更新，立即看到效果

# 4. 开发完成后，执行一次完整部署
./deploy.sh

# 5. 在生产环境测试
https://192.168.1.118:7899
```

### 快速迭代

```bash
# 只改前端
vim SPlayer/src/xxx.vue
./deploy.sh --frontend-only

# 只改后端
vim api-enhanced/xxx.js
./deploy.sh --backend-only

# 前后端都改
vim SPlayer/src/xxx.vue
vim api-enhanced/xxx.js
./deploy.sh
```

### 自动化开发

```bash
# 启动自动监控（后台运行）
nohup ./auto-deploy.sh > auto-deploy.log 2>&1 &

# 专注于开发，修改自动部署
vim SPlayer/src/xxx.vue
# 保存后10秒内自动部署

# 停止自动监控
pkill -f auto-deploy.sh
```

---

## 📚 相关文档

1. `deploy.sh` - 手动部署脚本
2. `auto-deploy.sh` - 自动监控部署脚本
3. `service-guardian.sh` - 服务守护脚本
4. `ROOT_CAUSE_ANALYSIS.md` - 根因分析报告
5. `QUEUE_LOGIC_FLOW.md` - 队列逻辑流程
6. `FINAL_QUEUE_SOLUTION.md` - 完整解决方案

---

## ⚡ 快速命令参考

```bash
# 完整部署
./deploy.sh

# 仅构建前端
./deploy.sh --frontend-only

# 仅重启后端
./deploy.sh --backend-only

# 启动服务
./service-guardian.sh start

# 停止服务
./service-guardian.sh stop

# 重启服务
./service-guardian.sh restart

# 查看服务状态
./service-guardian.sh status

# 查看部署日志
tail -f deploy.log

# 查看后端日志
tail -f api-enhanced/api-3001.log
```

---

## 🎉 立即测试

```bash
# 1. 执行首次完整部署
cd /home/chenbang/app/netease
./deploy.sh

# 2. 在浏览器中访问
https://192.168.1.118:7899

# 3. 强制刷新浏览器
Ctrl+Shift+R

# 4. 测试点歌队列功能
进入点歌队列页面 → 添加歌曲 → 播放 → 验证自动移除
```

---

## 💡 重要提示

### ⚠️ 必须执行的步骤

1. **修改代码后**: 必须执行 `./deploy.sh`
2. **部署完成后**: 必须在浏览器中 `Ctrl+Shift+R` 强制刷新
3. **使用生产环境**: 访问 `https://192.168.1.118:7899`，不是6944

### ✅ 验证修改是否生效

```bash
# 方法1: 检查构建文件时间
ls -la SPlayer/out/renderer/index.html
# 应该是刚刚的时间

# 方法2: 查看部署日志
tail -20 deploy.log | grep "构建成功"

# 方法3: 浏览器F12开发者工具
# Network标签 → 禁用缓存 → 刷新 → 查看JS文件时间
```

---

生成人: factory-droid[bot]
