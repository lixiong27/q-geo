# 多渠道发布模块

## 业务入口

- **Controller**: `PublishChannelController`, `PublishTaskController`
- **前端页面**: `pages/publish/`
- **Service**: `PublishChannelService`, `PublishTaskService`

## API 清单

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/publishChannel/list` | GET | 渠道列表查询 |
| `/api/publishChannel/config` | GET | 渠道配置 |
| `/api/publishChannel/enabledCodes` | GET | 已启用渠道代码 |
| `/api/publishTask/list` | GET | 任务列表查询 |
| `/api/publishTask/add` | POST | 创建发布任务 |
| `/api/publishTask/callback` | POST | 任务回调 |

## Mapper

- `PublishChannelMapper` - 渠道数据
- `PublishTaskMapper` - 任务数据

## 前端组件

| 组件 | 用途 |
|------|------|
| `ChannelManage.jsx` | 渠道管理页面 |
| `PublishManage.jsx` | 发布管理页面 |

## 相关配置

- **QConfig**: `publish_channel_config.json`（渠道配置）
- **执行器**: `PublishTaskExecutor`, `WeiboExecutor`, `ZhihuExecutor`, `WechatExecutor`

## 参考

- [状态常量](_states.md) - 发布状态、渠道状态
- [数据库表](_tables.md) - publish_task 表结构
