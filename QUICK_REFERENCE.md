# 快速参考手册 - SPlayer + api-enhanced

> 一页纸速查表，包含所有关键命令和配置

---

## 🚀 快速部署（3 分钟）

### Docker 单容器（最简单）

```bash
# 1. 克隆仓库
git clone https://github.com/MoeFurina/SPlayer.git
cd SPlayer

# 2. 配置环境变量
cp .env.example .env
vim .env  # 修改 RENDERER_VITE_SITE_URL 为你的域名

# 3. 启动容器
docker-compose up -d

# 4. 访问应用
open http://localhost:7899
```

**检查运行状态**：
```bash
docker logs -f splayer
# 应看到：
# Nginx started
# Netease Cloud Music API server running @ http://0.0.0.0:3000
```

---

## 📋 环境变量速查表

### api-enhanced/.env（核心配置）

```env
# 必须开启（解灰功能）
ENABLE_GENERAL_UNBLOCK = true
ENABLE_FLAC = true

# 音源优先级（推荐顺序）
UNBLOCK_SOURCE = pyncmd,qq,bodian,migu,kugou,kuwo
FOLLOW_SOURCE_ORDER = true

# 生产环境 CORS
CORS_ALLOW_ORIGIN = "https://player.example.com"
```

### SPlayer/.env（核心配置）

```env
# Docker 部署
RENDERER_VITE_SERVER_URL = "/api"
RENDERER_VITE_SITE_URL = "http://your-domain.com"

# 分离部署
RENDERER_VITE_SERVER_URL = "https://api.example.com"
RENDERER_VITE_SITE_URL = "https://player.example.com"

# Electron 桌面版
MAIN_VITE_SERVER_PORT = 11451
MAIN_VITE_SERVER_HOST = 127.0.0.1
```

---

## 🔧 常用命令

### api-enhanced 启动命令

```bash
# 开发环境
node app.js

# 指定端口
PORT=11451 node app.js

# PM2 部署
pm2 start app.js --name ncm-api
pm2 logs ncm-api

# Docker 官方镜像
docker run -d -p 3000:3000 \
  -e ENABLE_GENERAL_UNBLOCK=true \
  moefurina/ncm-api:latest
```

### SPlayer 启动命令

```bash
# 开发环境
pnpm install
pnpm dev

# 构建桌面版
pnpm build:win    # Windows
pnpm build:linux  # Linux
pnpm build:mac    # MacOS

# 构建 Web 版
pnpm build
# 输出：out/renderer/

# Docker 部署
docker build -t splayer .
docker run -d -p 7899:7899 splayer
```

---

## 🔍 故障排查命令

### 检查 API 服务

```bash
# 测试 API 连通性
curl http://localhost:3000/

# 测试歌曲解灰
curl "http://localhost:3000/song/url?id=1234567"

# 检查进程
ps aux | grep node
netstat -tuln | grep 3000
```

### 检查 Docker 容器

```bash
# 查看容器状态
docker ps | grep splayer

# 查看日志
docker logs -f splayer

# 进入容器调试
docker exec -it splayer sh

# 检查 Nginx 配置
docker exec splayer cat /etc/nginx/conf.d/default.conf

# 测试内部 API
docker exec splayer wget -O- http://localhost:3000/
```

### 检查端口占用

```bash
# Linux/Mac
lsof -i :3000
lsof -i :7899
lsof -i :11451

# Windows
netstat -ano | findstr :3000
netstat -ano | findstr :7899
```

---

## 🌐 Nginx 配置模板

### Docker 内置 Nginx (nginx.conf)

```nginx
server {
    listen 7899;
    server_name localhost;
    
    # 前端静态文件
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }
    
    # API 反向代理
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 独立部署 Nginx

```nginx
# 前端服务器配置
server {
    listen 80;
    server_name player.example.com;
    
    location / {
        root /var/www/splayer;
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass https://api.example.com/;
        proxy_set_header Host $host;
        add_header Access-Control-Allow-Origin "https://player.example.com";
    }
}

# 后端 API 服务器配置
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

---

## 📊 端口映射表

| 服务              | 端口   | 协议   | 说明                      |
|-------------------|--------|--------|---------------------------|
| api-enhanced      | 3000   | HTTP   | 默认后端 API 端口          |
| SPlayer (Docker)  | 7899   | HTTP   | Docker 容器前端端口        |
| SPlayer (Electron)| 11451  | HTTP   | 桌面版内嵌 API 端口        |
| SPlayer (开发)    | 6944   | HTTP   | Vite 开发服务器           |

---

## 🛠️ API 接口速查

### 核心接口

```bash
# 歌曲播放地址（解灰）
GET /song/url?id=123456

# 歌词
GET /lyric?id=123456

# 搜索
GET /search?keywords=歌曲名

# 歌单详情
GET /playlist/detail?id=123456

# 用户登录
POST /login/cellphone
Body: { phone: "13800138000", password: "md5_password" }

# 二维码登录
GET /login/qr/key        # 获取 key
GET /login/qr/create     # 生成二维码
GET /login/qr/check      # 检查扫码状态

# 每日推荐
GET /recommend/songs

# 私人 FM
GET /personal_fm
```

### 解灰相关接口

```bash
# 检查歌曲是否可用
GET /check/music?id=123456

# 获取音乐详情
GET /song/detail?ids=123456,789012

# 多音质选择
GET /song/url?id=123456&br=999000  # 320kbps
GET /song/url?id=123456&br=1999000 # Hi-Res
```

