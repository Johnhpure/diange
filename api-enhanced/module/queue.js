/**
 * GET /queue - 获取点歌队列
 */
const queueManager = require('./queue_manager');

module.exports = (query, request) => {
  return {
    status: 200,
    body: queueManager.getQueue(),
  };
};
