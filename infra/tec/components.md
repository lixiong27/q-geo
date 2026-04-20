# 技术组件

## Redis

详见 [redis.md](redis.md)

## QConfig 配置管理

### 配置类

| 类 | 配置文件 | 说明 |
|----|----------|------|
| `HotFileQConfig` | 公共配置 | 锁过期时间等公共配置 |
| `HotWordQConfig` | hotword_model_config.json | 热词模型配置 |
| `ContentQConfig` | content_template_config.json | 内容模板配置 |
| `PublishQConfig` | publish_channel_config.json | 发布渠道配置 |

### 使用示例

```java
@Resource
private HotWordQConfig hotWordQConfig;

// 获取配置
String host = hotWordQConfig.getDownstreamHost();
int retryTimes = hotFileQConfig.getInt("lock.retry.times", 6);
```

### 配置优先原则

新增可配置项应优先使用 QConfig，便于动态调整，无需重启服务。

## QSchedule 定时任务

**配置文件**: `spring-qschedule.xml`

用于定时任务调度，具体任务配置参见该文件。

## 下游服务客户端

**类路径**: `infra.client.DownstreamTaskClient`

### 方法

| 方法 | 用途 |
|------|------|
| `createTask(name, prompt, priority, maxRetries, type)` | 创建下游 AI 任务 |

### 使用示例

```java
@Resource
private DownstreamTaskClient downstreamTaskClient;

// 创建任务，type 为空时默认 default
String taskId = downstreamTaskClient.createTask(
    "任务名称",
    "prompt 内容",
    1,      // 优先级
    3,      // 最大重试次数
    "taskType"  // 任务类型
);
```

## 执行器工厂模式

各模块使用工厂模式创建任务执行器：

| 模块 | 工厂类 |
|------|--------|
| 热词 | `AnalysisTaskExecutor` |
| 内容 | `ContentTaskExecutorFactory` |
| 发布 | `PublishTaskExecutorFactory` |

### 使用示例

```java
// 获取对应类型的执行器
ContentTaskExecutor executor = ContentTaskExecutorFactory.getExecutor(type);
executor.execute(task);
```
