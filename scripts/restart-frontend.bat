@echo off
REM GEO 运营平台 - 前端重启脚本 (Windows)
REM 终止现有前端进程并重新启动

setlocal enabledelayedexpansion

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 加载平台配置
call "%SCRIPT_DIR%config\windows.env"

echo =========================================
echo GEO 运营平台 - 前端重启
echo =========================================

REM 查找并终止占用端口的进程
echo 检查端口 %FRONTEND_PORT%...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%FRONTEND_PORT% " ^| findstr "LISTENING"') do set PID=%%a

if defined PID (
    echo 发现进程 %PID% 占用端口 %FRONTEND_PORT%，正在终止...
    taskkill /PID %PID% /F >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo 进程已终止
) else (
    echo 端口 %FRONTEND_PORT% 未被占用
)

REM 进入前端目录
cd /d "%FRONTEND_DIR%"

REM 切换 Node 版本 (需要安装 nvm-windows)
echo 切换到 Node %NODE_VERSION%...
where nvm >nul 2>&1
if %errorlevel% equ 0 (
    call nvm use %NODE_VERSION%
) else (
    echo 警告: nvm 未安装，使用系统默认 Node
)

REM 验证 Node 版本
echo 当前 Node 版本:
node -v

REM 启动前端
echo 启动前端开发服务器...
echo 前端地址: http://localhost:%FRONTEND_PORT%
echo 后端代理: http://localhost:%BACKEND_PORT%
echo =========================================
call npm start

endlocal
