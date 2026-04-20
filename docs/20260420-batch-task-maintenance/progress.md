# 进度追踪

## 需求概述

**需求名称**：批量任务维护定时任务
**创建日期**：2026-04-20
**负责人**：Claude AI

## 当前阶段

**阶段**：后端开发完成，已提交

## 需求描述

新建定时任务，查询最近 n 天的批量任务（type=batch_analysis, status=running），串行处理每个批量任务，完成三个维护逻辑：

### 三个核心逻辑

**1. 校准 successIds/failedIds**
- 查询 subTaskIds 中实际 status=2 和 status=3 的任务
- 重新构建 successIds 和 failedIds
- 解决数据不一致问题，同时作为定期同步机制

**2. 检查未回调任务（80% 完成度时触发）**
- 完成度计算：`(successIds.size() + failedIds.size()) / subTaskIds.size() >= 0.8`
- 查询状态为 1 (RUNNING) 的子任务
- 调用下游接口检查是否回调过
- 未回调的任务标记为失败 (status=3)

**3. 批量重试失败任务**
- 对当前批量任务的失败子任务调用 retry()
- 不限制重试次数

## 技术方案

### 1. 整体架构

```
BatchTaskMaintenanceScheduleTask
├── @QSchedule("mkt_ares_batch_task_maintenance")  // 频率由外部配置
├── 查询最近 n 天的批量任务（QConfig 配置 n，默认 7）
│   └── type = batch_analysis, status = running
├── 串行遍历每个批量任务
│   ├── 步骤1: 校准 successIds/failedIds
│   ├── 步骤2: 检查 80% 完成度，处理未回调任务
│   └── 步骤3: 批量重试失败任务
└── 日志记录 + 监控指标
```

### 2. Redis 分布式锁抽象

新增 `RedisDistributedLock` 类，封装锁获取、重试、睡眠、释放逻辑：

```java
@Component
public class RedisDistributedLock {
    /**
     * 在分布式锁保护下执行任务
     * @return 执行结果，获取锁失败返回 Optional.empty()
     */
    public <T> Optional<T> executeWithLock(String lockKey, Supplier<T> task);

    /**
     * 无返回值版本
     */
    public boolean executeWithLock(String lockKey, Runnable task);
}
```

配置项：
- `distributed.lock.retries`: 最大重试次数，默认 6
- `distributed.lock.sleep.max`: 最大睡眠秒数，默认 9

### 3. 步骤1 - 校准逻辑

```
1. 解析 batchTask.result 获取 subTaskIds, successIds, failedIds
2. 批量查询子任务实际状态: SELECT id, status FROM hot_word_task WHERE id IN (subTaskIds)
3. 重新构建: newSuccessIds = [id WHERE status = 2], newFailedIds = [id WHERE status = 3]
4. 有变化则更新 batchTask.result
```

### 4. 步骤2 - 检查未回调任务

```
1. 计算完成度: completedRatio = (successIds + failedIds) / subTaskIds
2. if (completedRatio < 0.8) return
3. 查询 RUNNING 状态子任务: SELECT * FROM hot_word_task WHERE id IN (subTaskIds) AND status = 1
4. 调用下游接口: downstreamCallbackChecker.checkBatch(downstreamTaskIds)
   返回: Map<downstreamTaskId, hasCallback>
5. 标记未回调任务为失败: status = 3, result = {"error": "callback_lost"}
6. 更新 batchTask.failedIds
```

新增 `DownstreamCallbackChecker` 类（先 mock 实现）：
```java
@Service
public class DownstreamCallbackChecker {
    /**
     * 批量查询下游任务回调状态
     * @return Map<downstreamTaskId, hasCallback> true=已回调, false=未回调
     */
    public Map<String, Boolean> checkBatch(List<String> downstreamTaskIds);
}
```

### 5. 步骤3 - 批量重试

```
1. 从 batchTask.result 解析 failedIds
2. 查询失败子任务: SELECT * FROM hot_word_task WHERE id IN (failedIds) AND status = 3
3. 逐个调用 hotWordTaskService.retry(task.id)
4. 记录日志
```

### 6. QConfig 配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `batch.task.maintenance.days` | 7 | 查询最近 n 天的批量任务 |
| `distributed.lock.retries` | 6 | 分布式锁最大重试次数 |
| `distributed.lock.sleep.max` | 9 | 分布式锁最大睡眠秒数 |

## 任务清单

### 基础设施
- [x] 新增 `RedisDistributedLock.java` 分布式锁抽象类
- [x] 重构 `HotWordTaskService.updateBatchTaskProgress()` 使用新的锁抽象

### 下游接口
- [x] 新增 `DownstreamCallbackChecker.java`（mock 实现）

### 定时任务
- [x] 新增 `BatchTaskMaintenanceScheduleTask.java`
- [x] 实现 `calibrateBatchTask()` 校准逻辑
- [x] 实现 `checkUncallbackedTasks()` 未回调检查逻辑
- [x] 实现 `retryFailedSubTasks()` 重试逻辑

### Mapper
- [x] `HotWordTaskMapper` 新增 `selectBatchTasksForMaintenance()` 方法
- [x] `HotWordTaskMapper.xml` 新增对应 SQL

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-20 | 需求分析，完成技术方案设计 | 已完成 |
| 2026-04-20 | 后端开发完成 | 已完成 |
| 2026-04-20 | 代码提交到 GitLab | 已完成 |

## 下一步行动

1. 完成 - 后端开发已提交
2. 等待后续部署和验证

## 文件清单

| 文件 | 操作 |
|------|------|
| `infra/util/RedisDistributedLock.java` | 新增 |
| `invoker/http/DownstreamCallbackChecker.java` | 新增 |
| `task/BatchTaskMaintenanceScheduleTask.java` | 新增 |
| `service/hotword/HotWordTaskService.java` | 修改（重构锁逻辑） |
| `infra/dao/hotword/HotWordTaskMapper.java` | 修改 |
| `infra/dao/hotword/HotWordTaskMapper.xml` | 修改 |

## 注意事项

1. **串行处理**：批量任务串行处理，避免并发问题
2. **分布式锁**：每个批量任务处理前获取锁，防止与其他更新逻辑冲突
3. **异步重试**：重试是异步的，不等待执行结果
4. **无重试限制**：失败任务不限制重试次数
