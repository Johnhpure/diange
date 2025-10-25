<!-- 点歌队列面板 -->
<template>
  <n-drawer v-model:show="showDrawer" :width="isMobile ? '100%' : 420" placement="right">
    <n-drawer-content title="🎵 点歌队列" closable>
      <template #header-extra>
        <n-badge :value="queue.queueLength" :max="99">
          <n-icon size="22">
            <SvgIcon icon="record" />
          </n-icon>
        </n-badge>
      </template>

      <!-- 队列控制 -->
      <div class="queue-controls">
        <n-space justify="space-between">
          <n-button-group>
            <n-button :type="queue.queueMode ? 'primary' : 'default'" @click="toggleQueueMode">
              <template #icon>
                <n-icon>
                  <SvgIcon :icon="queue.queueMode ? 'play-circle' : 'play-circle-outline'" />
                </n-icon>
              </template>
              {{ queue.queueMode ? "队列模式" : "开启队列" }}
            </n-button>
            <n-button @click="refreshQueue">
              <template #icon>
                <n-icon>
                  <SvgIcon icon="refresh" />
                </n-icon>
              </template>
              刷新
            </n-button>
          </n-button-group>

          <n-popconfirm @positive-click="clearQueue">
            <template #trigger>
              <n-button :disabled="!queue.hasQueue" type="error" ghost>
                <template #icon>
                  <n-icon>
                    <SvgIcon icon="delete-outline" />
                  </n-icon>
                </template>
                清空
              </n-button>
            </template>
            确认清空队列吗？此操作不可恢复！
          </n-popconfirm>
        </n-space>
      </div>

      <!-- 队列统计 -->
      <div v-if="queue.hasQueue" class="queue-stats">
        <n-card size="small" :bordered="false">
          <n-space>
            <n-statistic label="队列歌曲" :value="queue.queueLength" />
            <n-statistic label="总时长" :value="formatTotalDuration()" />
          </n-space>
        </n-card>
      </div>

      <!-- 队列列表 -->
      <div class="queue-list">
        <Transition name="fade" mode="out-in">
          <!-- 空队列 -->
          <n-empty
            v-if="!queue.hasQueue"
            description="队列为空，快去添加歌曲吧！"
            size="large"
            style="margin-top: 60px"
          >
            <template #icon>
              <n-icon size="80">
                <SvgIcon icon="queue-music" />
              </n-icon>
            </template>
          </n-empty>

          <!-- 歌曲列表 -->
          <div v-else class="songs-list">
            <TransitionGroup name="list">
              <n-card
                v-for="(item, index) in queue.queue"
                :key="item.id"
                class="song-item"
                hoverable
                :class="{ current: item.id === queue.currentQueueId }"
              >
                <!-- 序号 -->
                <div class="song-index">
                  <n-text v-if="item.id !== queue.currentQueueId" depth="3">{{ index + 1 }}</n-text>
                  <n-icon v-else size="20" color="var(--n-color-target)">
                    <SvgIcon icon="music-note" />
                  </n-icon>
                </div>

                <!-- 封面 -->
                <div v-if="item.cover" class="song-cover">
                  <n-image :src="item.cover + '?param=100y100'" :preview-disabled="true" />
                </div>
                <div v-else class="song-cover-placeholder">
                  <n-icon size="30" depth="3">
                    <SvgIcon icon="music-note" />
                  </n-icon>
                </div>

                <!-- 信息 -->
                <div class="song-info">
                  <n-ellipsis class="song-name" :line-clamp="1">
                    <n-text :depth="item.id === queue.currentQueueId ? 1 : 2">
                      {{ item.songName || "未知歌曲" }}
                    </n-text>
                  </n-ellipsis>
                  <n-ellipsis class="song-artist" :line-clamp="1">
                    <n-text depth="3" style="font-size: 12px">
                      {{ item.artist || "未知艺术家" }}
                    </n-text>
                  </n-ellipsis>
                  <n-space style="font-size: 11px">
                    <n-text depth="3">点歌人: {{ item.addedBy || "匿名" }}</n-text>
                    <n-text v-if="item.duration" depth="3">
                      · 时长: {{ formatSongDuration(item.duration) }}
                    </n-text>
                  </n-space>
                </div>

                <!-- 操作 -->
                <div class="song-actions">
                  <n-popconfirm @positive-click="removeSong(item.id)">
                    <template #trigger>
                      <n-button size="small" type="error" ghost circle>
                        <template #icon>
                          <n-icon>
                            <SvgIcon icon="close" />
                          </n-icon>
                        </template>
                      </n-button>
                    </template>
                    确认移除此歌曲？
                  </n-popconfirm>
                </div>
              </n-card>
            </TransitionGroup>
          </div>
        </Transition>
      </div>
    </n-drawer-content>
  </n-drawer>
