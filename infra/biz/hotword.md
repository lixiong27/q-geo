# 热词管理模块

## 业务入口

- **Controller**: `HotWordController`
- **前端页面**: `pages/hotword/`
- **Service**: `HotWordTaskService`

## API 清单

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/hotWord/list` | GET | 热词列表查询 |
| `/api/hotWord/all` | GET | 获取所有热词 |
| `/api/hotWord/add` | POST | 新增热词 |
| `/api/hotWord/import` | POST | 批量导入热词 |
| `/api/hotWord/update` | POST | 更新热词 |
| `/api/hotWord/delete` | POST | 删除热词 |
| `/api/hotWord/types` | GET | 获取热词类型列表 |
| `/api/hotWord/models` | GET | 获取模型列表 |
| `/api/hotWord/task/list` | GET | 任务列表查询 |
| `/api/hotWord/task/detail` | GET | 任务详情 |
| `/api/hotWord/task/subTasks` | GET | 子任务列表 |
| `/api/hotWord/task/dig/create` | POST | 创建挖掘任务 |
| `/api/hotWord/task/expand/create` | POST | 创建扩展任务 |
| `/api/hotWord/task/analysis/create` | POST | 创建分析任务 |
| `/api/hotWord/task/batch/create` | POST | 创建批量任务 |
| `/api/hotWord/task/cancel` | POST | 取消任务 |
| `/api/hotWord/task/retry` | POST | 重试任务 |
| `/api/hotWord/task/callback` | POST | 任务回调 |
| `/api/hotWord/task/importResults` | POST | 导入任务结果 |
| `/api/hotWord/task/importAnalysisResults` | POST | 导入分析结果 |

## Mapper

- `HotWordMapper` - 热词基础数据
- `HotWordTaskMapper` - 任务数据

## 前端组件

| 组件 | 用途 |
|------|------|
| `HotWordManage.jsx` | 热词管理页面 |
| `HotWordDig.jsx` | 挖掘任务页面 |
| `HotWordExpand.jsx` | 扩展任务页面 |
| `HotWordAnalysis.jsx` | 分析任务页面 |

## 下游调用

- `DownstreamTaskClient.createTask()` - 调用下游 AI 服务创建任务

## 相关 QConfig

| 配置 | 说明 |
|------|------|
| `hotword_model_config.json` | 模型配置 |
| `HotWordQConfig` | 热词相关配置类 |
| `HotFileQConfig` | 公共文件配置 |

## 任务执行器

| 执行器 | 用途 |
|--------|------|
| `AnalysisTaskExecutor` | 分析任务执行 |
