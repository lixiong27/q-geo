# 内容生成模块改造 - 进度追踪

## 需求概述

**需求名称**：内容生成模块改造
**创建日期**：2026-04-09
**负责人**：Claude

### 变更内容

| 变更项 | 说明 |
|--------|------|
| content_template_config | 新增模板配置（QConfig），支持 llm/claw 两大类 |
| ContentTask 实体 | 新增 template_code、model、downstream_task_id 字段 |
| 任务执行器 | 参考 HotWordAnalysisTaskExecutor，实现 claw 调用下游服务 |
| 回调接口 | 支持下游服务回调更新任务状态 |

---

## 目录结构

```
docs/20260409-content-generate-enhance/
├── design/           # 设计文档
├── tech-spec/        # 技术方案
├── test/             # 测试用例
└── progress.md       # 本进度文件
```

---

## 开发阶段

### 阶段一：需求分析 ✅

| 任务 | 状态 | 说明 |
|------|------|------|
| 需求确认 | ✅ 完成 | 模板配置 + claw 调用下游服务 |

### 阶段二：后端开发

#### 2.1 数据库变更

| 任务 | 状态 | 说明 |
|------|------|------|
| 新增数据库变更脚本 | ✅ 完成 | content_task 新增 template_code、model、downstream_task_id 字段 |

#### 2.2 实体层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 ContentTask 实体 | ✅ 完成 | 新增 templateCode、model、downstreamTaskId 字段 |
| 新增 ContentTemplateConfig 实体 | ✅ 完成 | 模板配置项（prompt） |

#### 2.3 配置层新增

| 任务 | 状态 | 说明 |
|------|------|------|
| 新增 ContentQConfig 配置类 | ✅ 完成 | 从 QConfig 读取模板配置 |

#### 2.4 Mapper 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 ContentTaskMapper | ✅ 完成 | 新增字段映射、updateDownstreamTaskId、selectByDownstreamTaskId 方法 |

#### 2.5 Service 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 ContentTaskService | ✅ 完成 | 新增 createGenerateTask、handleCallback 方法 |
| 新增 ContentTaskExecutor | ✅ 完成 | 内容生成任务执行器抽象类 |
| 新增 ClawTaskExecutor | ✅ 完成 | Claw 类型任务执行器 |
| 新增 ContentTaskExecutorFactory | ✅ 完成 | 任务执行器工厂 |

#### 2.6 Controller 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 新增 /templates 接口 | ✅ 完成 | 获取模板配置列表 |
| 新增 /callback 接口 | ✅ 完成 | 下游服务回调接口 |
| 修改任务创建接口 | ✅ 完成 | 支持 templateCode、model 参数 |

---

## 当前进度

**当前阶段：** 阶段二 - 后端开发 + 前端适配（已完成）

**已完成：**
- 需求确认
- 目录结构创建
- 数据库变更脚本
- 实体层修改
- 配置层新增（二级目录结构 + name 字段）
- Mapper 层修改
- Service 层修改
- Controller 层修改
- 前端 API 修改
- 前端组件修改（二级联动选择，移除硬编码映射）
- 回调模板重构（ClawTaskExecutor、AnalysisTaskExecutor）
  - 模板配置移至 HotFileQConfig（hotfile.properties）
  - 内容生成：content.generate.callback.url、content.generate.callback.template
  - 热词分析：hotword.analysis.callback.url、hotword.analysis.callback.template
  - 简化模板格式，只保留回调参数 JSON

**下一步：**
1. 集成测试
2. QConfig 配置回调模板（hotfile.properties）

---

## 技术栈

### 后端
- Java 8
- Spring Boot 2.6.6
- MyBatis 3.x
- Lombok
- QConfig（配置中心）
- pxc-datasource（MySQL）

### 参考实现
- 热词分析模块：`service/hotword/executor/AnalysisTaskExecutor.java`
- 配置类：`infra/qconfig/HotWordQConfig.java`
