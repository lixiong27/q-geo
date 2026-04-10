# 多渠道发布模块

## 业务入口

- **Controller**: `PublishChannelController`, `PublishTaskController`
- **前端页面**: `pages/publish/`
- **Service**: `PublishChannelService`, `PublishTaskService`

## API 清单

### 渠道管理

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/publishChannel/list` | GET | 渠道列表查询 |
| `/api/publishChannel/detail` | GET | 渠道详情 |
| `/api/publishChannel/config` | GET | 渠道配置 |
| `/api/publishChannel/enabledCodes` | GET | 已启用渠道代码 |

### 发布任务

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/publishTask/list` | GET | 任务列表查询 |
| `/api/publishTask/detail` | GET | 任务详情 |
| `/api/publishTask/add` | POST | 创建发布任务 |
| `/api/publishTask/retry` | POST | 重试任务 |
| `/api/publishTask/callback` | POST | 任务回调 |

## Mapper

- `PublishChannelMapper` - 渠道数据
- `PublishTaskMapper` - 任务数据

## 前端组件

| 组件 | 用途 |
|------|------|
| `ChannelManage.jsx` | 渠道管理页面 |
| `PublishManage.jsx` | 发布管理页面 |

## 相关 QConfig

| 配置 | 说明 |
|------|------|
| `publish_channel_config.json` | 渠道配置 |
| `PublishQConfig` | 发布相关配置类 |

## 任务执行器

| 执行器 | 用途 |
|--------|------|
| `PublishTaskExecutor` | 发布任务执行基类 |
| `WeiboExecutor` | 微博发布执行 |
| `ZhihuExecutor` | 知乎发布执行 |
| `WechatExecutor` | 微信发布执行 |
