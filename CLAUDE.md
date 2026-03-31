# CLAUDE.md

## 项目概述

GEO 运营平台 - 支持 Query 词管理、内容生成、GEO 分析、多渠道发布。

## 工作流程

```
每次会话启动 → 读取 progress.md → 确认当前阶段 → 执行对应任务 → 更新 progress.md
```

**第一步：读取进度文件**

```
docs/20260330-geo-init/progress.md
```

该文件记录：
- 当前所处阶段
- 已完成/待完成任务
- 下一步行动

**第二步：确认任务**

读取 progress.md 后，向用户确认要执行的任务，用户确认后再开始开发。

**第三步：更新进度**

任务完成后，更新 progress.md 中对应任务状态。

## 敏捷需求结构

```
docs/20260330-geo-init/
├── design/           # 模块设计文档
│   ├── GEO分析.md
│   ├── 数据中心.md
│   ├── 热词中心.md
│   ├── 内容中心.md
│   └── 发布中心.md
├── tech-spec/        # 技术方案
│   ├── frontend-spec.md
│   └── backend-spec.md
└── progress.md       # 进度追踪
```

**开发阶段顺序：**

1. **设计文档** - 模块设计、表设计、接口设计
2. **技术方案** - 前后端技术选型、架构设计
3. **后端开发** - 建表 → Entity → DAO → Service → Controller
4. **前端开发** - 初始化 → 公共组件 → 页面开发
5. **联调测试** - 前后端联调、功能测试

## 技术栈

**后端：** Java 8 + Spring Boot 2.6.6 + QConfig + QSchedule + JdbcTemplate

**前端：** Node 12.16.1 + React 16 + Ant Design 4.x

## 接口规范

- 前缀：`/api`
- 响应：`{ code: 0, message: "success", data: {} }`

## Git 提交

```
feat: AI 功能描述
fix: AI 修复描述
docs: AI 文档描述
```
