<!-- 歌曲列表 -->
<template>
  <Transition name="fade" mode="out-in" @after-enter="checkHasPlaying">
    <div v-if="data?.[0]?.id" class="song-list">
      <div v-if="showTitle" class="song-list-header">
        <n-text class="num" depth="3"> # </n-text>
        <n-text :class="['info', { 'has-cover': data[0].cover && showCover }]" depth="3">
          {{ type === "song" ? "歌曲" : "声音" }}
        </n-text>
        <n-text v-if="data[0].album && showAlbum" class="album hidden" depth="3"> 专辑 </n-text>
        <n-text v-if="data[0].updateTime && type === 'dj'" class="update hidden" depth="3">
          更新日期
        </n-text>
        <n-text v-if="type !== 'dj'" class="control" />
        <n-text v-if="data[0].playCount && type === 'dj'" class="count hidden" depth="3">
          播放量
        </n-text>
        <n-text v-if="data[0].duration" class="duration hidden" depth="3"> 时长 </n-text>
        <n-text v-if="data[0].size" class="size hidden" depth="3"> 大小 </n-text>
      </div>
      <n-card
        v-for="(item, index) in data.slice(
          (pageNumber - 1) * loadSize,
          (pageNumber - 1) * loadSize + loadSize,
        )"
        :id="'song-list-' + index"
        :key="index"
        :content-style="{
          padding: '16px',
          display: 'flex',
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
        }"
        :class="Number(music.getPlaySongData?.id) === Number(item?.id) ? 'songs play' : 'songs'"
        hoverable
        @click="checkCanClick(data, item, songsIndex + index)"
        @dblclick.stop="playSong(data, item, songsIndex + index)"
        @contextmenu="
          songListDropdownRef?.openDropdown($event, data, item, songsIndex + index, sourceId, type)
        "
      >
        <!-- 序号 -->
        <n-text v-if="music.getPlaySongData?.id !== item?.id" class="num" depth="3">
          {{ songsIndex + index + 1 }}
        </n-text>
        <n-icon v-else class="num" size="22">
          <SvgIcon icon="music-note" />
        </n-icon>
        <!-- 封面 -->
        <div v-if="item.cover && showCover" class="cover">
          <n-image
            :src="item.coverSize.s"
            class="cover-img"
            preview-disabled
            lazy
            @load="
              (e) => {
                e.target.style.opacity = 1;
              }
            "
          >
            <template #placeholder>
              <div class="cover-loading">
                <img class="loading-img" src="/imgs/pic/song.jpg?assest" alt="song" />
              </div>
            </template>
          </n-image>
        </div>
        <!-- 信息 -->
        <div class="info">
          <div class="title">
            <!-- 名称 -->
            <n-text
              class="name"
              depth="2"
              :style="type !== 'dj' && !item.path && item?.id ? 'cursor: pointer' : ''"
              @click.stop="
                type !== 'dj' && !item.path && item?.id ? songDetailRef?.openDetail(item.id) : null
              "
            >
              {{ item?.name || "未知曲目" }}
            </n-text>
            <!-- 特权 -->
            <n-tag
              v-if="
                showPrivilege &&
                item.fee === 1 &&
                !hiddenVipTags &&
                userData.detail?.profile?.vipType !== 11
              "
              :bordered="false"
              type="error"
              size="small"
              round
            >
              VIP
            </n-tag>
            <n-tag
              v-if="showPrivilege && item.fee === 4"
              :bordered="false"
              type="error"
              size="small"
              round
            >
              EP
            </n-tag>
            <!-- 云盘 -->
            <n-tag
              v-if="showPrivilege && item.pc"
              :bordered="false"
              class="cloud"
              type="info"
              size="small"
              round
            >
              <template #icon>
                <n-icon>
                  <SvgIcon icon="cloud" />
                </n-icon>
              </template>
            </n-tag>
            <!-- MV -->
            <n-tag
              v-if="item?.mv"
              :bordered="false"
              class="mv"
              type="warning"
              size="small"
              round
              @click.stop="router.push(`/videos-player?id=${item.mv}`)"
            >
              MV
            </n-tag>
          </div>
          <!-- 歌手 -->
          <div v-if="Array.isArray(item.artists)" class="artist">
            <n-text
              v-for="ar in item.artists"
              :key="ar.id"
              class="ar"
              @click.stop="router.push(`/artist?id=${ar.id}`)"
              @dblclick.stop
            >
              {{ ar.name }}
            </n-text>
          </div>
          <div v-else-if="type === 'dj'" class="artist">
            <n-text class="ar" @dblclick.stop> 电台节目 </n-text>
          </div>
          <div v-else class="artist">
            <n-text class="ar" @dblclick.stop> {{ item.artists || "未知艺术家" }} </n-text>
          </div>
          <!-- 别名 -->
          <n-text v-if="item.alia" class="alia" depth="3">{{ item.alia }}</n-text>
        </div>
        <!-- 专辑 -->
        <template v-if="showAlbum && type !== 'dj'">
          <n-text
            v-if="item.album"
            class="album hidden"
            @click.stop="
              typeof item.album === 'object' ? router.push(`/album?id=${item.album.id}`) : null
            "
            @dblclick.stop
          >
            {{ typeof item.album === "object" ? item.album?.name || "未知专辑" : item.album }}
          </n-text>
          <n-text v-else class="album hidden">未知专辑</n-text>
        </template>
        <!-- 操作 -->
        <div v-if="type !== 'dj'" class="action">
          <!-- 点歌按钮 -->
          <n-icon
            class="queue-add"
            depth="3"
            size="20"
            title="加入点歌队列"
            @click.stop="addToQueueHandler(item)"
            @dblclick.stop
          >
            <SvgIcon icon="playlist-add" />
          </n-icon>
          <!-- 更多操作 -->
          <n-icon
            class="more mobile"
            depth="3"
            size="20"
            @click.stop="
              songListDropdownRef?.openDropdown(
                $event,
                data,
                item,
                songsIndex + index,
                sourceId,
                type,
              )
            "
            @dblclick.stop
          >
            <SvgIcon icon="more" />
          </n-icon>
        </div>
        <!-- 更新日期 -->
        <n-text v-if="type === 'dj' && item.updateTime" class="update hidden" depth="3">
          {{ djFormatDate(item.updateTime) }}
        </n-text>
        <!-- 播放量 -->
        <n-text v-if="type === 'dj' && item.playCount" class="count hidden" depth="3">
          {{ item.playCount }}次
        </n-text>
        <!-- 时长 -->
        <n-text v-if="item.duration" class="duration hidden" depth="3">{{ item.duration }}</n-text>
        <n-text v-else class="duration"> -- </n-text>
        <!-- 大小 -->
        <n-text v-if="item.size" class="size hidden" depth="3">{{ item.size }}M</n-text>
      </n-card>
      <!-- 分页 -->
      <Pagination
        v-if="data.length >= loadSize && showPagination"
        :totalCount="data.length"
        :pageNumber="pageNumber"
        @pageNumberChange="pageNumberChange"
      />
      <!-- 右键菜单 -->
      <SongListDropdown
        ref="songListDropdownRef"
        @playSong="playSong"
        @delCloudSong="delCloudSong"
        @deletePlaylistSong="deletePlaylistSong"
        @delLocalSong="delLocalSong"
      />
      <!-- 移动端菜单 -->
      <SongListDrawer
        ref="songListDrawerRef"
        @playSong="playSong"
        @delCloudSong="delCloudSong"
        @deletePlaylistSong="deletePlaylistSong"
        @delLocalSong="delLocalSong"
      />
      <!--SongListDrawer
        ref="songListDrawerRef"
        @playSong="playSong"
        @delCloudSong="delCloudSong"
        @deletePlaylistSong="deletePlaylistSong"
        @delLocalSong="delLocalSong"
      /-->
      <!-- 定位歌曲 -->
      <Transition name="shrink" mode="out-in">
        <n-card
          v-if="isHasPlayingDom"
          :bordered="false"
          :content-style="{
            padding: '0px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }"
          class="scroll-to-song"
          @click="checkHasPlaying('scroll')"
        >
          <n-icon size="26">
            <SvgIcon icon="location" />
          </n-icon>
        </n-card>
      </Transition>
    </div>
    <!-- 空列表 -->
    <n-empty
      v-else-if="data === 'empty' || data?.[0] === 'empty'"
      description="空空如也，怎么一首歌都没有啊"
      style="margin-top: 60px"
      size="large"
    />
    <!-- 错误 -->
    <n-empty
      v-else-if="data === 'error' || data?.[0] === 'error'"
      description="列表获取出错，请重试"
      style="margin-top: 60px"
      size="large"
    />
    <!-- 加载动画 -->
    <div v-else class="loading">
      <n-skeleton :repeat="10" text />
    </div>
  </Transition>
  <SongDetail ref="songDetailRef" />
