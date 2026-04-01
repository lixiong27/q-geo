-- GEO 运营平台数据库建表语句
-- 创建时间: 2026-03-31
-- 数据库: MySQL 5.7+

-- ============================================================
-- 一、热词中心模块
-- ============================================================

-- 1.1 热词表
CREATE TABLE `hot_word` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `word`          VARCHAR(256)     NOT NULL DEFAULT '' COMMENT '热词内容',
    `source_type`   TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '来源类型：0-手动导入 1-热词挖掘',
    `source_task_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '来源任务ID（source_type=1时有效）',
    `tags`          TEXT             DEFAULT NULL COMMENT '标签（JSON数组格式）',
    `create_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_word` (`word`),
    KEY `idx_source_type` (`source_type`),
    KEY `idx_source_task_id` (`source_task_id`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='热词表';

-- 1.2 热词任务表
CREATE TABLE `hot_word_task` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `name`          VARCHAR(128)     NOT NULL DEFAULT '' COMMENT '任务名称',
    `type`          VARCHAR(32)      NOT NULL DEFAULT '' COMMENT '任务类型：dig-热词挖掘 expand-热词扩词',
    `params`        TEXT             DEFAULT NULL COMMENT '任务参数（JSON格式字符串）',
    `status`        TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '状态：0-待执行 1-执行中 2-已完成 3-失败',
    `result`        TEXT             DEFAULT NULL COMMENT '执行结果（JSON格式字符串）',
    `created_by`    VARCHAR(64)      NOT NULL DEFAULT '' COMMENT '创建人',
    `create_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `completed_at`  DATETIME         DEFAULT NULL COMMENT '完成时间',
    PRIMARY KEY (`id`),
    KEY `idx_type` (`type`),
    KEY `idx_status` (`status`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='热词任务表';

-- ============================================================
-- 二、内容中心模块
-- ============================================================

-- 2.1 内容表
CREATE TABLE `content` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `title`            VARCHAR(256)     NOT NULL DEFAULT '' COMMENT '标题',
    `body`             MEDIUMTEXT       DEFAULT NULL COMMENT '正文内容',
    `source_type`      TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '来源类型：0-手动创建 1-任务生成',
    `source_task_id`   BIGINT UNSIGNED  NOT NULL DEFAULT 0 COMMENT '来源任务ID（source_type=1时有效）',
    `generate_method`  VARCHAR(32)      DEFAULT NULL COMMENT '生成方式：llm-LLM生成 claw-Claw抓取（source_type=1时有效）',
    `attachments`      TEXT             DEFAULT NULL COMMENT '附件（JSON数组）',
    `word_count`       INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '字数',
    `status`           TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '状态：0-草稿 1-待审核 2-已发布',
    `created_by`       VARCHAR(64)      NOT NULL DEFAULT '' COMMENT '创建人',
    `create_time`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_title` (`title`),
    KEY `idx_source_type` (`source_type`),
    KEY `idx_source_task_id` (`source_task_id`),
    KEY `idx_status` (`status`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='内容表';

-- 2.2 内容生成任务表
CREATE TABLE `content_task` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `name`             VARCHAR(128)     NOT NULL DEFAULT '' COMMENT '任务名称',
    `generate_method`  VARCHAR(32)      NOT NULL DEFAULT '' COMMENT '生成方式：llm-LLM生成 claw-Claw抓取',
    `input_data`       TEXT             DEFAULT NULL COMMENT '输入数据（JSON格式，存标题列表）',
    `template_code`    VARCHAR(64)      DEFAULT NULL COMMENT '模板编码（对应配置文件中的模板）',
    `status`           TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '状态：0-待执行 1-执行中 2-已完成 3-失败',
    `result`           TEXT             DEFAULT NULL COMMENT '执行结果（JSON格式）',
    `created_by`       VARCHAR(64)      NOT NULL DEFAULT '' COMMENT '创建人',
    `create_time`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `completed_at`     DATETIME         DEFAULT NULL COMMENT '完成时间',
    PRIMARY KEY (`id`),
    KEY `idx_generate_method` (`generate_method`),
    KEY `idx_status` (`status`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='内容生成任务表';

-- ============================================================
-- 三、GEO分析模块
-- ============================================================

-- 3.1 大模型公司表
CREATE TABLE `geo_provider` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `name`             VARCHAR(64)      NOT NULL DEFAULT '' COMMENT '公司名称',
    `code`             VARCHAR(32)      NOT NULL DEFAULT '' COMMENT '编码',
    `sort_order`       INT              NOT NULL DEFAULT 0 COMMENT '排序',
    `status`           TINYINT(1)       NOT NULL DEFAULT 1 COMMENT '状态：0-停用 1-启用',
    `create_time`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='大模型公司表';

-- 3.2 GEO监控数据表
CREATE TABLE `geo_monitor_data` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `provider_id`         BIGINT UNSIGNED  NOT NULL COMMENT '大模型公司ID',
    `product_id`          BIGINT UNSIGNED  NOT NULL DEFAULT 0 COMMENT '分析产品ID',
    `date`                DATE             NOT NULL COMMENT '数据日期',
    `mention_rate`        DECIMAL(5,2)     NOT NULL DEFAULT 0.00 COMMENT '产品提及率(%)',
    `priority_score`      INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '产品优先度(0-100)',
    `priority_rank`       INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '优先度排名',
    `positive_sentiment`  DECIMAL(5,2)     NOT NULL DEFAULT 0.00 COMMENT '正面情感占比(%)',
    `recommend_score`     DECIMAL(3,1)     NOT NULL DEFAULT 0.0 COMMENT '推荐指数(0-10)',
    `high_freq_words`     TEXT             DEFAULT NULL COMMENT '高频关联词(JSON数组)',
    `negative_words`      TEXT             DEFAULT NULL COMMENT '负面关联词(JSON数组)',
    `create_time`         DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`         DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_provider_product_date` (`provider_id`, `product_id`, `date`),
    KEY `idx_provider_id` (`provider_id`),
    KEY `idx_product_id` (`product_id`),
    KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='GEO监控数据表';

-- ============================================================
-- 四、发布中心模块
-- ============================================================

-- 4.1 发布渠道表
CREATE TABLE `publish_channel` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `name`          VARCHAR(64)      NOT NULL DEFAULT '' COMMENT '渠道名称',
    `code`          VARCHAR(32)      NOT NULL DEFAULT '' COMMENT '渠道编码',
    `icon`          VARCHAR(64)      DEFAULT NULL COMMENT '图标（emoji或图片路径）',
    `config`        TEXT             DEFAULT NULL COMMENT '配置信息（JSON格式）',
    `status`        TINYINT(1)       NOT NULL DEFAULT 1 COMMENT '状态：0-禁用 1-启用',
    `is_builtin`    TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '是否内置：0-否 1-是',
    `create_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发布渠道表';

-- 4.2 发布任务表
CREATE TABLE `publish_task` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `content_id`    BIGINT UNSIGNED  NOT NULL COMMENT '关联内容ID',
    `channel_id`    BIGINT UNSIGNED  NOT NULL COMMENT '发布渠道ID',
    `status`        TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '状态：0-待发布 1-发布中 2-已发布 3-失败',
    `publish_url`   VARCHAR(512)     DEFAULT NULL COMMENT '发布后外链地址',
    `error_msg`     VARCHAR(256)     DEFAULT NULL COMMENT '错误信息',
    `created_by`    VARCHAR(64)      NOT NULL DEFAULT '' COMMENT '创建人',
    `create_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `completed_at`  DATETIME         DEFAULT NULL COMMENT '完成时间',
    PRIMARY KEY (`id`),
    KEY `idx_content_id` (`content_id`),
    KEY `idx_channel_id` (`channel_id`),
    KEY `idx_status` (`status`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发布任务表';

-- ============================================================
-- 五、数据中心模块
-- ============================================================
-- 数据中心不创建独立表，通过聚合查询各业务表实时计算

-- ============================================================
-- 六、初始化数据
-- ============================================================

-- 6.1 大模型公司初始数据
INSERT INTO `geo_provider` (`name`, `code`, `sort_order`, `status`) VALUES
('DeepSeek', 'deepseek', 1, 1),
('豆包', 'doubao', 2, 1),
('通义千问', 'qianwen', 3, 1),
('Kimi', 'kimi', 4, 1),
('文心一言', 'yiyan', 5, 1),
('智谱清言', 'zhipu', 6, 1);

-- 6.2 发布渠道初始数据
INSERT INTO `publish_channel` (`name`, `code`, `icon`, `status`, `is_builtin`) VALUES
('微博', 'weibo', '📱', 1, 1),
('知乎', 'zhihu', '📝', 1, 1),
('微信公众号', 'wechat', '💬', 1, 1),
('小红书', 'xiaohongshu', '📕', 1, 1),
('抖音', 'douyin', '🎵', 1, 1),
('B站', 'bilibili', '📺', 1, 1);
