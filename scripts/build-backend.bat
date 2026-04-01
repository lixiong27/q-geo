@echo off
REM GEO 运营平台 - 后端编译脚本 (Windows)
REM 使用 Maven 编译 war exploded

setlocal enabledelayedexpansion

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 加载平台配置
call "%SCRIPT_DIR%config\windows.env"

set WEB_MODULE=%BACKEND_DIR%\mkt_ares_analysisterm_web

echo =========================================
echo GEO 运营平台 - 后端编译
echo =========================================

cd /d "%BACKEND_DIR%"

REM 检查 JAVA_HOME
if defined JAVA_HOME (
    echo JAVA_HOME: %JAVA_HOME%
    "%JAVA_HOME%\bin\java" -version
) else (
    echo 警告: JAVA_HOME 未设置，使用系统默认 Java
    java -version
)

echo.
echo 开始 Maven 编译 (profile: local)...
call mvn clean package -DskipTests -Plocal

echo.
echo =========================================
echo 编译完成!
echo WAR exploded: %WEB_MODULE%\target\ROOT\
echo =========================================

endlocal
