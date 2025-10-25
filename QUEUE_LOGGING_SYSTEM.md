# 📊 点歌队列日志系统文档

## 系统概述

为点歌队列功能创建了完整的日志记录系统，记录前端用户操作和后端API调用，帮助准确发现和诊断队列功能中的问题。

**创建时间**: 2025-10-13  
**状态**: ✅ 已完成（后端完整，前端部分集成）

---

## 📁 文件结构

### 后端文件
```
api-enhanced/
├── util/
│   └── queueLogger.js          # 后端日志记录器（新建）
├── module/
│   ├── queue_manager.js        # 队列管理模块（已添加日志）
│   └── log_frontend.js         # 前端日志接收接口（新建）
└── logs/
    └── queue/
        └── queue-YYYY-MM-DD.log  # 日志文件（按日期分文件）
```

### 前端文件
```
SPlayer/src/
├── utils/
│   └── queueLogger.js          # 前端日志工具（新建）
├── stores/
│   └── queueData.js            # 队列Store（已添加日志）
└── components/
    └── List/
        └── SongList.vue        # 歌曲列表（已添加日志）
```

---

## 🎯 功能特性

### 后端日志系统

#### 1. 多级别日志
- **INFO**: 正常操作信息
- **WARN**: 警告信息（如重复添加、队列为空）
- **ERROR**: 错误信息（异常、失败操作）

#### 2. 日志格式
```json
{
  "timestamp": "2025-10-13T15:30:45.123Z",
  "level": "INFO",
  "type": "QUEUE_OPERATION",
  "operation": "ADD",
  "data": {
    "id": 1,
    "songId": 186045,
    "songName": "七里香",
    "addedBy": "张三"
  },
  "user": "张三",
  "result": "SUCCESS"
}
```

#### 3. 存储方式
- **位置**: `api-enhanced/logs/queue/`
- **文件名**: `queue-2025-10-13.log`
- **格式**: 每行一个JSON对象（NDJSON格式）
- **分文件**: 按日期自动分文件
- **自动创建**: 日志目录不存在时自动创建

#### 4. 控制台输出
- 开发环境同时输出到控制台
- 彩色显示（INFO=蓝色, WARN=橙色, ERROR=红色）
- 格式：`[QUEUE-LOG] LEVEL TYPE data`

### 前端日志系统

#### 1. 本地日志
- 保存最近100条日志在内存
- 浏览器控制台实时输出
- 支持导出为JSON文件

#### 2. 远程日志
- 自动发送到后端 `/log/frontend` 接口
- 异步发送，不阻塞用户操作
- 发送失败不影响功能

---

## 📝 记录的操作

### 后端记录

#### 队列操作
1. **添加歌曲** (`ADD_QUEUE`)
   - 开始添加：`ADD_QUEUE_START`
   - 添加成功：`ADD_QUEUE_SUCCESS`
   - 信息不完整：`ADD_QUEUE_FAILED`
   - 重复添加：`ADD_QUEUE_DUPLICATE`
   - 操作摘要：`QUEUE_OPERATION`

2. **移除歌曲** (`REMOVE_QUEUE`)
   - 开始移除：`REMOVE_QUEUE_START`
   - 移除成功：`REMOVE_QUEUE_SUCCESS`
   - 未找到：`REMOVE_QUEUE_NOT_FOUND`
   - 操作摘要：`QUEUE_OPERATION`

3. **获取下一首** (`GET_NEXT`)
   - 开始获取：`GET_NEXT_START`
   - 获取成功：`GET_NEXT_SUCCESS`
   - 队列为空：`GET_NEXT_EMPTY`
   - 自动播放记录：`AUTO_PLAY`
   - 操作摘要：`QUEUE_OPERATION`

4. **清空队列** (`CLEAR_QUEUE`)
   - 清空成功：`CLEAR_QUEUE_SUCCESS`
   - 操作摘要：`QUEUE_OPERATION`

#### API请求
- 接口调用：`API_REQUEST`
- 接口响应：`API_RESPONSE`
- 包含：端点、方法、参数、响应时间

#### 错误记录
- 异常堆栈：`ERROR`
- 上下文信息：操作类型、参数、环境

### 前端记录

#### 用户操作
1. **点击添加队列** (`USER_CLICK_ADD_QUEUE`)
   - 歌曲信息
   - 用户名

