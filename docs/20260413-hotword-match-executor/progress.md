# 进度追踪

## 需求概述

**需求名称**：热词匹配分析 Executor 实现
**创建日期**：2026-04-13
**负责人**：Claude AI

## 当前阶段

**阶段**：阶段二 - 后端开发（已完成）

## 需求描述

实现一个热词匹配分析 Executor（DailyPubAnalysisExecutor），产出每条热词的匹配分析结果：
- hotwordName: 热词名称
- answerHasAct: 答案是否含有活动（活动由热词第一个 tag 映射）
- referHasAct: 引用信源是否含有活动
- answerHasQ: 答案是否含有"去哪儿"或"qunar"
- referHasQ: 引用信源是否含有"去哪儿"或"qunar"
- rankDetail: 排名详情
  - rank: 去哪儿在品牌出现顺序中的排名，未出现则为 -1
  - detail: answer 里按顺序出现的品牌列表

## 设计要点

### 活动映射配置
- 配置位置：HotFileQConfig（hotfile.properties）
- 配置格式：固定前缀 `dailyPubAnalysisExecutor_{tag}` = 活动名称
- 示例：`dailyPubAnalysisExecutor_tagA=免费机票活动`
- 获取方式：热词第一个 tag -> 拼接 key -> 从 HotFileQConfig 获取活动名

### 去哪儿匹配
- 匹配关键词："去哪儿"、"qunar"（不区分大小写）

### 排名规则
- 遍历 answer 中出现的品牌，记录顺序
- 如果"去哪儿"出现，rank 为其在品牌顺序中的位置（从1开始）
- 如果"去哪儿"未出现，rank 为 -1
- detail 为按顺序出现的品牌列表

### 类型限制
- ExecutorConfig 新增 typeLimitList 字段
- 如果为空，所有 type 都可使用
- 如果有值，仅指定 type 可使用

## 任务清单

### 阶段一：设计文档
- [x] 确认活动映射配置方式
- [x] 确认去哪儿匹配规则
- [x] 确认排名规则
- [x] 确认类型限制方式
- [x] 编写详细设计文档

### 阶段二：后端开发
- [x] 更新 ExecutorConfig 新增 typeLimitList 字段
- [x] 更新 GeoAnalysisQConfig 新增 qunarKeywords 配置
- [x] 创建 DailyPubAnalysisResult 结果实体
- [x] 实现 DailyPubAnalysisExecutor
- [x] 更新 Executor 工厂支持 typeLimitList 校验
- [x] 编译验证代码

### 阶段三：测试
- [ ] 单元测试
- [ ] 集成测试

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-13 | 确认需求和技术要点 | 已完成 |

## 下一步行动

1. 编写详细设计文档
2. 开始后端开发
