-- 任务调度模块数据库变更
-- 创建时间: 2026-04-02

-- ============================================================
-- hot_word_task 表新增下游任务ID字段
-- ============================================================
ALTER TABLE `hot_word_task` ADD COLUMN `downstream_task_id` VARCHAR(64) DEFAULT NULL COMMENT '下游任务ID' AFTER `model`;
ALTER TABLE `hot_word_task` ADD KEY `idx_downstream_task_id` (`downstream_task_id`);
