# 进度追踪

## 需求概述

**需求名称**：GEO 分析模块重构
**创建日期**：2026-04-11
**负责人**：Claude AI

## 当前阶段

**阶段**：需求分析 - 设计讨论中

## 需求描述

重构 GEO 分析模块，整体采用任务模型，分为两个模块：
1. **任务创建模块** - 支持周期性/一次性创建分析任务
2. **结果模块** - 分析结果聚合与报表生成

### 核心参数
- **周期性参数**：Cron 表达式，支持用户自定义周期
- **热词模块**：按 type 查询该类型下所有热词
- **分析任务参数**：models（模型列表）、regions（地域列表，待扩展）
- **Executor 配置**：本地计算处理器数组，支持工厂模式扩展

### 业务流程

```
geo_analysis_template 触发（QSchedule 轮询 next_execute_time）
    ↓
创建 geo_analysis_result (status=PENDING)
    ↓
遍历 groups，每个 group 创建：
    hot_word_task (type=geo_batch_analysis)
    params: { templateId, resultId, type, analysisTaskParam, executors }
    ↓
batch_analysis 任务执行：
    - 根据 type 查询该类型下所有热词
    - 遍历热词 × models 创建 sub_analysis 子任务
    ↓
所有 sub_analysis 完成后 → 触发回调
    ↓
回调时依次执行 executors
    ↓
executors 结果存入 geo_analysis_result
    ↓
所有 batch_analysis 完成 → 更新 geo_analysis_result (status=COMPLETED)
```

## 数据设计

### 新增表

#### 1. geo_analysis_template（模板表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| name | VARCHAR(128) | 模板名称 |
| cron_expression | VARCHAR(64) | Cron 表达式（为空表示一次性任务） |
| config | TEXT | 完整配置 JSON（包含 groups） |
| status | TINYINT | 状态：0-停用 1-启用 |
| next_execute_time | DATETIME | 下次执行时间 |
| last_execute_time | DATETIME | 上次执行时间 |
| created_by | VARCHAR(64) | 创建人 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

**config 结构示例：**
```json
{
  "groups": [
    {
      "type": "poiAnalysis",
      "analysisTaskParam": {
        "models": ["deepseek", "qianwen"],
        "regions": ["beijing", "shanghai"]
      },
      "executors": [
        { "code": "poiExecutor1", "params": {} },
        { "code": "poiExecutor2", "params": {} }
      ]
    },
    {
      "type": "platformAnalysis",
      "analysisTaskParam": {
        "models": ["deepseek"],
        "regions": []
      },
      "executors": [
        { "code": "platformExecutor", "params": {} }
      ]
    }
  ]
}
```

**配置说明：**
- `groups`: 热词组配置数组
- `type`: 热词类型，用于查询该类型下所有热词
- `analysisTaskParam`: 分析任务参数
  - `models`: 模型列表
  - `regions`: 地域列表（待扩展）
- `executors`: 执行器数组，每个 type 可配置多个 executor

#### 2. geo_analysis_result（结果表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| template_id | BIGINT | 关联模板 ID |
| status | TINYINT | 状态：0-待执行 1-执行中 2-完成 3-失败 |
| params | TEXT | 关联任务信息 JSON（batch 任务 ID + 状态） |
| result | TEXT | 最终分析结果 JSON |
| execute_time | DATETIME | 执行时间 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

**params 结构示例：**
```json
{
  "batchTasks": [
    {
      "batchTaskId": 123,
      "type": "poiAnalysis",
      "status": "completed",
      "executorResults": [
        { "code": "poiExecutor1", "status": "completed", "result": {} },
        { "code": "poiExecutor2", "status": "completed", "result": {} }
      ]
    },
    {
      "batchTaskId": 124,
      "type": "platformAnalysis",
      "status": "running",
      "executorResults": []
    }
  ]
}
```

**result 结构示例：**
```json
{
  "poiAnalysis": {
    "stats": {
      "totalTasks": 5,
      "completedTasks": 4,
      "failedTasks": 1,
      "avgScore": 85.5
    },
    "executorResults": [
      {
        "code": "poiExecutor1",
        "status": "completed",
        "data": { /* executor 具体输出 */ }
      },
      {
        "code": "poiExecutor2",
        "status": "completed",
        "data": { /* executor 具体输出 */ }
      }
    ]
  },
  "platformAnalysis": {
    "stats": {
      "totalTasks": 5,
      "completedTasks": 4,
      "failedTasks": 1,
      "avgScore": 78.2
    },
    "executorResults": [
      {
        "code": "platformExecutor",
        "status": "completed",
        "data": { /* executor 具体输出 */ }
      }
    ]
  }
}
```

### 复用表

复用 `hot_word_task` 表，新增类型常量：
- `TYPE_GEO_BATCH_ANALYSIS = "geo_batch_analysis"` - GEO 批量分析任务
- `TYPE_GEO_SUB_ANALYSIS = "geo_sub_analysis"` - GEO 子分析任务

## 任务清单

### 阶段一：设计文档
- [x] 需求讨论
- [ ] 设计文档确认
- [ ] 数据库变更脚本

### 阶段二：后端开发
- [ ] Entity 层
- [ ] Mapper 层
- [ ] Service 层
- [ ] Controller 层
- [ ] Executor 实现
- [ ] QSchedule 定时任务

### 阶段三：前端开发
- [ ] 模板管理页面
- [ ] 结果报表页面
- [ ] API 对接

### 阶段四：联调测试
- [ ] 后端接口测试
- [ ] 前端功能测试

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-11 | 需求讨论，确认方案 A（模板表 + 结果表，复用热词任务表） | 已完成 |
| 2026-04-11 | 创建 progress.md 和设计文档 | 已完成 |
| 2026-04-12 | 更新设计：config 合并 hotword+executor，每个 type 独立 executors 数组 | 已完成 |
| 2026-04-12 | 新增 analysisTaskParam 字段（models, regions），结果表新增 params 字段 | 已完成 |
| 2026-04-12 | 确认 result 字段结构：按 type 统计 + executorResults | 已完成 |
| 2026-04-12 | 设计方案确认完成 | 已完成 |

## 下一步行动

1. 编写数据库变更脚本
2. 开始后端开发

## 风险与问题

| 风险/问题 | 影响 | 解决方案 | 状态 |
|-----------|------|----------|------|
| hot_word_task 表承担两个业务域职责 | 表结构耦合 | 通过 type 字段区分，后续可拆分 | 待确认 |
