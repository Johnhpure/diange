/**
 * POST /queue/clear - 清空队列
 */
const queueManager = require('./queue_manager');

module.exports = (query, request) => {
  const result = queueManager.clearQueue();
  
  return {
    status: 200,
    body: result,
  };
};
