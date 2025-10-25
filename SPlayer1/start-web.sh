#!/bin/bash
cd "$(dirname "$0")"
export NODE_ENV=development
npx vite --host 0.0.0.0 --port 6944 --config electron.vite.config.mjs
