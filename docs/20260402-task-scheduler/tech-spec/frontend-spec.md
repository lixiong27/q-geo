# 任务调度模块 - 前端技术规格

## 1. API 层

### 1.1 hotWord.js 新增

```javascript
/**
 * 任务回调（内部接口，下游调用）
 */
export function taskCallback(data) {
  return request({
    url: '/api/hotWord/task/callback',
    method: 'post',
    data
  });
}
```

> 注：回调接口由下游服务调用，前端不直接使用。

---

## 2. 页面修改

前端无需修改，任务状态通过回调自动更新，前端只需轮询或刷新查看最新状态。

---

## 实现清单

| 序号 | 任务 | 文件 |
|------|------|------|
| 1 | API 新增 | hotWord.js |
