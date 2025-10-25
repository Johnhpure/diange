# ☁️ Cloudflare Tunnel 公网部署配置

## 📋 部署摘要

**部署时间**: 2025-10-13  
**公网域名**: https://music.jianzhile.vip  
**内网地址**: 192.168.1.118:7899  
**隧道工具**: Cloudflare Tunnel  
**状态**: ✅ 已完成

---

## 🔧 配置修改

### 问题描述

**原问题**：
- 前端页面可以通过公网访问（✅）
- 音频无法播放（❌）
- 浏览器尝试访问内网地址：`https://192.168.1.118:7899/proxy/...`
- 公网用户无法访问内网IP

**根本原因**：
- API 配置的 `PROXY_URL` 使用了内网IP
- SPlayer 配置的 `RENDERER_VITE_SITE_URL` 使用了内网IP
- API返回的 `proxyUrl` 包含内网IP，公网用户无法访问

---

## ✅ 解决方案

### 1. 修改 API 配置

**文件**: `api-enhanced/.env`

```env
# 修改前
PROXY_URL = "https://192.168.1.118:7899/proxy/"

# 修改后
PROXY_URL = "https://music.jianzhile.vip/proxy/"
```

### 2. 修改 SPlayer 配置

**文件**: `SPlayer/.env`

```env
# 修改前
RENDERER_VITE_SITE_URL = "https://192.168.1.118:7899"

# 修改后
RENDERER_VITE_SITE_URL = "https://music.jianzhile.vip"
```

### 3. 重启服务

```bash
# 重启 API
pkill -f "node app.js"
cd /home/chenbang/app/netease/api-enhanced
PORT=3001 nohup node app.js > /tmp/api-enhanced.log 2>&1 &

# 重新构建前端
cd /home/chenbang/app/netease/SPlayer
pnpm build

# 更新权限
chmod -R 755 /home/chenbang/app/netease/SPlayer/out/renderer
```

---

## 📊 部署架构

### 完整数据流

```
┌────────────────────────────────────────────────┐
│  公网用户浏览器                                  │
│  https://music.jianzhile.vip                   │
└──────────────────┬─────────────────────────────┘
                   │ HTTPS (Cloudflare)
                   ▼
┌────────────────────────────────────────────────┐
│  Cloudflare Tunnel                             │
│  - SSL/TLS 终止                                 │
│  - DDoS 防护                                    │
│  - CDN 加速                                     │
└──────────────────┬─────────────────────────────┘
                   │ 隧道连接到内网
                   ▼
┌────────────────────────────────────────────────┐
│  本地服务器 192.168.1.118:7899                  │
│  Nginx + HTTPS (自签名证书)                     │
│  - 托管 SPlayer 静态文件                        │
│  - /api/* → 反向代理到 API                      │
│  - /proxy/* → 音频流代理                        │
└──────────────────┬─────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────┐
│  api-enhanced (127.0.0.1:3001)                 │
│  - 解灰功能                                     │
│  - 返回 proxyUrl (公网域名)                     │
└──────────────────┬─────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────┐
│  外部音源 (酷我/QQ音乐/咪咕等)                   │
└────────────────────────────────────────────────┘
```

### 音频播放流程

```
1. 用户访问：https://music.jianzhile.vip
   ↓
2. Cloudflare Tunnel 转发到内网 192.168.1.118:7899
   ↓
3. 用户点击播放灰色歌曲
   ↓
4. 前端请求：https://music.jianzhile.vip/api/song/url?id=xxx
   ↓
5. Cloudflare → 本地Nginx → API (3001)
   ↓
6. API 返回：
   {
     "url": "http://sx.sycdn.kuwo.cn/xxx.flac",
     "proxyUrl": "https://music.jianzhile.vip/proxy/http://sx.sycdn.kuwo.cn/xxx.flac"
   }
   ↓
7. 前端使用 proxyUrl 加载音频
   请求：https://music.jianzhile.vip/proxy/http://sx.sycdn.kuwo.cn/xxx.flac
   ↓
8. Cloudflare → 本地Nginx /proxy/ location
   ↓
9. Nginx 代理到外部音源（忽略SSL验证）
   ↓
10. 音频流返回：Nginx → Cloudflare → 用户浏览器
    ↓
11. ✅ 音频正常播放
```

---

## 🌐 访问方式

### 公网访问（推荐）
```
https://music.jianzhile.vip
```
- ✅ 全球任意位置访问
- ✅ Cloudflare CDN 加速
- ✅ DDoS 防护
- ✅ 自动HTTPS（Cloudflare证书）
- ✅ 解灰功能完整支持

### 局域网直接访问
```
https://192.168.1.118:7899
```
- ✅ 局域网内设备访问
- ⚠️ 需要信任自签名证书
- ✅ 低延迟
- ✅ 不消耗公网带宽

---

## 🔑 关键配置说明

### Cloudflare Tunnel 配置

**隧道配置**:
- 公网域名: `music.jianzhile.vip`
- 本地服务: `https://192.168.1.118:7899`
- 协议: HTTPS

