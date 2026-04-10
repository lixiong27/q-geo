# 数据库表结构

## 热词模块

### hot_word_task

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| name | VARCHAR | 任务名称 |
| type | VARCHAR | 任务类型（dig/expand/analysis/subAnalysis/batch_analysis） |
| model | VARCHAR | 模型标识 |
| downstream_task_id | VARCHAR | 下游任务ID |
| params | TEXT | 任务参数（JSON） |
| status | INT | 状态（0-4） |
| result | TEXT | 执行结果（JSON） |
| created_by | VARCHAR | 创建人 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |
| completed_at | DATETIME | 完成时间 |

## 内容模块

### content_task

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| name | VARCHAR | 任务名称 |
| generate_method | VARCHAR | 生成方式 |
| template_code | VARCHAR | 模板编码 |
| input_data | TEXT | 输入数据（JSON） |
| status | INT | 状态（0-3） |
| result | TEXT | 执行结果（JSON） |
| downstream_task_id | VARCHAR | 下游任务ID |
| created_by | VARCHAR | 创建人 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |
| completed_at | DATETIME | 完成时间 |

## 发布模块

### publish_task

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| content_id | BIGINT | 内容ID |
| channel_id | BIGINT | 渠道ID |
| channel_code | VARCHAR | 渠道编码 |
| publish_method | VARCHAR | 发布方式 |
| status | INT | 状态（0-3） |
| publish_url | VARCHAR | 发布链接 |
| error_msg | TEXT | 错误信息 |
| downstream_task_id | VARCHAR | 下游任务ID |
| created_by | VARCHAR | 创建人 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |
| completed_at | DATETIME | 完成时间 |
