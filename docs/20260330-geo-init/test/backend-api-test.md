# 后端接口测试用例

## 测试概述

本文档包含 GEO 运营平台所有后端接口的测试用例，按模块划分。

**测试环境要求：**
- 后端服务启动正常
- 数据库连接正常
- 测试数据已初始化

**通用响应格式：**
```json
{
    "code": 0,
    "message": "success",
    "data": {}
}
```

**分页响应格式：**
```json
{
    "code": 0,
    "message": "success",
    "data": {
        "list": [],
        "total": 100,
        "pageNum": 1,
        "pageSize": 10
    }
}
```

---

## 一、热词中心模块

### 1.1 热词管理接口

#### 1.1.1 查询热词列表

**接口：** `GET /api/hotWord/list`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| keyword | String | 否 | 关键词搜索 |
| source | String | 否 | 来源：MANUAL/IMPORT/MINING/EXPANSION |
| status | String | 否 | 状态：ACTIVE/INACTIVE |
| pageNum | Integer | 否 | 页码，默认 1 |
| pageSize | Integer | 否 | 每页条数，默认 10 |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HW-001 | 查询全部热词 | 无参数 | 返回所有热词列表，包含分页信息 |
| HW-002 | 按关键词搜索 | keyword="机票" | 返回包含"机票"的热词列表 |
| HW-003 | 按来源筛选 | source="MANUAL" | 返回手动添加的热词列表 |
| HW-004 | 按状态筛选 | status="ACTIVE" | 返回有效状态的热词列表 |
| HW-005 | 分页查询 | pageNum=2, pageSize=5 | 返回第2页，每页5条数据 |
| HW-006 | 组合条件查询 | keyword="机票", source="MANUAL", status="ACTIVE" | 返回符合所有条件的热词列表 |
| HW-007 | 空结果查询 | keyword="不存在的关键词xyz" | 返回空列表，total=0 |

**响应示例：**
```json
{
    "code": 0,
    "message": "success",
    "data": {
        "list": [
            {
                "id": 1,
                "keyword": "特价机票",
                "source": "MANUAL",
                "status": "ACTIVE",
                "createTime": "2026-03-30 10:00:00",
                "updateTime": "2026-03-30 10:00:00"
            }
        ],
        "total": 1,
        "pageNum": 1,
        "pageSize": 10
    }
}
```

#### 1.1.2 新增热词

**接口：** `POST /api/hotWord/add`

