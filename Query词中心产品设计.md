# Query词中心产品设计文档

## 一、模块划分

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                        Query词中心                                            │
├────────────────┬───────────────────┬────────────────┬─────────────────┬─────────────────────┤
│  Query词管理    │    任务管理       │    扩词任务     │    发布模块      │    Geo监控          │
│                │    (新增任务)     │                │                 │                     │
├────────────────┼───────────────────┼────────────────┼─────────────────┼─────────────────────┤
│ • 手动导入     │ • 任务大类选择    │ • 选择Query词  │ • 发布渠道管理   │ • DeepSeek监控      │
│ • 手动新增     │ • 任务方式选择    │ • 配置扩词数量 │ • 发布任务管理   │ • 通义千问监控      │
│ • 手动编辑/删除│ • LLM / ClawAgent │ • 执行扩词     │                 │ • 豆包监控          │
│ • Query词展示  │ • 批量/单独       │ • 查看结果     │                 │ • 其他大模型监控    │
│   (Tags云)     │ • 模板配置        │   Map<query,   │                 │ • 提及率/排名统计   │
│                │                   │    List<otaQ>> │                 │                     │
└────────────────┴───────────────────┴────────────────┴─────────────────┴─────────────────────┘
```

### 1.1 模块说明

| 模块 | 子模块 | 说明 |
|------|--------|------|
| Query词管理 | - | Query词的导入、新增、编辑、删除、展示 |
| 任务管理 | - | 新建任务（Query词生产/扩词），任务执行 |
| 扩词任务 | - | 扩词任务执行与结果查看 |
| 发布模块 | 发布渠道管理 | 管理各发布渠道的配置（微博、知乎、公众号等） |
| 发布模块 | 发布任务管理 | 创建、执行发布任务，追踪发布状态 |
| Geo监控 | - | 大模型公司（DeepSeek/通义千问/豆包等）的舆情监控与统计分析 |

---

## 二、数据模型

### 2.1 Query词 (QueryWord)

```typescript
interface QueryWord {
  id: string;
  query: string;                   // Query词（如：北京天安门）
  
  // 来源类型
  sourceType: 'manual' | 'task';
  taskType?: 'generate' | 'expand' | 'fetch';  // 任务类型（当sourceType为task时）
  taskId?: string;                 // 来源任务ID
  
  // 扩词相关
  expandCount?: number;            // 扩词数量（关联的问题数）
  
  createdAt: Date;
  status: 'active' | 'archived';
}
```

**来源类型说明：**
| sourceType | taskType | 说明 |
|------------|----------|------|
| manual | - | 手动导入/新增 |
| task | generate | 任务生成 |
| task | expand | 扩词任务 |
| task | fetch | 获取任务（拉取） |

### 2.2 任务大类 (TaskCategory)

```typescript
// 任务大类
interface TaskCategory {
  id: string;
  name: string;                   // 任务大类名称
  code: 'generate' | 'expand';     // 任务大类编码
  description: string;
  isBuiltIn: boolean;
}

// 预置任务大类
const TASK_CATEGORIES = [
  { id: 'cat_1', name: 'Query词生产', code: 'generate', description: '生成Query词' },
  { id: 'cat_2', name: 'Query扩词', code: 'expand', description: '将Query词扩写为问题' },
];
```

### 2.3 任务方式 (TaskMethod)

```typescript
// 任务方式
interface TaskMethod {
  id: string;
  name: string;                   // 方式名称（LLM / ClawAgent）
  code: 'llm' | 'clawagent';       // 方式编码
  type: string;                   // 具体类型标识
  config?: Record<string, any>;    // 方式配置
  isBuiltIn: boolean;
}

// 预置任务方式
const TASK_METHODS = [
  { id: 'method_1', name: 'LLM', code: 'llm', type: 'openai/gpt4', description: '使用LLM生成' },
  { id: 'method_2', name: 'ClawAgent', code: 'clawagent', type: 'claw/agent', description: '使用ClawAgent执行' },
];
```

### 2.4 任务 (Task)

```typescript
interface Task {
  id: string;
  name: string;                   // 任务名称
  
  // 任务配置
  categoryId: string;             // 任务大类ID
  category: TaskCategory;         // 任务大类
  methodId: string;               // 任务方式ID
  method: TaskMethod;            // 任务方式
  
  // 任务类型
  isBatch: boolean;              // 是否批量任务
  
  // 关联的Query词
  queryIds?: string[];            // 选中的Query词ID列表
  queries?: string[];              // 选中的Query词内容
  
