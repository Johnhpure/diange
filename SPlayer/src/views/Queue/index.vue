<template>
  <div class="song-queue-page">
    <PageTransition>
      <!-- 页面标题 -->
      <div class="page-header">
        <div class="title-area">
          <n-icon size="36" class="title-icon">
            <SvgIcon icon="playlist-add" />
          </n-icon>
          <div>
            <n-text class="title">点歌队列</n-text>
            <n-text class="subtitle" depth="3">
              共 {{ queue.queueLength }} 首歌曲
            </n-text>
          </div>
        </div>
        <div class="actions">
          <n-space>
            <n-button @click="refreshQueue">
              <template #icon>
                <n-icon>
                  <SvgIcon icon="refresh" />
                </n-icon>
              </template>
              刷新
            </n-button>
            <n-button
              :type="queue.queueMode ? 'primary' : 'default'"
              :disabled="!queue.hasQueue"
              @click="toggleQueueMode"
            >
              {{ queue.queueMode ? '关闭队列模式' : '开启队列模式' }}
            </n-button>
            <n-button
              type="error"
              :disabled="!queue.hasQueue"
              @click="clearQueue"
            >
              清空队列
            </n-button>
          </n-space>
        </div>
      </div>

      <!-- 空状态 -->
      <n-empty
        v-if="!queue.hasQueue"
        description="暂无歌曲，快去添加吧"
        style="margin-top: 60px"
        size="large"
      >
        <template #icon>
          <n-icon size="120" :depth="3">
            <SvgIcon icon="playlist-add" />
          </n-icon>
        </template>
        <template #extra>
          <n-button type="primary" @click="goToDiscover">
            <template #icon>
              <n-icon>
                <SvgIcon icon="search-rounded" />
              </n-icon>
            </template>
            去发现音乐
          </n-button>
        </template>
      </n-empty>

      <!-- 歌曲列表 -->
      <div v-else class="queue-list">
        <SongList :data="formattedQueueData" :sourceId="'queue'" :showCover="true" />
      </div>
    </PageTransition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from "vue";
import { useRouter } from "vue-router";
import { storeToRefs } from "pinia";
import { queueData } from "@/stores";
import SongList from "@/components/List/SongList.vue";
import SvgIcon from "@/components/Global/SvgIcon";

const router = useRouter();
const queue = queueData();
const { queueLength, hasQueue, queueMode } = storeToRefs(queue);

// 自动刷新定时器
let autoRefreshTimer = null;

// 格式化队列数据为 SongList 所需格式
const formattedQueueData = computed(() => {
  return queue.queue.map((item) => ({
    id: item.songId,
    name: item.songName,
    artist: item.artist,
    ar: [{ name: item.artist }],
    artists: [{ id: 0, name: item.artist }],
    album: item.album || "",
    al: {
      name: item.album || "",
      picUrl: item.cover || "",
    },
    cover: item.cover || "",
    coverSize: {
      s: item.cover ? `${item.cover}?param=50y50` : "",
      m: item.cover ? `${item.cover}?param=200y200` : "",
      l: item.cover ? `${item.cover}?param=400y400` : "",
    },
    duration: item.duration,
    dt: item.duration,
    queueId: item.id,
    addedBy: item.addedBy,
    addedAt: item.addedAt,
  }));
});

// 刷新队列
const refreshQueue = async () => {
  await queue.refreshQueue();
  $message.success("队列已刷新");
};

// 切换队列模式
const toggleQueueMode = () => {
  if (queue.queueMode) {
    queue.disableQueueMode();
    $message.info("队列模式已关闭");
  } else {
    queue.enableQueueMode();
    $message.success("队列模式已开启");
  }
};

// 清空队列
const clearQueue = async () => {
  const success = await queue.clear();
  if (success) {
    $message.success("队列已清空");
  } else {
    $message.error("清空失败");
  }
};

// 跳转到发现音乐
const goToDiscover = () => {
  router.push("/discover");
};

// 开始自动刷新
const startAutoRefresh = () => {
  // 立即刷新一次
  queue.refreshQueue();
  
  // 每3秒自动刷新（多用户实时同步）
  autoRefreshTimer = setInterval(() => {
    queue.refreshQueue();
  }, 3000);
  
  console.log("🔄 队列页面自动刷新已启动（每3秒）");
};

// 停止自动刷新
const stopAutoRefresh = () => {
  if (autoRefreshTimer) {
    clearInterval(autoRefreshTimer);
    autoRefreshTimer = null;
    console.log("⏹️ 队列页面自动刷新已停止");
  }
};

// 初始化
onMounted(() => {
  startAutoRefresh();
});

// 清理
onBeforeUnmount(() => {
  stopAutoRefresh();
});
</script>

<style lang="scss" scoped>
.song-queue-page {
  width: 100%;
  max-width: 100%;
  padding: 0 2vw;
  box-sizing: border-box;
  
  .page-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 24px;
    padding: 20px 0;
    flex-wrap: wrap;
    gap: 16px;
    
    .title-area {
      display: flex;
      align-items: center;
      gap: 12px;
      
      .title {
        font-size: 28px;
        font-weight: bold;
        display: block;
      }
      
      .subtitle {
        font-size: 14px;
        margin-top: 4px;
        display: block;
      }
    }
  }
  
  .queue-list {
    margin-top: 24px;
  }
}

@media (max-width: 768px) {
  .song-queue-page {
    padding: 0 4px;
    
    .page-header {
      .title {
        font-size: 24px !important;
      }
      
      .actions {
        width: 100%;
      }
    }
  }
}
</style>
