# 🎉 SPlayer + api-enhanced 部署成功！

## 📋 部署摘要

**部署时间**: 2025-10-13  
**部署方式**: 方案 B - 分离部署  
**服务器 IP**: 192.168.1.118  
**部署架构**: 前后端分离 + Nginx 反向代理

---

## ✅ 已部署服务

### 1. api-enhanced (后端 API 服务)
- **端口**: 3001
- **进程状态**: 运行中 (nohup 后台进程)
- **访问地址**: http://192.168.1.118:3001
- **日志位置**: /tmp/api-enhanced.log
- **配置文件**: /home/chenbang/app/netease/api-enhanced/.env
- **解灰功能**: ✅ 已启用
- **音源优先级**: pyncmd → qq → bodian → migu → kugou → kuwo

### 2. SPlayer (前端)
- **端口**: 7899
- **Web 服务器**: Nginx
- **访问地址**: http://192.168.1.118:7899
- **静态文件目录**: /home/chenbang/app/netease/SPlayer/out/renderer
- **Nginx 配置**: /etc/nginx/sites-available/splayer
- **API 配置**: 指向 http://192.168.1.118:3001

---

## 🌐 访问方式

### 从局域网内任意设备访问

**前端界面**:  
```
http://192.168.1.118:7899
```

**后端 API**:  
```
http://192.168.1.118:3001
```

### 测试 API 接口
```bash
# 测试搜索
curl "http://192.168.1.118:3001/search?keywords=周杰伦&limit=1"

# 测试获取歌曲 URL（包含解灰）
curl "http://192.168.1.118:3001/song/url?id=347230"
```

---

## 🔧 服务管理命令

### api-enhanced 服务管理

#### 查看进程状态
```bash
ps aux | grep "node app.js" | grep -v grep
```

#### 查看日志
```bash
tail -f /tmp/api-enhanced.log
```

#### 停止服务
```bash
pkill -f "node app.js"
```

#### 启动服务
```bash
cd /home/chenbang/app/netease/api-enhanced
PORT=3001 nohup node app.js > /tmp/api-enhanced.log 2>&1 &
```

#### 重启服务
```bash
pkill -f "node app.js"
cd /home/chenbang/app/netease/api-enhanced
PORT=3001 nohup node app.js > /tmp/api-enhanced.log 2>&1 &
```

### Nginx 服务管理

#### 重启 Nginx
```bash
sudo systemctl reload nginx
```

#### 检查配置
```bash
sudo nginx -t
```

#### 查看日志
```bash
tail -f /var/log/nginx/splayer_access.log
tail -f /var/log/nginx/splayer_error.log
```

---

## 📁 关键文件位置

```
/home/chenbang/app/netease/
├── api-enhanced/                     # 后端 API 项目
│   ├── .env                         # API 配置文件（包含解灰设置）
│   ├── app.js                       # 启动入口
│   └── node_modules/                # 依赖包
│
├── SPlayer/                          # 前端项目
│   ├── .env                         # 前端配置文件
│   ├── out/renderer/                # 构建后的静态文件（Nginx 托管）
│   └── node_modules/                # 依赖包
│
└── DEPLOYMENT_SUCCESS.md            # 本文档

/etc/nginx/sites-available/splayer    # Nginx 配置文件
/tmp/api-enhanced.log                  # API 服务日志
```

---

## 🔐 安全配置

### 防火墙状态
```bash
# 当前防火墙未启用
ufw status
# 状态：不活动
```

### 端口开放情况
- ✅ 7899: SPlayer 前端（Nginx）
- ✅ 3001: api-enhanced 后端 API
- ⚠️ 3000: 已被其他服务占用（temp-wechat-server.js）

---

## 🚀 核心配置说明

### api-enhanced/.env（关键配置）
```env
# 核心解灰功能（必须开启）
ENABLE_GENERAL_UNBLOCK = true
ENABLE_FLAC = true
SELECT_MAX_BR = false

# 音源优先级配置
UNBLOCK_SOURCE = pyncmd,qq,bodian,migu,kugou,kuwo
FOLLOW_SOURCE_ORDER = true
```

### SPlayer/.env（关键配置）
```env
# API 服务地址（分离部署）
RENDERER_VITE_SERVER_URL = "http://192.168.1.118:3001"

# 站点地址（局域网访问）
RENDERER_VITE_SITE_URL = "http://192.168.1.118:7899"
```

