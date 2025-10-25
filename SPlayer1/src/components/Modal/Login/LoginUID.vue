<template>
  <div class="login-uid">
    <n-alert type="warning" :bordered="bordered" style="margin-bottom: 16px">
      功能正在开发中...
    </n-alert>
  </div>
</template>

<script setup>
import { ref } from "vue";

const uid = ref("");

const handleLogin = () => {
  if (!uid.value) {
    $message.warning("请输入UID");
    return;
  }
  // 触发登录逻辑
  $emit("setLoginData", { uid: uid.value });
};
</script>

<style scoped>
.login-uid {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 20px;
  min-height: 50px;
  transition: height 0.3s ease;
}
</style>
