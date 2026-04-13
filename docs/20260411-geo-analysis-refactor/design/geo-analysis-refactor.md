# GEO 分析模块重构设计

## 概述

重构 GEO 分析模块，整体采用任务模型，分为两个模块：
1. **任务创建模块** - 支持周期性/一次性创建分析任务
2. **结果模块** - 分析结果聚合与报表生成

## 核心参数

| 参数 | 说明 |
|------|------|
| 周期性参数 | Cron 表达式，支持用户自定义周期 |
| 热词模块 | 按 type 查询该类型下所有热词 |
| 分析任务参数 | models（模型列表）、regions（地域列表，待扩展） |
| Executor 配置 | QConfig 配置 code→beanName 映射，前端选择 code，后端通过 Map<String, Executor> 获取 |

## 业务流程

```
geo_analysis_template 触发（QSchedule 轮询 next_execute_time）
    ↓
创建 geo_analysis_result (status=PENDING)
    ↓
遍历 groups，每个 group 创建：
    hot_word_task (type=geo_batch_analysis)
    params: { templateId, resultId, type, analysisTaskParam, executors }
    ↓
batch_analysis 任务执行：
    - 根据 type 查询该类型下所有热词
    - 遍历热词 × models 创建 sub_analysis 子任务
    ↓
所有 sub_analysis 完成后 → 触发回调
    ↓
回调时依次执行 executors
    ↓
executors 结果存入 geo_analysis_result
    ↓
所有 batch_analysis 完成 → 更新 geo_analysis_result (status=COMPLETED)
```

## 表结构设计

### 1. geo_analysis_template（模板表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| name | VARCHAR(128) | 模板名称 |
| cron_expression | VARCHAR(64) | Cron 表达式（NOT NULL，为空表示一次性任务） |
| config | TEXT | 完整配置 JSON（包含 groups） |
| status | TINYINT | 状态：0-停用 1-启用 |
| template_execute_status | TINYINT | 模板执行状态：0-未执行 1-已执行 |
| next_execute_time | DATETIME | 下次执行时间（NOT NULL，默认当前时间） |
| last_execute_time | DATETIME | 上次执行时间（NOT NULL，默认当前时间） |
| created_by | VARCHAR(64) | 创建人 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

**config 结构：**

```json
{
  "groups": [
    {
      "type": "poiAnalysis",
      "analysisTaskParam": {
        "models": ["deepseek", "qianwen"],
        "regions": ["beijing", "shanghai"]
      },
      "executors": [
        { "code": "poiExecutor1", "params": {} },
        { "code": "poiExecutor2", "params": {} }
      ]
    },
    {
      "type": "platformAnalysis",
      "analysisTaskParam": {
        "models": ["deepseek"],
        "regions": []
      },
      "executors": [
        { "code": "platformExecutor", "params": {} }
      ]
    }
  ]
}
```

**配置说明：**
- `groups`: 热词组配置数组
- `type`: 热词类型，用于查询该类型下所有热词
- `analysisTaskParam`: 分析任务参数
  - `models`: 模型列表
  - `regions`: 地域列表（待扩展）
- `executors`: 执行器数组，每个 type 可配置多个 executor

### 2. geo_analysis_result（结果表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| template_id | BIGINT | 关联模板 ID |
| status | TINYINT | 状态：0-待执行 1-执行中 2-完成 3-失败 |
| version | INT | 乐观锁版本号（NOT NULL，默认 0） |
| params | TEXT | 关联任务信息 JSON（NOT NULL，默认空字符串） |
| result | TEXT | 最终分析结果 JSON（NOT NULL，默认空字符串） |
| execute_time | DATETIME | 执行时间（NOT NULL，默认当前时间） |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

**params 结构：**

