#!/bin/bash
# GEO 运营平台 - 后端启动脚本
# 使用 Homebrew Tomcat 启动后端服务

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载平台配置
source "$SCRIPT_DIR/config/mac.env"

# 后端 Web 模块
WEB_MODULE="$BACKEND_DIR/mkt_ares_analysisterm_web"
WAR_EXPLODED="$WEB_MODULE/target/ROOT"

echo "========================================="
echo "GEO 运营平台 - 后端启动"
echo "========================================="

# 检查端口是否被占用
if lsof -i :$BACKEND_PORT > /dev/null 2>&1; then
    echo "端口 $BACKEND_PORT 已被占用"
    echo "请先执行: ./scripts/stop-backend.sh"
    exit 1
fi

# 检查编译产物是否存在
if [ ! -d "$WAR_EXPLODED/WEB-INF" ]; then
    echo "WAR exploded 不存在，请先编译:"
    echo "  ./scripts/build-backend.sh"
    exit 1
fi

# 设置 Java 17 (通过 jenv)
cd "$BACKEND_DIR"
export JAVA_HOME=$(jenv prefix 2>/dev/null || echo "")
if [ -z "$JAVA_HOME" ]; then
    echo "错误: jenv 未正确配置 Java $JAVA_VERSION"
    exit 1
fi
echo "JAVA_HOME: $JAVA_HOME"
java -version

# 配置 CATALINA_BASE (使用独立的 Tomcat 实例目录)
CATALINA_BASE="$BACKEND_DIR/.tomcat"
mkdir -p "$CATALINA_BASE"/{logs,temp,work,webapps,conf/Catalina/localhost,bin}

# 创建 setenv.sh 配置 JVM 参数 (解决 Java 17 模块访问问题)
cat > "$CATALINA_BASE/bin/setenv.sh" << SETENVEOF
#!/bin/bash
export JAVA_OPTS="-Dspring.profiles.active=local --add-opens java.base/java.math=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.time=ALL-UNNAMED --add-opens java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED"
SETENVEOF
chmod +x "$CATALINA_BASE/bin/setenv.sh"

# 复制 Tomcat 配置文件
if [ ! -f "$CATALINA_BASE/conf/server.xml" ]; then
    cp "$TOMCAT_HOME/conf/server.xml" "$CATALINA_BASE/conf/"
fi

if [ ! -f "$CATALINA_BASE/conf/web.xml" ]; then
    cp "$TOMCAT_HOME/conf/web.xml" "$CATALINA_BASE/conf/"
fi

if [ ! -f "$CATALINA_BASE/conf/context.xml" ]; then
    cp "$TOMCAT_HOME/conf/context.xml" "$CATALINA_BASE/conf/"
fi

# 创建 context 配置，指向 war exploded
cat > "$CATALINA_BASE/conf/Catalina/localhost/ROOT.xml" << CTXEOF
<?xml version="1.0" encoding="UTF-8"?>
<Context docBase="$WAR_EXPLODED" reloadable="true"/>
CTXEOF

# 设置环境变量
export CATALINA_BASE
export CATALINA_HOME="$TOMCAT_HOME"

echo ""
echo "启动 Tomcat..."
echo "CATALINA_HOME: $CATALINA_HOME"
echo "CATALINA_BASE: $CATALINA_BASE"
echo "WAR exploded: $WAR_EXPLODED"
echo ""

# 启动 Tomcat
"$TOMCAT_HOME/bin/catalina.sh" start

sleep 5

# 检查是否启动成功
if lsof -i :$BACKEND_PORT > /dev/null 2>&1; then
    echo ""
    echo "========================================="
    echo "后端启动成功!"
    echo "地址: http://localhost:$BACKEND_PORT"
    echo "日志: tail -f $CATALINA_BASE/logs/catalina.out"
    echo "========================================="
else
    echo ""
    echo "启动可能失败，请检查日志:"
    echo "tail -100 $CATALINA_BASE/logs/catalina.out"
fi