2. **添加结果** (`USER_ADD_QUEUE / USER_ADD_QUEUE_FAILED`)
   - 是否成功
   - 返回消息

#### 队列模式
1. **模式切换** (`QUEUE_MODE_TOGGLE`)
   - 开启/关闭
   - 当前队列长度

2. **自动播放触发** (`AUTO_PLAY_TRIGGER`)
   - 当前歌曲
   - 队列模式状态

3. **获取下一首** (`GET_NEXT_SONG`)
   - 是否成功
   - 下一首歌曲信息
   - 错误信息

4. **自动播放歌曲** (`AUTO_PLAY_SONG`)
   - 歌曲信息
   - 是否成功
   - 错误信息

#### 播放器事件
- 播放：`PLAYER_PLAY`
- 暂停：`PLAYER_PAUSE`
- 结束：`PLAYER_ENDED`
- 错误：`PLAYER_ERROR`

#### API调用
- 调用成功：`API_CALL`
- 调用失败：`API_CALL_FAILED`
- 包含：端点、方法、参数、结果

---

## 🔍 日志示例

### 后端日志示例

#### 1. 用户添加歌曲
```json
{
  "timestamp": "2025-10-13T15:30:45.123Z",
  "level": "INFO",
  "type": "ADD_QUEUE_START",
  "songId": 186045,
  "songName": "七里香",
  "addedBy": "张三"
}

{
  "timestamp": "2025-10-13T15:30:45.234Z",
  "level": "INFO",
  "type": "QUEUE_OPERATION",
  "operation": "ADD",
  "data": {
    "id": 1,
    "songId": 186045,
    "songName": "七里香",
    "artist": "周杰伦",
    "addedBy": "张三",
    "addedAt": 1760370645123
  },
  "user": "张三",
  "result": "SUCCESS"
}

{
  "timestamp": "2025-10-13T15:30:45.345Z",
  "level": "INFO",
  "type": "ADD_QUEUE_SUCCESS",
  "queueItemId": 1,
  "songId": 186045,
  "songName": "七里香",
  "addedBy": "张三",
  "position": 5,
  "totalQueueLength": 5
}
```

#### 2. 自动播放
```json
{
  "timestamp": "2025-10-13T15:32:30.123Z",
  "level": "INFO",
  "type": "GET_NEXT_START",
  "currentQueueLength": 4
}

{
  "timestamp": "2025-10-13T15:32:30.234Z",
  "level": "INFO",
  "type": "AUTO_PLAY",
  "songId": 186045,
  "songName": "七里香",
  "queueId": 1,
  "user": "张三",
  "success": true
}

{
  "timestamp": "2025-10-13T15:32:30.345Z",
  "level": "INFO",
  "type": "GET_NEXT_SUCCESS",
  "queueItemId": 1,
  "songId": 186045,
  "songName": "七里香",
  "artist": "周杰伦",
  "addedBy": "张三",
  "remainingLength": 3
}
```

#### 3. 重复添加警告
```json
{
  "timestamp": "2025-10-13T15:33:15.123Z",
  "level": "WARN",
  "type": "ADD_QUEUE_DUPLICATE",
  "songId": 186045,
  "songName": "七里香",
  "addedBy": "李四",
  "currentQueueLength": 3
}
```

#### 4. 错误记录
```json
{
  "timestamp": "2025-10-13T15:34:00.123Z",
  "level": "ERROR",
  "type": "ERROR",
  "operation": "GET_NEXT",
  "errorMsg": "Cannot read property 'songId' of undefined",
  "stack": "Error: Cannot read...\n  at getNext (/api/queue_manager.js:95:20)\n  ...",
  "context": {
    "queueLength": 0
  }
}
```

### 前端日志示例

#### 1. 用户点击添加
```json
{
  "timestamp": "2025-10-13T15:30:45.000Z",
  "level": "INFO",
  "type": "USER_CLICK_ADD_QUEUE",
  "data": {
    "songId": 186045,
    "songName": "七里香",
    "user": "张三"
  },
  "userAgent": "Mozilla/5.0..."
}

{
  "timestamp": "2025-10-13T15:30:45.200Z",
  "level": "INFO",
  "type": "USER_ADD_QUEUE",
  "data": {
    "action": "ADD_TO_QUEUE",
    "songId": 186045,
    "songName": "七里香",
    "artist": "周杰伦",
    "user": "张三",
    "result": "SUCCESS",
    "message": "添加成功",
    "timestamp": 1760370645000
  },
  "userAgent": "Mozilla/5.0..."
}
```

