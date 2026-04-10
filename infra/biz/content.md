# 内容生成模块

## 业务入口

- **Controller**: `ContentController`, `ContentTaskController`
- **前端页面**: `pages/content/`
- **Service**: `ContentTaskService`

## API 清单

### 内容管理

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/content/list` | GET | 内容列表查询 |
| `/api/content/detail` | GET | 内容详情 |
| `/api/content/add` | POST | 新增内容 |
| `/api/content/update` | POST | 更新内容 |
| `/api/content/delete` | POST | 删除内容 |

### 内容任务

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/contentTask/list` | GET | 任务列表查询 |
| `/api/contentTask/detail` | GET | 任务详情 |
| `/api/contentTask/add` | POST | 创建任务 |
| `/api/contentTask/templates` | GET | 获取模板列表 |
| `/api/contentTask/callback` | POST | 任务回调 |
| `/api/contentTask/cancel` | POST | 取消任务 |
| `/api/contentTask/retry` | POST | 重试任务 |

## Mapper

- `ContentMapper` - 内容基础数据
- `ContentTaskMapper` - 任务数据

## 前端组件

| 组件 | 用途 |
|------|------|
| `ContentManage.jsx` | 内容管理页面 |
| `ContentGenerate.jsx` | 内容生成页面 |

## 下游调用

- `DownstreamTaskClient.createTask()` - 调用下游 AI 服务生成内容

## 相关 QConfig

| 配置 | 说明 |
|------|------|
| `content_template_config.json` | 模板配置 |
| `ContentQConfig` | 内容相关配置类 |

## 任务执行器

| 执行器 | 用途 |
|--------|------|
| `ContentTaskExecutor` | 内容任务执行基类 |
| `ClawTaskExecutor` | 爬虫任务执行 |
