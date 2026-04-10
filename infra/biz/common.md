# 公共能力

## 数据中心

- **Controller**: `DataCenterController`
- **前端页面**: `pages/datacenter/`

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/dataCenter/all` | GET | 获取所有数据中心 |

## 用户管理

- **Controller**: `UserController`

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/users` | POST | 创建用户 |
| `/api/users/{id}` | GET | 获取用户 |
| `/api/users` | GET | 用户列表 |

## 公共 Mapper

- `UserMapper` - 用户数据

## 前端 API 模块

| 模块 | 用途 |
|------|------|
| `api/hotWord.js` | 热词相关 API |
| `api/content.js` | 内容相关 API |
| `api/publish.js` | 发布相关 API |
| `api/geo.js` | GEO 相关 API |
| `api/datacenter.js` | 数据中心 API |

## 公共工具类

| 类 | 用途 |
|----|------|
| `HttpUtils` | HTTP 请求工具 |
| `JsonUtils` | JSON 序列化工具 |
