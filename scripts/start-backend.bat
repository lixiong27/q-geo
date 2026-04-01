@echo off
REM GEO 运营平台 - 后端启动脚本 (Windows)
REM 使用 Tomcat 启动后端服务

setlocal enabledelayedexpansion

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 加载平台配置
call "%SCRIPT_DIR%config\windows.env"

set WEB_MODULE=%BACKEND_DIR%\mkt_ares_analysisterm_web
set WAR_EXPLODED=%WEB_MODULE%\target\ROOT

echo =========================================
echo GEO 运营平台 - 后端启动
echo =========================================

REM 检查端口是否被占用
netstat -ano | findstr ":%BACKEND_PORT% " | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo 端口 %BACKEND_PORT% 已被占用
    echo 请先执行: scripts\stop-backend.bat
    exit /b 1
)

REM 检查编译产物是否存在
if not exist "%WAR_EXPLODED%\WEB-INF" (
    echo WAR exploded 不存在，请先编译:
    echo   scripts\build-backend.bat
    exit /b 1
)

REM 设置 JAVA_HOME
if not defined JAVA_HOME (
    echo 错误: JAVA_HOME 未设置
    echo 请在 config\windows.env 中配置 JAVA_HOME
    exit /b 1
)

echo JAVA_HOME: %JAVA_HOME%
"%JAVA_HOME%\bin\java" -version

REM 配置 CATALINA_BASE
set CATALINA_BASE=%BACKEND_DIR%\.tomcat
if not exist "%CATALINA_BASE%\logs" mkdir "%CATALINA_BASE%\logs"
if not exist "%CATALINA_BASE%\temp" mkdir "%CATALINA_BASE%\temp"
if not exist "%CATALINA_BASE%\work" mkdir "%CATALINA_BASE%\work"
if not exist "%CATALINA_BASE%\webapps" mkdir "%CATALINA_BASE%\webapps"
if not exist "%CATALINA_BASE%\conf\Catalina\localhost" mkdir "%CATALINA_BASE%\conf\Catalina\localhost"
if not exist "%CATALINA_BASE%\bin" mkdir "%CATALINA_BASE%\bin"

REM 创建 setenv.bat 配置 JVM 参数
echo @echo off > "%CATALINA_BASE%\bin\setenv.bat"
echo set JAVA_OPTS=-Dspring.profiles.active=local --add-opens java.base/java.math=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.time=ALL-UNNAMED --add-opens java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED >> "%CATALINA_BASE%\bin\setenv.bat"

REM 复制 Tomcat 配置文件
if not exist "%CATALINA_BASE%\conf\server.xml" copy "%TOMCAT_HOME%\conf\server.xml" "%CATALINA_BASE%\conf\"
if not exist "%CATALINA_BASE%\conf\web.xml" copy "%TOMCAT_HOME%\conf\web.xml" "%CATALINA_BASE%\conf\"
if not exist "%CATALINA_BASE%\conf\context.xml" copy "%TOMCAT_HOME%\conf\context.xml" "%CATALINA_BASE%\conf\"

REM 创建 context 配置
echo ^<?xml version="1.0" encoding="UTF-8"?^> > "%CATALINA_BASE%\conf\Catalina\localhost\ROOT.xml"
echo ^<Context docBase="%WAR_EXPLODED%" reloadable="true"/^> >> "%CATALINA_BASE%\conf\Catalina\localhost\ROOT.xml"

REM 设置环境变量
set CATALINA_HOME=%TOMCAT_HOME%

echo.
echo 启动 Tomcat...
echo CATALINA_HOME: %CATALINA_HOME%
echo CATALINA_BASE: %CATALINA_BASE%
echo WAR exploded: %WAR_EXPLODED%
echo.

REM 启动 Tomcat
call "%TOMCAT_HOME%\bin\catalina.bat" start

timeout /t 5 /nobreak >nul

REM 检查是否启动成功
netstat -ano | findstr ":%BACKEND_PORT% " | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo =========================================
    echo 后端启动成功!
    echo 地址: http://localhost:%BACKEND_PORT%
    echo 日志: type "%CATALINA_BASE%\logs\catalina.out"
    echo =========================================
) else (
    echo.
    echo 启动可能失败，请检查日志:
    echo type "%CATALINA_BASE%\logs\catalina.*.log"
)

endlocal
