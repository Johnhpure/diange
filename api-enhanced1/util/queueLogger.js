/**
 * 点歌队列专用日志记录器
 */
const fs = require('fs');
const path = require('path');

// 日志目录
const LOG_DIR = path.join(__dirname, '../logs');
const QUEUE_LOG_DIR = path.join(LOG_DIR, 'queue');

// 确保日志目录存在
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}
if (!fs.existsSync(QUEUE_LOG_DIR)) {
  fs.mkdirSync(QUEUE_LOG_DIR, { recursive: true });
}

/**
 * 获取当前日期的日志文件路径
 */
function getLogFilePath() {
  const date = new Date();
  const dateStr = date.toISOString().split('T')[0]; // YYYY-MM-DD
  return path.join(QUEUE_LOG_DIR, `queue-${dateStr}.log`);
}

/**
 * 格式化日志内容
 */
function formatLog(level, type, data) {
  const timestamp = new Date().toISOString();
  const logData = {
    timestamp,
    level,
    type,
    ...data,
  };
  return JSON.stringify(logData) + '\n';
}

/**
 * 写入日志
 */
function writeLog(level, type, data) {
  try {
    const logFilePath = getLogFilePath();
    const logContent = formatLog(level, type, data);
    
    fs.appendFileSync(logFilePath, logContent, 'utf8');
    
    // 同时输出到控制台（开发环境）
    if (process.env.NODE_ENV !== 'production') {
      const color = level === 'ERROR' ? '\x1b[31m' : level === 'WARN' ? '\x1b[33m' : '\x1b[36m';
      console.log(`${color}[QUEUE-LOG]`, level, type, '\x1b[0m', data);
    }
  } catch (error) {
    console.error('日志写入失败:', error);
  }
}

/**
 * 记录信息日志
 */
function info(type, data) {
  writeLog('INFO', type, data);
}

/**
 * 记录警告日志
 */
function warn(type, data) {
  writeLog('WARN', type, data);
}

/**
 * 记录错误日志
 */
function error(type, data) {
  writeLog('ERROR', type, data);
}

/**
 * 记录API请求
 */
function logApiRequest(endpoint, method, params, ip) {
  info('API_REQUEST', {
    endpoint,
    method,
    params,
    ip,
  });
}

/**
 * 记录API响应
 */
function logApiResponse(endpoint, statusCode, data, duration) {
  info('API_RESPONSE', {
    endpoint,
    statusCode,
    responseData: data,
    duration: `${duration}ms`,
  });
}

/**
 * 记录队列操作
 */
function logQueueOperation(operation, data, user, result) {
  info('QUEUE_OPERATION', {
    operation, // 'ADD', 'REMOVE', 'CLEAR', 'GET_NEXT'
    data,
    user,
    result,
  });
}

/**
 * 记录自动播放
 */
function logAutoPlay(songId, songName, queueId, user, success) {
  info('AUTO_PLAY', {
    songId,
    songName,
    queueId,
    user,
    success,
  });
}

/**
 * 记录错误
 */
function logError(operation, errorMsg, stack, context) {
  error('ERROR', {
    operation,
    errorMsg,
    stack,
    context,
  });
}

/**
 * 记录前端日志（接收前端发送的日志）
 */
function logFrontend(logData) {
  const { level = 'INFO', type, data, userAgent, ip } = logData;
  writeLog(level, `FRONTEND_${type}`, {
    ...data,
    userAgent,
    ip,
  });
}

module.exports = {
  info,
  warn,
  error,
  logApiRequest,
  logApiResponse,
  logQueueOperation,
  logAutoPlay,
  logError,
  logFrontend,
};