</template>

<script setup>
import { storeToRefs } from "pinia";
import { useRouter } from "vue-router";
import { setCloudDel } from "@/api/cloud";
import { addSongToPlayList } from "@/api/playlist";
import { siteData, siteSettings, musicData, siteStatus, queueData } from "@/stores";
import queueLogger from "@/utils/queueLogger";
import { initPlayer, fadePlayOrPause, addSongToNext } from "@/utils/Player";
import { djFormatDate } from "@/utils/time.ts";
import SongDetail from "@/components/Modal/SongDetail.vue";

const router = useRouter();
const music = musicData();
const dataStore = siteData();
const status = siteStatus();
const settings = siteSettings();
const queue = queueData();
const { userData } = storeToRefs(dataStore);
const { loadSize, playSearch, useMusicCache, hiddenVipTags } = storeToRefs(settings);
const { playList, playSongData, playSongSource } = storeToRefs(music);
const { playIndex, playMode, playHeartbeatMode, playLoading } = storeToRefs(status);

// eslint-disable-next-line no-unused-vars
const props = defineProps({
  // 列表类型
  type: {
    type: String,
    default: "song",
  },
  // 列表数据
  data: {
    type: [Array, String],
    default: () => [],
  },
  // 列表 id
  sourceId: {
    type: [Number, String],
    default: 0,
  },
  // 是否显示封面
  showCover: {
    type: Boolean,
    default: true,
  },
  // 是否显示分页
  showPagination: {
    type: Boolean,
    default: true,
  },
  // 是否显示特权
  showPrivilege: {
    type: Boolean,
    default: true,
  },
  // 是否显示专辑
  showAlbum: {
    type: Boolean,
    default: true,
  },
  // 是否显示表头
  showTitle: {
    type: Boolean,
    default: true,
  },
});

