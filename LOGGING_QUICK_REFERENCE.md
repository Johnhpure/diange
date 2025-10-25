# 📊 日志系统快速参考

## ✅ 已完成功能

### 后端日志系统
- ✅ 日志记录器 (`api-enhanced/util/queueLogger.js`)
- ✅ 队列管理模块日志 (`api-enhanced/module/queue_manager.js`)
- ✅ 前端日志接收接口 (`api-enhanced/module/log_frontend.js`)
- ✅ 按日期分文件存储 (`logs/queue/queue-YYYY-MM-DD.log`)

### 前端日志系统
- ✅ 日志工具类 (`SPlayer/src/utils/queueLogger.js`)
- ✅ 歌曲列表日志 (`SPlayer/src/components/List/SongList.vue`)
- ✅ 队列Store日志 (`SPlayer/src/stores/queueData.js`)
- ⏳ 播放器日志 (`SPlayer/src/utils/Player.js` - 待完成)

---

## 🔍 快速查看日志

### 后端日志
```bash
# 实时监控
tail -f /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log

# 查看今天的日志
cat /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log

# 搜索错误
grep "ERROR" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log

# 搜索添加操作
grep "ADD_QUEUE" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log

# 搜索自动播放
grep "AUTO_PLAY" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log
```

### 前端日志
- 打开浏览器控制台（F12）
- 筛选 `[QUEUE-LOG]`
- 或执行：`queueLogger.getLocalLogs()`

---

## 📝 记录的操作

### 后端
- ✅ 添加歌曲（开始/成功/失败/重复）
- ✅ 移除歌曲（开始/成功/未找到）
- ✅ 获取下一首（开始/成功/空队列）
- ✅ 清空队列（成功）
- ✅ 自动播放（成功/失败）
- ✅ 错误和异常堆栈

### 前端
- ✅ 用户点击添加队列
- ✅ 添加队列结果
- ✅ 队列模式切换
- ✅ 获取下一首歌曲
- ✅ Store操作日志
- ⏳ 播放器事件（待完成）
- ⏳ 自动播放逻辑（待完成）

---

## 🔧 常见问题诊断

### 1. 添加队列失败
```bash
# 查看失败原因
grep "ADD_QUEUE_FAILED\|ADD_QUEUE_DUPLICATE" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -10
```

**可能原因**:
- 歌曲信息不完整（songId缺失）
- 歌曲已在队列中

### 2. 自动播放不工作
```bash
# 检查队列模式
grep "QUEUE_MODE" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -5

# 检查自动播放
grep "AUTO_PLAY\|GET_NEXT" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -10
```

**可能原因**:
- 队列模式未开启
- 队列为空
- 播放器初始化失败

### 3. 队列长度异常
```bash
# 追踪队列长度
grep "totalQueueLength\|remainingLength" /home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log | tail -20
```

---

## 📊 统计脚本

```bash
#!/bin/bash
# 快速统计今日队列操作

LOG="/home/chenbang/app/netease/api-enhanced/logs/queue/queue-$(date +%Y-%m-%d).log"

echo "### 今日队列统计 ###"
echo "添加次数: $(grep -c "ADD_QUEUE_SUCCESS" "$LOG")"
echo "移除次数: $(grep -c "REMOVE_QUEUE_SUCCESS" "$LOG")"
echo "自动播放: $(grep -c "GET_NEXT_SUCCESS" "$LOG")"
echo "错误次数: $(grep -c '"level":"ERROR"' "$LOG")"
echo ""

echo "### 用户点歌排行 ###"
grep "addedBy" "$LOG" | grep -oP '"addedBy":"[^"]*"' | sort | uniq -c | sort -nr | head -10
```

---

## ⏭️ 待完成任务

### 前端日志完成
需要在 `SPlayer/src/utils/Player.js` 添加日志：

1. **播放器事件**
   - 播放开始
   - 播放暂停
   - 播放结束
   - 播放错误

2. **自动播放逻辑**
   - 自动播放触发
   - 自动播放成功/失败
   - 队列模式检查

### 实施步骤
```javascript
// 1. 导入logger
import queueLogger from "@/utils/queueLogger";

// 2. 在播放结束事件中添加
player?.on("end", () => {
  // 记录播放结束
  queueLogger.logPlayerEvent("ended", music.playSongData, {
    queueMode: queue.queueMode,
    hasQueue: queue.hasQueue,
  });
  
  // 触发自动播放
  if (queue.queueMode && queue.hasQueue) {
    queueLogger.logAutoPlayTrigger(music.playSongData, true);
    // ...
  }
});
```

---

## 📁 文件位置

### 后端
- 日志工具：`api-enhanced/util/queueLogger.js`
- 队列管理：`api-enhanced/module/queue_manager.js`
- 日志接口：`api-enhanced/module/log_frontend.js`
- 日志文件：`api-enhanced/logs/queue/queue-YYYY-MM-DD.log`

### 前端
- 日志工具：`SPlayer/src/utils/queueLogger.js`
- 歌曲列表：`SPlayer/src/components/List/SongList.vue`
- 队列Store：`SPlayer/src/stores/queueData.js`
- 播放器：`SPlayer/src/utils/Player.js`（待完成）

---

## 🚀 服务重启

```bash
# 重启API服务（加载日志模块）
pkill -f "node app.js"
cd /home/chenbang/app/netease/api-enhanced
PORT=3001 nohup node app.js > /tmp/api-enhanced.log 2>&1 &

# 构建前端（前端日志集成）
cd /home/chenbang/app/netease/SPlayer
npm run build
sudo cp -r out/renderer/* /var/www/splayer/
sudo chmod -R 755 /var/www/splayer
sudo nginx -s reload
```

---

## 📞 API测试

```bash
# 测试前端日志接口
curl -X POST "https://192.168.1.118:7899/api/log/frontend" \
  -k \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "type": "TEST",
    "data": {"test": "hello"},
    "userAgent": "Test/1.0"
  }'

# 应返回
# {"code":200,"message":"日志已记录"}
```

---

## 📝 日志格式示例

### 后端日志（NDJSON）
```json
{"timestamp":"2025-10-13T15:30:45.123Z","level":"INFO","type":"ADD_QUEUE_SUCCESS","queueItemId":1,"songId":186045,"songName":"七里香","addedBy":"张三","position":5,"totalQueueLength":5}
{"timestamp":"2025-10-13T15:32:30.234Z","level":"INFO","type":"GET_NEXT_SUCCESS","queueItemId":1,"songId":186045,"songName":"七里香","artist":"周杰伦","addedBy":"张三","remainingLength":4}
```

### 前端日志（控制台）
```
[QUEUE-LOG] INFO USER_ADD_QUEUE {action: "ADD_TO_QUEUE", songId: 186045, songName: "七里香", ...}
[QUEUE-LOG] INFO STORE_ADD_SONG_SUCCESS {songId: 186045, songName: "七里香", addedBy: "张三", ...}
[QUEUE-LOG] INFO AUTO_PLAY_TRIGGER {currentSongId: 186044, queueModeEnabled: true, ...}
```
