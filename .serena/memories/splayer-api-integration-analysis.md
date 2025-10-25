# SPlayer 与 api-enhanced 集成分析

## 项目概述

### api-enhanced
- **项目类型**: Node.js 后端 API 服务
- **版本**: v4.29.9
- **NPM 包名**: @neteaseapireborn/api
- **技术栈**: Express.js + @unblockneteasemusic/server
- **默认端口**: 3000
- **核心功能**: 网易云音乐 API + 解灰功能（支持多音源：pyncmd, qq, bodian, migu, kugou, kuwo）

### SPlayer
- **项目类型**: Vue 3 音乐播放器（支持 Web + Electron 桌面版）
- **版本**: v2.7.36
- **技术栈**: Vue 3 + Vite + Electron + Naive UI
- **依赖关系**: package.json 中声明依赖 `@neteaseapireborn/api: ^4.29.8`

## 依存关系架构

```
┌─────────────────────────────────────────────┐
│              SPlayer (前端)                  │
│  - Vue 3 单页应用                            │
│  - 音乐播放、歌词显示、用户交互              │
└──────────────┬──────────────────────────────┘
               │ HTTP 请求 (/api/*)
               ▼
┌─────────────────────────────────────────────┐
│         api-enhanced (后端 API)              │
│  - @neteaseapireborn/api                     │
│  - 网易云音乐 API 封装                       │
│  - UnblockNeteaseMusic 解灰功能              │
└─────────────────────────────────────────────┘
```

## API 调用机制

### SPlayer 请求配置 (src/utils/request.js)

```js
// Electron 环境或 SITE_ROOT=true
if (checkPlatform.electron() || import.meta.env.RENDERER_VITE_SITE_ROOT === "true") {
  axios.defaults.baseURL = "/api";
} else {
  // Web 环境
  axios.defaults.baseURL = import.meta.env.RENDERER_VITE_SERVER_URL;
}
```

### 三种部署模式的 API 配置

#### 1. Electron 桌面版
- **API 服务**: 内嵌在应用内部
- **启动文件**: `electron/main/startNcmServer.js`
- **端口**: 11451 (MAIN_VITE_SERVER_PORT)
- **调用方式**: `/api` 路径通过 Electron 主进程代理到 localhost:11451

#### 2. Docker 容器化部署
- **架构**: Nginx (前端) + API 服务在同一容器
- **前端端口**: 7899
- **API 端口**: 3000 (内部)
- **反向代理**: nginx.conf 配置 `/api/` → `http://localhost:3000/`

#### 3. Vercel/云平台部署
- **架构**: 前端和 API 分离部署
- **前端**: 纯静态文件 (out/renderer)
- **API**: 独立部署在外部域名
- **配置**: vercel.json 重写规则 `/api/*` → 外部 API 域名

## 关键配置文件

### api-enhanced/.env
```env
# 核心解灰功能配置
ENABLE_GENERAL_UNBLOCK = true          # 启用全局解灰
ENABLE_FLAC = true                     # 启用无损音质
SELECT_MAX_BR = false                  # 是否选择最高码率
UNBLOCK_SOURCE = pyncmd,qq,bodian,migu,kugou,kuwo  # 音源优先级
FOLLOW_SOURCE_ORDER = true             # 严格按音源顺序匹配
```

### SPlayer/.env
```env
# Electron 版本 API 配置
MAIN_VITE_SERVER_HOST = 127.0.0.1     # 本地 API 地址
MAIN_VITE_SERVER_PORT = 11451          # 本地 API 端口

# Web 版本 API 配置
RENDERER_VITE_SERVER_URL = "/api"     # API 路径（需配合反向代理）
RENDERER_VITE_SITE_URL = "https://player.example.com"  # 站点地址
RENDERER_VITE_SITE_ROOT = false        # 是否使用同级域名 API
```

## 部署依赖关系

### 必须先部署 api-enhanced 的场景
1. ✅ **Vercel/云平台分离部署**: SPlayer 前端需要指向已部署的 API 服务器
2. ❌ **Docker 单容器部署**: 前端和 API 在同一容器，通过 nginx 反向代理
3. ❌ **Electron 桌面版**: API 作为 NPM 依赖打包进应用

### Docker 部署流程
SPlayer 的 Dockerfile 已经包含了 API 服务的启动：
```dockerfile
# 安装 API
RUN npm install @neteaseapireborn/api -g
# 同时启动 Nginx 和 API
CMD nginx && npx @neteaseapireborn/api@latest
```

## 环境变量映射关系

| SPlayer 配置                      | api-enhanced 配置          | 说明                |
|-----------------------------------|----------------------------|---------------------|
| RENDERER_VITE_SERVER_URL          | -                          | 外部 API 地址       |
| MAIN_VITE_SERVER_PORT (11451)    | PORT (3000)                | API 服务端口        |
| -                                 | ENABLE_GENERAL_UNBLOCK     | 解灰功能开关        |
| -                                 | UNBLOCK_SOURCE             | 解灰音源配置        |

## 启动命令

### api-enhanced
```bash
# 开发环境
node app.js

# 指定端口
PORT=11451 node app.js

# Docker
docker run -p 3000:3000 moefurina/ncm-api:latest
```

### SPlayer
```bash
# 开发环境（Web）
pnpm dev

# 构建 Electron 应用
pnpm build:win   # Windows
pnpm build:linux # Linux
pnpm build:mac   # MacOS

# Docker 构建
docker build -t splayer .
docker run -p 7899:7899 splayer
```