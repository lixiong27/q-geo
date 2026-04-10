# 内容生成模块

## 业务入口

- **Controller**: `ContentController`, `ContentTaskController`
- **前端页面**: `pages/content/`
- **Service**: `ContentTaskService`

## API 清单

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/content/list` | GET | 内容列表查询 |
| `/api/content/detail` | GET | 内容详情 |
| `/api/content/add` | POST | 新增内容 |
| `/api/contentTask/list` | GET | 任务列表查询 |
| `/api/contentTask/add` | POST | 创建任务 |
| `/api/contentTask/templates` | GET | 获取模板列表 |
| `/api/contentTask/callback` | POST | 任务回调 |

## Mapper

- `ContentMapper` - 内容基础数据
- `ContentTaskMapper` - 任务数据

## 前端组件

| 组件 | 用途 |
|------|------|
| `ContentManage.jsx` | 内容管理页面 |
| `ContentGenerate.jsx` | 内容生成页面 |

## 相关配置

- **QConfig**: `content_template_config.json`（模板配置）
- **执行器**: `ContentTaskExecutor`, `ClawTaskExecutor`

## 参考

- [状态常量](_states.md) - 任务状态、内容状态
- [数据库表](_tables.md) - content_task 表结构
