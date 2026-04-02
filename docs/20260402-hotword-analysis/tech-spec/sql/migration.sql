-- 热词分析模块数据库变更
-- 创建时间: 2026-04-02

-- ============================================================
-- 1. hot_word 表新增 type 字段
-- ============================================================
ALTER TABLE `hot_word` ADD COLUMN `type` VARCHAR(64) DEFAULT NULL COMMENT '热词类型（从QConfig获取）' AFTER `tags`;
ALTER TABLE `hot_word` ADD KEY `idx_type` (`type`);

-- ============================================================
-- 2. hot_word_task 表新增 model 字段
-- ============================================================
ALTER TABLE `hot_word_task` ADD COLUMN `model` VARCHAR(32) NOT NULL DEFAULT 'default' COMMENT '模型标识：default/deepseek/qianwen/doubao等' AFTER `type`;
