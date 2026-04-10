# 下游服务调用新增 type 参数

## 需求背景

下游服务 API 新增 `type` 参数，调用时需要传递该参数用于区分任务类型。如果没有配置则默认传 `default`。

热词中心调用时，`type` 从 `hotword_model_config.json` 配置中读取新增的 `taskType` 字段，实时传递。

## 方案概述

1. 修改 `DownstreamTaskRequest` 添加 `type` 字段，默认值 `default`
2. 修改 `DownstreamTaskClient.createTask` 方法签名，新增 `type` 参数
3. 各配置文件添加 `taskType` 字段
4. 各 Executor 调用时传递对应的 `type`

## 技术方案

### 1. 配置文件改动

#### hotword_model_config.json

```json
{
  "doubao": {
    "prompt": "请分析以下热词...",
    "downstreamHost": "...",
    "taskType": "hotword_analysis"
  }
}
```

#### HotWordModelConfig.java

新增字段：
```java
private String taskType;  // 传给下游服务的 type 参数
```

### 2. 代码改动

#### DownstreamTaskRequest.java

```java
@Data
public class DownstreamTaskRequest {
    private String name;
    private String prompt;
    private int priority;
    private int maxRetries;
    private String type = "default";  // 新增，默认 default

    public DownstreamTaskRequest(String name, String prompt, int priority, int maxRetries, String type) {
        this.name = name;
        this.prompt = prompt;
        this.priority = priority;
        this.maxRetries = maxRetries;
        this.type = type != null ? type : "default";
    }
}
```

#### DownstreamTaskClient.java

```java
public String createTask(String name, String prompt, int priority, int maxRetries, String type) {
    // ...
    DownstreamTaskRequest request = new DownstreamTaskRequest(name, prompt, priority, maxRetries, type);
    // ...
}
```

#### HotWordQConfig.java

新增方法：
```java
/**
 * 获取模型的 taskType
 */
public String getModelTaskType(String model) {
    HotWordModelConfig config = getModelConfig(model);
    if (config != null && StringUtils.isNotEmpty(config.getTaskType())) {
        return config.getTaskType();
    }
    return "default";
}
```

#### AnalysisTaskExecutor.java

```java
// 获取 taskType
String taskType = hotWordQConfig.getModelTaskType(task.getModel());

// 调用下游服务
String returnedTaskId = downstreamTaskClient.createTask(
    task.getName(),
    fullPrompt,
    5,    // priority
    3,    // maxRetries
    taskType  // type
);
```

### 3. 其他 Executor 改动

| Executor | type 来源 | 默认值 |
|----------|----------|--------|
| AnalysisTaskExecutor | hotword_model_config.json 的 taskType | default |
| ClawTaskExecutor | 可扩展从 ContentTemplateConfig 获取 | default |
| PublishTaskExecutor | 可扩展从 PublishChannelConfig 获取 | default |

本次优先实现 AnalysisTaskExecutor，其他 Executor 暂传 `default`。

---

## 任务清单

- [x] DownstreamTaskRequest 添加 type 字段
- [x] DownstreamTaskClient.createTask 添加 type 参数
- [x] HotWordModelConfig 添加 taskType 字段
- [x] HotWordQConfig 添加 getModelTaskType 方法
- [x] AnalysisTaskExecutor 传递 taskType
- [x] ClawTaskExecutor 传递 default
- [x] PublishTaskExecutor 传递 default
- [x] 编译验证
- [x] 提交代码

## 当前进度

**阶段：** 已完成
**提交记录：** efe9e37 feat: AI add type parameter for downstream task creation
