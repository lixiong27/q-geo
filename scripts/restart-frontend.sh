#!/bin/bash
# GEO 运营平台 - 前端重启脚本
# 终止现有前端进程并重新启动

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载平台配置
source "$SCRIPT_DIR/config/mac.env"

echo "========================================="
echo "GEO 运营平台 - 前端重启"
echo "========================================="

# 查找并终止占用端口的进程
echo "检查端口 $FRONTEND_PORT..."
PID=$(lsof -ti :$FRONTEND_PORT 2>/dev/null || true)

if [ -n "$PID" ]; then
    echo "发现进程 $PID 占用端口 $FRONTEND_PORT，正在终止..."
    kill "$PID" 2>/dev/null || true
    sleep 2
    echo "进程已终止"
else
    echo "端口 $FRONTEND_PORT 未被占用"
fi

# 进入前端目录
cd "$FRONTEND_DIR"

# 加载 nvm 并切换 Node 版本
echo "切换到 Node $NODE_VERSION..."
source "$NVM_PATH"
nvm use "$NODE_VERSION"

# 验证 Node 版本
echo "当前 Node 版本: $(node -v)"

# 启动前端
echo "启动前端开发服务器..."
echo "前端地址: http://localhost:$FRONTEND_PORT"
echo "后端代理: http://localhost:$BACKEND_PORT"
echo "========================================="
npm start
