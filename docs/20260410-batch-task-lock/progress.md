# 批量任务进度更新 Redis 分布式锁

## 需求背景

批量分析任务的子任务回调时，需要并发更新主批量任务的 `successIds` / `failedIds` 字段。当前使用数据库行锁 `selectByIdForUpdate`，存在以下问题：
- 数据库连接资源占用
- 锁粒度较粗，影响数据库性能

## 方案概述

改用 Redis 分布式锁替代数据库行锁，支持重试机制。

## 技术方案

### 1. 锁配置

| 配置项 | QConfig Key | 默认值 | 说明 |
|--------|-------------|--------|------|
| 重试次数 | `batch.task.lock.retries` | 6 | 获取锁最大重试次数 |
| 随机等待最大秒数 | `batch.task.lock.sleep.max` | 9 | 重试前随机等待 1~n 秒 |
| 锁过期时间 | `lock.expire.seconds` | 30 | Redis 锁自动过期时间（已有） |

### 2. 锁 Key 格式

```
batch_task_progress:{batchTaskId}
```

示例：`batch_task_progress:431`

### 3. 核心逻辑

```
for i in 0..maxRetries:
    if tryLock(lockKey):
        locked = true
        break
    sleep(random(1, sleepMaxSeconds))

if not locked:
    record monitor "batch_task_lock_failed"
    return

try:
    // 执行更新逻辑
    batchTask = selectById(batchTaskId)  // 无需行锁
    update successIds / failedIds
    update batchTask
finally:
    if locked:
        unlock(lockKey)
```

### 4. 代码改动

**文件：** `HotWordTaskService.java`

**改动点：**
1. 注入 `RedisUtil` 和 `HotFileQConfig`
2. 修改 `updateBatchTaskProgress` 方法：
   - 使用 Redis 锁替代 `selectByIdForUpdate`
   - 添加重试逻辑
   - finally 块释放锁

### 5. 监控指标

| 指标名 | 说明 |
|--------|------|
| `batch_task_lock_failed` | 获取锁失败次数 |

---

## 任务清单

- [x] 修改 HotWordTaskService 注入 RedisUtil 和 HotFileQConfig
- [x] 实现 updateBatchTaskProgress Redis 锁逻辑
- [x] 编译验证
- [x] 提交代码

## 当前进度

**阶段：** 已完成
**提交记录：** 5160fac feat: AI implement Redis distributed lock for batch task progress update
