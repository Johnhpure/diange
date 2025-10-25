/**
 * GET /queue/stats - 获取队列统计信息
 */
const queueManager = require('./queue_manager');

module.exports = (query, request) => {
  const result = queueManager.getQueueStats();
  
  return {
    status: 200,
    body: result,
  };
};