// 分页数据
const pageNumber = ref(1);

// 子组件
const songListDrawerRef = ref(null);
const songListDropdownRef = ref(null);
const songDetailRef = ref(null);

// 当前索引
const songsIndex = computed(() => {
  const page = props.showPagination
    ? pageNumber.value
    : Number(router.currentRoute.value.query?.page) || 1;
  return (page - 1) * loadSize.value;
});

// 正在播放元素
const isHasPlayingDom = ref(null);

// 检查是否有正在播放的歌曲
const checkHasPlaying = (isScoll = null) => {
  const songDom = document.querySelector(".songs.play");
  // 滚动至元素
  if (isScoll === "scroll" && songDom) {
    songDom?.scrollIntoView({ behavior: "smooth", block: "center" });
  }
  isHasPlayingDom.value = songDom ? true : false;
};

// 添加到点歌队列
const addToQueueHandler = async (song) => {
  const user = userData.value?.profile?.nickname || "匿名用户";

  try {
    queueLogger.info("USER_CLICK_ADD_QUEUE", {
      songId: song.id,
      songName: song.name,
      user,
    });

    const result = await queue.addSong(song, user);

    // 记录添加结果
    queueLogger.logAddToQueue(song, user, result);

    if (result.success) {
      $message.success(result.message || "已加入点歌队列");
    } else {
      $message.warning(result.message || "添加失败");
    }
  } catch (error) {
    console.error("添加到队列失败:", error);
    queueLogger.logError("ADD_TO_QUEUE_HANDLER", error, {
      songId: song.id,
      songName: song.name,
      user,
    });
    $message.error("添加到队列失败");
  }
};

// 播放歌曲
const playSong = async (data, song, index) => {
  console.log(data, song, index);
  // 若开启了缓存且正在加载
  if (useMusicCache.value && playLoading.value) {
    $message.warning("歌曲正在缓冲中，请稍后");
    return false;
  }
  // 更改模式
  playMode.value = props.type === "song" ? "normal" : "dj";
  // 检查当前页面
  const isPage = router.currentRoute.value.matched?.[0].path || null;
  // 是否关闭心动模式
  if (isPage !== "/like-songs") playHeartbeatMode.value = false;
  
  // ========== 队列模式强制启用 ==========
  // 如果从队列页面播放，强制启用队列模式
  if (props.sourceId === 'queue') {
    if (!queue.queueMode) {
      queue.enableQueueMode();
    }
    console.log("🎵 从队列播放，队列模式已确保开启");
  }
  // ========== 队列模式强制启用结束 ==========
  
  // 是否为当前播放歌曲
  if (music.getPlaySongData?.id === song?.id) {
    // 继续播放
    fadePlayOrPause();
  } else {
    // 若为特殊状态
    if (
      (isPage === "/search" && !playSearch.value) ||
      isPage === "/history" ||
      playHeartbeatMode.value
    ) {
      console.log("仅播放当前歌曲");
      addSongToNext(song, true);
    } else {
      // 添加播放列表
      playList.value = data.slice();
      // 更改播放索引
      playIndex.value = index;
    }
    console.log("与当前播放歌曲不一致");
    playSongData.value = song;
    // 初始化播放器
    await initPlayer(true);
  }
  // 附加来源
  playSongSource.value = Number(props.sourceId);
  // 检查是否有正在播放的歌曲
  nextTick().then(() => checkHasPlaying());
};

