# 状态常量

## 任务状态（热词/内容）

适用于 `HotWordTask`, `ContentTask`

| 值 | 常量 | 含义 |
|----|------|------|
| 0 | `STATUS_PENDING` | 待处理 |
| 1 | `STATUS_RUNNING` | 执行中 |
| 2 | `STATUS_COMPLETED` | 已完成 |
| 3 | `STATUS_FAILED` | 失败 |

## 发布任务状态

适用于 `PublishTask`

| 值 | 常量 | 含义 |
|----|------|------|
| 0 | `STATUS_PENDING` | 待发布 |
| 1 | `STATUS_PUBLISHING` | 发布中 |
| 2 | `STATUS_PUBLISHED` | 已发布 |
| 3 | `STATUS_FAILED` | 发布失败 |

## 内容状态

适用于 `Content`

| 值 | 常量 | 含义 |
|----|------|------|
| 0 | `STATUS_DRAFT` | 草稿 |
| 1 | `STATUS_PENDING_REVIEW` | 待审核 |
| 2 | `STATUS_PUBLISHED` | 已发布 |

## 启用/禁用状态

适用于 `PublishChannel`, `GeoProvider`

| 值 | 常量 | 含义 |
|----|------|------|
| 0 | `STATUS_DISABLED` | 禁用 |
| 1 | `STATUS_ENABLED` | 启用 |

## 热词任务类型

适用于 `HotWordTask`

| 值 | 常量 | 用途 |
|----|------|------|
| `dig` | `TYPE_DIG` | 挖掘任务 |
| `expand` | `TYPE_EXPAND` | 扩展任务 |
| `analysis` | `TYPE_ANALYSIS` | 分析任务 |
| `subAnalysis` | `TYPE_SUB_ANALYSIS` | 子分析任务 |
| `batch_analysis` | `TYPE_BATCH_ANALYSIS` | 批量分析任务 |
