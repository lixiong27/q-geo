# GEO 项目开发进度

## 项目概述

基于现有后端 Demo (ares_analysisterm) 扩展实现 GEO 运营平台。

**后端工程已存在**：`backend/ares_analysisterm/`

---

## 目录结构

```
q-geo/
├── backend/
│   └── ares_analysisterm/              # 后端项目 (去哪儿内部框架)
│       ├── pom.xml                     # 父 POM
│       └── mkt_ares_analysisterm_web/  # Web 模块
│           ├── pom.xml
│           └── src/main/
│               ├── java/com/qunar/ug/flight/contact/ares/analysisterm/
│               │   ├── Application.java         # 启动类
│               │   ├── domain/                   # 领域层
│               │   │   └── entity/               # 实体类
│               │   ├── infra/                    # 基础设施层
│               │   │   ├── config/               # 配置类
│               │   │   ├── configuration/        # 组件配置
│               │   │   ├── dao/                  # Mapper 接口
│               │   │   └── qconfig/              # QConfig 配置服务
│               │   ├── service/                  # 服务层
│               │   ├── web/                      # 控制层
│               │   └── task/                     # 定时任务
│               └── resources/
│                   └── mapper/                   # Mapper XML
│
├── front/                               # 前端项目 (待创建)
│
└── docs/
    └── 20260330-geo-init/              # 本次迭代文档
        ├── design/                      # 设计文档
        │   ├── GEO分析.md               # GEO 分析模块设计
        │   ├── 数据中心.md              # 数据中心模块设计
        │   ├── 热词中心.md              # 热词中心模块设计
        │   ├── 内容中心.md              # 内容中心模块设计
        │   └── 发布中心.md              # 发布中心模块设计
        ├── tech-spec/                   # 技术方案
        │   ├── frontend-spec.md         # 前端技术方案
        │   └── backend-spec.md          # 后端技术方案
        └── progress.md                  # 本进度文件
```

**后端分支：** `20260330-geoInit-FD-401306`

---

## 开发阶段

### 阶段一：设计文档 ✅

| 任务 | 状态 | 说明 |
|------|------|------|
| GEO 分析设计文档 | ✅ 完成 | 表设计、接口设计、数据流向 |
| 数据中心设计文档 | ✅ 完成 | 实时聚合查询、单接口返回全部数据 |
| 热词中心设计文档 | ✅ 完成 | 表设计、接口设计 |
| 内容中心设计文档 | ✅ 完成 | 表设计、接口设计 |
| 发布中心设计文档 | ✅ 完成 | 表设计、接口设计、模块关联 |

### 阶段二：技术方案 ✅

| 任务 | 状态 | 说明 |
|------|------|------|
| 前端技术方案 | ✅ 完成 | Node 12.16.1 + React + Ant Design |
| 后端技术方案 | ✅ 完成 | 基于现有 Demo，使用 Qunar 内部框架 |
| 接口文档 | ❌ 待完成 | 需要更新为实际后端结构 |

### 阶段三：后端开发

| 任务 | 状态 | 说明 |
|------|------|------|
| 数据库建表 | ❌ 待开始 | - |
| Entity 实体类 | ❌ 待开始 | - |
| Mapper 层 | ❌ 待开始 | - |
| Service 层 | ❌ 待开始 | - |
| Controller 层 | ❌ 待开始 | - |
| QSchedule 定时任务 | ❌ 待开始 | GEO 监控数据采集 |

### 阶段四：前端开发

| 任务 | 状态 | 说明 |
|------|------|------|
| 项目初始化 | ❌ 待开始 | - |
| 公共组件 | ❌ 待开始 | - |
| 热词中心页面 | ❌ 待开始 | - |
| 内容中心页面 | ❌ 待开始 | - |
| GEO 分析页面 | ❌ 待开始 | - |
| 数据中心页面 | ❌ 待开始 | - |
| 发布中心页面 | ❌ 待开始 | - |

### 阶段五：联调测试

| 任务 | 状态 | 说明 |
|------|------|------|
| 前后端联调 | ❌ 待开始 | - |
| 功能测试 | ❌ 待开始 | - |

---

## 当前进度

**当前阶段：** 阶段二 - 技术方案（已完成）

**已完成：**
- 设计文档（GEO分析、数据中心、热词中心、内容中心、发布中心）
- 前端技术方案
- 后端技术方案（基于 Qunar 内部框架）

**下一步：**
1. 数据库建表
2. 后端 Entity/Mapper/Service/Controller 开发
3. 前端项目初始化

---

## 技术栈

### 后端
- Java 8
- Spring Boot 2.6.6
- MyBatis 3.x
- Lombok
- QConfig（配置中心）
- QSchedule（定时任务）
- qclient-redis
- pxc-datasource（MySQL）

### 前端
- Node.js 12.16.1
- React 16.14.0
- Ant Design 4.x
- React Router 5.x
- Axios

---

## 关键约定

### 接口规范
- 统一前缀：`/api`
- 统一响应格式：`{ code: 0, message: "success", data: {} }`

### QConfig 配置 Key
- GEO Provider 配置：`geo.provider.{code}.logo/description/icon`

### 定时任务
- GEO 监控数据采集：每日 00:30 执行
