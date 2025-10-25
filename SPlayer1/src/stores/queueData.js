import { defineStore } from "pinia";
import { getQueue, addToQueue, removeFromQueue, getNextFromQueue, clearQueue } from "@/api/queue";
import queueLogger from "@/utils/queueLogger";

const useQueueDataStore = defineStore("queueData", {
  state: () => ({
    // 队列列表
    queue: [],
    // 队列总数
    total: 0,
    // 是否启用队列模式（默认开启）
    queueMode: true,
    // 当前播放的队列项ID
    currentQueueId: null,
    // 轮询定时器
    pollingTimer: null,
    // 队列面板是否打开
    queuePanelOpen: false,
  }),

  getters: {
    // 获取队列长度
    queueLength: (state) => state.queue.length,

    // 是否有歌曲在队列中
    hasQueue: (state) => state.queue.length > 0,
  },

  actions: {
    /**
     * 刷新队列数据
     */
    async refreshQueue() {
      try {
        const res = await getQueue();
        if (res.code === 200) {
          this.queue = res.queue || [];
          this.total = res.total || 0;
        }
      } catch (error) {
        console.error("❌ 获取队列失败:", error);
      }
    },

    /**
     * 添加歌曲到队列
     */
    async addSong(song, addedBy = "匿名用户") {
      try {
        // 提取艺术家名称（支持多种格式）
        let artistName = "未知艺术家";
        if (song.artist) {
          artistName = song.artist;
        } else if (song.artists && Array.isArray(song.artists) && song.artists.length > 0) {
          artistName = song.artists.map(a => a.name).join(" / ");
        } else if (song.ar && Array.isArray(song.ar) && song.ar.length > 0) {
          artistName = song.ar.map(a => a.name).join(" / ");
        }

        const songData = {
          id: song.id,
          name: song.name || song.songName,
          artist: artistName,
          album: song.album || song.al?.name,
          cover: song.cover || song.al?.picUrl,
          // 确保duration是毫秒数，网易云API返回的dt是毫秒
          duration: song.duration || song.dt || song.time || 0,
        };

        queueLogger.info("STORE_ADD_SONG_START", { songData, addedBy });

        const res = await addToQueue(songData, addedBy);

        if (res.code === 200) {
          console.log("✅ 添加到队列:", res.message);
          queueLogger.info("STORE_ADD_SONG_SUCCESS", {
            songId: songData.id,
            songName: songData.name,
            addedBy,
            response: res,
          });
          await this.refreshQueue();
          return { success: true, message: res.message };
        } else {
          console.warn("⚠️ 添加失败:", res.message);
          queueLogger.warn("STORE_ADD_SONG_FAILED", {
            songData,
            addedBy,
            response: res,
          });
          return { success: false, message: res.message };
        }
      } catch (error) {
        console.error("❌ 添加到队列失败:", error);
        queueLogger.logError("STORE_ADD_SONG", error, { song, addedBy });
        return { success: false, message: "添加失败" };
      }
    },

    /**
     * 从队列移除歌曲
     */
    async removeSong(id) {
      try {
        const res = await removeFromQueue(id);
        if (res.code === 200) {
          console.log("✅ 已从队列移除");
          await this.refreshQueue();
          return true;
        }
      } catch (error) {
        console.error("❌ 移除失败:", error);
      }
      return false;
    },

    /**
     * 获取队列下一首歌曲
     * @param {string|number} currentSongId - 当前播放的歌曲ID（可选）
     */
    async getNext(currentSongId = null) {
      try {
        queueLogger.info("STORE_GET_NEXT_START", {
          currentQueueLength: this.queue.length,
          queueMode: this.queueMode,
          currentSongId,
        });

        const res = await getNextFromQueue(currentSongId);

        if (res.code === 200 && res.data) {
          this.currentQueueId = res.data.id;

          queueLogger.logGetNextSong(true, res.data, null);
          queueLogger.info("STORE_GET_NEXT_SUCCESS", {
            nextSong: res.data,
            remaining: res.remaining,
          });

          await this.refreshQueue();
          return res.data;
        }

        queueLogger.warn("STORE_GET_NEXT_EMPTY", {
          responseCode: res.code,
          message: res.message,
        });
        return null;
      } catch (error) {
        console.error("❌ 获取下一首失败:", error);
        queueLogger.logGetNextSong(false, null, error);
        queueLogger.logError("STORE_GET_NEXT", error, {
          queueLength: this.queue.length,
          currentSongId,
        });
        return null;
      }
    },

    /**
     * 清空队列
     */
    async clear() {
      try {
        const res = await clearQueue();
        if (res.code === 200) {
          console.log("✅ 队列已清空");
          this.queue = [];
          this.total = 0;
          this.currentQueueId = null;
          return true;
        }
      } catch (error) {
        console.error("❌ 清空队列失败:", error);
      }
      return false;
    },

    /**
     * 启用队列模式
     */
    enableQueueMode() {
      this.queueMode = true;
      this.startPolling();

      queueLogger.logQueueModeToggle(true, this.queue.length);
      queueLogger.info("QUEUE_MODE_ENABLED", {
        queueLength: this.queue.length,
        timestamp: Date.now(),
      });

      console.log("🎵 队列模式已启用");
    },

    /**
     * 禁用队列模式
     */
    disableQueueMode() {
      this.queueMode = false;
      this.stopPolling();

      queueLogger.logQueueModeToggle(false, this.queue.length);
      queueLogger.info("QUEUE_MODE_DISABLED", {
        queueLength: this.queue.length,
        timestamp: Date.now(),
      });

      console.log("⏸️ 队列模式已禁用");
    },

    /**
     * 开始轮询队列状态
     */
    startPolling() {
      // 清除现有定时器
      this.stopPolling();

      // 立即刷新一次
      this.refreshQueue();

      // 每5秒刷新一次
      this.pollingTimer = setInterval(() => {
        this.refreshQueue();
      }, 5000);

      console.log("🔄 队列轮询已启动");
    },

    /**
     * 停止轮询
     */
    stopPolling() {
      if (this.pollingTimer) {
        clearInterval(this.pollingTimer);
        this.pollingTimer = null;
        console.log("⏹️ 队列轮询已停止");
      }
    },

    /**
     * 切换队列面板显示状态
     */
    toggleQueuePanel() {
      this.queuePanelOpen = !this.queuePanelOpen;

      // 打开面板时刷新队列
      if (this.queuePanelOpen) {
        this.refreshQueue();
      }
    },

    /**
     * 重置队列状态
     */
    reset() {
      this.queue = [];
      this.total = 0;
      this.queueMode = false;
      this.currentQueueId = null;
      this.queuePanelOpen = false;
      this.stopPolling();
    },
  },
});

export default useQueueDataStore;
