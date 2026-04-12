# 进度追踪

## 需求概述

**需求名称**：GEO 分析模块重构
**创建日期**：2026-04-11
**负责人**：Claude AI

## 当前阶段

**阶段**：阶段一 - 设计文档（完成）

## 需求描述

重构 GEO 分析模块，整体采用任务模型，分为两个模块：
1. **任务创建模块** - 支持周期性/一次性创建分析任务
2. **结果模块** - 分析结果聚合与报表生成

**详细设计文档**：[design/geo-analysis-refactor.md](design/geo-analysis-refactor.md)

**数据库脚本**：[tech-spec/sql/migration.sql](tech-spec/sql/migration.sql)

## 目录结构

```
docs/20260411-geo-analysis-refactor/
├── design/
│   └── geo-analysis-refactor.md    # 详细设计文档
├── tech-spec/
│   └── sql/
│       └── migration.sql           # 数据库变更脚本
└── progress.md                     # 本进度文件
```

## 任务清单

### 阶段一：设计文档
- [x] 需求讨论
- [x] 设计文档确认
- [x] 数据库变更脚本

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
| 2026-04-12 | 编写数据库变更脚本 migration.sql | 已完成 |
| 2026-04-12 | 拆分设计文档到 design/ 目录 | 已完成 |

## 下一步行动

1. 执行数据库变更脚本
2. 开始后端开发（Entity 层）

## 风险与问题

| 风险/问题 | 影响 | 解决方案 | 状态 |
|-----------|------|----------|------|
| hot_word_task 表承担两个业务域职责 | 表结构耦合 | 通过 type 字段区分，后续可拆分 | 待确认 |
