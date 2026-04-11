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
- **热词模块**：选择 N 组热词（不同 type）
- **分析模型模块**：配置分析模型
- **Executor 配置**：本地计算处理器，支持工厂模式扩展

### 业务流程

```
用户创建模板（配置热词组、周期、executor）
    ↓
geo_analysis_template（存储模板配置）
    ↓
QSchedule 轮询（检查 next_execute_time）
    ↓ (到期)
创建 geo_analysis_result（status=PENDING）
    ↓
创建 hot_word_task（type=geo_batch_analysis）
    ↓
为每个 type 创建 hot_word_task（type=geo_sub_analysis）
    ↓
Executor 执行分析
    ↓
更新 geo_analysis_result 状态（子任务回调时聚合统计）
    ↓
生成报表（按 type 分组统计）
```

## 数据设计

### 新增表

#### 1. geo_analysis_template（模板表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| name | VARCHAR(128) | 模板名称 |
| cron_expression | VARCHAR(64) | Cron 表达式（为空表示一次性任务） |
| hotword_config | TEXT | 热词配置 JSON（按 type 分组） |
| executor_config | TEXT | Executor 配置 JSON |
| status | TINYINT | 状态：0-停用 1-启用 |
| next_execute_time | DATETIME | 下次执行时间 |
| last_execute_time | DATETIME | 上次执行时间 |
| created_by | VARCHAR(64) | 创建人 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

**hotword_config 结构示例：**
```json
{
  "groups": [
    { "type": "poiAnalysis", "hotwordIds": [1, 2, 3] },
    { "type": "platformAnalysis", "hotwordIds": [4, 5, 6] }
  ]
}
```

**executor_config 结构示例：**
```json
{
  "executors": [
    { "code": "default", "params": {} },
    { "code": "custom", "params": { "key": "value" } }
  ]
}
```

#### 2. geo_analysis_result（结果表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| template_id | BIGINT | 关联模板 ID |
| batch_task_id | BIGINT | 关联批量任务 ID |
| status | TINYINT | 状态：0-待执行 1-执行中 2-完成 3-失败 |
| result | TEXT | 结果 JSON（按 type 分组统计） |
| execute_time | DATETIME | 执行时间 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

**result 结构示例：**
```json
{
  "totalTasks": 10,
  "completedTasks": 8,
  "failedTasks": 2,
  "byType": {
    "poiAnalysis": { "total": 5, "completed": 4, "failed": 1, "avgScore": 85.5 },
    "platformAnalysis": { "total": 5, "completed": 4, "failed": 1, "avgScore": 78.2 }
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
| 2026-04-11 | 创建 progress.md 和设计文档 | 进行中 |

## 下一步行动

1. 用户在 design/geo-analysis-refactor.md 中标注需要调整的内容
2. 根据反馈更新设计文档
3. 编写数据库变更脚本

## 风险与问题

| 风险/问题 | 影响 | 解决方案 | 状态 |
|-----------|------|----------|------|
| hot_word_task 表承担两个业务域职责 | 表结构耦合 | 通过 type 字段区分，后续可拆分 | 待确认 |