**Cloudflare设置建议**:
```
1. SSL/TLS 模式: Full (严格)
2. 缓存级别: 标准
3. Browser Cache TTL: 4 hours
4. 禁用 "Always Use HTTPS"（已经是HTTPS）
5. 启用 "HTTP/2"
```

### API 配置

**api-enhanced/.env**:
```env
ENABLE_PROXY = true
PROXY_URL = "https://music.jianzhile.vip/proxy/"
```

**作用**: 
- API检测到解灰音源后，自动生成包含公网域名的 `proxyUrl`
- 公网用户可以正常访问代理URL

### 前端配置

**SPlayer/.env**:
```env
RENDERER_VITE_SERVER_URL = "/api"
RENDERER_VITE_SITE_URL = "https://music.jianzhile.vip"
```

**作用**:
- API请求使用相对路径 `/api`，自动匹配当前域名
- SITE_URL用于生成绝对路径（如PWA manifest）

### Nginx 配置

**/etc/nginx/sites-available/splayer**:
```nginx
# 音频流代理
location ~ ^/proxy/ {
    if ($request_uri ~ "^/proxy/(.*)$") {
        set $target_url $1;
    }
    
    resolver 8.8.8.8 8.8.4.4;
    proxy_pass $target_url;
    proxy_ssl_verify off;
    add_header Access-Control-Allow-Origin "*" always;
}
```

**作用**:
- 接收来自 Cloudflare 的代理请求
- 转发到外部音源并忽略SSL验证
- 返回音频流给用户

---

## 🧪 测试验证

### 测试 1: 公网访问前端
```bash
curl -I https://music.jianzhile.vip/
# 应返回 200 OK
```

### 测试 2: 公网访问 API
```bash
curl -s "https://music.jianzhile.vip/api/search?keywords=test&limit=1" | jq '.code'
# 应返回 200
```

### 测试 3: 解灰功能
```bash
curl -s "https://music.jianzhile.vip/api/song/url?id=186045" | jq '.data[0] | {url, proxyUrl}'

# 预期输出
{
  "url": "http://sx.sycdn.kuwo.cn/.../xxx.flac?from=bodian",
  "proxyUrl": "https://music.jianzhile.vip/proxy/http://sx.sycdn.kuwo.cn/.../xxx.flac?from=bodian"
}
```

### 测试 4: 音频代理
```bash
curl -I "https://music.jianzhile.vip/proxy/http://sx.sycdn.kuwo.cn/test.flac"
# 应返回外部音源的响应（可能是403或其他）
```

### 测试 5: 浏览器播放
1. 打开 https://music.jianzhile.vip
2. 搜索"周杰伦"
3. 打开任意专辑
4. 点击播放灰色歌曲
5. **应该可以正常播放** ✅

---

## 🚀 性能优化建议

### 1. Cloudflare 缓存配置

**页面规则**:
```
https://music.jianzhile.vip/assets/*
- 缓存级别: 缓存所有内容
- Edge缓存TTL: 1个月
- 浏览器缓存TTL: 1个月

https://music.jianzhile.vip/api/*
- 缓存级别: 绕过
- 禁用缓存

https://music.jianzhile.vip/proxy/*
- 缓存级别: 标准
- Edge缓存TTL: 1小时
```

### 2. 启用 HTTP/3
在 Cloudflare Dashboard:
- 网络 → HTTP/3 → 开启

### 3. 启用 Brotli 压缩
在 Cloudflare Dashboard:
- 速度 → 优化 → Brotli → 开启

---

## 🔒 安全建议

### 1. 限制 API 访问来源

**Nginx 配置添加**:
```nginx
# 仅允许 Cloudflare IP 访问
location /api/ {
    # Cloudflare IPv4
    allow 173.245.48.0/20;
    allow 103.21.244.0/22;
    allow 103.22.200.0/22;
    allow 103.31.4.0/22;
    allow 141.101.64.0/18;
    allow 108.162.192.0/18;
    allow 190.93.240.0/20;
    allow 188.114.96.0/20;
    allow 197.234.240.0/22;
    allow 198.41.128.0/17;
    allow 162.158.0.0/15;
    allow 104.16.0.0/13;
    allow 104.24.0.0/14;
    allow 172.64.0.0/13;
    allow 131.0.72.0/22;
    
    # Cloudflare IPv6
    allow 2400:cb00::/32;
    allow 2606:4700::/32;
    allow 2803:f800::/32;
    allow 2405:b500::/32;
    allow 2405:8100::/32;
    allow 2a06:98c0::/29;
    allow 2c0f:f248::/32;
    
    deny all;
    
    # 其余配置...
}
```

### 2. 添加访问频率限制

```nginx
# 在 http 块中添加
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=proxy_limit:10m rate=20r/s;

# 在 location 中应用
location /api/ {
    limit_req zone=api_limit burst=20 nodelay;
    # ...
}

location ~ ^/proxy/ {
    limit_req zone=proxy_limit burst=50 nodelay;
    # ...
}
```

### 3. 启用 Cloudflare Access（可选）

