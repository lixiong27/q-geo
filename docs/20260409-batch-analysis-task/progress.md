# 进度追踪

## 需求概述

**需求名称**：热词分析批量创建任务
**创建日期**：2026-04-09
**负责人**：Claude AI

## 当前阶段

**阶段**：方案设计已完成，待用户确认开始开发

## 需求描述

在热词中心的热词分析页面新增「批量创建」按钮，支持：
1. 选择同一热词类型，批量创建分析任务
2. 任务名称格式：`日期-热词类型-热词ID`（如：`20260409-poiAnalysis-3000`）
3. 支持选择多个模型，每个模型对每个热词创建一个任务
4. 创建一个批量执行的主任务记录，跟踪整体进度

## 业务流程

```
用户点击「批量创建」
    ↓
选择热词类型 + 选择模型（多选） + 预期数量
    ↓
创建批量任务记录（type=batch_analysis）
    ↓
异步执行：
  1. 根据类型查询所有热词
  2. 遍历热词ID，为每个热词×每个模型创建子任务
  3. 子任务 params 携带 sourceBatchId
  4. 创建完成后更新批量任务 result（subTaskIds）
    ↓
子任务执行完成/失败时：
  1. 检查 params 是否有 sourceBatchId
  2. 如有，更新批量任务 result（successIds/failIds）
  3. 检查是否全部完成，更新批量任务状态
```

## 数据设计

**无需数据库变更**，利用现有字段：

### 批量任务 result 结构
```json
{
  "type": "poiAnalysis",
  "models": ["deepseek", "qianwen"],
  "count": 10,
  "subTaskIds": [124, 125, 126, ...],
  "successIds": [124, 125, ...],
  "failIds": [126, ...]
}
```

### 子任务 params 结构（新增 sourceBatchId）
```json
{
  "hotwordId": 3000,
  "hotword": "北京天安门",
  "type": "poiAnalysis",
  "count": 10,
  "prompt": "...",
  "sourceBatchId": 123  // 新增：来源批量任务ID
}
```

## 核心逻辑

### 1. 批量任务创建
- 创建批量任务记录，status=RUNNING
- 异步创建所有子任务，每个子任务 params 携带 sourceBatchId
- 创建完成后，更新批量任务 result.subTaskIds
- 更新批量任务 status=COMPLETED（表示创建完成，非执行完成）

### 2. 子任务回调更新批量任务
- 子任务执行完成/失败时，检查 params.sourceBatchId
- 如有 sourceBatchId：
  - 查询批量任务，获取当前 result
  - 根据状态更新 successIds 或 failIds
  - 保存更新后的 result
  - 检查 successIds + failIds 是否等于 subTaskIds
  - 如全部完成，更新批量任务状态为 COMPLETED

## 任务清单

### 后端改造
- [ ] HotWordTask 实体新增 `TYPE_BATCH_ANALYSIS` 常量
- [ ] 新增 BatchAnalysisTaskCreateRequest 请求实体
- [ ] HotWordMapper 新增 selectByType 方法
- [ ] HotWordMapper.xml 新增对应 SQL
- [ ] HotWordService 新增 listByType 方法
- [ ] HotWordTaskService.createAnalysisTask 支持 sourceBatchId 参数
- [ ] HotWordTaskService 新增 createBatchAnalysisTask 方法
- [ ] HotWordTaskService 新增 executeBatchAnalysisTaskAsync 异步执行方法
- [ ] HotWordTaskService 新增 updateBatchTaskProgress 方法（子任务回调）
- [ ] HotWordController 新增批量创建接口

### 前端改造
- [ ] HotWordAnalysis.jsx 新增「批量创建」按钮
- [ ] 新增批量创建 Modal（类型选择 + 模型多选 + 数量选择）
- [ ] 新增批量任务卡片渲染（显示进度条）
- [ ] API 新增 createBatchAnalysisTask 方法

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-09 | 需求分析，创建设计文档 | 已完成 |

## 下一步行动

用户确认方案后开始开发

## 风险与问题

| 风险/问题 | 影响 | 解决方案 | 状态 |
|-----------|------|----------|------|
| 批量任务数量可能很大 | 数据库压力 | 分批创建，每批间隔 100ms | 待评估 |
| 并发更新批量任务 result | 数据一致性 | 使用数据库行锁或乐观锁 | 待评估 |
