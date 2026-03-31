# GEO分析

## 一、模块概述

GEO分析负责监控各大模型对产品的分析数据，通过定时任务每日采集并展示分析结果。

### 功能说明

- 展示各大模型（DeepSeek、豆包、通义千问等）对产品的分析指标
- 支持按产品、日期筛选查看
- 展示提及率、优先度、情感分析、关联词等核心指标
- 支持历史趋势对比

---

## 二、数据表设计

### 2.1 大模型公司表 (geo_provider)

```sql
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
```

**预置数据：**

| id | name | code | sort_order |
|----|------|------|------------|
| 1 | DeepSeek | deepseek | 1 |
| 2 | 豆包 | doubao | 2 |
| 3 | 通义千问 | qianwen | 3 |
| 4 | Kimi | kimi | 4 |
| 5 | 文心一言 | yiyan | 5 |
| 6 | 智谱清言 | zhipu | 6 |

---

### 2.2 监控数据表 (geo_monitor_data)

```sql
CREATE TABLE `geo_monitor_data` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `provider_id`         BIGINT UNSIGNED  NOT NULL COMMENT '大模型公司ID',
    `product_id`          BIGINT UNSIGNED  NOT NULL DEFAULT 0 COMMENT '分析产品ID',
    `date`                DATE             NOT NULL COMMENT '数据日期',

    -- 核心指标
    `mention_rate`        DECIMAL(5,2)     NOT NULL DEFAULT 0.00 COMMENT '产品提及率(%)',
    `priority_score`      INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '产品优先度(0-100)',
    `priority_rank`       INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '优先度排名',
    `positive_sentiment`  DECIMAL(5,2)     NOT NULL DEFAULT 0.00 COMMENT '正面情感占比(%)',
    `recommend_score`     DECIMAL(3,1)     NOT NULL DEFAULT 0.0 COMMENT '推荐指数(0-10)',

    -- 关联词
    `high_freq_words`     TEXT             DEFAULT NULL COMMENT '高频关联词(JSON数组)',
    `negative_words`      TEXT             DEFAULT NULL COMMENT '负面关联词(JSON数组)',

    -- 审计
    `create_time`         DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`         DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_provider_product_date` (`provider_id`, `product_id`, `date`),
    KEY `idx_provider_id` (`provider_id`),
    KEY `idx_product_id` (`product_id`),
    KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='GEO监控数据表';
```

**high_freq_words / negative_words 示例：**

```json
["性价比高", "功能齐全", "用户体验好", "响应速度快"]
```

---

## 三、数据流向

```
┌─────────────────────────────────────────────────────────────┐
│                    GEO分析数据流                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────┐      ┌──────────────────┐               │
│   │ QConfig      │      │ geo_provider     │               │
│   │ logo/desc    │      │ 公司基础信息      │               │
│   └──────┬───────┘      └────────┬─────────┘               │
│          │                       │                          │
│          ▼                       ▼                          │
│   ┌────────────────────────────────────┐                   │
│   │         定时任务执行                │                   │
│   │   (调用各模型API / Mock数据)       │                   │
│   └────────────────┬───────────────────┘                   │
│                    │                                        │
│                    ▼                                        │
│   ┌────────────────────────────────────┐                   │
│   │       geo_monitor_data             │                   │
│   │   提及率、优先度、情感、关联词      │                   │
│   └────────────────────────────────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**说明：**
- 定时任务每日执行，调用各模型API获取分析数据（MVP阶段可Mock）
- `trend` 和 `trendChange` 在接口层动态计算，对比前一天数据
- 公司的 logo、description、icon 等静态资源通过 QConfig 配置

---

## 四、QConfig 配置项

| Key | 说明 | 示例值 |
|-----|------|--------|
| `geo.provider.{code}.logo` | 公司Logo URL | `https://cdn.example.com/logo/deepseek.png` |
| `geo.provider.{code}.description` | 公司描述 | `深度求索 · 智能分析引擎` |
| `geo.provider.{code}.icon` | 图标emoji | `🤖` |

---

## 五、接口设计

### 5.1 获取GEO分析列表

**接口：** `GET /api/geoMonitor/list`

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| productId | Long | 否 | 产品ID，默认0表示全部 |
| date | String | 否 | 查询日期，格式yyyy-MM-dd，默认最新一天 |
| providerIds | String | 否 | 公司ID列表，逗号分隔，如: 1,2,3 |

**响应参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| date | String | 数据日期 |
| items | Array | 分析结果列表 |
| items[].providerId | Long | 公司ID |
| items[].providerCode | String | 公司编码 |
| items[].providerName | String | 公司名称 |
| items[].providerLogo | String | 公司Logo (from QConfig) |
| items[].providerDesc | String | 公司描述 |
| items[].mentionRate | Decimal | 产品提及率(%) |
| items[].priorityScore | Integer | 产品优先度(0-100) |
| items[].priorityRank | Integer | 优先度排名 |
| items[].positiveSentiment | Decimal | 正面情感占比(%) |
| items[].recommendScore | Decimal | 推荐指数(0-10) |
| items[].highFreqWords | Array | 高频关联词 |
| items[].negativeWords | Array | 负面关联词 |
| items[].trend | String | 趋势：up/down/stable |
| items[].trendChange | Decimal | 变化幅度(%) |
| items[].analyzeTime | String | 分析时间 |

**响应示例：**

```json
{
    "code": 0,
    "message": "success",
    "data": {
        "date": "2026-03-30",
        "items": [
            {
                "providerId": 1,
                "providerCode": "deepseek",
                "providerName": "DeepSeek",
                "providerLogo": "https://cdn.example.com/logo/deepseek.png",
                "providerDesc": "深度求索 · 智能分析引擎",
                "mentionRate": 78.50,
                "priorityScore": 92,
                "priorityRank": 2,
                "positiveSentiment": 85.00,
                "recommendScore": 7.8,
                "highFreqWords": ["性价比高", "功能齐全", "用户体验好", "响应速度快", "界面简洁"],
                "negativeWords": ["价格偏高", "学习成本"],
                "trend": "up",
                "trendChange": 5.20,
                "analyzeTime": "2026-03-30 14:30:00"
            },
            {
                "providerId": 2,
                "providerCode": "doubao",
                "providerName": "豆包",
                "providerLogo": "https://cdn.example.com/logo/doubao.png",
                "providerDesc": "字节跳动 · 智能助手",
                "mentionRate": 82.30,
                "priorityScore": 95,
                "priorityRank": 1,
                "positiveSentiment": 91.00,
                "recommendScore": 8.5,
                "highFreqWords": ["操作简单", "功能强大", "服务好", "更新及时", "文档完善"],
                "negativeWords": ["偶有卡顿"],
                "trend": "up",
                "trendChange": 8.10,
                "analyzeTime": "2026-03-30 14:25:00"
            },
            {
                "providerId": 3,
                "providerCode": "qianwen",
                "providerName": "通义千问",
                "providerLogo": "https://cdn.example.com/logo/qianwen.png",
                "providerDesc": "阿里云 · 智能问答",
                "mentionRate": 65.20,
                "priorityScore": 78,
                "priorityRank": 4,
                "positiveSentiment": 79.00,
                "recommendScore": 7.2,
                "highFreqWords": ["稳定可靠", "接口丰富", "社区活跃", "案例多"],
                "negativeWords": ["配置复杂", "文档分散", "版本更新慢"],
                "trend": "up",
                "trendChange": 2.30,
                "analyzeTime": "2026-03-30 14:20:00"
            }
        ]
    }
}
```
