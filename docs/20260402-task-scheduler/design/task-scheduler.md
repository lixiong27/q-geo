# 任务调度系统设计

## 概述

热词分析任务需要调用下游 AI 服务执行，本模块实现任务调度、下游对接、回调处理。

## 架构

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   前端创建任务   │────▶│   后端调度器    │────▶│   下游 AI 服务   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │                        │
                               │                        │ 回调
                               ▼                        ▼
                        ┌─────────────────────────────────┐
                        │        更新任务状态/结果         │
                        └─────────────────────────────────┘
```

## 核心流程

### 1. 创建任务

```
用户创建热词分析任务
    ↓
构造 prompt (模型prompt + 热词内容)
    ↓
调用下游 POST /api/tasks
    ↓
保存 downstream_task_id 到任务表
    ↓
定时轮询 或 等待回调
```

### 2. 回调处理

```
下游任务完成
    ↓
POST /api/hotWord/task/callback
    ↓
根据类型更新任务状态和结果
```

## 下游接口

### 创建任务

```
POST {downstream_host}/api/tasks

请求体:
{
  "name": "热词分析-xxx",
  "prompt": "基于模型prompt + 热词内容",
  "priority": 5,
  "maxRetries": 3
}

响应:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "热词分析-xxx",
  "status": "pending",
  ...
}
```

## 配置

### QConfig - hotfile.properties

```properties
# 下游服务域名
hotword.analysis.downstream.host=http://ai-service.internal.corp.qunar.com

# 各模型 prompt 模板
hotword.model.prompt.deepseek=请分析以下热词，生成相关词汇...
hotword.model.prompt.qianwen=基于以下热词进行扩展分析...
hotword.model.prompt.doubao=对以下热词进行深度分析...
```

## 数据库变更

### hot_word_task 表新增字段

| 字段 | 类型 | 说明 |
|------|------|------|
| downstream_task_id | VARCHAR(64) | 下游任务ID |

## 回调接口设计

### 请求

```
POST /api/hotWord/task/callback

请求体:
{
  "taskId": "550e8400-e29b-41d4-a716-446655440000",  // 下游任务ID
  "type": "analysis",                                 // 任务类型
  "status": "completed",                              // completed/failed
  "result": ["词汇1", "词汇2", "词汇3"]                // 分析结果
}
```

### 响应

```json
{
  "code": 0,
  "msg": "success"
}
```
