# 进度追踪

## 需求概述

**需求名称**：热词分析批量创建任务
**创建日期**：2026-04-09
**负责人**：Claude AI

## 当前阶段

**阶段**：开发完成，已提交代码

## 需求描述

在热词中心的热词分析页面新增「批量创建」按钮，支持：
1. 选择同一热词类型，批量创建分析任务
2. 任务名称格式：`日期-热词类型-热词ID`（如：`20260409-poiAnalysis-3000`）
3. 支持选择多个模型，每个模型对每个热词创建一个任务
4. 创建一个批量执行的主任务记录，跟踪整体进度
5. 查询该类型下的所有热词，全部创建任务

## 业务流程

```
用户点击「批量创建」
    ↓
选择热词类型 + 选择模型（多选）
    ↓
创建批量任务记录（type=batch_analysis）
    ↓
异步执行：
  1. 根据类型查询所有热词
  2. 遍历热词ID，为每个热词×每个模型创建子任务
  3. 子任务 params 携带 sourceBatchTaskId
  4. 创建完成后更新批量任务 result（subTaskIds）
    ↓
子任务回调时（/callback 接口）：
  1. 检查 params 是否有 sourceBatchTaskId
  2. 如有 sourceBatchTaskId：
     - 查询批量任务，获取当前 result
     - 根据子任务状态更新 successIds 或 failedIds
     - 保存更新后的 result
     - 检查 successIds + failedIds 数量是否等于 subTaskIds 数量
     - 如全部完成，更新批量任务状态为 COMPLETED
```

## 数据设计

**无需数据库变更**，利用现有字段：

### 批量任务 result 结构
```json
{
  "type": "poiAnalysis",
  "models": ["deepseek", "qianwen"],
  "subTaskIds": [124, 125, 126, ...],
  "successIds": [124, 125, ...],
  "failedIds": [126, ...]
}
```

**字段说明：**
- `subTaskIds`: 所有子任务ID列表
- `successIds`: 执行成功的子任务ID列表
- `failedIds`: 执行失败的子任务ID列表

### 子任务 params 结构（新增 sourceBatchTaskId）
```json
{
  "hotwordId": 3000,
  "hotword": "北京天安门",
  "type": "poiAnalysis",
  "prompt": "...",
  "sourceBatchTaskId": 123  // 新增：来源批量任务ID，标识此子任务由批量任务创建
}
```

**判断逻辑：**
- 普通分析任务：params 中无 `sourceBatchTaskId` 字段
- 批量子任务：params 中有 `sourceBatchTaskId` 字段，值为批量任务ID

## 核心逻辑

### 1. 批量任务创建（B方案）
```
createBatchAnalysisTask(type, models):
  1. 创建批量任务记录
     - type = "batch_analysis"
     - status = RUNNING
     - result = {"type": type, "models": models, "subTaskIds": [], "successIds": [], "failedIds": []}

  2. 异步执行：
     a. 根据类型查询所有热词列表
     b. 遍历热词 × 遍历模型：
        - 创建子任务（type=analysis）
        - params 中添加 sourceBatchTaskId = 批量任务ID
        - 收集子任务ID
     c. 更新批量任务 result.subTaskIds = 子任务ID列表
     d. 更新批量任务 status = PENDING（等待子任务执行）
```

### 2. 子任务回调更新批量任务
```
handleCallback(taskId, status):
  1. 根据 taskId 查询子任务
  2. 解析 params，检查是否有 sourceBatchTaskId
  3. 如果 params.sourceBatchTaskId 存在：
     a. 使用 SELECT FOR UPDATE 锁定批量任务行
     b. 获取批量任务 result
     c. 根据 status 更新：
        - 成功：result.successIds.push(taskId)
        - 失败：result.failedIds.push(taskId)
     d. 保存更新后的 result
     e. 检查完成状态：
        - 如果 len(successIds) + len(failedIds) == len(subTaskIds)：
          - 更新批量任务 status = COMPLETED
     f. 提交事务，释放行锁
```

## 任务清单

### 后端改造
- [x] HotWordTask 实体新增 `TYPE_BATCH_ANALYSIS` 常量
- [x] 新增 BatchAnalysisTaskCreateRequest 请求实体
- [x] HotWordMapper 新增 selectByType 方法
- [x] HotWordMapper.xml 新增对应 SQL
- [x] HotWordService 新增 listByType 方法
- [x] HotWordTaskService.createAnalysisTask 支持 sourceBatchTaskId 参数
- [x] HotWordTaskService 新增 createBatchAnalysisTask 方法
- [x] HotWordTaskService 新增 executeBatchAnalysisTaskAsync 异步执行方法
- [x] HotWordTaskService.handleCallback 方法增强：检查 sourceBatchTaskId 并更新批量任务进度
- [x] HotWordController 新增批量创建接口

### 前端改造
- [x] HotWordAnalysis.jsx 新增「批量创建」按钮
- [x] 新增批量创建 Modal（类型选择 + 模型多选）
- [x] 批量任务列表展示（点击查看详情时实时查询进度）
- [x] API 新增 createBatchAnalysisTask 方法

### 前端交互逻辑
- 批量任务列表只展示基本信息（ID、类型、状态、创建时间）
- 用户点击「查看详情」时，调用接口获取最新 result
- 根据 result.successIds/failedIds/subTaskIds 计算并展示进度
- 无需轮询，按需查询

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-09 | 需求分析，创建设计文档 | 已完成 |
| 2026-04-10 | 方案更新：采用B方案，明确 sourceBatchTaskId 字段和回调逻辑 | 已完成 |
| 2026-04-10 | 移除预期数量字段，查询该类型下所有热词 | 已完成 |
| 2026-04-10 | 后端开发完成：批量任务创建、异步执行、回调进度更新 | 已完成 |
| 2026-04-10 | 前端开发完成：批量创建UI、任务列表展示 | 已完成 |
| 2026-04-10 | 代码提交并推送到三个仓库 | 已完成 |

## 下一步行动

功能开发完成，可以进行联调测试

## 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| 批量任务数量可能很大（该类型下所有热词×模型数） | 数据库压力、创建耗时长 | 分批创建，每批间隔 100ms，异步执行不阻塞用户 |
| 并发更新批量任务 result | 数据一致性 | 使用数据库行锁（SELECT FOR UPDATE）更新批量任务 result |
| 子任务回调顺序不确定 | 进度统计准确性 | 回调时直接追加 taskId 到 successIds/failedIds，幂等处理 |