</template>

<script setup>
import { computed, watch, onBeforeUnmount } from "vue";
import { queueData } from "@/stores";

const queue = queueData();

// 自动刷新定时器
let panelRefreshTimer = null;

const isMobile = computed(() => window.innerWidth <= 700);

const showDrawer = computed({
  get: () => queue.queuePanelOpen,
  set: (val) => {
    if (!val) {
      queue.queuePanelOpen = false;
    }
  },
});

const refreshQueue = async () => {
  await queue.refreshQueue();
  $message.success("队列已刷新");
};

const clearQueue = async () => {
  const success = await queue.clear();
  if (success) {
    $message.success("队列已清空");
  } else {
    $message.error("清空失败");
  }
};

const removeSong = async (id) => {
  const success = await queue.removeSong(id);
  if (success) {
    $message.success("已移除");
  } else {
    $message.error("移除失败");
  }
};

const toggleQueueMode = () => {
  if (queue.queueMode) {
    queue.disableQueueMode();
    $message.info("队列模式已关闭");
  } else {
    if (!queue.hasQueue) {
      $message.warning("队列为空，请先添加歌曲");
      return;
    }
    queue.enableQueueMode();
    $message.success("队列模式已开启");
  }
};

const formatTotalDuration = () => {
  const total = queue.queue.reduce((sum, item) => sum + (item.duration || 0), 0);
  const minutes = Math.floor(total / 60000);
  const seconds = Math.floor((total % 60000) / 1000);
  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
};

const formatSongDuration = (ms) => {
  if (!ms || ms === 0) return "0:00";
  const minutes = Math.floor(ms / 60000);
  const seconds = Math.floor((ms % 60000) / 1000);
  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
};

// 开始面板自动刷新
const startPanelAutoRefresh = () => {
  queue.refreshQueue();
  panelRefreshTimer = setInterval(() => {
    queue.refreshQueue();
  }, 3000);
  console.log("🔄 队列面板自动刷新已启动");
};

// 停止面板自动刷新
const stopPanelAutoRefresh = () => {
  if (panelRefreshTimer) {
    clearInterval(panelRefreshTimer);
    panelRefreshTimer = null;
    console.log("⏹️ 队列面板自动刷新已停止");
  }
};

// 监听面板打开/关闭
watch(
  () => queue.queuePanelOpen,
  (newVal) => {
    if (newVal) {
      startPanelAutoRefresh();
    } else {
      stopPanelAutoRefresh();
    }
  },
);

// 清理
onBeforeUnmount(() => {
  stopPanelAutoRefresh();
});
</script>

<style lang="scss" scoped>
.queue-controls {
  margin-bottom: 16px;
}

.queue-stats {
  margin-bottom: 16px;
}

.queue-list {
  .songs-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .song-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px !important;
    transition: all 0.3s;

    &.current {
      border: 2px solid var(--n-color-target);
    }

    .song-index {
      width: 30px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
    }

    .song-cover,
    .song-cover-placeholder {
      width: 50px;
      height: 50px;
      border-radius: 8px;
      flex-shrink: 0;
    }

    .song-cover-placeholder {
      background: var(--n-color-hover);
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .song-info {
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 4px;

      .song-name {
        font-weight: 500;
      }
    }

    .song-actions {
      flex-shrink: 0;
    }
  }
}
</style>
