/**
 * 点歌队列管理模块
 * 支持多用户共享点歌队列
 */

const logger = require('../util/queueLogger');

// 内存存储队列（重启会清空）
let songQueue = [];
let currentQueueId = 0;

/**
 * 获取完整队列
 */
function getQueue() {
  return {
    code: 200,
    queue: songQueue,
    total: songQueue.length,
  };
}

/**
 * 添加歌曲到队列
 * @param {Object} song - 歌曲信息
 * @param {string} addedBy - 点歌人（可选）
 */
function addToQueue(song, addedBy = '匿名用户') {
  try {
    logger.info('ADD_QUEUE_START', { songId: song?.id, songName: song?.name, addedBy });

    if (!song || !song.id) {
      logger.warn('ADD_QUEUE_FAILED', {
        reason: '歌曲信息不完整',
        song,
        addedBy,
      });
      return {
        code: 400,
        message: '歌曲信息不完整',
      };
    }

    // 规范化songId（处理字符串和数字）
    const normalizedSongId = String(song.id);

    // 检查是否已在队列中（使用字符串比较避免类型问题）
    const exists = songQueue.some(item => String(item.songId) === normalizedSongId);
    if (exists) {
      logger.warn('ADD_QUEUE_DUPLICATE', {
        songId: song.id,
        songName: song.name || song.songName,
        addedBy,
        currentQueueLength: songQueue.length,
      });
      return {
        code: 400,
        message: '该歌曲已在队列中',
      };
    }

    // 提取艺术家名称（支持多种格式）
    let artistName = '未知艺术家';
    if (song.artist) {
      artistName = song.artist;
    } else if (song.artists && Array.isArray(song.artists) && song.artists.length > 0) {
      artistName = song.artists.map(a => a.name).join(' / ');
    } else if (song.ar && Array.isArray(song.ar) && song.ar.length > 0) {
      artistName = song.ar.map(a => a.name).join(' / ');
    }

    const queueItem = {
      id: ++currentQueueId,
      songId: song.id,  // 保持原始类型
      songName: song.name || song.songName || '未知歌曲',
      artist: artistName,
      album: song.album || song.al?.name || '',
      cover: song.cover || song.al?.picUrl || '',
      duration: song.duration || song.dt || 0,
      addedBy: addedBy,
      addedAt: Date.now(),
    };

    songQueue.push(queueItem);

    logger.logQueueOperation('ADD', queueItem, addedBy, 'SUCCESS');
    logger.info('ADD_QUEUE_SUCCESS', {
      queueItemId: queueItem.id,
      songId: queueItem.songId,
      songName: queueItem.songName,
      addedBy,
      position: songQueue.length,
      totalQueueLength: songQueue.length,
    });

    return {
      code: 200,
      message: '添加成功',
      data: queueItem,
      position: songQueue.length,
    };
  } catch (error) {
    logger.logError('ADD_QUEUE', error.message, error.stack, { song, addedBy });
    return {
      code: 500,
      message: '添加失败',
    };
  }
}

/**
 * 从队列中移除歌曲
 * @param {number} id - 队列项ID
 */
function removeFromQueue(id) {
  try {
    logger.info('REMOVE_QUEUE_START', { queueItemId: id });

    const index = songQueue.findIndex(item => item.id === parseInt(id));
    
    if (index === -1) {
      logger.warn('REMOVE_QUEUE_NOT_FOUND', {
        queueItemId: id,
        currentQueueLength: songQueue.length,
      });
      return {
        code: 404,
        message: '队列中未找到该歌曲',
      };
    }

    const removed = songQueue.splice(index, 1)[0];

    logger.logQueueOperation('REMOVE', removed, removed.addedBy, 'SUCCESS');
    logger.info('REMOVE_QUEUE_SUCCESS', {
      queueItemId: removed.id,
      songId: removed.songId,
      songName: removed.songName,
      remainingLength: songQueue.length,
    });

    return {
      code: 200,
      message: '移除成功',
      data: removed,
    };
  } catch (error) {
    logger.logError('REMOVE_QUEUE', error.message, error.stack, { id });
    return {
      code: 500,
      message: '移除失败',
    };
  }
}

/**
 * 获取并移除队列中的下一首歌曲
 */