### Nginx 配置（/etc/nginx/sites-available/splayer）
```nginx
server {
    listen 7899;
    server_name 192.168.1.118;
    
    root /home/chenbang/app/netease/SPlayer/out/renderer;
    index index.html;
    
    # SPA 路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## ✨ 功能验证清单

### 后端 API 验证
- [x] API 服务启动成功（端口 3001）
- [x] 搜索接口可用
- [x] 歌曲 URL 获取接口可用（包含解灰）
- [x] 解灰功能已启用
- [x] 多音源配置正确

### 前端验证
- [x] Nginx 服务运行正常（端口 7899）
- [x] 静态文件可访问（HTTP 200）
- [x] 前端配置指向正确的 API 地址
- [x] 文件权限配置正确

### 网络验证
- [x] 局域网可访问前端（http://192.168.1.118:7899）
- [x] 局域网可访问 API（http://192.168.1.118:3001）
- [x] 端口监听正常（0.0.0.0:7899, :::3001）

---

## 📊 部署架构图

```
┌─────────────────────────────────────────────────────────────┐
│         局域网内的任意设备（浏览器访问）                        │
│              http://192.168.1.118:7899                       │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP 请求
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Nginx (端口 7899) - Ubuntu 服务器 192.168.1.118            │
│  - 托管 SPlayer 静态文件                                     │
│  - /home/chenbang/app/netease/SPlayer/out/renderer          │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ 前端发起 API 请求
                         │ axios.get('http://192.168.1.118:3001/...')
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  api-enhanced (端口 3001) - Node.js 后台进程                 │
│  - Express.js 服务器                                         │
│  - UnblockNeteaseMusic 解灰引擎                              │
│  - 音源: pyncmd/qq/bodian/migu/kugou/kuwo                   │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ 调用外部 API / 匹配音源
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  网易云音乐 API + 多音源服务                                  │
│  - music.163.com                                             │
│  - QQ音乐、咪咕、酷狗、酷我等                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 下一步操作建议

### 1. 设置开机自启动

#### api-enhanced 自启动（使用 systemd）
创建 systemd 服务文件：
```bash
sudo nano /etc/systemd/system/api-enhanced.service
```

内容：
```ini
[Unit]
Description=Netease Cloud Music API Enhanced
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/chenbang/app/netease/api-enhanced
Environment="PORT=3001"
ExecStart=/root/.nvm/versions/node/v18.20.8/bin/node app.js
Restart=always
RestartSec=10
StandardOutput=append:/var/log/api-enhanced.log
StandardError=append:/var/log/api-enhanced.log

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable api-enhanced
sudo systemctl start api-enhanced
sudo systemctl status api-enhanced
```

### 2. 配置反向代理（可选）
如果需要通过 Nginx 代理 API，可在 Nginx 配置中启用：
```nginx
location /api/ {
    proxy_pass http://127.0.0.1:3001/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

然后修改 SPlayer .env：
```env
RENDERER_VITE_SERVER_URL = "/api"
```

### 3. 启用 HTTPS（可选）
使用 Let's Encrypt 免费证书：
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### 4. 性能优化建议
- ✅ 已启用 Gzip 压缩
- ✅ 已配置静态资源缓存（1年）
- 考虑使用 PM2 管理 Node.js 进程
- 考虑配置 Redis 缓存 API 响应

---

## 🐛 故障排查

### 前端无法访问
```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查端口监听
netstat -tuln | grep 7899

# 检查文件权限
ls -la /home/chenbang/app/netease/SPlayer/out/renderer/

# 查看错误日志
tail -f /var/log/nginx/splayer_error.log
```

### API 服务异常
```bash
# 检查进程
ps aux | grep "node app.js"

# 查看日志
tail -f /tmp/api-enhanced.log

# 测试 API
curl http://127.0.0.1:3001/

# 重启服务
pkill -f "node app.js"
cd /home/chenbang/app/netease/api-enhanced
PORT=3001 nohup node app.js > /tmp/api-enhanced.log 2>&1 &
```

### 解灰功能不生效
```bash
# 检查配置
cat /home/chenbang/app/netease/api-enhanced/.env | grep ENABLE_GENERAL_UNBLOCK
# 应输出: ENABLE_GENERAL_UNBLOCK = true

# 测试解灰接口
curl "http://192.168.1.118:3001/song/url?id=1969519579"
# 查看返回的 url 字段是否有值
```

---

## 📞 联系信息

**项目地址**:
- SPlayer: https://github.com/MoeFurina/SPlayer
- api-enhanced: https://github.com/neteasecloudmusicapienhanced/api-enhanced

**部署文档**:
- 完整部署指南: /home/chenbang/app/netease/DEPLOYMENT_GUIDE.md
- 架构分析: /home/chenbang/app/netease/ARCHITECTURE.md
- 快速参考: /home/chenbang/app/netease/QUICK_REFERENCE.md

---

## ✅ 部署完成确认

- [x] api-enhanced 服务运行在端口 3001
- [x] SPlayer 前端部署在端口 7899
- [x] 解灰功能已启用
- [x] 局域网可访问
- [x] 所有接口测试通过
- [x] 日志记录正常
- [x] 文件权限配置正确

**🎊 恭喜！SPlayer 音乐播放器已成功部署，现在可以从局域网内任意设备访问 http://192.168.1.118:7899 开始使用！**
