#!/bin/bash
# GEO 运营平台 - 后端停止脚本
# 停止 Tomcat 后端服务

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载平台配置
source "$SCRIPT_DIR/config/mac.env"

CATALINA_BASE="$BACKEND_DIR/.tomcat"

echo "========================================="
echo "GEO 运营平台 - 后端停止"
echo "========================================="

# 检查是否有进程在端口上运行
PID=$(lsof -ti :$BACKEND_PORT 2>/dev/null || true)

if [ -z "$PID" ]; then
    echo "端口 $BACKEND_PORT 未被占用，后端未运行"
    exit 0
fi

echo "发现进程 $PID 占用端口 $BACKEND_PORT"
lsof -i :$BACKEND_PORT

# 使用 Tomcat 脚本停止
if [ -d "$CATALINA_BASE" ]; then
    export CATALINA_BASE
    export CATALINA_HOME="$TOMCAT_HOME"
    echo ""
    echo "使用 catalina.sh stop 停止..."
    "$TOMCAT_HOME/bin/catalina.sh" stop 2>/dev/null || true

    sleep 3

    # 检查是否停止成功
    if lsof -i :$BACKEND_PORT > /dev/null 2>&1; then
        echo "进程仍在运行，强制终止..."
        kill -9 $PID 2>/dev/null || true
    fi
else
    echo "强制终止进程 $PID..."
    kill -9 $PID 2>/dev/null || true
fi

sleep 1

# 最终检查
if lsof -i :$BACKEND_PORT > /dev/null 2>&1; then
    echo "停止失败，请手动检查"
else
    echo ""
    echo "========================================="
    echo "后端已停止"
    echo "========================================="
fi
