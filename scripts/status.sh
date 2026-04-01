#!/bin/bash
# GEO 运营平台 - 状态检查脚本
# 检查前后端服务运行状态

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载平台配置
source "$SCRIPT_DIR/config/mac.env"

echo "========================================="
echo "GEO 运营平台 - 服务状态"
echo "========================================="

# 检查后端状态
echo ""
echo "【后端服务】端口 $BACKEND_PORT"
BACKEND_PID=$(lsof -ti :$BACKEND_PORT 2>/dev/null || true)
if [ -n "$BACKEND_PID" ]; then
    echo "状态: 运行中 (PID: $BACKEND_PID)"
    echo "地址: http://localhost:$BACKEND_PORT"

    # 健康检查
    HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$BACKEND_PORT/healthcheck.html 2>/dev/null || echo "000")
    if [ "$HEALTH" = "200" ]; then
        echo "健康检查: 正常"
    else
        echo "健康检查: 异常 (HTTP $HEALTH)"
    fi
else
    echo "状态: 未运行"
fi

# 检查前端状态
echo ""
echo "【前端服务】端口 $FRONTEND_PORT"
FRONTEND_PID=$(lsof -ti :$FRONTEND_PORT 2>/dev/null || true)
if [ -n "$FRONTEND_PID" ]; then
    echo "状态: 运行中 (PID: $FRONTEND_PID)"
    echo "地址: http://localhost:$FRONTEND_PORT"

    # 检查 Node 版本
    NODE_VERSION_RUNNING=$(ps -p $FRONTEND_PID -o command= 2>/dev/null | grep -o 'node v[0-9.]*' | head -1 || echo "未知")
    echo "Node 版本: $NODE_VERSION_RUNNING"
else
    echo "状态: 未运行"
fi

# 检查数据库连接
echo ""
echo "【数据库连接】"
echo "环境: local"
echo "命名空间: noah498975_noahstanddb_07f98"
echo "数据库: mkt_ares_live_beta"

echo ""
echo "========================================="
echo "快速命令:"
echo "  启动前端: ./scripts/start-frontend.sh"
echo "  重启前端: ./scripts/restart-frontend.sh"
echo "  停止前端: ./scripts/stop-frontend.sh"
echo "  查看状态: ./scripts/status.sh"
echo "========================================="