#### 2. 队列模式切换
```json
{
  "timestamp": "2025-10-13T15:31:00.000Z",
  "level": "INFO",
  "type": "QUEUE_MODE_TOGGLE",
  "data": {
    "action": "TOGGLE_QUEUE_MODE",
    "enabled": true,
    "queueLength": 5,
    "timestamp": 1760370660000
  },
  "userAgent": "Mozilla/5.0..."
}
```

#### 3. 自动播放
```json
{
  "timestamp": "2025-10-13T15:32:30.000Z",
  "level": "INFO",
  "type": "AUTO_PLAY_TRIGGER",
  "data": {
    "action": "AUTO_PLAY_TRIGGER",
    "currentSongId": 186044,
    "currentSongName": "晴天",
    "queueModeEnabled": true,
    "timestamp": 1760370750000
  },
  "userAgent": "Mozilla/5.0..."
}

{
  "timestamp": "2025-10-13T15:32:30.200Z",
  "level": "INFO",
  "type": "AUTO_PLAY_SONG",
  "data": {
    "action": "AUTO_PLAY_SONG",
    "songId": 186045,
    "songName": "七里香",
    "artist": "周杰伦",
    "addedBy": "张三",
    "success": true,
    "timestamp": 1760370750200
  },
  "userAgent": "Mozilla/5.0..."
}
```

---

## 🛠️ 使用方法

### 后端日志查看

#### 查看今天的日志
```bash
tail -f /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log
```

#### 查看实时日志（最后50行）
```bash
tail -50 /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log
```

#### 搜索特定操作
```bash
# 搜索添加操作
grep "ADD_QUEUE" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log

# 搜索错误
grep "ERROR" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log

# 搜索自动播放
grep "AUTO_PLAY" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log
```

#### 统计操作次数
```bash
# 统计今天添加了多少首歌
grep "ADD_QUEUE_SUCCESS" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | wc -l

# 统计自动播放次数
grep "AUTO_PLAY.*success.*true" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | wc -l

# 统计错误次数
grep "ERROR" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | wc -l
```

#### 按用户统计
```bash
# 统计各用户点歌次数
grep "addedBy" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | \
  grep -oP '"addedBy":"[^"]*"' | sort | uniq -c | sort -nr
```

### 前端日志查看

#### 控制台查看
打开浏览器开发者工具（F12）→ Console 标签页，筛选 `[QUEUE-LOG]`

#### 导出本地日志
在浏览器控制台执行：
```javascript
// 导出JSON文件
queueLogger.exportLogs()

// 查看本地日志
queueLogger.getLocalLogs()

// 清空本地日志
queueLogger.clearLocalLogs()
```

---

## 📊 日志分析

### 常见问题诊断

#### 1. 添加队列失败

**搜索关键字**: `ADD_QUEUE_FAILED`, `ADD_QUEUE_DUPLICATE`

**分析步骤**:
```bash
# 1. 查看失败日志
grep "ADD_QUEUE_FAILED\|ADD_QUEUE_DUPLICATE" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -10

# 2. 查看是否有错误
grep "ERROR.*ADD" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log

# 3. 查看前后文
grep -A 5 -B 5 "ADD_QUEUE_FAILED" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -20
```

**可能原因**:
- 歌曲信息不完整（songId 缺失）
- 歌曲已在队列中（重复添加）
- API 服务异常

#### 2. 自动播放不工作

**搜索关键字**: `AUTO_PLAY`, `GET_NEXT`

**分析步骤**:
```bash
# 1. 检查队列模式是否开启
grep "QUEUE_MODE" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -5

# 2. 检查是否触发自动播放
grep "AUTO_PLAY_TRIGGER" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -5

# 3. 检查获取下一首是否成功
grep "GET_NEXT" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -10

# 4. 查看错误
grep "ERROR.*AUTO_PLAY\|ERROR.*GET_NEXT" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log
```

**可能原因**:
- 队列模式未开启
- 队列为空
- 播放器初始化失败
- 网络请求失败

#### 3. 队列状态异常

**搜索关键字**: `QUEUE_OPERATION`