**请求参数：**
```json
{
    "keyword": "特价机票",
    "source": "MANUAL"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HW-008 | 正常新增 | keyword="新热词", source="MANUAL" | code=0, 返回新增记录ID |
| HW-009 | 重复新增 | keyword="已存在的热词" | code=非0, 提示重复 |
| HW-010 | 空关键词 | keyword="" | code=非0, 参数校验失败 |
| HW-011 | 空来源 | keyword="测试", source="" | code=非0, 参数校验失败 |

#### 1.1.3 批量导入热词

**接口：** `POST /api/hotWord/import`

**请求参数：**
```json
{
    "keywords": ["热词1", "热词2", "热词3"]
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HW-012 | 正常批量导入 | keywords=["词1", "词2", "词3"] | code=0, 返回成功导入数量 |
| HW-013 | 空数组导入 | keywords=[] | code=非0, 参数校验失败 |
| HW-014 | 部分重复导入 | keywords=["新词", "已存在词"] | code=0, 返回成功数量，跳过重复项 |

#### 1.1.4 更新热词

**接口：** `POST /api/hotWord/update`

**请求参数：**
```json
{
    "id": 1,
    "keyword": "更新后的热词",
    "status": "INACTIVE"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HW-015 | 正常更新 | id=1, keyword="新关键词" | code=0, 更新成功 |
| HW-016 | 更新状态 | id=1, status="INACTIVE" | code=0, 状态更新成功 |
| HW-017 | 不存在的ID | id=99999, keyword="测试" | code=非0, 记录不存在 |
| HW-018 | 空ID | id=null | code=非0, 参数校验失败 |

#### 1.1.5 删除热词

**接口：** `POST /api/hotWord/delete`

**请求参数：**
```json
{
    "id": 1
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HW-019 | 正常删除 | id=1 | code=0, 删除成功 |
| HW-020 | 删除不存在的记录 | id=99999 | code=非0, 记录不存在 |
| HW-021 | 空ID | id=null | code=非0, 参数校验失败 |

### 1.2 热词任务接口

#### 1.2.1 查询任务列表

**接口：** `GET /api/hotWordTask/list`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| taskType | String | 否 | 任务类型：MINING/EXPANSION |
| status | String | 否 | 状态：PENDING/RUNNING/COMPLETED/FAILED/CANCELLED |
| pageNum | Integer | 否 | 页码 |
| pageSize | Integer | 否 | 每页条数 |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HT-001 | 查询全部任务 | 无参数 | 返回所有任务列表 |
| HT-002 | 按类型筛选 | taskType="MINING" | 返回挖掘任务列表 |
| HT-003 | 按状态筛选 | status="COMPLETED" | 返回已完成任务列表 |

#### 1.2.2 创建任务

**接口：** `POST /api/hotWordTask/add`

**请求参数（挖掘任务）：**
```json
{
    "taskType": "MINING",
    "productId": 1,
    "keywords": ["机票", "酒店"]
}
```

**请求参数（扩词任务）：**
```json
{
    "taskType": "EXPANSION",
    "seedKeyword": "特价机票"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HT-004 | 创建挖掘任务 | taskType="MINING", productId=1, keywords=["机票"] | code=0, 返回任务ID |
| HT-005 | 创建扩词任务 | taskType="EXPANSION", seedKeyword="机票" | code=0, 返回任务ID |
| HT-006 | 空关键词列表 | taskType="MINING", keywords=[] | code=非0, 参数校验失败 |
| HT-007 | 空种子词 | taskType="EXPANSION", seedKeyword="" | code=非0, 参数校验失败 |

#### 1.2.3 任务详情

**接口：** `GET /api/hotWordTask/detail`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 任务ID |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HT-008 | 正常查询 | id=1 | 返回任务详情，包含结果列表 |
| HT-009 | 不存在的任务 | id=99999 | code=非0, 任务不存在 |

#### 1.2.4 取消任务

**接口：** `POST /api/hotWordTask/cancel`

**请求参数：**
```json
{
    "id": 1
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HT-010 | 取消进行中任务 | id=1 (状态为RUNNING) | code=0, 状态变为CANCELLED |
| HT-011 | 取消已完成任务 | id=2 (状态为COMPLETED) | code=非0, 无法取消已完成任务 |

#### 1.2.5 重试任务

**接口：** `POST /api/hotWordTask/retry`

**请求参数：**
```json
{
    "id": 1
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| HT-012 | 重试失败任务 | id=1 (状态为FAILED) | code=0, 重新执行 |
| HT-013 | 重试成功任务 | id=2 (状态为COMPLETED) | code=非0, 无需重试 |

---

## 二、内容中心模块

### 2.1 内容管理接口

#### 2.1.1 查询内容列表

**接口：** `GET /api/content/list`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| keyword | String | 否 | 标题关键词 |
| contentType | String | 否 | 类型：ARTICLE/FAQ/PRODUCT_DESC |
| status | String | 否 | 状态：DRAFT/PUBLISHED/ARCHIVED |
| pageNum | Integer | 否 | 页码 |
| pageSize | Integer | 否 | 每页条数 |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CT-001 | 查询全部内容 | 无参数 | 返回所有内容列表 |
| CT-002 | 按关键词搜索 | keyword="机票" | 返回标题包含"机票"的内容 |
| CT-003 | 按类型筛选 | contentType="ARTICLE" | 返回文章类型内容 |
| CT-004 | 按状态筛选 | status="PUBLISHED" | 返回已发布内容 |

#### 2.1.2 新增内容

**接口：** `POST /api/content/add`

**请求参数：**
```json
{
    "title": "特价机票购买指南",
    "contentType": "ARTICLE",
    "content": "内容正文...",
    "keywords": ["机票", "特价"],
    "summary": "摘要内容"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CT-005 | 正常新增 | title="测试标题", contentType="ARTICLE", content="内容" | code=0, 返回内容ID |
| CT-006 | 空标题 | title="" | code=非0, 参数校验失败 |
| CT-007 | 空内容 | title="测试", content="" | code=非0, 参数校验失败 |

#### 2.1.3 内容详情

**接口：** `GET /api/content/detail`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 内容ID |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CT-008 | 正常查询 | id=1 | 返回内容详情 |
| CT-009 | 不存在的内容 | id=99999 | code=非0, 内容不存在 |

#### 2.1.4 更新内容

**接口：** `POST /api/content/update`

**请求参数：**
```json
{
    "id": 1,
    "title": "更新后的标题",
    "content": "更新后的内容",
    "status": "PUBLISHED"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CT-010 | 正常更新 | id=1, title="新标题" | code=0, 更新成功 |
| CT-011 | 发布内容 | id=1, status="PUBLISHED" | code=0, 状态更新成功 |

#### 2.1.5 删除内容

**接口：** `POST /api/content/delete`

**请求参数：**
```json
{
    "id": 1
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CT-012 | 正常删除 | id=1 | code=0, 删除成功 |
| CT-013 | 删除不存在内容 | id=99999 | code=非0, 内容不存在 |

### 2.2 内容任务接口

#### 2.2.1 查询任务列表

**接口：** `GET /api/contentTask/list`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| status | String | 否 | 状态：PENDING/RUNNING/COMPLETED/FAILED/CANCELLED |
| pageNum | Integer | 否 | 页码 |
| pageSize | Integer | 否 | 每页条数 |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CTT-001 | 查询全部任务 | 无参数 | 返回所有内容生成任务 |
| CTT-002 | 按状态筛选 | status="COMPLETED" | 返回已完成任务 |

#### 2.2.2 创建内容生成任务

**接口：** `POST /api/contentTask/add`

**请求参数：**
```json
{
    "title": "生成机票攻略",
    "contentType": "ARTICLE",
    "keywords": ["机票", "攻略"],
    "productId": 1
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CTT-003 | 正常创建 | title="测试", contentType="ARTICLE", keywords=["测试"] | code=0, 返回任务ID |
| CTT-004 | 空关键词 | title="测试", keywords=[] | code=非0, 参数校验失败 |

#### 2.2.3 任务详情

**接口：** `GET /api/contentTask/detail`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 任务ID |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CTT-005 | 正常查询 | id=1 | 返回任务详情和生成结果 |
| CTT-006 | 不存在的任务 | id=99999 | code=非0, 任务不存在 |

#### 2.2.4 取消/重试任务

**接口：** `POST /api/contentTask/cancel` / `POST /api/contentTask/retry`

**测试用例：**

| 用例编号 | 用例名称 | 接口 | 预期结果 |
|----------|----------|------|----------|
| CTT-007 | 取消进行中任务 | cancel | code=0, 状态变为CANCELLED |
| CTT-008 | 重试失败任务 | retry | code=0, 重新执行 |

---

## 三、GEO 分析模块

### 3.1 监控数据接口

#### 3.1.1 查询监控数据列表

**接口：** `GET /api/geoMonitor/list`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| productId | Long | 是 | 产品ID |
| providerCode | String | 否 | AI平台编码 |
| startDate | String | 否 | 开始日期 yyyy-MM-dd |
| endDate | String | 否 | 结束日期 yyyy-MM-dd |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| GEO-001 | 查询产品监控数据 | productId=1 | 返回该产品的所有AI平台监控数据 |
| GEO-002 | 按平台筛选 | productId=1, providerCode="chatgpt" | 返回指定平台数据 |
| GEO-003 | 按日期范围 | productId=1, startDate="2026-03-01", endDate="2026-03-31" | 返回日期范围内数据 |
| GEO-004 | 空产品ID | productId=null | code=非0, 参数校验失败 |

**响应示例：**
```json
{
    "code": 0,
    "message": "success",
    "data": {
        "list": [
            {
                "id": 1,
                "productId": 1,
                "providerCode": "chatgpt",
                "providerName": "ChatGPT",
                "mentionRate": 0.85,
                "priorityScore": 92,
                "priorityRank": 1,
                "positiveSentiment": 0.78,
                "recommendScore": 0.82,
                "highFreqWords": "机票,特价,优惠",
                "monitorDate": "2026-03-30"
            }
        ],
        "date": "2026-03-30"
    }
}
```

### 3.2 AI平台配置接口

#### 3.2.1 查询平台列表

**接口：** `GET /api/geoProvider/list`

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| GEO-005 | 查询全部平台 | 无参数 | 返回所有AI平台配置列表 |

---

## 四、发布中心模块

### 4.1 发布任务接口

#### 4.1.1 创建发布任务

**接口：** `POST /api/publishTask/add`

**请求参数：**
```json
{
    "contentId": 1,
    "channelId": 1,
    "scheduledTime": "2026-03-31 10:00:00"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| PUB-001 | 正常创建 | contentId=1, channelId=1 | code=0, 返回任务ID |
| PUB-002 | 指定发布时间 | contentId=1, channelId=1, scheduledTime="2026-04-01 10:00:00" | code=0, 创建定时发布任务 |
| PUB-003 | 空内容ID | contentId=null | code=非0, 参数校验失败 |
| PUB-004 | 空渠道ID | channelId=null | code=非0, 参数校验失败 |

#### 4.1.2 任务详情

**接口：** `GET /api/publishTask/detail`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 任务ID |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| PUB-005 | 正常查询 | id=1 | 返回任务详情 |
| PUB-006 | 不存在的任务 | id=99999 | code=非0, 任务不存在 |

#### 4.1.3 重试发布

**接口：** `POST /api/publishTask/retry`

**请求参数：**
```json
{
    "id": 1
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| PUB-007 | 重试失败任务 | id=1 (状态为FAILED) | code=0, 重新发布 |
| PUB-008 | 重试成功任务 | id=2 (状态为SUCCESS) | code=非0, 无需重试 |

### 4.2 发布渠道接口

#### 4.2.1 查询渠道列表

**接口：** `GET /api/publishChannel/list`

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CH-001 | 查询全部渠道 | 无参数 | 返回所有发布渠道 |

#### 4.2.2 渠道详情

**接口：** `GET /api/publishChannel/detail`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 渠道ID |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CH-002 | 正常查询 | id=1 | 返回渠道配置详情 |

#### 4.2.3 更新渠道

**接口：** `POST /api/publishChannel/update`

**请求参数：**
```json
{
    "id": 1,
    "channelName": "微信公众号",
    "channelConfig": "{\"appId\":\"xxx\",\"appSecret\":\"xxx\"}"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CH-003 | 正常更新 | id=1, channelName="新名称" | code=0, 更新成功 |

#### 4.2.4 启用/禁用渠道

**接口：** `POST /api/publishChannel/toggleStatus`

**请求参数：**
```json
{
    "id": 1,
    "status": "ACTIVE"
}
```

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| CH-004 | 启用渠道 | id=1, status="ACTIVE" | code=0, 渠道启用 |
| CH-005 | 禁用渠道 | id=1, status="INACTIVE" | code=0, 渠道禁用 |

---

## 五、数据中心模块

### 5.1 聚合数据查询

**接口：** `GET /api/dataCenter/all`

**请求参数：**
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| timeRange | String | 否 | 时间范围：7d/30d/90d |
| trendDays | Integer | 否 | 趋势天数，默认7天 |

**测试用例：**

| 用例编号 | 用例名称 | 请求参数 | 预期结果 |
|----------|----------|----------|----------|
| DC-001 | 查询默认数据 | 无参数 | 返回近7天汇总数据 |
| DC-002 | 查询30天数据 | timeRange="30d" | 返回近30天汇总数据 |
| DC-003 | 自定义趋势天数 | trendDays=14 | 返回14天趋势数据 |

**响应示例：**
```json
{
    "code": 0,
    "message": "success",
    "data": {
        "overview": {
            "totalHotWords": 150,
            "totalContents": 80,
            "totalPublishTasks": 45,
            "publishedTasks": 38,
            "pendingReview": 5,
            "failed": 2
        },
        "hotWordSourceDistribution": [
            {"name": "手动添加", "value": 50, "color": "#3b82f6"},
            {"name": "批量导入", "value": 30, "color": "#10b981"},
            {"name": "热词挖掘", "value": 40, "color": "#f59e0b"},
            {"name": "智能扩词", "value": 30, "color": "#8b5cf6"}
        ],
        "publishChannelDistribution": [
            {"name": "微信公众号", "value": 20, "color": "#07c160"},
            {"name": "小红书", "value": 15, "color": "#fe2c55"},
            {"name": "知乎", "value": 8, "color": "#0066ff"}
        ],
        "dailyTrend": {
            "dates": ["2026-03-24", "2026-03-25", "2026-03-26", "2026-03-27", "2026-03-28", "2026-03-29", "2026-03-30"],
            "hotWordCounts": [5, 8, 3, 6, 4, 7, 5],
            "contentCounts": [3, 5, 4, 2, 6, 3, 4],
            "publishCounts": [2, 3, 1, 4, 2, 3, 2]
        }
    }
}
```

---

## 六、异常场景测试

### 6.1 参数校验异常

| 用例编号 | 场景 | 预期响应 |
|----------|------|----------|
| ERR-001 | 必填参数为空 | code=400, message="参数不能为空" |
| ERR-002 | 参数类型错误 | code=400, message="参数类型错误" |
| ERR-003 | 参数格式错误 | code=400, message="参数格式不正确" |

### 6.2 业务异常

| 用例编号 | 场景 | 预期响应 |
|----------|------|----------|
| ERR-004 | 记录不存在 | code=404, message="记录不存在" |
| ERR-005 | 状态不允许操作 | code=400, message="当前状态不允许此操作" |
| ERR-006 | 数据重复 | code=400, message="数据已存在" |

### 6.3 系统异常

| 用例编号 | 场景 | 预期响应 |
|----------|------|----------|
| ERR-007 | 数据库连接失败 | code=500, message="系统异常" |
| ERR-008 | 外部服务超时 | code=503, message="服务暂不可用" |

---

## 七、测试执行记录

| 执行日期 | 执行人 | 通过数 | 失败数 | 备注 |
|----------|--------|--------|--------|------|
| - | - | - | - | - |

---

## 八、测试数据准备

### 初始化数据脚本

```sql
-- 热词测试数据
INSERT INTO hot_word (keyword, source, status, create_time) VALUES
('特价机票', 'MANUAL', 'ACTIVE', NOW()),
('酒店预订', 'IMPORT', 'ACTIVE', NOW()),
('旅游攻略', 'MINING', 'ACTIVE', NOW());

-- 内容测试数据
INSERT INTO content (title, content_type, content, status, create_time) VALUES
('机票购买攻略', 'ARTICLE', '内容...', 'PUBLISHED', NOW()),
('酒店选择指南', 'ARTICLE', '内容...', 'DRAFT', NOW());

-- 发布渠道测试数据
INSERT INTO publish_channel (channel_name, channel_type, status, create_time) VALUES
('微信公众号', 'WECHAT', 'ACTIVE', NOW()),
('小红书', 'XIAOHONGSHU', 'ACTIVE', NOW());
```
