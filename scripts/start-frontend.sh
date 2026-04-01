#!/bin/bash
# GEO 运营平台 - 前端启动脚本
# 使用 Node v12.16.1 启动前端开发服务器

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载平台配置
source "$SCRIPT_DIR/config/mac.env"

echo "========================================="
echo "GEO 运营平台 - 前端启动"
echo "========================================="

# 进入前端目录
cd "$FRONTEND_DIR"

# 加载 nvm 并切换 Node 版本
echo "切换到 Node $NODE_VERSION..."
source "$NVM_PATH"
nvm use "$NODE_VERSION"

# 验证 Node 版本
echo "当前 Node 版本: $(node -v)"
echo "当前 npm 版本: $(npm -v)"

# 启动前端
echo "启动前端开发服务器..."
echo "前端地址: http://localhost:$FRONTEND_PORT"
echo "后端代理: http://localhost:$BACKEND_PORT"
echo "========================================="
npm start
