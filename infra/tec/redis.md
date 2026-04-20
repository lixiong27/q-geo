# Redis 组件

## Redis 工具

**类路径**: `infra.util.RedisUtil`

### 方法

| 方法 | 用途 |
|------|------|
| `get(key)` | 获取缓存值 |
| `set(key, value, seconds)` | 设置缓存（带过期时间） |
| `exists(key)` | 判断 key 是否存在 |
| `incr(key)` | 自增 |
| `delete(key)` | 删除 key |
| `tryLock(lockName)` | 获取锁（默认 30 秒过期） |
| `tryLock(lockName, seconds)` | 获取锁（自定义过期时间） |
| `unLock(lockName)` | 释放锁 |

### 使用示例

```java
@Resource
private RedisUtil redisUtil;

// 缓存操作
redisUtil.set("key", "value", RedisUtil.ONE_DAY_SECONDS);
String value = redisUtil.get("key");

// 分布式锁
if (redisUtil.tryLock("lock:key")) {
    try {
        // 执行业务逻辑
    } finally {
        redisUtil.unLock("lock:key");
    }
}
```

## 分布式锁抽象

**类路径**: `infra.util.RedisDistributedLock`

封装锁获取、重试、睡眠、释放逻辑，支持自定义配置。

### 方法

| 方法 | 用途 |
|------|------|
| `executeWithLock(lockKey, task)` | 在分布式锁保护下执行任务（默认配置） |
| `executeWithLock(lockKey, configKey, task)` | 使用特定配置执行任务 |

### 使用示例

```java
@Resource
private RedisDistributedLock redisDistributedLock;

// 默认配置（distributed.lock.retries, distributed.lock.sleep.max）
boolean success = redisDistributedLock.executeWithLock("lock:key", () -> {
    // 执行业务逻辑
});

// 使用特定配置（distributed.lock.maintenance.retries, distributed.lock.maintenance.sleep.max）
Optional<Result> result = redisDistributedLock.executeWithLock("lock:key", "maintenance", () -> {
    // 执行业务逻辑
    return new Result();
});
```

### 配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `distributed.lock.retries` | 6 | 最大重试次数 |
| `distributed.lock.sleep.max` | 9 | 最大睡眠秒数 |
| `distributed.lock.{configKey}.retries` | - | 特定配置的重试次数 |
| `distributed.lock.{configKey}.sleep.max` | - | 特定配置的最大睡眠秒数 |
