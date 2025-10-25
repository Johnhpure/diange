# 🔧 解灰功能问题排查与解决方案

## 🐛 当前问题

**现象**: 周杰伦专辑歌曲无法播放  
**错误**: `ERR_CERT_COMMON_NAME_INVALID` - HTTPS 证书验证失败  
**根本原因**: 浏览器从 HTTP 站点加载 HTTPS 音频资源时，遇到证书验证问题

---

## 📊 问题分析

### 错误日志解读
```
sx.sycdn.kuwo.cn/...flac?from=bodian
GET https://sx.sycdn.kuwo.cn/... net::ERR_CERT_COMMON_NAME_INVALID
```

**分析**：
1. ✅ API 成功获取到解灰 URL（来自酷我音乐 bodian 音源）
2. ✅ 前端触发解灰流程（日志显示 "🎵 开始解灰"）
3. ❌ 浏览器加载音频时，因为 HTTPS 证书问题被阻止
4. ❌ 混合内容策略：HTTP 页面 → HTTPS 资源（安全风险）

### 为什么 API 返回 HTTP 但浏览器使用 HTTPS？

```bash
# API 实际返回
curl http://192.168.1.118:3001/song/url?id=186045
# 返回: http://sx.sycdn.kuwo.cn/...

# 但浏览器收到的是
https://sx.sycdn.kuwo.cn/...  # 被升级为 HTTPS
```

**原因**：现代浏览器（Chrome/Edge）启用了 **HTTPS-Only 模式** 或 **自动升级不安全请求**。

---

## 🛠️ 解决方案

### 方案 1：浏览器禁用 HTTPS 自动升级（临时测试）

#### Edge / Chrome
1. 打开设置 → 隐私、搜索和服务
2. 找到 "自动将 HTTP 升级为 HTTPS"
3. **关闭此选项**
4. 刷新页面重试

#### Firefox
```
about:config
security.mixed_content.block_active_content = false
```

---

### 方案 2：启用站点 HTTPS（推荐生产环境）

#### 使用自签名证书（局域网测试）

```bash
# 生成自签名证书
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/splayer-selfsigned.key \
  -out /etc/ssl/certs/splayer-selfsigned.crt \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=SPlayer/CN=192.168.1.118"

# 修改 Nginx 配置
sudo nano /etc/nginx/sites-available/splayer
```

添加 HTTPS 监听：
```nginx
server {
    listen 7899 ssl;
    listen [::]:7899 ssl;
    
    ssl_certificate /etc/ssl/certs/splayer-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/splayer-selfsigned.key;
    
    # ... 其余配置保持不变
}

# HTTP 自动跳转 HTTPS
server {
    listen 7898;
    server_name 192.168.1.118;
    return 301 https://$host:7899$request_uri;
}
```

```bash
# 重启 Nginx
sudo nginx -t && sudo systemctl reload nginx

# 访问（会提示证书不受信任，点击"高级"→"继续访问"）
https://192.168.1.118:7899
```

---

### 方案 3：Nginx 音频流代理（已配置，但需前端配合）

#### 当前 Nginx 配置
```nginx
location /proxy/ {
    set $target_url $arg_url;
    proxy_ssl_verify off;
    proxy_pass $target_url;
    add_header Access-Control-Allow-Origin "*" always;
}
```

#### 使用方式
前端需要将音频 URL 改为：
```
原始: https://sx.sycdn.kuwo.cn/xxx.flac
代理: http://192.168.1.118:7899/proxy/?url=https://sx.sycdn.kuwo.cn/xxx.flac
```

**但这需要修改 SPlayer 源码**，不推荐。

---

### 方案 4：配置 CORS 代理服务（中间方案）

创建一个简单的 Node.js 代理服务器：

```javascript
// /home/chenbang/app/netease/audio-proxy.js
const express = require('express');
const axios = require('axios');
const app = express();

app.get('/audio/*', async (req, res) => {
    const audioUrl = req.query.url;
    try {
        const response = await axios({
            method: 'get',
            url: audioUrl,
            responseType: 'stream',
            headers: {
                'User-Agent': 'Mozilla/5.0',
                'Referer': ''
            },
            httpsAgent: new (require('https')).Agent({
                rejectUnauthorized: false  // 忽略证书验证
            })
        });
        
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Content-Type', response.headers['content-type']);
        response.data.pipe(res);
    } catch (error) {
        res.status(500).send('Proxy error');
    }
});

app.listen(3002, () => console.log('Audio proxy on :3002'));
```

