# GEO 运营平台 - 环境准备指南

本文档描述在不同平台上搭建开发环境的步骤。

## 依赖清单

| 依赖 | 版本 | 用途 |
|------|------|------|
| Java | 17 | 后端运行时 |
| Node.js | v12.16.1 | 前端运行时 |
| npm | 6.14.x | 前端包管理 |
| Maven | 3.x | 后端构建 |
| Tomcat | 9.x | 后端容器 |

---

## Mac 环境设置

### 1. 安装 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. 安装 Java 17 (via jenv)

```bash
# 安装 jenv
brew install jenv

# 配置 shell
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(jenv init -)"' >> ~/.zshrc
source ~/.zshrc

# 安装 OpenJDK 17
brew install openjdk@17

# 添加到 jenv
jenv add /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# 设置全局版本
jenv global 17

# 在项目目录设置
cd /Users/apple/personal/q-geo/backend/ares_analysisterm
jenv local 17
```

### 3. 安装 Node.js (via nvm)

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 加载 nvm
source ~/.zshrc

# 安装 Node v12.16.1
nvm install v12.16.1
nvm use v12.16.1
```

### 4. 安装 Maven

```bash
brew install maven
```

### 5. 安装 Tomcat

```bash
brew install tomcat@9
```

### 6. 配置项目

修改 `scripts/config/mac.env`，确认路径正确：

```bash
# 项目根目录
PROJECT_ROOT=/Users/apple/personal/q-geo

# Tomcat 路径 (检查实际安装版本)
TOMCAT_HOME=/opt/homebrew/Cellar/tomcat@9/9.0.105/libexec
```

---

## Windows 环境设置

### 1. 安装 Java 17

1. 下载 OpenJDK 17: https://adoptium.net/
2. 安装到 `C:\Program Files\Java\jdk-17`
3. 设置环境变量：
   - `JAVA_HOME=C:\Program Files\Java\jdk-17`
   - 添加 `%JAVA_HOME%\bin` 到 `PATH`

### 2. 安装 Node.js (via nvm-windows)

1. 下载 nvm-windows: https://github.com/coreybutler/nvm-windows/releases
2. 安装 nvm-windows
3. 安装 Node v12.16.1：
   ```batch
   nvm install v12.16.1
   nvm use v12.16.1
   ```

### 3. 安装 Maven

1. 下载 Maven: https://maven.apache.org/download.cgi
2. 解压到 `C:\apache-maven-3.8.6`
3. 设置环境变量：
   - `MAVEN_HOME=C:\apache-maven-3.8.6`
   - 添加 `%MAVEN_HOME%\bin` 到 `PATH`

### 4. 安装 Tomcat

1. 下载 Tomcat 9: https://tomcat.apache.org/download-90.cgi
2. 解压到 `C:\apache-tomcat-9.0.105`
3. 设置环境变量：
   - `CATALINA_HOME=C:\apache-tomcat-9.0.105`

### 5. 配置项目

修改 `scripts/config/windows.env`，设置实际路径：

```batch
REM 项目根目录 (根据实际位置修改)
set PROJECT_ROOT=C:\projects\q-geo

REM Tomcat 路径 (根据实际安装修改)
set TOMCAT_HOME=C:\apache-tomcat-9.0.105

REM JAVA_HOME (根据实际安装修改)
set JAVA_HOME=C:\Program Files\Java\jdk-17
```

---

## 配置文件说明

### Mac 配置 (`scripts/config/mac.env`)

```bash
PROJECT_ROOT=/Users/apple/personal/q-geo
FRONTEND_DIR=$PROJECT_ROOT/front/ares_analysisnode
BACKEND_DIR=$PROJECT_ROOT/backend/ares_analysisterm
TOMCAT_HOME=/opt/homebrew/Cellar/tomcat@9/9.0.105/libexec
NODE_VERSION=v12.16.1
JAVA_VERSION=17
BACKEND_PORT=8080
FRONTEND_PORT=3000
NVM_PATH=~/.nvm/nvm.sh
```

### Windows 配置 (`scripts/config/windows.env`)

```batch
set PROJECT_ROOT=C:\projects\q-geo
set FRONTEND_DIR=%PROJECT_ROOT%\front\ares_analysisnode
set BACKEND_DIR=%PROJECT_ROOT%\backend\ares_analysisterm
set TOMCAT_HOME=C:\apache-tomcat-9.0.105
set NODE_VERSION=v12.16.1
set JAVA_VERSION=17
set BACKEND_PORT=8080
set FRONTEND_PORT=3000
set JAVA_HOME=C:\Program Files\Java\jdk-17
```

---

## 快速启动

### Mac

```bash
# 启动后端
./scripts/start-backend.sh

# 启动前端
./scripts/start-frontend.sh

# 查看状态
./scripts/status.sh
```

### Windows

```batch
REM 启动后端
scripts\start-backend.bat

REM 启动前端
scripts\start-frontend.bat

REM 查看状态
scripts\status.bat
```

---

## 常见问题

### Java 17 模块访问错误

**错误信息：**
```
Unable to make field private int java.math.BigInteger.lowestSetBitPlusTwo accessible
```

**解决方案：** 已在 `setenv.sh` / `setenv.bat` 中添加 `--add-opens` JVM 参数。

### Node 版本不匹配

**Mac:**
```bash
source ~/.nvm/nvm.sh
nvm use v12.16.1
```

**Windows:**
```batch
nvm use v12.16.1
```

### 端口被占用

**Mac:**
```bash
lsof -i :8080
kill -9 <PID>
```

**Windows:**
```batch
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

---

## 数据库连接

使用 Noah MySQL Skill 连接数据库：

- **envCode:** `live-marketing`
- **appCode:** `mkt_ares_analysisterm`
- **db-prefix:** `mysql-mkt_ares_live`
- **数据库:** `mkt_ares_live_beta`
