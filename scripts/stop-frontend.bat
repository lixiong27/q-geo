@echo off
REM GEO 运营平台 - 前端停止脚本 (Windows)
REM 终止前端开发服务器进程

setlocal enabledelayedexpansion

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 加载平台配置
call "%SCRIPT_DIR%config\windows.env"

echo =========================================
echo GEO 运营平台 - 前端停止
echo =========================================

REM 查找占用端口的进程
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%FRONTEND_PORT% " ^| findstr "LISTENING"') do set PID=%%a

if not defined PID (
    echo 端口 %FRONTEND_PORT% 未被占用，前端未运行
    echo =========================================
    exit /b 0
)

echo 发现进程 %PID% 占用端口 %FRONTEND_PORT%
netstat -ano | findstr ":%FRONTEND_PORT% "
echo 正在终止进程...
taskkill /PID %PID% /F >nul 2>&1

timeout /t 1 /nobreak >nul
echo 前端已停止
echo =========================================

endlocal