```json
{
  "batchTasks": [
    {
      "batchTaskId": 123,
      "type": "poiAnalysis",
      "status": "completed",
      "executorResults": [
        { "code": "poiExecutor1", "status": "completed", "result": {} },
        { "code": "poiExecutor2", "status": "completed", "result": {} }
      ]
    },
    {
      "batchTaskId": 124,
      "type": "platformAnalysis",
      "status": "running",
      "executorResults": []
    }
  ]
}
```

**result 结构：**

```json
{
  "poiAnalysis": {
    "stats": {
      "totalTasks": 5,
      "completedTasks": 4,
      "failedTasks": 1,
      "avgScore": 85.5
    },
    "executorResults": [
      {
        "code": "poiExecutor1",
        "status": "completed",
        "data": {}
      },
      {
        "code": "poiExecutor2",
        "status": "completed",
        "data": {}
      }
    ]
  },
  "platformAnalysis": {
    "stats": {
      "totalTasks": 5,
      "completedTasks": 4,
      "failedTasks": 1,
      "avgScore": 78.2
    },
    "executorResults": [
      {
        "code": "platformExecutor",
        "status": "completed",
        "data": {}
      }
    ]
  }
}
```

### 3. 复用 hot_word_task 表

新增类型常量：
- `TYPE_GEO_BATCH_ANALYSIS = "geo_batch_analysis"` - GEO 批量分析任务
- `TYPE_GEO_SUB_ANALYSIS = "geo_sub_analysis"` - GEO 子分析任务

## Executor 管理

### 设计思路

1. **Spring Bean 管理**：所有 Executor 实现类通过 `@Service` 注解注册为 Spring Bean
2. **QConfig 映射配置**：通过 QConfig 配置 executor code 与 beanName 的映射关系，以及描述信息
3. **Map 注入**：Spring 自动注入 `Map<String, GeoAnalysisExecutor>`，key 为 beanName

### QConfig 配置结构

```json
{
  "executors": [
    {
      "code": "poiScoreExecutor",
      "beanName": "poiScoreExecutor",
      "name": "POI评分执行器",
      "description": "对POI分析结果进行综合评分"
    },
    {
      "code": "platformStatExecutor",
      "beanName": "platformStatExecutor",
      "name": "平台统计执行器",
      "description": "汇总各平台分析数据"
    },
    {
      "code": "hotwordRankExecutor",
      "beanName": "hotwordRankExecutor",
      "name": "热词排名执行器",
      "description": "生成热词排名报表"
    }
  ]
}
```

### 后端实现

```java
// Executor 接口
public interface GeoAnalysisExecutor {
    String getCode();
    ExecutorResult execute(ExecutorContext context);
}

// 示例实现
@Service("poiScoreExecutor")
public class PoiScoreExecutor implements GeoAnalysisExecutor {
    @Override
    public String getCode() {
        return "poiScoreExecutor";
    }

    @Override
    public ExecutorResult execute(ExecutorContext context) {
        // 执行逻辑
    }
}

// Executor 工厂
@Service
public class GeoAnalysisExecutorFactory {

    @Resource
    private Map<String, GeoAnalysisExecutor> executorMap;  // Spring 自动注入

    @Resource
    private GeoAnalysisQConfig geoAnalysisQConfig;

    public GeoAnalysisExecutor getExecutor(String code) {
        ExecutorConfig config = geoAnalysisQConfig.getExecutorConfig(code);
        if (config == null) {
            throw new IllegalArgumentException("Executor not found: " + code);
        }
        return executorMap.get(config.getBeanName());
    }
}
```

### 前端选择流程

1. 前端调用 API 获取 QConfig 中配置的 executor 列表（包含 code、name、description）
2. 用户在模板配置页面选择需要的 executor
3. 选中的 executor code 存入模板 config 的 executors 数组

### 好处

- **动态配置**：通过 QConfig 可以新增/修改 executor 配置，无需重新部署
- **解耦前后端**：前端只感知 code 和描述，不关心具体实现
- **灵活扩展**：新增 executor 只需添加实现类 + QConfig 配置
