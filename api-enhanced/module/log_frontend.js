/**
 * POST /log/frontend - 接收前端日志
 */
const logger = require('../util/queueLogger');

module.exports = (query, request) => {
  try {
    const { level, type, data, userAgent } = query;
    
    // 记录前端日志
    logger.logFrontend({
      level: level || 'INFO',
      type: type || 'UNKNOWN',
      data: data || {},
      userAgent: userAgent || '',
    });
    
    return {
      status: 200,
      body: {
        code: 200,
        message: '日志已记录',
      },
    };
  } catch (error) {
    return {
      status: 500,
      body: {
        code: 500,
        message: '日志记录失败',
      },
    };
  }
};
