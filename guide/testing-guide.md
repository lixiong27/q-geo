# GEO 运营平台 - 测试指南

## 资源索引

### Skills

| Skill | 路径 | 用途 |
|-------|------|------|
| Noah MySQL | `.claude/skills/noah-mysql-skill` | 连接 Noah 数据库，执行 SQL |

**Noah MySQL 连接参数：**
```
envCode: live-marketing
appCode: mkt_ares_analysisterm
db-prefix: mysql-mkt_ares_live
数据库: mkt_ares_live_beta
```

### 脚本命令

| 脚本 | Mac | Windows | 功能 |
|------|-----|---------|------|
| 启动后端 | `./scripts/start-backend.sh` | `scripts\start-backend.bat` | Tomcat 启动后端 |
| 停止后端 | `./scripts/stop-backend.sh` | `scripts\stop-backend.bat` | 停止后端 |
| 编译后端 | `./scripts/build-backend.sh` | `scripts\build-backend.bat` | Maven 编译 |
| 启动前端 | `./scripts/start-frontend.sh` | `scripts\start-frontend.bat` | 启动 React 开发服务器 |
| 停止前端 | `./scripts/stop-frontend.sh` | `scripts\stop-frontend.bat` | 停止前端 |
| 重启前端 | `./scripts/restart-frontend.sh` | `scripts\restart-frontend.bat` | 重启前端 |
| 查看状态 | `./scripts/status.sh` | `scripts\status.bat` | 检查服务状态 |

**配置文件：** `scripts/config/mac.env` 或 `scripts/config/windows.env`

---

## 测试循环流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  选择 Case  │────▶│  触发测试   │────▶│  验证结果   │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────┬───────────┘
                    │              │
                    ▼              ▼
              ┌──────────┐  ┌──────────────┐
              │ 通过 ✓   │  │ 失败 → 定位  │
              └──────────┘  └──────┬───────┘
                                   │
                                   ▼
                            ┌─────────────┐
                            │ 修复 → 重启 │
                            └─────────────┘
```

### 触发测试方式

1. **curl 接口调用** - 后端 API 测试
2. **前端页面操作** - UI 功能测试
3. **Playwright** - 自动化测试

### 验证方式

1. **接口返回** - 检查 `code`/`message`/`data`
2. **数据库查询** - Noah MySQL Skill 执行 SQL
3. **页面效果** - 浏览器查看

---

## 环境配置

详见 [environment-setup.md](environment-setup.md)

| 服务 | 端口 | 地址 |
|------|------|------|
| 后端 | 8080 | http://localhost:8080 |
| 前端 | 3000 | http://localhost:3000 |

---

## 测试结果文档规范

测试每个模块后，需在 `test/` 目录下生成测试结果文档。

**命名规则：** `{module}_test_result.md`

| 模块 | 测试结果文档 |
|------|-------------|
| 热词中心 | `hot_word_test_result.md` |
| 内容中心 | `content_test_result.md` |
| GEO 分析 | `geo_analysis_test_result.md` |
| 发布中心 | `publish_test_result.md` |
| 数据中心 | `data_center_test_result.md` |

**测试结果文档模板：**

```markdown
# {模块名称} 测试结果

## 测试时间
YYYY-MM-DD HH:mm:ss

## 测试人员
[姓名]

## 测试环境
- 操作系统: Mac / Windows
- 后端版本: [commit hash]
- 前端版本: [commit hash]

## 测试用例

### Case 1: {用例标题}
- 测试步骤:
  1. ...
  2. ...
- 预期结果:
- 实际结果:
- 状态: ✅ 通过 / ❌ 失败
- 备注:

### Case 2: {用例标题}
...

## 问题汇总
| 序号 | 问题描述 | 严重程度 | 状态 |
|------|---------|---------|------|
| 1 | ... | 高/中/低 | 待修复/已修复 |
```

---

## 详细测试用例

详见 [test-cases.md](docs/20260330-geo-init/test/test-cases.md)