function getNext(currentSongId = null) {
  try {
    logger.info('GET_NEXT_START', { 
      currentQueueLength: songQueue.length,
      currentSongId 
    });

    if (songQueue.length === 0) {
      logger.warn('GET_NEXT_EMPTY', { message: '队列为空' });
      return {
        code: 404,
        message: '队列为空',
        data: null,
      };
    }

    let nextSong = null;

    // 如果提供了当前歌曲ID，需要先从队列中移除该歌曲
    if (currentSongId) {
      // 查找当前歌曲在队列中的位置
      const currentIndex = songQueue.findIndex(item => 
        String(item.songId) === String(currentSongId)
      );

      if (currentIndex !== -1) {
        // 移除当前播放完成的歌曲
        const removedSong = songQueue.splice(currentIndex, 1)[0];
        logger.info('AUTO_REMOVE_PLAYED_SONG', {
          currentSongId,
          currentIndex,
          removedSong: {
            id: removedSong.id,
            songName: removedSong.songName,
            addedBy: removedSong.addedBy,
          },
          remainingLength: songQueue.length,
        });
        logger.logQueueOperation('AUTO_REMOVE', removedSong, removedSong.addedBy, 'SUCCESS');

        // 检查队列是否还有歌曲
        if (songQueue.length === 0) {
          logger.warn('QUEUE_EMPTY_AFTER_REMOVE', { message: '移除后队列为空' });
          return {
            code: 404,
            message: '队列已播放完毕',
            data: null,
          };
        }

        // 移除后，获取下一首
        // 如果移除的不是最后一首，返回同位置的歌曲（原来的下一首）
        // 如果移除的是最后一首，返回队列第一首
        const nextIndex = currentIndex < songQueue.length ? currentIndex : 0;
        nextSong = songQueue[nextIndex];
        
        logger.info('GET_NEXT_AFTER_REMOVE', {
          nextIndex,
          nextSongId: nextSong.songId,
          nextSongName: nextSong.songName,
          remainingInQueue: songQueue.length,
        });
      } else {
        // 当前歌曲不在队列中（可能已被移除或是队列外的歌曲）
        logger.warn('CURRENT_SONG_NOT_IN_QUEUE', {
          currentSongId,
          queueLength: songQueue.length,
        });
        // 返回队列第一首
        nextSong = songQueue[0];
      }
    } else {
      // 没有提供当前歌曲ID，返回队列第一首（不移除）
      nextSong = songQueue[0];
    }

    if (!nextSong) {
      logger.warn('GET_NEXT_NO_SONG', { message: '无法获取下一首' });
      return {
        code: 404,
        message: '队列已空',
        data: null,
      };
    }

    logger.logQueueOperation('GET_NEXT', nextSong, nextSong.addedBy, 'SUCCESS');
    logger.logAutoPlay(nextSong.songId, nextSong.songName, nextSong.id, nextSong.addedBy, true);
    logger.info('GET_NEXT_SUCCESS', {
      queueItemId: nextSong.id,
      songId: nextSong.songId,
      songName: nextSong.songName,
      artist: nextSong.artist,
      addedBy: nextSong.addedBy,
      remainingLength: songQueue.length,
    });

    return {
      code: 200,
      message: '获取成功',
      data: nextSong,
      remaining: songQueue.length,
    };
  } catch (error) {
    logger.logError('GET_NEXT', error.message, error.stack, { 
      queueLength: songQueue.length,
      currentSongId 
    });
    return {
      code: 500,
      message: '获取失败',
      data: null,
    };
  }
}

/**
 * 清空队列
 */
function clearQueue() {
  try {
    const count = songQueue.length;
    const clearedSongs = songQueue.map(item => ({
      id: item.id,
      songName: item.songName,
      addedBy: item.addedBy,
    }));
    
    songQueue = [];
    
    logger.logQueueOperation('CLEAR', { clearedCount: count, songs: clearedSongs }, 'SYSTEM', 'SUCCESS');
    logger.info('CLEAR_QUEUE_SUCCESS', {
      clearedCount: count,
      clearedSongs: clearedSongs.slice(0, 5), // 只记录前5首
    });
    
    return {
      code: 200,
      message: `已清空 ${count} 首歌曲`,
      cleared: count,
    };
  } catch (error) {
    logger.logError('CLEAR_QUEUE', error.message, error.stack, { queueLength: songQueue.length });
    return {
      code: 500,
      message: '清空失败',
    };
  }
}

/**
 * 获取队列统计信息
 */
function getQueueStats() {
  return {
    code: 200,
    total: songQueue.length,
    totalDuration: songQueue.reduce((sum, item) => sum + (item.duration || 0), 0),
    users: [...new Set(songQueue.map(item => item.addedBy))],
  };
}

module.exports = {
  getQueue,
  addToQueue,
  removeFromQueue,
  getNext,
  clearQueue,
  getQueueStats,
};
