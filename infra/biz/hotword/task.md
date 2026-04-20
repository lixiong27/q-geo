# 热词定时任务

## 批量任务维护定时任务

**类路径**: `task.BatchTaskMaintenanceScheduleTask`

**QSchedule Key**: `mkt_ares_batch_task_maintenance`

### 功能

定期维护批量任务，包含三个核心逻辑：

| 步骤 | 方法 | 用途 |
|------|------|------|
| 1 | `checkUncallbackedTasks()` | 检查未回调任务，标记为失败 |
| 2 | `retryFailedSubTasks()` | 重试失败的子任务 |
| 3 | `calibrateBatchTask()` | 校准 successIds/failedIds |

### 配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `batch.task.maintenance.days` | 7 | 查询最近 n 天的批量任务 |
| `downstream.callback.check.url` | - | 下游回调检查 API 地址 |
| `downstream.callback.check.timeout.minutes` | 10 | 回调超时阈值（分钟） |

### 下游回调检查器

**类路径**: `invoker.http.DownstreamCallbackChecker`

检查下游任务回调状态，判断是否需要重试。

**判断逻辑**: 返回 `true`（需要重试）当：
- `status != "pending"` 且
- `updatedAt` 超过指定分钟数

```java
@Resource
private DownstreamCallbackChecker downstreamCallbackChecker;

Map<String, Boolean> needRetry = downstreamCallbackChecker.checkBatch(downstreamTaskIds);
```
