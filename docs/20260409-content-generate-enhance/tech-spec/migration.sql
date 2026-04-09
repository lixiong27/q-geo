-- 内容生成任务表新增字段
-- 执行时间：2026-04-09

-- 新增 template_code 字段（模板代码）
ALTER TABLE content_task ADD COLUMN template_code VARCHAR(64) COMMENT '模板代码' AFTER generate_method;

-- 新增 model 字段（模型/细分类型）
ALTER TABLE content_task ADD COLUMN model VARCHAR(64) COMMENT '模型/细分类型' AFTER template_code;

-- 新增 downstream_task_id 字段（下游任务ID）
ALTER TABLE content_task ADD COLUMN downstream_task_id VARCHAR(128) COMMENT '下游任务ID' AFTER result;

-- 添加索引
ALTER TABLE content_task ADD INDEX idx_downstream_task_id (downstream_task_id);