  // 执行配置
  config: {
    count?: number;              // 扩词数量（扩词任务使用）
    prompt?: string;             // 自定义Prompt
    params?: Record<string, any>; // 其他参数
  };
  
  // 状态
  status: 'pending' | 'running' | 'completed' | 'failed';
  progress?: number;
  
  // 结果
  results?: {
    query: string;
    questions?: string[];
  }[];
  
  createdBy: string;
  createdAt: Date;
  completedAt?: Date;
}
```

### 2.5 扩词结果 (ExpandResult)

```typescript
// 扩词结果的数据结构：Map<query, List<otaQuestion>>
interface ExpandResult {
  id: string;
  query: string;                   // 原始Query词
  questions: string[];            // 扩词后的问题列表
  count: number;                  // 扩词数量
  createdAt: Date;
}
```

---

## 二-A、发布模块数据模型

### 2.6 发布渠道 (PublishChannel)

```typescript
interface PublishChannel {
  id: string;
  name: string;                   // 渠道名称（如：微博、知乎、公众号、小红书）
  code: string;                   // 渠道编码（如：weibo, zhihu, wechat, xiaohongshu）
  type: 'social' | 'blog' | 'official' | 'other';  // 渠道类型
  
  // 配置信息
  config: {
    appId?: string;               // 应用ID
    appSecret?: string;           // 应用密钥（加密存储）
    accountId?: string;           // 账号ID
    webhookUrl?: string;          // Webhook回调地址
  };
  
  // 状态
  status: 'active' | 'inactive';
  isBuiltIn: boolean;             // 是否内置（系统预置）
  
  createdAt: Date;
  updatedAt: Date;
}

// 预置发布渠道
const PUBLISH_CHANNELS = [
  { id: 'ch_1', name: '微博', code: 'weibo', type: 'social', isBuiltIn: true },
  { id: 'ch_2', name: '知乎', code: 'zhihu', type: 'blog', isBuiltIn: true },
  { id: 'ch_3', name: '微信公众号', code: 'wechat', type: 'official', isBuiltIn: true },
  { id: 'ch_4', name: '小红书', code: 'xiaohongshu', type: 'social', isBuiltIn: true },
  { id: 'ch_5', name: '抖音', code: 'douyin', type: 'social', isBuiltIn: true },
  { id: 'ch_6', name: 'B站', code: 'bilibili', type: 'social', isBuiltIn: true },
];
```

### 2.7 发布任务 (PublishTask)

```typescript
interface PublishTask {
  id: string;
  name: string;                   // 任务名称
  
  // 关联内容
  contentId: string;              // 发布内容ID
  contentType: 'query' | 'question' | 'custom';  // 内容类型
  
  // 目标渠道
  channelIds: string[];           // 选中的发布渠道ID列表
  channels?: PublishChannel[];
  
  // 发布配置
  config: {
    publishTime?: Date;           // 定时发布时间（可选）
    isDraft?: boolean;            // 是否存为草稿
    additionalParams?: Record<string, any>;  // 额外参数
  };
  
  // 状态
  status: 'pending' | 'publishing' | 'published' | 'failed';
  progress?: number;              // 发布进度（0-100）
  
  // 发布结果
  results?: {
    channelId: string;
    channelName: string;
    status: 'success' | 'failed';
    publishedAt?: Date;
    externalId?: string;          // 外部平台返回的ID
    error?: string;
  }[];
  
  createdBy: string;
  createdAt: Date;
  publishedAt?: Date;
}
```

### 2.8 发布内容 (PublishContent)

```typescript
interface PublishContent {
  id: string;
  title: string;                  // 标题
  body: string;                   // 正文内容
  
  // 内容来源
  sourceType: 'manual' | 'query-expand' | 'ai-generate';
  sourceId?: string;              // 来源ID（Query词ID/扩词结果ID）
  
  // 附件
  attachments?: {
    type: 'image' | 'video' | 'file';
    url: string;
    name?: string;
  }[];
  
  // 标签
  tags?: string[];
  
