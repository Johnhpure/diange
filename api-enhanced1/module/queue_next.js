/**
 * GET /queue/next - 获取并播放下一首
 */
const queueManager = require('./queue_manager');

module.exports = (query, request) => {
  // 从query参数中获取当前歌曲ID
  const currentSongId = query.currentSongId || null;
  const result = queueManager.getNext(currentSongId);
  
  return {
    status: 200,  // ✅ 统一返回 HTTP 200，通过 body.code 区分成功/失败
    body: result,
  };
};
