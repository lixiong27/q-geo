-- GEO 分析模块重构数据库变更脚本
-- 创建时间: 2026-04-12
-- 数据库: MySQL 5.7+

-- ============================================================
-- 一、GEO 分析模块
-- ============================================================

-- 1.1 GEO 分析模板表
CREATE TABLE `geo_analysis_template` (
    `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `name`                    VARCHAR(128)     NOT NULL DEFAULT '' COMMENT '模板名称',
    `cron_expression`         VARCHAR(64)      NOT NULL DEFAULT '' COMMENT 'Cron表达式（为空表示一次性任务）',
    `config`                  TEXT             DEFAULT NULL COMMENT '完整配置JSON（包含groups）',
    `status`                  TINYINT(1)       NOT NULL DEFAULT 1 COMMENT '状态：0-停用 1-启用',
    `template_execute_status` TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '模板执行状态：0-未执行 1-已执行',
    `next_execute_time`       DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下次执行时间',
    `last_execute_time`       DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上次执行时间',
    `created_by`              VARCHAR(64)      NOT NULL DEFAULT '' COMMENT '创建人',
    `create_time`             DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`             DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`),
    KEY `idx_template_execute_status` (`template_execute_status`),
    KEY `idx_next_execute_time` (`next_execute_time`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='GEO分析模板表';

-- 1.2 GEO 分析结果表
CREATE TABLE `geo_analysis_result` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `template_id`   BIGINT UNSIGNED  NOT NULL COMMENT '关联模板ID',
    `status`        TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '状态：0-待执行 1-执行中 2-完成 3-失败',
    `version`       INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    `params`        TEXT             NOT NULL COMMENT '关联任务信息JSON（batch任务ID+状态）',
    `result`        TEXT             NOT NULL COMMENT '最终分析结果JSON',
    `execute_time`  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '执行时间',
    `create_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_template_id` (`template_id`),
    KEY `idx_status` (`status`),
    KEY `idx_execute_time` (`execute_time`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='GEO分析结果表';

-- ============================================================
-- 二、config 字段结构说明
-- ============================================================

-- config 字段存储的 JSON 结构示例：
-- {
--   "groups": [
--     {
--       "type": "poiAnalysis",
--       "analysisTaskParam": {
--         "models": ["deepseek", "qianwen"],
--         "regions": ["beijing", "shanghai"]
--       },
--       "executors": [
--         { "code": "poiExecutor1", "params": {} },
--         { "code": "poiExecutor2", "params": {} }
--       ]
--     }
--   ]
-- }

-- ============================================================
-- 三、params 字段结构说明
-- ============================================================

-- params 字段默认为空字符串 ''，执行后存储的 JSON 结构示例：
-- {
--   "batchTasks": [
--     {
--       "batchTaskId": 123,
--       "type": "poiAnalysis",
--       "status": "completed",
--       "executorResults": [
--         { "code": "poiExecutor1", "status": "completed", "result": {} },
--         { "code": "poiExecutor2", "status": "completed", "result": {} }
--       ]
--     }
--   ]
-- }

-- ============================================================
-- 四、result 字段结构说明
-- ============================================================

-- result 字段默认为空字符串 ''，执行完成后存储的 JSON 结构示例：
-- {
--   "poiAnalysis": {
--     "stats": {
--       "totalTasks": 5,
--       "completedTasks": 4,
--       "failedTasks": 1,
--       "avgScore": 85.5
--     },
--     "executorResults": [
--       { "code": "poiExecutor1", "status": "completed", "data": {} },
--       { "code": "poiExecutor2", "status": "completed", "data": {} }
--     ]
--   }
-- }
