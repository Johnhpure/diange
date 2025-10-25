import axios from "@/utils/request";

/**
 * 获取点歌队列
 */
export const getQueue = () => {
  return axios({
    method: "GET",
    url: "/queue",
    params: {
      timestamp: new Date().getTime(),
    },
  });
};

/**
 * 添加歌曲到队列
 * @param {Object} song - 歌曲信息
 * @param {string} addedBy - 点歌人
 */
export const addToQueue = (song, addedBy = "匿名用户") => {
  return axios({
    method: "POST",
    url: "/queue/add",
    data: {
      song,
      addedBy,
    },
  });
};

/**
 * 从队列移除歌曲
 * @param {number} id - 队列项ID
 */
export const removeFromQueue = (id) => {
  return axios({
    method: "POST",
    url: "/queue/remove",
    data: { id },
  });
};

/**
 * 获取并播放下一首
 * @param {string|number} currentSongId - 当前播放的歌曲ID（可选）
 */
export const getNextFromQueue = (currentSongId = null) => {
  const params = {
    timestamp: new Date().getTime(),
  };
  
  // 如果提供了当前歌曲ID，添加到参数中
  if (currentSongId) {
    params.currentSongId = currentSongId;
  }
  
  return axios({
    method: "GET",
    url: "/queue/next",
    params,
  });
};

/**
 * 清空队列
 */
export const clearQueue = () => {
  return axios({
    method: "POST",
    url: "/queue/clear",
  });
};

/**
 * 获取队列统计
 */
export const getQueueStats = () => {
  return axios({
    method: "GET",
    url: "/queue/stats",
    params: {
      timestamp: new Date().getTime(),
    },
  });
};
