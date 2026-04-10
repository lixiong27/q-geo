# 进度追踪

## 需求概述

**需求名称**：热词分析模块优化
**创建日期**：2026-04-10
**负责人**：Claude AI

## 当前阶段

**阶段**：编译完成，待提交代码

## 需求描述

热词中心的热词分析模块需要以下优化：

1. **忽略"预期数量"字段**：新建单个分析任务时，前后端均忽略"预期数量"字段（该字段仅在批量分析任务中有意义）
2. **移除热词列表显示**：
   - 单个任务详情页中的"热词列表 (共 x个)"显示需要移除
   - 任务列表页中普通分析任务显示的"n个热词"需要移除
3. **批量任务进度展示修复**：
   - 后端：batch_analysis 类型任务需要返回 success/failed/total 三个字段
   - 前端：修复批量任务进度展示（当前显示"完成: 0 成功 / 0 失败"格式不正确）
4. **任务列表支持分页和搜索**：
   - 后端：任务列表接口支持分页参数和任务名模糊查询
   - 前端：任务列表添加分页组件和搜索框

## 任务清单

### 后端改造
- [x] HotWordTaskListRequest 新增 name 查询参数
- [x] HotWordTaskMapper 新增分页和模糊查询支持
- [x] HotWordTaskMapper.xml 新增模糊查询 SQL
- [x] HotWordTaskService.list 方法传递 name 参数
- [x] HotWordController.getTaskList 接口增加搜索参数

### 前端改造
- [x] HotWordAnalysis.jsx 移除单任务创建表单中的"预期数量"字段
- [x] HotWordAnalysis.jsx 移除任务详情中的"热词列表"标题
- [x] HotWordAnalysis.jsx 移除任务列表中普通任务的"n个热词"显示
- [x] HotWordAnalysis.jsx 修复 batch_analysis 进度展示逻辑（使用 subTaskIds.length 作为总量）
- [x] HotWordAnalysis.jsx 添加任务列表分页组件
- [x] HotWordAnalysis.jsx 添加任务名搜索框
- [x] hotWord.js API 适配分页和搜索参数
- [x] hotWord.js createAnalysisTask 移除 count 参数

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-10 | 创建需求文档 | 已完成 |
| 2026-04-10 | 后端改造完成：任务列表支持任务名模糊查询 | 已完成 |
| 2026-04-10 | 前端改造完成：移除预期数量、修复批量任务进度、添加分页搜索 | 已完成 |
| 2026-04-10 | 编译通过：修复 DataCenterService mapper 调用、添加 cross-env | 已完成 |

## 下一步行动

1. ~~编译前后端代码~~ ✅
2. 提交代码到三个仓库

## 风险与问题

| 风险/问题 | 影响 | 解决方案 | 状态 |
|-----------|------|----------|------|
| 无 | - | - | - |
