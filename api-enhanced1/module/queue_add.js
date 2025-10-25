/**
 * POST /queue/add - 添加歌曲到队列
 */
const queueManager = require('./queue_manager');

module.exports = (query, request) => {
  const { song, addedBy } = query;
  
  if (!song) {
    return {
      status: 200,  // ✅ 统一返回 HTTP 200
      body: { code: 400, message: '缺少歌曲信息' },
    };
  }

  const result = queueManager.addToQueue(song, addedBy);
  
  return {
    status: 200,  // ✅ 统一返回 HTTP 200，通过 body.code 区分成功/失败
    body: result,
  };
};
