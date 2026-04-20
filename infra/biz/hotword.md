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
| `/api/hotWord/task/list` | GET | 任务列表查询 |
| `/api/hotWord/task/subTasks` | GET | 子任务列表 |
| `/api/hotWord/task/dig/create` | POST | 创建挖掘任务 |
| `/api/hotWord/task/expand/create` | POST | 创建扩展任务 |
| `/api/hotWord/task/analysis/create` | POST | 创建分析任务 |
| `/api/hotWord/task/batch/create` | POST | 创建批量任务 |
| `/api/hotWord/task/callback` | POST | 任务回调 |
| `/api/hotWord/task/priority/list` | GET | 获取优先级列表 |

## Mapper

- `HotWordMapper` - 热词基础数据
- `HotWordTaskMapper` - 任务数据

## 定时任务

详见 [hotword/task.md](hotword/task.md)

## 前端组件

| 组件 | 用途 |
|------|------|
| `HotWordManage.jsx` | 热词管理页面 |
| `HotWordDig.jsx` | 挖掘任务页面 |
| `HotWordExpand.jsx` | 扩展任务页面 |
| `HotWordAnalysis.jsx` | 分析任务页面 |

## 相关配置

- **QConfig**: `hotword_model_config.json`（模型配置）
- **执行器**: `AnalysisTaskExecutor`

## 参考

- [状态常量](_states.md) - 任务状态、任务类型
- [数据库表](_tables.md) - hot_word_task 表结构
