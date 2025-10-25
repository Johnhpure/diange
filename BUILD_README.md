# 自动构建系统使用文档

## 📋 概述

为确保在 Nginx 生产环境下，前后端代码修改后用户能访问到最新版本，本项目提供了两个自动化构建脚本：

1. **`auto-build.sh`** - 按需构建脚本（推荐）
2. **`watch-and-build.sh`** - 文件监听自动构建脚本

## 🚀 快速开始

### 方式一：手动触发构建（推荐）

每次修改代码后，执行以下命令：

```bash
# 构建所有项目（前端 + 后端 + API）
bash auto-build.sh

# 仅构建前端（Vue项目）
bash auto-build.sh frontend

# 仅构建后端
bash auto-build.sh backend

# 清理后重新构建
bash auto-build.sh clean all
```

### 方式二：自动监听模式（开发时使用）

```bash
# 启动自动监听（需要安装 inotify-tools）
bash watch-and-build.sh auto

# 交互式手动构建
bash watch-and-build.sh manual
```

## 📖 详细说明

### auto-build.sh - 按需构建脚本

#### 功能特点
- ✅ 支持构建前端（SPlayer）、后端（server）、API Enhanced
- ✅ 自动检查并安装依赖（node_modules）
- ✅ 详细的构建日志（保存在 `build.log`）
- ✅ 彩色输出，清晰明了
- ✅ 错误检测与处理
- ✅ 可选的服务重启

#### 命令选项

| 选项 | 说明 |
|------|------|
| `all` | 构建所有项目【默认】 |
| `frontend` | 仅构建前端 Vue 项目（SPlayer） |
| `backend` | 仅构建后端服务（server） |
| `api` | 检查 API Enhanced 依赖 |
| `clean` | 清理所有构建产物 |
| `restart` | 重启相关服务 |
| `help` | 显示帮助信息 |

#### 使用示例

```bash
# 1. 修改了前端代码后
bash auto-build.sh frontend

# 2. 修改了后端代码后
bash auto-build.sh backend

# 3. 同时修改了前后端
bash auto-build.sh all

# 4. 清理旧构建产物后重新构建
bash auto-build.sh clean all

# 5. 构建完成后重启服务
bash auto-build.sh all
# 然后根据提示选择是否重启服务
```

#### 构建流程

```
开始构建
    ↓
检查目录是否存在
    ↓
检查并安装依赖（node_modules）
    ↓
执行 npm run build
    ↓
记录构建日志
    ↓
提示是否重启服务
    ↓
完成
```

### watch-and-build.sh - 文件监听自动构建

#### 功能特点
- ✅ 自动监听文件变化
- ✅ 智能防抖（避免频繁构建）
- ✅ 支持手动和自动两种模式
- ✅ 实时构建反馈

#### 前置要求

自动监听模式需要安装 `inotify-tools`：

```bash
sudo apt-get update
sudo apt-get install -y inotify-tools
```

#### 使用模式

**1. 自动监听模式**

```bash
bash watch-and-build.sh auto
```

启动后会自动监听以下文件变化：
- 前端：`SPlayer/src/**/*.{vue,js,ts,jsx,tsx,css,scss,sass,html}`
- 后端：`server/src/**/*.{js,ts,json}`

检测到变化后，等待 3 秒（防抖），然后自动触发构建。

按 `Ctrl+C` 停止监听。

**2. 手动交互模式**

```bash
bash watch-and-build.sh manual
```

提供交互式菜单，选择要构建的项目。

## 🔧 集成到开发流程

### 方案一：Git Hooks（推荐）

在提交代码前自动构建：

```bash
# 创建 pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "正在构建项目..."
bash /home/chenbang/app/netease/auto-build.sh all
if [ $? -ne 0 ]; then
    echo "构建失败，取消提交"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

### 方案二：部署脚本集成

将构建步骤集成到现有的 `deploy.sh` 中：

```bash
# 在 deploy.sh 中添加
bash /home/chenbang/app/netease/auto-build.sh all
```

### 方案三：定时任务

设置定时自动构建（例如每小时一次）：

```bash
# 编辑 crontab
crontab -e

