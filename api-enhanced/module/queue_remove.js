/**
 * POST /queue/remove - 从队列移除歌曲
 */
const queueManager = require('./queue_manager');

module.exports = (query, request) => {
  const { id } = query;
  
  if (!id) {
    return {
      status: 200,  // ✅ 统一返回 HTTP 200
      body: { code: 400, message: '缺少队列项ID' },
    };
  }

  const result = queueManager.removeFromQueue(id);
  
  return {
    status: 200,  // ✅ 统一返回 HTTP 200，通过 body.code 区分成功/失败
    body: result,
  };
};
