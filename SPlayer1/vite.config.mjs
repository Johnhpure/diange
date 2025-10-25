import { resolve } from "path";
import { defineConfig, loadEnv } from "vite";
import { NaiveUiResolver } from "unplugin-vue-components/resolvers";
import { VitePWA } from "vite-plugin-pwa";
import vue from "@vitejs/plugin-vue";
import AutoImport from "unplugin-auto-import/vite";
import Components from "unplugin-vue-components/vite";
import viteCompression from "vite-plugin-compression";
import wasm from "vite-plugin-wasm";
import topLevelAwait from "vite-plugin-top-level-await";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd());
  const serverHost = env.MAIN_VITE_SERVER_HOST || "127.0.0.1";
  const serverPort = env.MAIN_VITE_SERVER_PORT || "3001";

  return {
    resolve: {
      extensions: [".js", ".vue", ".json"],
      alias: {
        "@": resolve(__dirname, "src"),
      },
    },
    plugins: [
      wasm(),
      topLevelAwait(),
      vue(),
      AutoImport({
        imports: [
          "vue",
          {
            "naive-ui": ["useDialog", "useMessage", "useNotification", "useLoadingBar"],
          },
        ],
      }),
      Components({
        resolvers: [NaiveUiResolver()],
      }),
      viteCompression(),
      VitePWA({
        registerType: "autoUpdate",
        workbox: {
          clientsClaim: true,
          skipWaiting: true,
          cleanupOutdatedCaches: true,
        },
        manifest: {
          name: env.RENDERER_VITE_SITE_TITLE || "SPlayer",
          short_name: env.RENDERER_VITE_SITE_TITLE || "SPlayer",
          display: "standalone",
          start_url: "/",
          theme_color: "#fff",
          background_color: "#efefef",
        },
      }),
    ],
    server: {
      host: "0.0.0.0",
      port: 6944,
      proxy: {
        "/api": {
          target: `http://${serverHost}:${serverPort}`,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ""),
        },
      },
    },
    build: {
      target: "esnext",
      minify: "terser",
      outDir: "dist",
      sourcemap: false,
    },
  };
});