# 添加以下行
0 * * * * bash /home/chenbang/app/netease/auto-build.sh all >> /home/chenbang/app/netease/build-cron.log 2>&1
```

### 方案四：IDE/编辑器集成

#### VS Code Tasks

在 `.vscode/tasks.json` 中添加：

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "构建所有项目",
      "type": "shell",
      "command": "bash auto-build.sh all",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "构建前端",
      "type": "shell",
      "command": "bash auto-build.sh frontend"
    },
    {
      "label": "构建后端",
      "type": "shell",
      "command": "bash auto-build.sh backend"
    }
  ]
}
```

快捷键：`Ctrl+Shift+B` 触发构建。

## 📁 构建产物位置

| 项目 | 构建产物路径 | Nginx 配置 |
|------|--------------|------------|
| 前端（SPlayer） | `SPlayer/out` | 静态文件目录 |
| 后端（server） | `server/dist` 或 `server/precompiled` | Node.js 运行 |
| API Enhanced | 无构建产物 | 直接运行 |

## 🔍 日志查看

构建日志保存在项目根目录：

```bash
# 查看最新构建日志
tail -f /home/chenbang/app/netease/build.log

# 查看监听日志
tail -f /home/chenbang/app/netease/watch-build.log
```

## ⚠️ 注意事项

1. **生产环境重要提示**
   - 修改前端（Vue）代码后**必须**执行 `npm run build`
   - Nginx 提供的是 `SPlayer/out` 目录中的静态文件
   - 不重新构建，用户访问的仍然是旧版本

2. **后端服务重启**
   - 构建后端后需要重启服务才能生效
   - 手动重启：`bash service-guardian.sh restart`
   - 或使用脚本：`bash auto-build.sh restart`

3. **依赖管理**
   - 脚本会自动检查 `node_modules`
   - 如果缺失会自动执行 `npm install`
   - 首次构建可能需要较长时间

4. **权限问题**
   - 确保脚本有执行权限：`chmod +x *.sh`
   - Nginx 重载需要 sudo 权限

## 🐛 故障排除

### 问题：构建失败

```bash
# 查看详细日志
cat build.log | grep ERROR

# 清理并重新构建
bash auto-build.sh clean all
```

### 问题：依赖安装失败

```bash
# 手动安装依赖
cd SPlayer && npm install
cd ../server && npm install
cd ../api-enhanced && npm install
```

### 问题：监听脚本无法启动

```bash
# 检查 inotify-tools
which inotifywait

# 安装
sudo apt-get install -y inotify-tools
```

### 问题：构建后 Nginx 仍显示旧版本

```bash
# 检查构建产物
ls -lh SPlayer/out

# 强制清空浏览器缓存（Ctrl+F5）

# 检查 Nginx 配置的静态文件路径
sudo nginx -T | grep root

# 重载 Nginx
sudo nginx -t && sudo nginx -s reload
```

## 📊 性能优化建议

1. **增量构建**
   - 仅构建修改的部分（frontend/backend）
   - 避免不必要的全量构建

2. **使用监听模式**
   - 开发时使用 `watch-and-build.sh auto`
   - 自动检测变化，提高效率

3. **并行构建**
   - 如果前后端独立，可以并行构建
   - 修改 `auto-build.sh` 使用 `&` 后台任务

4. **构建缓存**
   - 保留 `node_modules` 避免重复安装
   - 使用 npm ci 代替 npm install

## 🤝 最佳实践

### 日常开发流程

```bash
# 1. 开发前：启动自动监听
bash watch-and-build.sh auto

# 2. 开发中：自动构建

# 3. 开发完成：测试构建
bash auto-build.sh all

# 4. 部署前：清理重建
bash auto-build.sh clean all

# 5. 部署后：重启服务
bash auto-build.sh restart
```

### 团队协作

1. 将构建脚本加入版本控制
2. 在 README 中说明构建流程
3. 统一使用相同的构建命令
4. 定期检查构建日志

## 📞 支持

如有问题，请检查：
1. 构建日志：`build.log`
2. 监听日志：`watch-build.log`
3. 部署日志：`deploy.log`
4. 守护进程日志：`guardian.log`

---

**最后更新：** 2025-10-14  
**脚本版本：** 1.0  
**维护者：** 系统管理员
