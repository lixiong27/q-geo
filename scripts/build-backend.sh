#!/bin/bash
# GEO 运营平台 - 后端编译脚本
# 使用 Maven 编译 war exploded

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载平台配置
source "$SCRIPT_DIR/config/mac.env"

WEB_MODULE="$BACKEND_DIR/mkt_ares_analysisterm_web"

echo "========================================="
echo "GEO 运营平台 - 后端编译"
echo "========================================="

cd "$BACKEND_DIR"

# jenv 已在项目目录设置 Java 17
echo "检查 Java 版本..."
java -version

echo ""
echo "开始 Maven 编译 (profile: local)..."
mvn clean package -DskipTests -Plocal

echo ""
echo "========================================="
echo "编译完成!"
echo "WAR exploded: $WEB_MODULE/target/ROOT/"
echo "========================================="