  // 状态
  status: 'draft' | 'published' | 'archived';
  
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## 二-B、Geo监控模块数据模型

### 2.9 大模型公司配置 (LLMProvider)

```typescript
interface LLMProvider {
  id: string;
  name: string;                   // 公司名称（如：DeepSeek、通义千问、豆包）
  code: string;                   // 编码（如：deepseek, qianwen, doubao）
  logo?: string;                  // Logo URL
  
  // 监控配置
  config: {
    keywords: string[];           // 监控关键词
    excludeKeywords?: string[];   // 排除关键词
    platforms?: string[];         // 监控平台（微博、知乎、新闻等）
  };
  
  // 状态
  status: 'active' | 'inactive';
  isBuiltIn: boolean;
  
  createdAt: Date;
  updatedAt: Date;
}

// 预置大模型公司
const LLM_PROVIDERS = [
  { id: 'llm_1', name: 'DeepSeek', code: 'deepseek', isBuiltIn: true },
  { id: 'llm_2', name: '通义千问', code: 'qianwen', isBuiltIn: true },
  { id: 'llm_3', name: '豆包', code: 'doubao', isBuiltIn: true },
  { id: 'llm_4', name: '文心一言', code: 'yiyan', isBuiltIn: true },
  { id: 'llm_5', name: 'Kimi', code: 'kimi', isBuiltIn: true },
  { id: 'llm_6', name: '智谱清言', code: 'zhipu', isBuiltIn: true },
];
```

### 2.10 监控数据 (GeoMonitorData)

```typescript
interface GeoMonitorData {
  id: string;
  providerId: string;             // 大模型公司ID
  provider?: LLMProvider;
  
  // 数据维度
  date: Date;                     // 数据日期
  platform?: string;              // 数据来源平台
  
  // 统计指标
  metrics: {
    mentionCount: number;         // 提及次数
    mentionRate?: number;         // 提及率（占比）
    sentiment?: {
      positive: number;           // 正面数量
      neutral: number;            // 中性数量
      negative: number;           // 负面数量
    };
    engagement?: {
      likes: number;              // 点赞数
      comments: number;           // 评论数
      shares: number;             // 转发/分享数
    };
    reach?: number;               // 触达人数
  };
  
  // 排名数据
  rank?: {
    overall?: number;             // 综合排名
    trend?: 'up' | 'down' | 'stable';  // 趋势
    rankChange?: number;          // 排名变化
  };
  
  createdAt: Date;
}
```

### 2.11 监控报告 (GeoReport)

```typescript
interface GeoReport {
  id: string;
  name: string;                   // 报告名称
  
  // 报告范围
  providerIds: string[];          // 涉及的大模型公司
  dateRange: {
    start: Date;
    end: Date;
  };
  
  // 报告内容
  summary: {
    totalMentions: number;        // 总提及量
    topProvider?: string;         // 提及量最高的公司
    topKeywords?: string[];       // 热议关键词
  };
  
  // 详细数据
  data: {
    providerId: string;
    mentionCount: number;
    mentionRate: number;
    rank: number;
    trend: 'up' | 'down' | 'stable';
  }[];
  
  createdBy: string;
  createdAt: Date;
}
```

---

### 2.6 任务模板 (TaskTemplate)

```typescript
// 获取任务 - 用于从各平台拉取Query词
interface FetchTemplate {
  id: string;
  name: string;                     // 模板名称
  description: string;
  
  // 模板类型
  type: 'prompt' | 'tool';
  
  // Prompt 配置
  prompt?: string;
  variables?: Variable[];
  
  // 工具配置
  toolId?: string;
  toolConfig?: Record<string, any>;
  
  // 输出配置
  outputConfig?: {
    targetTable: string;             // 写入目标表
    sourceMark: string;             // 来源标记
  };
  
  isBuiltIn: boolean;
  createdBy: 'system' | 'admin' | 'user';
}
```

---

### 2.3 获取任务 (FetchTask)

```typescript
interface FetchTask {
  id: string;
  name: string;
  templateId: string;
  template: FetchTemplate;
  
  // 执行配置
  schedule?: {
    type: 'cron' | 'interval' | 'manual';
    cron?: string;
    intervalMinutes?: number;
  };
  
  // 来源配置
  source: string;
  keywords?: string[];
  
  // 任务配置
  status: 'active' | 'inactive' | 'paused';
  createdBy: 'system' | 'admin' | 'user';
  createdAt: Date;
  lastRunAt?: Date;
  
  // 执行结果
  lastResult?: {
    count: number;
    success: boolean;
    error?: string;
  };
}
```

---

### 2.4 扩词任务 (ExpandTask)

```typescript
interface ExpandTask {
  id: string;
  name: string;
  
  // 关联的Query词
  queryIds: string[];
  queries: string[];
  
  // 扩词配置
  config: {
    countPerQuery: number;          // 每个Query词扩词数量
    style?: string;                 // 扩词风格
    additionalPrompt?: string;      // 附加指令
  };
  
  // 任务配置
  status: 'pending' | 'running' | 'completed' | 'failed';
  progress?: number;
  
  // 执行结果: Map<query, List<otaQuestion>>
  results?: {
    query: string;
    questions: string[];
  }[];
  
  createdBy: string;
  createdAt: Date;
  completedAt?: Date;
}
```

---

### 2.5 任务执行记录 (TaskExecution)

```typescript
interface TaskExecution {
  id: string;
  taskId: string;
  taskType: 'fetch' | 'expand';     // 任务类型
  status: 'pending' | 'running' | 'success' | 'failed';
  startAt: Date;
  endAt?: Date;
  result?: {
    queryCount?: number;            // 获取/扩词Query词数
    questionCount?: number;         // 扩词后的问题数
    results?: ExpandResult[];      // 扩词结果
  };
  error?: string;
}
```

---

## 三、页面设计

### 3.1 Query词管理（首页）

```
┌────────────────────────────────────────────────────────────────┐
│  [Query词管理] [任务管理] [扩词任务]              [+新增Query词]│
├────────────────────────────────────────────────────────────────┤
│  来源: [全部] 手动  任务生成  任务扩词              [+手动导入]│
├────────────────────────────────────────────────────────────────┤
│  Query词展示 (Tags云)                                          │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  [北京天安门] [GPT-5发布] [两会AI政策] [科技趋势]        │ │
│  │  [行业观察]   [技术突破]   [智能驾驶]   [大模型]        │ │
│  └──────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────┤
│  Query词列表                                                   │
│  ┌─────┬──────────────┬──────────┬──────────┬────────┬─────┐  │
│  │ ☐   │ Query词      │ 扩词数量 │ 来源     │ 时间   │操作  │  │
│  ├─────┼──────────────┼──────────┼──────────┼────────┼─────┤  │
│  │ ☐   │ 北京天安门   │ 5        │ 任务扩词 │ 14:30  │ ⋯   │  │
│  │ ☐   │ GPT-5发布    │ 3        │ 任务生成 │ 14:15  │ ⋯   │  │
│  │ ☐   │ 测试Query词 │ 0        │ 手动     │ 10:00  │ ⋯   │  │
│  └─────┴──────────────┴──────────┴──────────┴────────┴─────┘  │
│                                            已选 2 个 [新建任务]│
└────────────────────────────────────────────────────────────────┘
```

**交互说明：**
- **Query词展示**：Tags云展示，每个Tag显示扩词数量角标
- **来源筛选**：手动 / 任务生成 / 任务扩词
- **手动导入**：支持Excel/CSV上传、批量粘贴
- **扩词数量列**：显示该Query词已扩词的问题数量
- **批量操作**：勾选后可批量删除、导出、新建任务

---

### 3.2 任务管理（新增任务）

```
┌────────────────────────────────────────────────────────────────┐
│                        新建任务                                │
├────────────────────────────────────────────────────────────────┤
│  任务名称: [                                    ]              │
│                                                                │
│  任务大类:                                                    │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  ┌──────────────────┐  ┌──────────────────┐             │ │
│  │  │  Query词生产     │  │  Query扩词       │             │ │
│  │  │  生成Query词     │  │  扩写为问题      │             │ │
│  │  │  ○               │  │  ●              │             │ │
│  │  └──────────────────┘  └──────────────────┘             │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  任务方式:                                                    │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  ┌──────────────────┐  ┌──────────────────┐             │ │
│  │  │      LLM        │  │   ClawAgent      │             │ │
│  │  │  使用大模型生成  │  │  使用Agent执行   │             │ │
│  │  │  ●              │  │  ○               │             │ │
│  │  └──────────────────┘  └──────────────────┘             │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  选择Query词: (●) 批量选择  ( ) 手动输入                      │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ 已选 3 个Query词                                          │ │
│  │ [北京天安门] [GPT-5发布] [智能驾驶]            [清空/添加]│ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  任务类型:                                                    │
│  (●) 批量任务 (n个Query词 -> n个结果)                         │
│  ( ) 单独任务 (1个Query词 -> 1个结果)                         │
│                                                                │
│  扩词配置 (仅Query扩词任务):                                   │
│  扩词数量: [5] 个/每个Query词                                  │
│                                                                │
│                              [取消]            [开始执行]     │
└────────────────────────────────────────────────────────────────┘
```

**功能说明：**
- **任务大类**：Query词生产 / Query扩词（互斥选择）
- **任务方式**：LLM / ClawAgent（互斥选择，可扩展）
- **选择Query词**：从已有Query词库批量选择，或手动输入
- **任务类型**：
  - 批量任务：n个Query词 → n个结果
  - 单独任务：1个Query词 → 1个结果（仅生成任务）
- **扩词配置**：每个Query词扩词的数量

---

### 3.3 扩词任务

```
┌────────────────────────────────────────────────────────────────┐
│  [Query词管理] [任务管理] [扩词任务]                    [+新建任务]│
├────────────────────────────────────────────────────────────────┤
│  任务状态: [全部] [运行中] [已完成] [失败]                     │
├─────────────────────────────────┬──────────────────────────────┤
│  任务列表                        │  扩词结果预览                 │
│  ┌────────────────────────────┐ │  Map<query,                  │
│  │ 📝 热门景区扩词 3个  运行中│ │   List<otaQuestion>>         │
│  │ 📝 科技话题扩词 5个  已完成│ │                              │
│  │ 📝 AI产品测试   2个  失败  │ │ 北京天安门 (5)               │
│  │ 📝 批量生成任务 10个 已完成│ │  - 北京天安门门票在哪买      │
│  └────────────────────────────┘ │  - 北京天安门开放时间         │
│                                 │  - 北京天安门怎么预约         │
│                                 │                              │
│                                 │ GPT-5发布 (3)                │
│                                 │  - GPT-5什么时候发布         │
│                                 │  - GPT-5有哪些新功能         │
├─────────────────────────────────┴──────────────────────────────┤
│  新建扩词任务                                                  │
│  Step 1: 选择Query词 [已选3个] [清空]                          │
│  Step 2: 扩词数量 [5]  扩词风格 [通用问题]                      │
│                                    [取消] [开始扩词]           │
└────────────────────────────────────────────────────────────────┘
```

**功能说明：**
- **扩词任务**：将Query词扩展为多个相关问题
- **数据结构**：Map<query, List<otaQuestion>>
- **任务状态**：运行中/已完成/失败
- **结果预览**：查看每个Query词扩词后的问题列表
- **新建扩词**：选择Query词 → 配置扩词数量 → 开始扩词
│  └────────────┴────────────┴────────┴────────┴────────┴─────┘ │
├────────────────────────────────────────────────────────────────┤
│  执行记录                                    [查看详情]        │
│  · 科技热点 - 2024-03-27 10:00 - 成功 (获取12条)              │
│  · AI行业追踪 - 2024-03-27 09:00 - 成功 (获取8条)             │
│  · AI行业追踪 - 2024-03-26 09:00 - 失败 (网络超时)            │
└────────────────────────────────────────────────────────────────┘
```

---

### 3.4 新建任务（弹窗）

```
┌────────────────────────────────────────────────────────────────┐
│                        新建任务                                │
├────────────────────────────────────────────────────────────────┤
│  任务名称: [                                    ]              │
│                                                                │
│  任务类型: (●) 定时执行   ( ) 手动执行                         │
│                                                                │
│  选择模板:                                                     │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  内置模板                    │  自定义Prompt  │  调用工具 │ │
│  ├──────────────────────────────────────────────────────────┤ │
│  │ ○ 微博热搜抓取               │                │           │ │
│  │ ○ 知乎热榜拉取               │                │           │ │
│  │ ○ 百度风云榜                 │                │           │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  [ ○ 使用内置 prompt ]                                        │
│     内置prompt: [选择...] ▼                                    │
│                                                                │
│  [ ● 自定义 prompt ]                                          │
│     Prompt: [                                           ]     │
│              [                                           ]     │
│                                                                │
│  定时配置:                                                     │
│  频率: [每天 ▼]  时间: [09:00]                                │
│                                                                │
│  关键词过滤: [+添加] (可选)                                    │
│                                                                │
│                              [取消]            [保存]         │
└────────────────────────────────────────────────────────────────┘
```

---

### 3.5 发布渠道管理

```
┌────────────────────────────────────────────────────────────────┐
│  [Query词管理] [任务管理] [扩词任务] [发布渠道] [发布任务]    │
│                                              [Geo监控] [+新增渠道]│
├────────────────────────────────────────────────────────────────┤
│  渠道类型: [全部 ▼]    状态: [全部 ▼]    搜索: [🔍         ]│
├────────────────────────────────────────────────────────────────┤
│  渠道列表                                                       │
│  ┌─────┬──────────┬──────────┬───────────┬────────┬────────┐  │
│  │ ☐   │ 渠道名称  │ 渠道类型 │ 渠道编码   │ 状态   │ 操作   │  │
│  ├─────┼──────────┼──────────┼───────────┼────────┼────────┤  │
│  │ ☐   │ 微博      │ 社交媒体 │ weibo     │ 启用   │ ⋯     │  │
│  │ ☐   │ 知乎      │ 博客    │ zhihu     │ 启用   │ ⋯     │  │
│  │ ☐   │ 微信公众号 │ 官方号  │ wechat    │ 停用   │ ⋯     │  │
│  │ ☐   │ 小红书    │ 社交媒体 │ xiaohongshu│ 启用  │ ⋯     │  │
│  └─────┴──────────┴──────────┴───────────┴────────┴────────┘  │
│                                            已选 2 个 [批量启用] │
└────────────────────────────────────────────────────────────────┘
```

**功能说明：**
- **渠道类型筛选**：社交媒体、博客、官方号、其他
- **状态筛选**：全部、启用、停用
- **渠道配置**：点击渠道可配置AppID、AppSecret等认证信息
- **批量操作**：批量启用/停用/删除

---

### 3.6 新增/编辑渠道（弹窗）

```
┌────────────────────────────────────────────────────────────────│
│                     新增发布渠道                                │
├────────────────────────────────────────────────────────────────┤
│  渠道名称: [                    ]  渠道编码: [        ]       │
│                                                                │
│  渠道类型:                                                    │
│  (●) 社交媒体  ( ) 博客  ( ) 官方号  ( ) 其他                 │
│                                                                │
│  认证配置:                                                    │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ App ID:     [                                    ]        │ │
│  │ App Secret: [                                    ]  🔒    │ │
│  │ Account ID: [                                    ]        │ │
│  │ Webhook:    [                                    ]        │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  状态: (●) 启用  ( ) 停用                                     │
│                                                                │
│                              [取消]            [保存]         │
└────────────────────────────────────────────────────────────────┘
```

---

### 3.7 发布任务管理

```
┌────────────────────────────────────────────────────────────────┐
│  [Query词管理] [任务管理] [扩词任务] [发布渠道] [发布任务]    │
│                                              [Geo监控] [+新建发布任务]│
├────────────────────────────────────────────────────────────────┤
│  任务状态: [全部] [待发布] [发布中] [已发布] [失败]           │
├────────────────────────────────────────────────────────────────┤
│  发布任务列表                                                  │
│  ┌────────┬──────────────┬────────────┬──────────┬─────────┐  │
│  │ 任务名  │ 发布内容     │ 目标渠道   │ 状态     │ 操作   │  │
│  ├────────┼──────────────┼────────────┼──────────┼─────────┤  │
│  │ AI新品宣发│ DeepSeek新模型│ 微博,知乎  │ 已发布   │ 查看   │  │
│  │ 产品解读 │ 通义千问使用指南│ 公众号    │ 发布中 50%│ 查看   │  │
│  │ 热点追踪 │ Kimi新功能发布│ 微博      │ 待发布   │ 发布/删│  │
│  └────────┴──────────────┴────────────┴──────────┴─────────┘  │
├────────────────────────────────────────────────────────────────┤
│  执行记录                                                      │
│  · AI新品宣发 - 2024-03-27 14:00 - 成功 (微博、知乎)           │
│  · 产品解读 - 2024-03-27 13:30 - 进行中 (微信公众号)           │
└────────────────────────────────────────────────────────────────┘
```

---

### 3.8 新建发布任务（弹窗）

```
┌────────────────────────────────────────────────────────────────┐
│                      新建发布任务                               │
├────────────────────────────────────────────────────────────────┤
│  任务名称: [                                            ]       │
│                                                                │
│  选择发布内容:                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  [○] 从Query词选择    [ ] 从扩词结果选择   [ ] 自定义内容  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  选择内容: [北京天安门旅游攻略 ▼]  [预览]                       │
│                                                                │
│  选择发布渠道:                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ ☑ 微博      ☑ 知乎      ☐ 微信公众号  ☑ 小红书          │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  发布配置:                                                     │
│  发布时间: (●) 立即发布  ( ) 定时发布  [选择日期时间]          │
│                                                                │
│                              [取消]            [开始发布]     │
└────────────────────────────────────────────────────────────────┘
```

---

### 3.9 Geo监控大屏

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [Query词管理] [任务管理] [扩词任务] [发布渠道] [发布任务] [Geo监控]        │
├─────────────────────────────────────────────────────────────────────────────┤
│                        Geo大模型监控中心                    时间: 2024-03-27 │
├─────────────────────────────────────────────────────────────────────────────┤
│  大模型: [全部 ▼]  时间范围: [近7天 ▼]  平台: [全部 ▼]                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────────────┐  │
│  │ 总提及量        │ │ 今日新增        │ │ 正面占比        │ │ 活跃公司数   │  │
│  │ 128,450        │ │ +23.5%         │ │ 78.2%          │ │ 12           │  │
│  └────────────────┘ └────────────────┘ └────────────────┘ └──────────────┘  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐ ┌────────────────────────────────┐ │
│  │          提及量排名                   │ │         趋势变化                │ │
│  │  ┌───────────────────────────────┐  │ │  📈 DeepSeek     ↑ +15%       │ │
│  │  │ 1. DeepSeek     45,230       │  │ │  📈 通义千问     ↑ +8%        │ │
│  │  │ 2. 通义千问     32,105       │  │ │  📈 豆包         ↑ +5%        │ │
│  │  │ 3. 豆包         21,880       │  │ │  📉 文心一言     ↓ -3%        │ │
│  │  │ 4. Kimi         15,220       │  │ │  📉 智谱清言     ↓ -12%       │ │
│  │  │ 5. 文心一言     14,015       │  │ │                                │ │
│  │  └───────────────────────────────┘  │ │                                │ │
│  └─────────────────────────────────────┘ └────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────────────────┐ │
│  │                          各平台提及率对比                                │ │
│  │  DeepSeek    ████████████████████░░░░░░░░░░░░  35.2%                    │ │
│  │  通义千问    ██████████████░░░░░░░░░░░░░░░░  25.0%                    │ │
│  │  豆包        ██████████░░░░░░░░░░░░░░░░░░░░  17.0%                    │ │
│  │  Kimi        ███████░░░░░░░░░░░░░░░░░░░░░░░  11.8%                    │ │
│  │  文心一言    █████░░░░░░░░░░░░░░░░░░░░░░░░░   5.9%                    │ │
│  │  智谱清言    ███░░░░░░░░░░░░░░░░░░░░░░░░░░░   3.1%                    │ │
│  └──────────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  热搜关键词                                                      │
│  [DeepSeek-V2] [MoE架构] [开源大模型] [降价] [API调用] [多模态]          │
├─────────────────────────────────────────────────────────────────────────────┤
│  [导出报告]  [定时推送]  [查看详情 >>]                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

**功能说明：**
- **核心指标**：总提及量、今日新增、正面占比、活跃公司数
- **提及量排名**：按大模型公司统计提及量，支持时间范围筛选
- **趋势变化**：显示各公司提及量的环比变化（上升/下降）
- **提及率对比**：各公司在监控范围内的提及占比（百分比条形图）
- **热搜关键词**：当前热度最高的关联关键词标签
- **操作**：导出报告、定时推送、查看详情

---

### 3.10 Geo监控 - 公司详情

```
┌────────────────────────────────────────────────────────────────┐
│  [返回]  DeepSeek 监控详情                    时间: 2024-03-27 │
├────────────────────────────────────────────────────────────────┤
│  平台筛选: [全部 ▼]  时间: [近7天 ▼]                           │
├────────────────────────────────────────────────────────────────┤
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐       │
│  │ 总提及量        │ │ 今日新增        │ │ 正面情感        │       │
│  │ 45,230         │ │ +15.2%         │ │ 82.5%          │       │
│  └────────────────┘ └────────────────┘ └────────────────┘       │
├────────────────────────────────────────────────────────────────┤
│  情感分布                                                       │
│  👍 正面: 37,315 (82.5%)    ➡ 中性: 5,428 (12.0%)    👎 负面: 2,487 │
│                                                                │
│  平台分布                                                       │
│  微博: 18,092 (40%)   知乎: 9,046 (20%)   公众号: 6,785 (15%)  │
│  新闻: 4,523 (10%)    其他: 6,784 (15%)                        │
│                                                                │
│  热门内容                                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 🔹 DeepSeek-V2发布，性能超越GPT-4  微博  2024-03-27       │  │
│  │ 🔹 DeepSeek MoE架构解读  知乎  2024-03-26                 │  │
│  │ 🔹 开源大模型新选择  公众号  2024-03-25                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

---

## 四、接口设计

### 4.1 Query词相关接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/query-words` | GET | 获取Query词列表（支持筛选、分页） |
| `/api/query-words` | POST | 手动新增Query词 |
| `/api/query-words/import` | POST | 导入Query词（Excel/CSV） |
| `/api/query-words/:id` | GET | 获取Query词详情 |
| `/api/query-words/:id` | PUT | 编辑Query词 |
| `/api/query-words/:id` | DELETE | 删除Query词 |
| `/api/query-words/batch` | DELETE | 批量删除Query词 |

### 4.2 获取任务接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/fetch-templates` | GET | 获取获取任务模板 |
| `/api/fetch-tasks` | GET | 获取获取任务列表 |
| `/api/fetch-tasks` | POST | 创建获取任务 |
| `/api/fetch-tasks/:id/run` | POST | 手动执行获取任务 |
| `/api/fetch-tasks/:id/toggle` | POST | 启用/停用任务 |

### 4.3 扩词任务接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/expand-tasks` | GET | 获取扩词任务列表 |
| `/api/expand-tasks` | POST | 创建扩词任务 |
| `/api/expand-tasks/:id` | GET | 获取扩词任务详情（含结果） |
| `/api/expand-tasks/:id/cancel` | POST | 取消扩词任务 |
| `/api/expand-tasks/:id/retry` | POST | 重试失败任务 |

### 4.4 执行记录接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/task-executions` | GET | 获取执行记录列表 |
| `/api/task-executions/:id` | GET | 获取执行详情 |

### 4.5 发布渠道接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/publish-channels` | GET | 获取发布渠道列表（支持筛选、分页） |
| `/api/publish-channels` | POST | 新增发布渠道 |
| `/api/publish-channels/:id` | GET | 获取渠道详情 |
| `/api/publish-channels/:id` | PUT | 编辑渠道配置 |
| `/api/publish-channels/:id` | DELETE | 删除渠道 |
| `/api/publish-channels/:id/toggle` | POST | 启用/停用渠道 |
| `/api/publish-channels/batch` | POST | 批量启用/停用 |

### 4.6 发布任务接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/publish-tasks` | GET | 获取发布任务列表（支持筛选、分页） |
| `/api/publish-tasks` | POST | 创建发布任务 |
| `/api/publish-tasks/:id` | GET | 获取任务详情（含发布结果） |
| `/api/publish-tasks/:id` | DELETE | 删除发布任务 |
| `/api/publish-tasks/:id/publish` | POST | 执行发布 |
| `/api/publish-tasks/:id/cancel` | POST | 取消发布 |
| `/api/publish-tasks/:id/retry` | POST | 重试失败发布 |

### 4.7 发布内容接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/publish-contents` | GET | 获取发布内容列表 |
| `/api/publish-contents` | POST | 创建发布内容 |
| `/api/publish-contents/:id` | GET | 获取内容详情 |
| `/api/publish-contents/:id` | PUT | 编辑内容 |
| `/api/publish-contents/:id` | DELETE | 删除内容 |

### 4.8 Geo监控接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/llm-providers` | GET | 获取大模型公司列表 |
| `/api/llm-providers` | POST | 新增大模型公司 |
| `/api/llm-providers/:id` | GET | 获取公司详情 |
| `/api/llm-providers/:id` | PUT | 编辑公司配置 |
| `/api/llm-providers/:id` | DELETE | 删除公司 |
| `/api/geo-monitor/summary` | GET | 获取监控汇总数据 |
| `/api/geo-monitor/rankings` | GET | 获取排名数据 |
| `/api/geo-monitor/trends` | GET | 获取趋势数据 |
| `/api/geo-monitor/providers/:id` | GET | 获取指定公司详情数据 |
| `/api/geo-monitor/reports` | GET | 获取监控报告列表 |
| `/api/geo-monitor/reports` | POST | 生成监控报告 |
| `/api/geo-monitor/reports/:id` | GET | 获取报告详情 |

---

## 五、核心交互说明

| 场景 | 处理方式 |
|------|----------|
| **手动导入** | 来源标记为 `manual` |
| **获取任务** | 从各平台拉取Query词，定时/手动触发 |
| **扩词任务** | 将Query词扩展为List<otaQuestion>，数据结构：Map<query, List<otaQuestion>> |
| **扩词结果** | 每个Query词可扩多个问题，显示在Query词列表的"扩词数量"列 |
| **模板扩展** | 支持Prompt模板和工具任务两种类型 |

---

## 六、待扩展功能

- [ ] 模板管理中心（统一模板维护）
- [ ] Query词分类管理
- [ ] 扩词趋势分析
- [ ] 任务执行监控大屏
- [ ] 任务失败自动重试策略