**分析步骤**:
```bash
# 1. 查看所有队列操作
grep "QUEUE_OPERATION" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -20

# 2. 统计各操作次数
grep "QUEUE_OPERATION" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | \
  grep -oP '"operation":"[^"]*"' | sort | uniq -c

# 3. 检查队列长度变化
grep "totalQueueLength\|remainingLength" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -10
```

---

## 🔧 日志配置

### 修改日志保留数量（前端）

编辑 `SPlayer/src/utils/queueLogger.js`:
```javascript
constructor() {
  this.logs = [];
  this.maxLocalLogs = 200; // 修改为200条
  this.enabled = true;
}
```

### 禁用远程日志发送

编辑 `SPlayer/src/utils/queueLogger.js`:
```javascript
constructor() {
  this.logs = [];
  this.maxLocalLogs = 100;
  this.enabled = false; // 禁用远程发送
}
```

### 修改日志目录（后端）

编辑 `api-enhanced/util/queueLogger.js`:
```javascript
// 日志目录
const LOG_DIR = path.join(__dirname, '../logs');
const QUEUE_LOG_DIR = path.join(LOG_DIR, 'queue');

// 修改为:
const LOG_DIR = '/var/log/splayer';
const QUEUE_LOG_DIR = path.join(LOG_DIR, 'queue');
```

---

## 📈 日志统计脚本

### 创建日志分析脚本

```bash
#!/bin/bash
# 保存为 analyze-queue-logs.sh

LOG_FILE="/home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log"

echo "========== 点歌队列日志分析 =========="
echo "日期: $(date)"
echo "日志文件: $LOG_FILE"
echo ""

echo "### 操作统计 ###"
echo "总操作次数: $(grep -c "QUEUE_OPERATION" "$LOG_FILE")"
echo "添加次数: $(grep -c "ADD_QUEUE_SUCCESS" "$LOG_FILE")"
echo "移除次数: $(grep -c "REMOVE_QUEUE_SUCCESS" "$LOG_FILE")"
echo "自动播放次数: $(grep -c "GET_NEXT_SUCCESS" "$LOG_FILE")"
echo "清空次数: $(grep -c "CLEAR_QUEUE_SUCCESS" "$LOG_FILE")"
echo ""

echo "### 错误统计 ###"
echo "错误总数: $(grep -c '"level":"ERROR"' "$LOG_FILE")"
echo "警告总数: $(grep -c '"level":"WARN"' "$LOG_FILE")"
echo ""

echo "### 用户统计 ###"
grep "addedBy" "$LOG_FILE" | grep -oP '"addedBy":"[^"]*"' | sort | uniq -c | sort -nr
echo ""

echo "### 最近10条错误 ###"
grep '"level":"ERROR"' "$LOG_FILE" | tail -10 | jq -r '"\(.timestamp) - \(.type): \(.errorMsg // .message)"'
```

使用方法:
```bash
chmod +x analyze-queue-logs.sh
./analyze-queue-logs.sh
```

---

## 🎯 实际应用场景

### 场景 1: 用户反馈"点歌没反应"

1. 查看用户操作日志
```bash
grep "USER_CLICK_ADD_QUEUE" logs/queue/queue-*.log | grep "用户A" | tail -5
```

2. 检查是否有错误
```bash
grep "ERROR\|FAILED" logs/queue/queue-*.log | grep -A 3 "用户A"
```

3. 查看API响应
```bash
grep "STORE_ADD_SONG" logs/queue/queue-*.log | grep "用户A" | tail -5
```

### 场景 2: 自动播放跳过某些歌曲

1. 查看自动播放记录
```bash
grep "AUTO_PLAY" logs/queue/queue-*.log | tail -20
```

2. 检查获取下一首的逻辑
```bash
grep "GET_NEXT" logs/queue/queue-*.log | tail -20
```

3. 查看播放器事件
```bash
grep "PLAYER_" logs/queue/queue-*.log | tail -20
```

### 场景 3: 队列长度显示不一致

1. 追踪队列长度变化
```bash
grep "totalQueueLength\|remainingLength\|queueLength" logs/queue/queue-*.log | tail -30
```

2. 查看队列操作
```bash
grep "QUEUE_OPERATION" logs/queue/queue-*.log | tail -20
```

---

## 📝 开发者注意事项

### 添加新的日志记录

#### 后端添加日志