// 页数变化
const pageNumberChange = (page) => {
  pageNumber.value = page;
  nextTick().then(() => {
    const mainLayout = document.getElementById("main-layout");
    mainLayout?.scrollIntoView({ behavior: "smooth" });
    checkHasPlaying();
  });
};

// 检查是否可执行双击
const checkCanClick = (data, item, index) => {
  if (window.innerWidth > 700) return false;
  playSong(data, item, index);
};

// 云盘歌曲删除
const delCloudSong = (data, song, index) => {
  console.log(data, song, index);
  $dialog.warning({
    title: "确认删除",
    content: `确认从云盘中删除 ${song.name}？该操作无法撤销！`,
    positiveText: "删除",
    negativeText: "取消",
    onPositiveClick: async () => {
      const result = await setCloudDel(song.id);
      if (result.code == 200) {
        data.splice(index, 1);
        $message.success("删除成功");
      } else {
        $message.error("删除失败，请重试");
      }
    },
  });
};

// 歌单歌曲删除
const deletePlaylistSong = (pid, song, data, index) => {
  if (!pid || !song) return $message.error("无法正确定位到歌单，请重试");
  $dialog.warning({
    title: "确认删除",
    content: `确认从歌单中移除 ${song.name}？该操作无法撤销！`,
    positiveText: "删除",
    negativeText: "取消",
    onPositiveClick: async () => {
      const result = await addSongToPlayList(pid, song?.id, "del");
      if (result.status === 200) {
        data.length === 1 ? data.splice(0, 1, "empty") : data.splice(index, 1);
        $message.success("歌曲删除成功");
      } else {
        $message.error("歌曲删除失败，请重试");
      }
    },
  });
};

// 本地歌曲删除
const delLocalSong = (data, song, index) => {
  $dialog.warning({
    title: "确认删除",
    content: `确认从本地磁盘中删除 ${song.name}？该操作无法撤销！`,
    positiveText: "删除",
    negativeText: "取消",
    onPositiveClick: async () => {
      console.log(data, song, index);
      const result = await electron.ipcRenderer.invoke("deleteFile", song?.path);
      if (result) {
        data.length === 1 ? data.splice(0, 1, "empty") : data.splice(index, 1);
        $message.success("歌曲删除成功");
      } else {
        $message.error("歌曲删除失败，请重试");
      }
    },
  });
};

// 监听歌曲变化
watch(
  () => music.getPlaySongData?.id,
  () => nextTick().then(() => checkHasPlaying()),
);

onMounted(() => {
  checkHasPlaying();
});

onBeforeUnmount(() => {
  isHasPlayingDom.value = false;
});
</script>

