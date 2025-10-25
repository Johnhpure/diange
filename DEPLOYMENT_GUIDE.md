# SPlayer + api-enhanced 完整部署指南

> 本指南详细说明如何配置和部署 api-enhanced 后端服务，以支持 SPlayer 音乐播放器的正常运行

---

## 📋 目录

- [架构概述](#架构概述)
- [依存关系](#依存关系)
- [部署方案](#部署方案)
  - [方案一：Docker 单容器部署（推荐）](#方案一docker-单容器部署推荐)
  - [方案二：分离部署（Vercel/VPS）](#方案二分离部署vercelvps)
  - [方案三：Electron 桌面版](#方案三electron-桌面版)
- [配置详解](#配置详解)
- [常见问题](#常见问题)

---

## 架构概述

### 项目说明

**api-enhanced**
- 网易云音乐 API 后端服务（基于 NeteaseCloudMusicApi Reborn）
- NPM 包名：`@neteaseapireborn/api`
- 支持解灰功能（UnblockNeteaseMusic），可播放无版权/VIP 歌曲
- 多音源支持：PyncMD、QQ音乐、咪咕、酷狗、酷我等

**SPlayer**
- 基于 Vue 3 的现代音乐播放器
- 支持 Web 端和 Electron 桌面版
- 直接依赖 `@neteaseapireborn/api` 包

### 依存关系图

```
┌──────────────────────────────────────────────────┐
│                   用户浏览器                      │
│              访问 http://localhost:7899           │
└────────────────────┬─────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────┐
│              SPlayer 前端 (Vue 3)                 │
│  - 播放器界面                                     │
│  - 用户交互逻辑                                   │
│  - 发起 API 请求到 /api/*                        │
└────────────────────┬─────────────────────────────┘
                     │ HTTP 请求
                     │ axios.get('/api/song/url')
                     ▼
┌──────────────────────────────────────────────────┐
│            Nginx 反向代理（可选）                 │
│  location /api/ → http://localhost:3000/         │
└────────────────────┬─────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────┐
│          api-enhanced (Express Server)            │
│  - 端口：3000 (默认) 或 11451 (Electron)         │
│  - 网易云 API 封装                                │
│  - UnblockNeteaseMusic 解灰引擎                   │
│  - 多音源匹配：pyncmd/qq/migu/kuwo...            │
└──────────────────────────────────────────────────┘
```

---

## 依存关系

### SPlayer 如何依赖 api-enhanced

1. **包依赖声明**（SPlayer/package.json）
```json
{
  "dependencies": {
    "@neteaseapireborn/api": "^4.29.8"
  }
}
```

2. **API 调用逻辑**（SPlayer/src/utils/request.js）
```javascript
// Electron 环境：使用本地内嵌 API
if (checkPlatform.electron() || import.meta.env.RENDERER_VITE_SITE_ROOT === "true") {
  axios.defaults.baseURL = "/api";
} else {
  // Web 环境：使用环境变量配置的 API 地址
  axios.defaults.baseURL = import.meta.env.RENDERER_VITE_SERVER_URL;
}
```

3. **关键依赖点**
- ✅ 所有歌曲播放、歌词获取、用户登录功能都依赖 API 服务
- ✅ 解灰功能（播放无版权歌曲）需要 api-enhanced 的 UnblockNeteaseMusic 模块
- ✅ 多音源匹配优先级由 api-enhanced 的 `.env` 配置决定

---

## 部署方案

### 方案一：Docker 单容器部署（推荐）

> **适用场景**：个人自建服务器、VPS，需要快速一键部署

#### 特点
- ✅ 前端 (Nginx) + 后端 (API) 在同一容器
- ✅ 无需额外配置，开箱即用
- ✅ Nginx 自动处理反向代理

#### 部署步骤

**1. 准备环境变量**

创建 `SPlayer/.env` 文件：
```bash
cd SPlayer
cp .env.example .env
```

编辑 `.env`（保持默认值即可）：
```env
# API 配置（Docker 内部使用）
MAIN_VITE_SERVER_HOST = 127.0.0.1
MAIN_VITE_SERVER_PORT = 3000

# Web 前端 API 路径（通过 nginx 反向代理）
RENDERER_VITE_SERVER_URL = "/api"

# 站点地址（改成你的域名或 IP）
RENDERER_VITE_SITE_URL = "http://your-domain.com"
```

**2. 构建并启动容器**

```bash
# 方式 1：使用 docker-compose
docker-compose up -d

# 方式 2：手动构建
docker build -t splayer .
docker run -d \
  --name splayer \
  -p 7899:7899 \
  --restart always \
  splayer
```

**3. 访问应用**
打开浏览器访问：`http://localhost:7899`

#### 工作原理

SPlayer 的 Dockerfile 执行流程：
```dockerfile
# 第一阶段：构建前端
FROM node:18-alpine as builder
RUN pnpm install
RUN pnpm run build  # 输出到 out/renderer

# 第二阶段：运行环境
FROM nginx:1.25.3-alpine-slim
COPY --from=builder /app/out/renderer /usr/share/nginx/html
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf

# 安装 API 服务
RUN npm install @neteaseapireborn/api -g

# 同时启动 Nginx 和 API
CMD nginx && npx @neteaseapireborn/api@latest
```

Nginx 反向代理配置（nginx.conf）：
```nginx
server {
  listen 7899;
  
  # 前端静态文件
  location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;
  }
  
  # API 反向代理
  location /api/ {
    proxy_pass http://localhost:3000/;  # 转发到本地 API 服务
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

---

### 方案二：分离部署（Vercel/VPS）

> **适用场景**：前端部署在 Vercel，后端独立部署

#### 架构
```
前端 (Vercel)：https://player.example.com
后端 (VPS/Vercel)：https://api.example.com
```

#### 步骤 1：部署 api-enhanced 后端

**选项 A：Vercel 部署**

```bash
cd api-enhanced

# 1. 准备配置
cp .env.example .env
vim .env
```

编辑 `.env`：
```env
# 启用解灰功能
ENABLE_GENERAL_UNBLOCK = true
ENABLE_FLAC = true
SELECT_MAX_BR = false

# 音源优先级
UNBLOCK_SOURCE = pyncmd,qq,bodian,migu,kugou,kuwo
FOLLOW_SOURCE_ORDER = true

# CORS 配置（允许你的前端域名）
CORS_ALLOW_ORIGIN = "https://player.example.com"
```

```bash
# 2. 部署到 Vercel
npm install -g vercel
vercel
```

**选项 B：VPS/服务器部署**

```bash
cd api-enhanced

# 1. 安装依赖
pnpm install

# 2. 配置环境变量
cp .env.example .env
vim .env  # 同上配置

# 3. 启动服务（推荐使用 PM2）
pm2 start app.js --name netease-api

# 4. 配置 Nginx 反向代理
# /etc/nginx/sites-available/api.example.com
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**选项 C：Docker 独立部署**

```bash
cd api-enhanced

# 使用官方镜像
docker run -d \
  --name ncm-api \
  -p 3000:3000 \
  -e ENABLE_GENERAL_UNBLOCK=true \
  -e UNBLOCK_SOURCE=pyncmd,qq,bodian,migu,kugou,kuwo \
  --restart always \
  moefurina/ncm-api:latest

# 或自建镜像
docker build -t api-enhanced .
docker run -d -p 3000:3000 --restart always api-enhanced
```

#### 步骤 2：部署 SPlayer 前端

**配置环境变量**

编辑 `SPlayer/.env`：
```env
# 指向已部署的 API 地址
RENDERER_VITE_SERVER_URL = "https://api.example.com"

# 站点地址
RENDERER_VITE_SITE_URL = "https://player.example.com"

# 不使用同级域名 API
RENDERER_VITE_SITE_ROOT = false
```

**选项 A：Vercel 部署**

编辑 `SPlayer/vercel.json`（配置 API 重写）：
```json
{
  "rewrites": [
    {
      "source": "/:path",
      "destination": "/index.html"
    },
    {
      "source": "/api/:apiurl*",
      "destination": "https://api.example.com/:apiurl*"
    }
  ],
  "outputDirectory": "out/renderer"
}
```

```bash
# 部署
vercel
```

**选项 B：静态文件部署**

```bash
# 构建
pnpm install
pnpm build

# 将 out/renderer 目录部署到 Nginx/CDN
```

Nginx 配置：
```nginx
server {
    listen 80;
    server_name player.example.com;
    
    location / {
        root /var/www/splayer;
        try_files $uri $uri/ /index.html;
    }
    
    # API 反向代理
    location /api/ {
        proxy_pass https://api.example.com/;
        proxy_set_header Host $host;
    }
}
```

---

### 方案三：Electron 桌面版

> **适用场景**：用户本地使用，无需服务器

#### 特点
- ✅ API 服务内嵌在应用内
- ✅ 自动启动本地 API（端口 11451）
- ✅ 无需额外配置

#### 构建步骤

```bash
cd SPlayer

# 1. 安装依赖
pnpm install

# 2. 配置环境变量（使用默认配置即可）
cp .env.example .env

# 3. 根据平台构建
pnpm build:win    # Windows 打包
pnpm build:linux  # Linux 打包
pnpm build:mac    # MacOS 打包

# 4. 输出位置
# dist/ 目录下生成安装包
```

#### 工作原理

Electron 主进程启动 API 服务（electron/main/startNcmServer.js）：
```javascript
import netEaseApi from "@neteaseapireborn/api";

export const startNcmServer = async (options = { port: 11451, host: "127.0.0.1" }) => {
  const serverPort = await checkPort(options.port);
  options.port = serverPort;
  return await netEaseApi.serveNcmApi(options);
};
```

前端请求自动路由到本地 API：
```javascript
// src/utils/request.js
if (checkPlatform.electron()) {
  axios.defaults.baseURL = "/api";  // 通过 Electron 主进程代理
}
```

---

## 配置详解

### api-enhanced 环境变量

| 变量名                     | 默认值                                      | 说明                                    |
|---------------------------|---------------------------------------------|----------------------------------------|
| `PORT`                    | `3000`                                      | API 服务端口                            |
| `CORS_ALLOW_ORIGIN`       | `*`                                         | 允许的跨域来源（生产环境建议指定域名）   |
| `ENABLE_GENERAL_UNBLOCK`  | `true`                                      | 全局启用解灰功能（核心功能）            |
| `ENABLE_FLAC`             | `true`                                      | 启用无损音质（FLAC/Hi-Res）             |
| `SELECT_MAX_BR`           | `false`                                     | 是否选择最高码率                        |
| `UNBLOCK_SOURCE`          | `pyncmd,qq,bodian,migu,kugou,kuwo`         | 音源优先级列表（逗号分隔）              |
| `FOLLOW_SOURCE_ORDER`     | `true`                                      | 严格按音源顺序匹配                      |
| `NETEASE_COOKIE`          | `""`                                        | 网易云 Cookie（MUSIC_U）                |
| `QQ_COOKIE`               | `""`                                        | QQ音乐 Cookie                           |
| `MIGU_COOKIE`             | `""`                                        | 咪咕音乐 Cookie                         |

**推荐配置**（api-enhanced/.env）：
```env
# 核心功能
ENABLE_GENERAL_UNBLOCK = true
ENABLE_FLAC = true
SELECT_MAX_BR = false

# 音源配置（推荐顺序）
UNBLOCK_SOURCE = pyncmd,qq,bodian,migu,kugou,kuwo
FOLLOW_SOURCE_ORDER = true

# CORS（生产环境）
CORS_ALLOW_ORIGIN = "https://your-domain.com"
```

### SPlayer 环境变量

| 变量名                        | 默认值                            | 说明                              |
|------------------------------|-----------------------------------|-----------------------------------|
| `MAIN_VITE_SERVER_HOST`      | `127.0.0.1`                       | Electron 本地 API 地址            |
| `MAIN_VITE_SERVER_PORT`      | `11451`                           | Electron 本地 API 端口            |
| `RENDERER_VITE_SERVER_URL`   | `"/api"`                          | Web 环境 API 路径                 |
| `RENDERER_VITE_SITE_URL`     | `"https://player.example.com"`    | 站点地址（用于解决跨域）          |
| `RENDERER_VITE_SITE_ROOT`    | `false`                           | 是否使用同级域名 API              |
| `RENDERER_VITE_MAIN_PORT`    | `7899`                            | Electron 应用主端口               |

**Docker 部署推荐配置**（SPlayer/.env）：
```env
MAIN_VITE_SERVER_PORT = 3000
RENDERER_VITE_SERVER_URL = "/api"
RENDERER_VITE_SITE_URL = "http://your-ip:7899"
RENDERER_VITE_SITE_ROOT = false
```

**分离部署推荐配置**（SPlayer/.env）：
```env
RENDERER_VITE_SERVER_URL = "https://api.example.com"
RENDERER_VITE_SITE_URL = "https://player.example.com"
RENDERER_VITE_SITE_ROOT = false
```

---

## 常见问题

### 1. 歌曲无法播放 / 显示灰色

**原因**：API 服务未启动或解灰功能未开启

**解决方案**：
```bash
# 检查 api-enhanced 是否运行
curl http://localhost:3000/

# 确认解灰配置
cat api-enhanced/.env | grep ENABLE_GENERAL_UNBLOCK
# 应输出：ENABLE_GENERAL_UNBLOCK = true

# Docker 环境检查容器日志
docker logs splayer
# 应看到：Netease Cloud Music API server running @ http://0.0.0.0:3000
```

### 2. CORS 跨域错误

**现象**：浏览器控制台显示 `Access-Control-Allow-Origin` 错误

**解决方案**：

方案 A - 修改 api-enhanced CORS 配置：
```env
# api-enhanced/.env
CORS_ALLOW_ORIGIN = "https://player.example.com"
```

方案 B - 使用 Nginx 反向代理：
```nginx
location /api/ {
    proxy_pass http://api-backend:3000/;
    add_header Access-Control-Allow-Origin "https://player.example.com";
    add_header Access-Control-Allow-Credentials "true";
}
```

方案 C - 使用 SPlayer 的同级域名 API 模式：
```env
# SPlayer/.env
RENDERER_VITE_SITE_ROOT = true
```

并在 `vercel.json` 配置重写：
```json
{
  "rewrites": [
    {
      "source": "/api/:apiurl*",
      "destination": "https://api.example.com/:apiurl*"
    }
  ]
}
```

### 3. Docker 部署后 API 无响应

**检查步骤**：

```bash
# 1. 进入容器检查进程
docker exec -it splayer sh
ps aux | grep node
# 应看到 node 进程运行 @neteaseapireborn/api

# 2. 检查端口监听
netstat -tuln | grep 3000
# 应看到 0.0.0.0:3000 LISTEN

# 3. 测试 API 接口
curl http://localhost:3000/
# 应返回 API 文档页面

# 4. 检查 Nginx 配置
cat /etc/nginx/conf.d/default.conf
# 确认 proxy_pass http://localhost:3000/;
```

### 4. Electron 版本启动失败

**常见原因**：
- 端口 11451 被占用
- 依赖安装不完整

**解决方案**：
```bash
# 检查端口占用
lsof -i :11451  # Mac/Linux
netstat -ano | findstr :11451  # Windows

# 重新安装依赖
cd SPlayer
rm -rf node_modules pnpm-lock.yaml
pnpm install

# 清除 Electron 缓存
rm -rf ~/.cache/electron
```

### 5. 音源匹配失败（解灰不生效）

**检查配置**：
```bash
# api-enhanced/.env
UNBLOCK_SOURCE = pyncmd,qq,bodian,migu,kugou,kuwo
FOLLOW_SOURCE_ORDER = true
```

**测试音源**：
```bash
# 测试解灰接口
curl "http://localhost:3000/song/url?id=1234567&realIP=116.25.146.177"
```

**推荐音源顺序**：
- `pyncmd`：PyncMD 音源（推荐优先）
- `qq`：QQ音乐
- `migu`：咪咕音乐
- `kuwo`：酷我音乐
- `kugou`：酷狗音乐

### 6. Vercel 部署后无法登录

**原因**：Vercel 无服务器函数不支持持久化 Cookie

**解决方案**：
- 使用服务器部署 api-enhanced（VPS/Docker）
- 或使用 Vercel KV 存储 Cookie（需修改代码）

---

## 快速部署清单

### ✅ Docker 单容器（最简单）

```bash
cd SPlayer
cp .env.example .env
# 编辑 .env，修改 RENDERER_VITE_SITE_URL
docker-compose up -d
# 访问 http://localhost:7899
```

### ✅ 分离部署（生产环境）

**后端**：
```bash
cd api-enhanced
cp .env.example .env
# 配置 ENABLE_GENERAL_UNBLOCK=true 和音源
docker run -d -p 3000:3000 --env-file .env moefurina/ncm-api:latest
```

**前端**：
```bash
cd SPlayer
cp .env.example .env
# 配置 RENDERER_VITE_SERVER_URL 指向后端地址
pnpm build
# 部署 out/renderer 到 Nginx/Vercel
```

---

## 总结

### 推荐部署方式

| 场景                | 推荐方案              | 复杂度 | 适用人群        |
|---------------------|-----------------------|--------|----------------|
| 个人自建服务器      | Docker 单容器         | ⭐      | 所有用户       |
| 生产环境/团队       | 分离部署（VPS+Vercel）| ⭐⭐⭐   | 有运维经验者   |
| 本地使用            | Electron 桌面版       | ⭐⭐    | 普通用户       |
| 无服务器环境        | Vercel 双部署         | ⭐⭐⭐⭐  | 高级用户       |

### 核心要点

1. ✅ **api-enhanced 必须开启 `ENABLE_GENERAL_UNBLOCK=true`** 才能解灰
2. ✅ **Docker 部署最简单**，Nginx 自动处理反向代理
3. ✅ **分离部署需要配置 CORS** 或使用 Nginx 反向代理
4. ✅ **Electron 版本无需额外配置**，API 自动内嵌
5. ✅ **音源顺序影响解灰效果**，推荐 `pyncmd,qq,migu,kuwo`

---

**部署完成后测试清单**：
- [ ] 访问首页是否正常加载
- [ ] 搜索歌曲功能是否可用
- [ ] 播放正常歌曲是否成功
- [ ] 播放灰色歌曲是否自动解灰
- [ ] 用户登录功能是否正常
- [ ] 歌词显示是否正常

如有问题，请查看项目 Issues 或参考本指南的 [常见问题](#常见问题) 章节。