---

## 🔐 环境变量完整清单

### api-enhanced/.env（全量）

```env
# CORS 配置
CORS_ALLOW_ORIGIN = "*"

# 代理设置
ENABLE_PROXY = false
PROXY_URL = "https://your-proxy-url.com/?proxy="

# 解灰功能
ENABLE_GENERAL_UNBLOCK = true
ENABLE_FLAC = true
SELECT_MAX_BR = false
UNBLOCK_SOURCE = pyncmd,qq,bodian,migu,kugou,kuwo
FOLLOW_SOURCE_ORDER = true

# Cookie 配置（可选）
NETEASE_COOKIE = ""
JOOX_COOKIE = ""
MIGU_COOKIE = ""
QQ_COOKIE = ""
YOUTUBE_KEY = ""
```

### SPlayer/.env（全量）

```env
# 程序配置
MAIN_VITE_TITLE = "SPlayer"
MAIN_VITE_MAIN_PORT = 7899
MAIN_VITE_DEV_PORT = 6944

# API 配置
MAIN_VITE_SERVER_HOST = 127.0.0.1
MAIN_VITE_SERVER_PORT = 11451
RENDERER_VITE_SERVER_URL = "/api"
RENDERER_VITE_SITE_URL = "https://player.example.com"
RENDERER_VITE_SITE_ROOT = false

# 程序信息
RENDERER_VITE_SITE_TITLE = "SPlayer"

# Cookie（仅 Electron）
MAIN_VITE_MIGU_COOKIE = ""

# 公告配置
RENDERER_VITE_ANN_TYPE = "info"
RENDERER_VITE_ANN_TITLE = "🎉新版本推出"
RENDERER_VITE_ANN_CONTENT = "新增解灰功能"
RENDERER_VITE_ANN_DURATION = 8000

# 捐赠入口
RENDERER_VITE_NO_DONATE = false
```

---

## 📦 依赖包版本锁定

### 关键版本

```json
{
  "@neteaseapireborn/api": "^4.29.8",
  "@unblockneteasemusic/server": "^0.28.0",
  "vue": "^3.5.22",
  "electron": "^35.7.5",
  "express": "^5.1.0",
  "axios": "^1.12.2"
}
```

### 更新检查

```bash
# SPlayer 依赖更新
cd SPlayer
pnpm outdated
pnpm update @neteaseapireborn/api

# api-enhanced 依赖更新
cd api-enhanced
pnpm outdated
pnpm update @unblockneteasemusic/server
```

---

## 🐞 常见错误及解决方案

| 错误现象                     | 原因                     | 解决方案                              |
|------------------------------|--------------------------|---------------------------------------|
| 歌曲无法播放                 | API 未启动               | `curl http://localhost:3000/`         |
| 解灰失败                     | `ENABLE_GENERAL_UNBLOCK=false` | 设置为 `true` 并重启            |
| CORS 错误                    | 跨域配置错误             | 配置 `CORS_ALLOW_ORIGIN`              |
| 404 Not Found                | Nginx 反向代理配置错误   | 检查 `location /api/` 配置            |
| Electron 启动失败            | 端口 11451 被占用        | `lsof -i :11451` 并杀死进程           |
| Docker 容器无法访问          | 端口映射错误             | `docker ps` 检查 `0.0.0.0:7899->7899` |
| 登录后 Cookie 丢失           | Cookie 未正确存储        | 检查浏览器 Cookie 设置                |

---

## 📝 部署检查清单

### 部署前检查

- [ ] 已安装 Node.js >= 18 / pnpm >= 8
- [ ] 已配置 `.env` 文件
- [ ] 已检查端口是否占用
- [ ] 已配置防火墙规则（生产环境）

### 部署后验证

- [ ] 访问首页是否正常加载
- [ ] 搜索功能是否可用
- [ ] 播放正常歌曲是否成功
- [ ] 播放灰色歌曲是否自动解灰
- [ ] 用户登录功能是否正常
- [ ] 歌词显示是否正常

### 性能检查

```bash
# 检查响应时间
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3000/song/url?id=123456

# 检查内存占用
docker stats splayer

# 检查 CPU 使用率
top -p $(pgrep node)
```

---

## 🔗 相关链接

- **SPlayer 仓库**: https://github.com/MoeFurina/SPlayer
- **api-enhanced 仓库**: https://github.com/neteasecloudmusicapienhanced/api-enhanced
- **UNM Server**: https://github.com/UnblockNeteaseMusic/server
- **在线演示**: https://player.focalors.ltd/
- **API 文档**: https://neteasecloudmusicapienhanced.js.org/

---

## 💡 最佳实践

1. **生产环境必须**：
   - ✅ 使用 HTTPS
   - ✅ 配置 CORS 白名单
   - ✅ 使用 PM2/Docker 守护进程
   - ✅ 配置日志轮转

2. **性能优化**：
   - ✅ 启用 Gzip 压缩
   - ✅ 配置 CDN 加速
   - ✅ API 响应缓存（Redis）

3. **安全加固**：
   - ✅ 敏感信息使用环境变量
   - ✅ 定期更新依赖包
   - ✅ 启用 CSP 头

---

**版本**: v1.0  
**更新**: 2024-01-01  
**格式**: Markdown 速查表