<style lang="scss" scoped>
.song-list {
  width: 100%;

  .song-list-header {
    display: flex;
    flex-direction: row;
    align-items: center;
    margin-bottom: 12px;
    padding: 0 16px;

    * {
      box-sizing: border-box;
    }

    .num {
      width: 30px;
      margin-right: 16px;
      text-align: center;
    }

    .info,
    .album {
      flex: 1;
    }

    .has-cover {
      margin-right: 66px;
    }

    .control {
      width: 40px;
    }

    .update {
      width: 80px;
      text-align: center;
      margin-right: auto;
    }

    .count {
      width: 120px;
      text-align: center;
    }

    .duration {
      width: 50px;
      text-align: center;
    }

    .size {
      width: 80px;
      padding-right: 10px;
      text-align: right;
    }
  }

  .songs {
    border-radius: 8px;
    margin-bottom: 12px;
    transition:
      transform 0.3s,
      border-color 0.3s,
      box-shadow 0.3s;
    cursor: pointer;

    .cover {
      width: 50px;
      height: 50px;
      min-width: 50px;
      border-radius: 8px;
      margin-right: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;

      .cover-img {
        width: 100%;
        height: 100%;
        z-index: 1;
        transition:
          filter 0.3s,
          transform 0.3s;

        :deep(img) {
          width: 100%;
          opacity: 0;
          transition: opacity 0.35s ease-in-out;
        }
      }
    }

    .num {
      width: 30px;
      height: 30px;
      min-width: 30px;
      border-radius: 8px;
      margin-right: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .info {
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: center;
      padding-right: 20px;

      .title {
        display: flex;
        align-items: center;
        flex-direction: row;

        .name {
          font-size: 16px;
          font-weight: bold;
          transition: color 0.3s;
          -webkit-line-clamp: 2;

          &:hover {
            color: var(--main-color);
          }
        }

        .n-tag {
          margin-left: 8px;
          height: 18px;

          &.cloud {
            padding: 0 10px;
            align-items: center;
            justify-content: center;

            :deep(.n-tag__icon) {
              margin-right: 0;
              width: 100%;
            }
          }

          &.mv {
            cursor: pointer;
          }
        }
      }

      .artist {
        margin-top: 2px;
        font-size: 13px;
        display: -webkit-box;
        -webkit-box-orient: vertical;
        -webkit-line-clamp: 1;
        overflow: hidden;
        word-break: break-all;

        .ar {
          display: inline-flex;
          transition: opacity 0.3s;
          opacity: 0.6;
          cursor: pointer;

          &::after {
            content: "/";
            margin: 0 4px;
          }

          &:last-child {
            &::after {
              display: none;
            }
          }

          &:hover {
            opacity: 0.8;
          }
        }
      }

      .alia {
        margin-top: 2px;
        font-size: 12px;
        opacity: 0.8;
      }
    }

    .album {
      flex: 1;
      padding-right: 20px;
      transition: color 0.3s;
      -webkit-line-clamp: 2;

      &:hover {
        color: var(--main-color);
      }
    }

    .action {
      width: 40px;
      display: flex;
      align-items: center;
      justify-content: space-evenly;



      .more {
        display: none;
      }
    }

    .update {
      width: 80px;
      text-align: center;
    }

    .count {
      width: 120px;
      text-align: center;
    }

    .duration {
      width: 50px;
      text-align: center;
    }

    .size {
      width: 80px;
      text-align: right;
    }

    &.play {
      background-color: var(--main-second-color);
      border-color: var(--main-color);

      a,
      span,
      .num {
        color: var(--main-color) !important;
      }

      .artist {
        .ar {
          opacity: 0.8;
          transition: opacity 0.3s;

          &:hover {
            opacity: 1;
          }
        }
      }

      .album {
        opacity: 0.8;
        transition: opacity 0.3s;

        &:hover {
          opacity: 1;
        }
      }
    }

    &:last-child {
      margin-bottom: 0;
    }

    &:hover {
      border-color: var(--main-color);
      box-shadow:
        0 1px 2px -2px var(--main-boxshadow-color),
        0 3px 6px 0 var(--main-boxshadow-color),
        0 5px 12px 4px var(--main-boxshadow-hover-color);
    }

    &:active {
      transform: scale(0.995);
    }
  }

  .scroll-to-song {
    position: absolute;
    width: 44px;
    height: 44px;
    right: calc(40px);
    bottom: 100px;
    border-radius: 50%;
    background-color: var(--n-color-embedded-popover);
    transition:
      transform 0.3s,
      opacity 0.3s;
    cursor: pointer;

    &:active {
      transform: scale(0.9);
    }
  }

  @media (max-width: 700px) {
    .song-list-header,
    .songs {
      .hidden {
        display: none;
      }
    }

    .songs {
      .num {
        font-size: 12px;
        width: 28px;
        height: 28px;
        min-width: 28px;
      }

      .info {
        .title {
          .name {
            font-size: 15px;
          }
        }

        .artist {
          font-size: 12px;
        }
      }

      .action {
        width: 60px;
        justify-content: flex-end;

        .more {
          display: inline-block;
          margin-left: 12px;
        }
      }
    }
  }
}

.loading {
  :deep(.n-skeleton) {
    &:nth-of-type(1) {
      margin-top: 0;
    }

    height: 80px;
    margin-top: 12px;
    border-radius: 8px;
  }
}
</style>
