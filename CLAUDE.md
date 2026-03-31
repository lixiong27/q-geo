# CLAUDE.md

## 项目概述

GEO 运营平台 - 支持 Query 词管理、内容生成、GEO 分析、多渠道发布。

## 工作流程

```
确认开发目录 → 读取 progress.md → 确认当前阶段 → 执行任务 → 更新 progress.md
```

**第一步：确认开发目录**

查看 `docs/` 下有哪些开发需求文件夹，向用户确认当前开发哪个。

**第二步：读取进度文件**

```
docs/{需求目录}/progress.md
```

该文件记录：
- 当前所处阶段
- 已完成/待完成任务
- 下一步行动

**第三步：确认任务**

读取 progress.md 后，向用户确认要执行的任务，用户确认后再开始开发。

**第四步：更新进度**

任务完成后，更新 progress.md 中对应任务状态。

## 需求结构

```
docs/{需求目录}/
├── design/           # 模块设计文档
├── tech-spec/        # 技术方案
└── progress.md       # 进度追踪
```

## 技术栈

**后端：** Java 8 + Spring Boot 2.6.6 + QConfig + QSchedule + JdbcTemplate

**前端：** Node 12.16.1 + React 16 + Ant Design 4.x

## Git 提交

```
feat: AI 功能描述
fix: AI 修复描述
docs: AI 文档描述
```
