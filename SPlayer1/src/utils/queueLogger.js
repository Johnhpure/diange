/**
 * 点歌队列前端日志工具
 */
import axios from "@/utils/request";

class QueueLogger {
  constructor() {
    this.logs = [];
    this.maxLocalLogs = 100;
    this.enabled = true;
  }

  /**
   * 记录日志（本地）
   */
  _recordLocal(level, type, data) {
    const log = {
      timestamp: new Date().toISOString(),
      level,
      type,
      data,
      userAgent: navigator.userAgent,
    };

    this.logs.push(log);

    if (this.logs.length > this.maxLocalLogs) {
      this.logs.shift();
    }

    const color =
      level === "ERROR" ? "color: red" : level === "WARN" ? "color: orange" : "color: blue";
    console.log(`%c[QUEUE-LOG] ${level} ${type}`, color, data);
  }

  /**
   * 发送日志到后端
   */
  async _sendToBackend(level, type, data) {
    if (!this.enabled) return;

    try {
      await axios({
        method: "POST",
        url: "/log/frontend",
        data: {
          level,
          type,
          data,
          userAgent: navigator.userAgent,
        },
      });
    } catch (error) {
      console.error("[QUEUE-LOG] 发送日志失败:", error);
    }
  }

  info(type, data) {
    this._recordLocal("INFO", type, data);
    this._sendToBackend("INFO", type, data);
  }

  warn(type, data) {
    this._recordLocal("WARN", type, data);
    this._sendToBackend("WARN", type, data);
  }

  error(type, data) {
    this._recordLocal("ERROR", type, data);
    this._sendToBackend("ERROR", type, data);
  }

  logAddToQueue(song, user, result) {
    const data = {
      action: "ADD_TO_QUEUE",
      songId: song.id,
      songName: song.name,
      artist: song.artist || song.ar?.[0]?.name,
      user,
      result: result.success ? "SUCCESS" : "FAILED",
      message: result.message,
      timestamp: Date.now(),
    };

    if (result.success) {
      this.info("USER_ADD_QUEUE", data);
    } else {
      this.warn("USER_ADD_QUEUE_FAILED", data);
    }
  }

  logQueueModeToggle(enabled, queueLength) {
    this.info("QUEUE_MODE_TOGGLE", {
      action: "TOGGLE_QUEUE_MODE",
      enabled,
      queueLength,
      timestamp: Date.now(),
    });
  }

  logAutoPlayTrigger(currentSong, queueModeEnabled) {
    this.info("AUTO_PLAY_TRIGGER", {
      action: "AUTO_PLAY_TRIGGER",
      currentSongId: currentSong?.id,
      currentSongName: currentSong?.name,
      queueModeEnabled,
      timestamp: Date.now(),
    });
  }

  logGetNextSong(success, nextSong, error) {
    const data = {
      action: "GET_NEXT_SONG",
      success,
      nextSongId: nextSong?.songId,
      nextSongName: nextSong?.songName,
      error: error?.message,
      timestamp: Date.now(),
    };

    if (success) {
      this.info("GET_NEXT_SONG", data);
    } else {
      this.error("GET_NEXT_SONG_FAILED", data);
    }
  }

  logAutoPlaySong(song, success, error) {
    const data = {
      action: "AUTO_PLAY_SONG",
      songId: song?.songId,
      songName: song?.songName,
      artist: song?.artist,
      addedBy: song?.addedBy,
      success,
      error: error?.message,
      timestamp: Date.now(),
    };

    if (success) {
      this.info("AUTO_PLAY_SONG", data);
    } else {
      this.error("AUTO_PLAY_SONG_FAILED", data);
    }
  }

  logPlayerEvent(eventType, songData, extraData = {}) {
    this.info(`PLAYER_${eventType.toUpperCase()}`, {
      eventType,
      songId: songData?.id,
      songName: songData?.name,
      ...extraData,
      timestamp: Date.now(),
    });
  }

  logApiCall(endpoint, method, params, result) {
    const data = {
      endpoint,
      method,
      params,
      result: result.success ? "SUCCESS" : "FAILED",
      statusCode: result.statusCode,
      message: result.message,
      timestamp: Date.now(),
    };

    if (result.success) {
      this.info("API_CALL", data);
    } else {
      this.error("API_CALL_FAILED", data);
    }
  }

  logError(operation, error, context = {}) {
    this.error("ERROR", {
      operation,
      errorMessage: error?.message || String(error),
      errorStack: error?.stack,
      context,
      timestamp: Date.now(),
    });
  }

  getLocalLogs() {
    return [...this.logs];
  }

  clearLocalLogs() {
    this.logs = [];
  }

  exportLogs() {
    const blob = new Blob([JSON.stringify(this.logs, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `queue-logs-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }
}

const queueLogger = new QueueLogger();

export default queueLogger;
