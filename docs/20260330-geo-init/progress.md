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
├── front/
│   └── ares_analysisnode/              # 前端项目
│       ├── src/
│       │   ├── api/                    # API 服务
│       │   ├── components/             # 组件
│       │   ├── pages/                  # 页面
│       │   └── setupProxy.js           # 本地代理配置
│       └── package.json
│
├── scripts/                         # 快捷脚本
│   ├── start-frontend.sh            # 启动前端
│   ├── restart-frontend.sh          # 重启前端
│   ├── stop-frontend.sh             # 停止前端
│   └── status.sh                    # 服务状态检查
│
└── docs/
    └── 20260330-geo-init/              # 本次迭代文档
        ├── design/                      # 设计文档
        ├── tech-spec/                   # 技术方案
        │   ├── frontend-spec.md
        │   ├── backend-spec.md
        │   └── sql/schema.sql           # 数据库建表脚本
        ├── test/                        # 测试用例
        │   ├── test-cases.md            # 按模块组织的测试用例
        │   └── testing-guide.md         # 测试指南
        └── progress.md
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
| 数据库建表脚本 | ✅ 完成 | 8张表 + 初始数据 |

### 阶段三：后端开发

| 任务 | 状态 | 说明 |
|------|------|------|
| 数据库建表 | ✅ 完成 | 已在 mkt_ares_live_beta 创建 8 张表 |
| 热词模块 Entity | ✅ 完成 | HotWord, HotWordTask |
| 热词模块 Mapper | ✅ 完成 | HotWordMapper, HotWordTaskMapper |
| 热词模块 Service | ✅ 完成 | HotWordService, HotWordTaskService (含 Mock LLM) |
| 热词模块 Controller | ✅ 完成 | HotWordController |
| 内容模块 Entity | ✅ 完成 | Content, ContentTask |
| 内容模块 Mapper | ✅ 完成 | ContentMapper, ContentTaskMapper |
| 内容模块 Service | ✅ 完成 | ContentService, ContentTaskService (含 Mock LLM) |
| 内容模块 Controller | ✅ 完成 | ContentController |
| GEO 分析模块 Entity | ✅ 完成 | GeoProvider, GeoMonitorData |
| GEO 分析模块 Mapper | ✅ 完成 | GeoProviderMapper, GeoMonitorDataMapper |
| GEO 分析模块 Service | ✅ 完成 | GeoProviderService, GeoMonitorDataService |
| GEO 分析模块 Controller | ✅ 完成 | GeoController |
| 发布中心模块 Entity | ✅ 完成 | PublishChannel, PublishTask |
| 发布中心模块 Mapper | ✅ 完成 | PublishChannelMapper, PublishTaskMapper |
| 发布中心模块 Service | ✅ 完成 | PublishChannelService, PublishTaskService |
| 发布中心模块 Controller | ✅ 完成 | PublishController |
| 数据中心模块 Controller | ✅ 完成 | DataCenterController (聚合查询) |
| QSchedule 定时任务 | ❌ 待开始 | GEO 监控数据采集 |

### 阶段四：前端开发

| 任务 | 状态 | 说明 |
|------|------|------|
| 项目初始化 | ✅ 完成 | React 16 + Ant Design 4.x |
| 公共组件 (Layout) | ✅ 完成 | 侧边栏导航 |
| 热词中心页面 | ✅ 完成 | 管理/挖掘/扩词三个 Tab |
| 内容中心页面 | ✅ 完成 | 内容管理/内容生成两个 Tab |
| GEO 分析页面 | ✅ 完成 | AI 平台排名监控面板 |
| 数据中心页面 | ✅ 完成 | 汇总统计与趋势图表 |
| 发布中心页面 | ✅ 完成 | 发布任务/渠道管理两个 Tab |
| API 服务改造 | ✅ 完成 | 移除 mock，连接真实后端 |
| 本地代理配置 | ✅ 完成 | setupProxy.js 配置 |

### 阶段五：联调测试

| 任务 | 状态 | 说明 |
|------|------|------|
| 测试用例文档 | ✅ 完成 | 按模块组织，合并前后端测试 |
| 后端本地启动 | ✅ 完成 | IDEA Tomcat 部署，端口 8080 |
| 前端本地启动 | ✅ 完成 | Node v12.16.1，端口 3000 |
| 前后端联调 | ❌ 待开始 | - |
| 功能测试 | ❌ 待开始 | - |

---

## 当前进度

**当前阶段：** 阶段五 - 联调测试

**测试指南：** [guide/testing-guide.md](../../guide/testing-guide.md)

**已完成：**
- 设计文档（GEO分析、数据中心、热词中心、内容中心、发布中心）
- 前端技术方案
- 后端技术方案（基于 Qunar 内部框架）
- **数据库建表**（8张表 + 初始数据）
- **全部模块后端**（Entity, Mapper, Service, Controller）
- **全部模块前端**（页面 + API 服务）
- **前端代理配置**（连接后端 8080）
- **测试用例文档**（按模块组织）
- **前端本地启动**（Node v12.16.1，端口 3000）

**进行中：**
- 前后端联调测试

**下一步：**
1. 功能测试
2. QSchedule 定时任务（GEO 监控数据采集）

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
- http-proxy-middleware（本地代理）

---

## 关键约定

### 接口规范
- 统一前缀：`/api`
- 统一响应格式：`{ code: 0, message: "success", data: {} }`

### 本地开发
- 后端：IDEA Tomcat 部署，端口 8080
- 前端：npm start，端口 3000，代理到后端 8080
- 数据库：mkt_ares_live_beta

### QConfig 配置 Key
- GEO Provider 配置：`geo.provider.{code}.logo/description/icon`

### 定时任务
- GEO 监控数据采集：每日 00:30 执行
