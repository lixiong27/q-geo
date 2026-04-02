# Task Scheduler 项目开发进度

## 项目概述

任务调度模块 - 支持热词分析任务对接下游 AI 服务，实现任务提交、回调处理。

### 变更内容

| 变更项 | 说明 |
|--------|------|
| hot_word_task 表 | 新增 downstream_task_id 字段 |
| HotWordQConfig | 新增下游域名、模型 prompt 配置 |
| DownstreamTaskClient | 下游服务客户端 |
| 回调接口 | POST /api/hotWord/task/callback |

---

## 目录结构

```
docs/20260402-task-scheduler/
├── design/               # 设计文档
│   └── task-scheduler.md
├── tech-spec/            # 技术方案
│   ├── sql/migration.sql
│   ├── backend-spec.md
│   └── frontend-spec.md
├── test/                 # 测试用例
│   └── hotword-test-cases.md
└── progress.md           # 本进度文件
```

---

## 开发阶段

### 阶段一：需求分析 ✅

| 任务 | 状态 | 说明 |
|------|------|------|
| 需求确认 | ✅ 完成 | 下游对接、回调接口 |
| 设计文档 | ✅ 完成 | task-scheduler.md |

### 阶段二：技术方案 ✅

| 任务 | 状态 | 说明 |
|------|------|------|
| 数据库变更脚本 | ✅ 完成 | migration.sql |
| 后端技术规格 | ✅ 完成 | backend-spec.md |
| 前端技术规格 | ✅ 完成 | frontend-spec.md |

### 阶段三：后端开发

#### 3.1 数据库变更

| 任务 | 状态 | 说明 |
|------|------|------|
| 执行数据库变更 | ✅ 完成 | ALTER TABLE 新增 downstream_task_id |

#### 3.2 实体层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 HotWordTask 实体 | ✅ 完成 | 新增 downstreamTaskId |

#### 3.3 配置层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 HotWordQConfig | ✅ 完成 | 新增 getDownstreamHost、getModelPrompt |

#### 3.4 Mapper 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 HotWordTaskMapper.xml | ✅ 完成 | 新增字段映射、updateDownstreamTaskId、selectByDownstreamTaskId |
| 修改 HotWordTaskMapper.java | ✅ 完成 | 新增方法接口 |

#### 3.5 下游客户端

| 任务 | 状态 | 说明 |
|------|------|------|
| 新增 DownstreamTaskClient | ✅ 完成 | 下游服务调用 |
| 新增 DownstreamTaskRequest | ✅ 完成 | 请求类 |
| 新增 DownstreamTaskResponse | ✅ 完成 | 响应类 |

#### 3.6 Service 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 HotWordTaskService | ✅ 完成 | handleCallback、getByDownstreamTaskId |
| 修改 AnalysisTaskExecutor | ✅ 完成 | 调用下游服务 |

#### 3.7 Controller 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 新增 TaskCallbackRequest | ✅ 完成 | 回调请求类 |
| 新增回调接口 | ✅ 完成 | POST /task/callback |

### 阶段四：前端开发

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 hotWord.js | ❌ 待开始 | 新增 taskCallback API |

### 阶段五：联调测试

| 任务 | 状态 | 说明 |
|------|------|------|
| 下游接口联调 | ❌ 待开始 | 创建任务、回调 |
| 功能测试 | ❌ 待开始 | 端到端流程 |

---

## 当前进度

**当前阶段：** 阶段三 - 后端开发（已完成）

**已完成：**
- 需求确认
- 设计文档（task-scheduler.md）
- 数据库变更脚本（migration.sql）
- 后端技术规格（backend-spec.md）
- 前端技术规格（frontend-spec.md）
- 数据库变更执行
- 后端代码实现

**下一步：**
1. 前端代码实现
2. 联调测试

---

## 技术栈

### 后端
- Java 8
- Spring Boot 2.6.6
- MyBatis 3.x
- Lombok
- QConfig（配置中心）
- RestTemplate / OkHttp（HTTP 客户端）

### 前端
- Node.js 12.16.1
- React 16.14.0
- Ant Design 4.x
