#!/bin/bash
# GEO 运营平台 - 前端停止脚本
# 终止前端开发服务器进程

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载平台配置
source "$SCRIPT_DIR/config/mac.env"

echo "========================================="
echo "GEO 运营平台 - 前端停止"
echo "========================================="

# 查找并终止占用端口的进程
echo "检查端口 $FRONTEND_PORT..."
PID=$(lsof -ti :$FRONTEND_PORT 2>/dev/null || true)

if [ -n "$PID" ]; then
    echo "发现进程 $PID 占用端口 $FRONTEND_PORT"
    lsof -i :$FRONTEND_PORT
    echo "正在终止进程..."
    kill "$PID" 2>/dev/null || true
    sleep 1
    echo "前端已停止"
else
    echo "端口 $FRONTEND_PORT 未被占用，前端未运行"
fi

echo "========================================="