如果需要限制访问：
1. Cloudflare Dashboard → Access
2. 创建应用程序
3. 设置访问规则（邮箱验证/GitHub登录等）

---

## 🌍 多环境支持

### 配置说明

当前配置**自动适配**公网和内网访问：

**公网访问** (https://music.jianzhile.vip):
- API: `https://music.jianzhile.vip/api/` (通过Cloudflare)
- 音频: `https://music.jianzhile.vip/proxy/` (通过Cloudflare)

**局域网访问** (https://192.168.1.118:7899):
- API: `https://192.168.1.118:7899/api/` (直连Nginx)
- 音频: `https://192.168.1.118:7899/proxy/` (直连Nginx)
- ⚠️ 需要信任自签名证书

### 如何切换？

**无需切换！** 配置已支持两种访问方式：
- 使用 `/api` 相对路径，自动匹配当前域名
- 使用公网域名生成 proxyUrl，内外网都能访问

---

## 📊 流量统计

### Cloudflare Analytics

在 Cloudflare Dashboard 可以查看：
- 访问量统计
- 带宽使用
- 缓存命中率
- 攻击拦截记录
- 地理分布

### Nginx 日志

```bash
# 访问日志
tail -f /var/log/nginx/splayer_access.log

# 统计API请求
cat /var/log/nginx/splayer_access.log | grep "/api/" | wc -l

# 统计音频代理请求
cat /var/log/nginx/splayer_access.log | grep "/proxy/" | wc -l
```

---

## 🐛 故障排查

### 问题 1: 公网无法播放音乐

**症状**: 浏览器尝试访问 `https://192.168.1.118:7899/proxy/...`

**原因**: API配置未更新，仍返回内网IP

**解决**:
```bash
# 检查API配置
grep PROXY_URL /home/chenbang/app/netease/api-enhanced/.env
# 应输出: PROXY_URL = "https://music.jianzhile.vip/proxy/"

# 如果不对，修改后重启API
vi /home/chenbang/app/netease/api-enhanced/.env
pkill -f "node app.js"
cd /home/chenbang/app/netease/api-enhanced
PORT=3001 nohup node app.js > /tmp/api-enhanced.log 2>&1 &
```

### 问题 2: 502 Bad Gateway

**症状**: 前端请求API时返回502

**原因**: Cloudflare无法连接到本地服务器

**解决**:
```bash
# 检查本地服务
systemctl status nginx
ps aux | grep "node app.js"

# 检查Cloudflare Tunnel状态
cloudflared tunnel list
cloudflared tunnel info <tunnel-name>
```

### 问题 3: 音频代理返回HTML

**症状**: /proxy/ 请求返回首页HTML

**原因**: Nginx location配置问题

**解决**:
```bash
# 检查Nginx配置
nginx -T | grep -A 10 "location.*proxy"

# 测试正则匹配
curl -I https://music.jianzhile.vip/proxy/http://test.com/test.mp3
```

---

## 📱 多设备访问

### 公网访问（任意设备）
```
https://music.jianzhile.vip
```
- ✅ PC浏览器
- ✅ 手机浏览器
- ✅ 平板浏览器
- ✅ 全球任意位置

### 局域网访问（局域网设备）
```
https://192.168.1.118:7899
```
- ✅ 更低延迟
- ✅ 不消耗公网流量
- ⚠️ 首次需要信任证书

---

## 💡 优化建议

### 1. 使用环境变量自动切换

**创建配置文件**: `config.js`
```javascript
const isDev = process.env.NODE_ENV === 'development';
const isLocal = window.location.hostname === '192.168.1.118';

export const SITE_URL = isLocal 
  ? 'https://192.168.1.118:7899' 
  : 'https://music.jianzhile.vip';
```

### 2. 添加域名检测

**在前端添加**:
```javascript
// 自动检测并使用当前域名
const currentDomain = window.location.origin;
const proxyUrl = `${currentDomain}/proxy/`;
```

### 3. 配置反向代理缓存

**Nginx 添加缓存**:
```nginx
http {
    proxy_cache_path /var/cache/nginx/music 
                     levels=1:2 
                     keys_zone=music_cache:100m 
                     max_size=1g 
                     inactive=24h;
}

location ~ ^/proxy/ {
    proxy_cache music_cache;
    proxy_cache_key $target_url;
    proxy_cache_valid 200 1h;
    # ...
}
```

---

## 📚 相关文档

- DEPLOYMENT_SUCCESS.md - 初次部署记录
- HTTPS_DEPLOYMENT_COMPLETE.md - HTTPS配置
- FINAL_FIX_COMPLETE.md - 解灰功能修复
- TROUBLESHOOTING_GRAY_SONGS.md - 故障排查

---

## 🎊 部署完成

✅ **公网访问**: https://music.jianzhile.vip  
✅ **解灰功能**: 完整支持  
✅ **全球访问**: Cloudflare CDN加速  
✅ **安全防护**: DDoS防护 + SSL加密

现在全球任意位置都可以访问并播放所有歌曲（包括灰色/VIP歌曲）！🎵
