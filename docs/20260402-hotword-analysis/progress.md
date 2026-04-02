# Hotword Analysis 项目开发进度

## 项目概述

热词分析模块 - 对现有热词中心的扩展，新增热词类型字段和热词分析任务功能。

### 变更内容

| 变更项 | 说明 |
|--------|------|
| hot_word 表 | 新增 type 字段 |
| hot_word_task 表 | 新增 model 字段 |
| QConfig 配置 | 新增热词类型配置 |
| 热词管理页面 | 新增类型筛选 |
| 热词任务页面 | 新增「热词分析」Tab |

---

## 目录结构

```
docs/20260402-hotword-analysis/
├── design/           # 设计文档
│   └── 热词分析.md
├── tech-spec/        # 技术方案
│   ├── sql/migration.sql
│   ├── backend-spec.md   # 后端技术规格
│   └── frontend-spec.md  # 前端技术规格
├── test/             # 测试用例
└── progress.md       # 本进度文件
```

---

## 开发阶段

### 阶段一：需求分析 ✅

| 任务 | 状态 | 说明 |
|------|------|------|
| 需求确认 | ✅ 完成 | 热词类型字段 + 热词分析任务 |
| 设计文档 | ✅ 完成 | 数据库变更、接口设计、页面设计 |

### 阶段二：技术方案 ✅

| 任务 | 状态 | 说明 |
|------|------|------|
| 数据库变更脚本 | ✅ 完成 | ALTER TABLE 语句 |
| 后端技术规格 | ✅ 完成 | backend-spec.md |
| 前端技术规格 | ✅ 完成 | frontend-spec.md |
| 原型更新 | ✅ 完成 | prototype.md + prototype.html（热词分析Tab、类型筛选、类型列、分析任务弹窗、分析结果弹窗） |

### 阶段三：后端开发

#### 3.1 数据库变更

| 任务 | 状态 | 说明 |
|------|------|------|
| 执行数据库变更 | ❌ 待开始 | ALTER TABLE（hot_word 新增 type，hot_word_task 新增 model） |

#### 3.2 实体层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 HotWord 实体 | ✅ 完成 | 新增 type 字段、SOURCE_TYPE_ANALYSIS = 2 |
| 修改 HotWordTask 实体 | ✅ 完成 | 新增 model 字段、TYPE_ANALYSIS = "analysis" |
| 新增 HotWordTypeConfig 实体 | ✅ 完成 | 热词类型配置项（key/type/subType/name/description） |
| 新增 HotWordModelConfig 实体 | ✅ 完成 | 模型配置项（prompt） |

#### 3.3 配置层新增

| 任务 | 状态 | 说明 |
|------|------|------|
| 新增 HotWordQConfig 配置类 | ✅ 完成 | 从 QConfig 读取类型配置和模型配置 |

#### 3.4 Mapper 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 HotWordMapper.java | ✅ 完成 | selectList/selectCount 新增 type 参数 |
| 修改 HotWordMapper.xml | ✅ 完成 | 新增 type 字段映射、Base_Column_List、INSERT、SELECT 条件 |
| 修改 HotWordTaskMapper.xml | ✅ 完成 | 新增 model 字段映射、Base_Column_List、INSERT |

#### 3.5 Service 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 HotWordService | ✅ 完成 | list/add 方法新增 type 参数，新增 addFromAnalysisTask 方法 |
| 修改 HotWordTaskService | ✅ 完成 | 新增 createAnalysisTask、importAnalysisResults 方法 |
| 新增 AnalysisTaskExecutor | ✅ 完成 | 热词分析任务执行器（模板方法模式） |
| 新增 TaskExecutorFactory | ✅ 完成 | 任务执行器工厂 |

#### 3.6 Controller 层修改

| 任务 | 状态 | 说明 |
|------|------|------|
| 新增 AnalysisTaskCreateRequest | ✅ 完成 | 分析任务创建请求类 |
| 新增 AnalysisResultImportRequest | ✅ 完成 | 分析结果导入请求类 |
| 新增 HotWordTypeListResponse | ✅ 完成 | 热词类型列表响应类 |
| 新增 HotWordModelListResponse | ✅ 完成 | 分析模型列表响应类 |
| 修改 HotWordController | ✅ 完成 | 新增 /types、/models、/task/analysis/create、/task/importAnalysisResults 接口 |

### 阶段四：前端开发

| 任务 | 状态 | 说明 |
|------|------|------|
| 修改 hotWord.js API | ✅ 完成 | 新增 getHotWordTypes、getAnalysisModels、createAnalysisTask、importAnalysisResults |
| 修改 index.jsx | ✅ 完成 | 新增「热词分析」Tab |
| 修改 HotWordManage.jsx | ✅ 完成 | 新增类型筛选、类型列、来源「分析」选项、新增/编辑弹窗类型选择 |
| 新增 HotWordAnalysis.jsx | ✅ 完成 | 热词分析任务页面（关联热词模糊搜索、任务列表、新建任务、查看结果、导入热词） |

### 阶段五：联调测试

| 任务 | 状态 | 说明 |
|------|------|------|
| 后端接口测试 | ❌ 待开始 | 新增接口功能验证 |
| 前端功能测试 | ❌ 待开始 | 类型筛选、热词分析任务流程 |
| E2E 测试用例补充 | ❌ 待开始 | 热词分析相关测试用例 |

---

## 当前进度

**当前阶段：** 阶段五 - 联调测试（待开始）

**已完成：**
- 需求确认
- 设计文档（热词分析.md）
- 数据库变更脚本（migration.sql）
- 后端技术规格（backend-spec.md）
- 前端技术规格（frontend-spec.md）
- 原型更新（prototype.md - 分析模型动态获取、关联热词模糊搜索）
- 原型页面更新（prototype.html - 新增热词分析Tab、关联热词模糊搜索）
- 数据库初始化（schema.sql 已执行到 Noah 环境）
- 后端代码实现（实体、配置、Mapper、Service、Controller 全部完成）
- 前端代码实现（API、页面组件全部完成）

**关键设计变更（2026-04-02）：**
- 热词分析任务创建时需关联已有热词（通过模糊搜索选择）
- createAnalysisTask 接口新增必填参数 hotwordId
- 任务参数中存储关联热词ID和热词内容

**下一步：**
1. 执行数据库变更（hot_word 新增 type 字段，hot_word_task 新增 model 字段）
2. 后端接口测试
3. 前端功能测试
4. E2E 测试用例补充

**关联需求：**
- 基于主需求 [docs/20260330-geo-init/](../20260330-geo-init/) 的热词模块扩展

---

## 技术栈

### 后端
- Java 8
- Spring Boot 2.6.6
- MyBatis 3.x
- Lombok
- QConfig（配置中心）
- QSchedule（定时任务）
- pxc-datasource（MySQL）

### 前端
- Node.js 12.16.1
- React 16.14.0
- Ant Design 4.x
- React Router 5.x
- Axios