---

## 🎯 推荐解决方案（按优先级）

### ⭐ 快速测试方案
**浏览器禁用 HTTPS 自动升级**
- 优点：立即生效，无需改代码
- 缺点：每个客户端都需要配置
- 适用：局域网测试环境

### ⭐⭐ 临时解决方案
**使用自签名 HTTPS 证书**
- 优点：所有客户端统一配置
- 缺点：每次访问需要信任证书
- 适用：团队内网测试

### ⭐⭐⭐ 长期方案
**使用有效的 HTTPS 证书**
- 优点：完全解决问题，生产环境标准
- 缺点：需要域名（Let's Encrypt 免费）
- 适用：公网部署

---

## 🔍 验证解灰功能是否正常

### 测试 API 解灰接口
```bash
# 测试获取灰色歌曲 URL
curl "http://192.168.1.118:3001/song/url?id=186045"

# 查看返回的 url 字段
# 如果有 URL 且包含 from=bodian/pyncmd 等，说明解灰成功
```

### 测试音源可用性
```bash
# 测试酷我音源
curl -I "http://sx.sycdn.kuwo.cn/xxx.flac?from=bodian"

# 如果返回 403 Forbidden，说明音源需要特定 headers
```

---

## 🚀 立即可用的临时方案

### 步骤 1：生成自签名证书
```bash
cd /home/chenbang/app/netease
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout splayer-selfsigned.key \
  -out splayer-selfsigned.crt \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=SPlayer/CN=192.168.1.118"
```

### 步骤 2：更新 Nginx 配置
```bash
sudo nano /etc/nginx/sites-available/splayer
```

添加 HTTPS 支持：
```nginx
server {
    listen 7899 ssl http2;
    listen [::]:7899 ssl http2;
    server_name 192.168.1.118;
    
    # SSL 证书
    ssl_certificate /home/chenbang/app/netease/splayer-selfsigned.crt;
    ssl_certificate_key /home/chenbang/app/netease/splayer-selfsigned.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # ... 其余配置保持不变
}
```

### 步骤 3：更新 SPlayer 配置
```bash
nano /home/chenbang/app/netease/SPlayer/.env
```

修改站点地址为 HTTPS：
```env
RENDERER_VITE_SITE_URL = "https://192.168.1.118:7899"
```

### 步骤 4：重新构建并重启
```bash
cd /home/chenbang/app/netease/SPlayer
pnpm build
sudo systemctl reload nginx
```

### 步骤 5：访问测试
```
https://192.168.1.118:7899
```

浏览器会提示"不安全"，点击 **高级 → 继续访问** 即可。

---

## 📝 测试清单

完成上述配置后，测试以下功能：

- [ ] 访问 https://192.168.1.118:7899（信任证书）
- [ ] 搜索周杰伦歌曲
- [ ] 点击播放灰色歌曲
- [ ] 检查浏览器控制台是否还有 `ERR_CERT_COMMON_NAME_INVALID`
- [ ] 验证音频是否正常播放

---

## 💡 其他可能的问题

### 1. 音源 URL 失效
有些解灰音源的 URL 有时效性（几分钟到几小时）

**解决方案**: 重新获取歌曲 URL

### 2. 音源需要特定 Headers
某些音源（如酷我）需要 Referer 或 Cookie

**解决方案**: 在 Nginx 代理中添加对应 headers（已配置）

### 3. 音源地域限制
某些音源可能有 IP 地域限制

**解决方案**: 尝试其他音源，调整 `UNBLOCK_SOURCE` 优先级

---

## 🎯 下一步建议

建议立即执行 **方案 2（自签名 HTTPS）**，这是最快且最彻底的解决方案。

我可以帮你执行配置吗？请回复 `yes` 开始配置 HTTPS。
