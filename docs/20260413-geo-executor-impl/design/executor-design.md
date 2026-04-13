# GEO 分析 Executor 实现方案

## 一、业务分析

### 1.1 数据来源

根据 Python 脚本分析，热词分析任务执行结果（单条）包含：
- `question`: 问题文本
- `answer`: AI 回答内容
- `references`: 引用信源列表，每个信源包含 `source`（网站名）、`title`、`url`、`snippet`

### 1.2 四个 Executor 对应四个统计功能

| Executor | 数据类型 | 统计内容 |
|----------|----------|----------|
| PoiSourceMentionExecutor | 城市poi词 | 信源提及率 - 各品牌被引用为信源的比例 |
| PoiSourceDistributionExecutor | 城市poi词 | 信源分布 - 按信源类型统计占比 |
| IndustryContentExecutor | 行业词 | 内容统计 - 品牌在回答中被提及的情况 |
| IndustrySourceDistributionExecutor | 行业词 | 信源分布 - 与 POI 信源分布逻辑相同 |

### 1.3 排名行业词背景

**问题背景**：行业词内容统计需要计算"平均排名"和"第一名次数"两个指标。

**为什么需要区分普通行业词和排名行业词？**

| 指标 | 数据来源 | 说明 |
|------|----------|------|
| 内容提及率 | 普通行业词 | 品牌在回答中被提及的问题数 / 总问题数 |
| 平均排名 | 排名行业词 | 品牌在回答中出现的位置排名的平均值 |
| 第一名次数 | 排名行业词 | 品牌排第一的次数 / 总问题数 |

**排名行业词示例**：
- "推荐在那个旅游平台购票" → AI 回答中品牌出现顺序：去哪儿、携程、飞猪 → 去哪儿排名第1
- "哪个平台订酒店最便宜" → AI 回答中品牌出现顺序：美团、携程 → 美团排名第1

**区分方式**（Python 脚本逻辑）：
```
文件名包含"排名"且不包含"非排名" → 排名行业词
```

**当前方案**：模板配置中通过 `analysisTaskParam` 区分，或者 Executor 执行时按文件名/任务名判断。

---

## 二、实体类设计

### 2.1 热词分析结果实体类

根据 `.prevpython/single_hotword_analysis_result.json` 结构，设计以下实体类：

```java
/**
 * 热词分析结果
 * 对应子任务 result 字段（JSON数组）
 */
@Data
public class HotWordAnalysisResult {
    
    /**
     * 问题文本
     */
    private String question;
    
    /**
     * AI 回答内容
     */
    private String answer;
    
    /**
     * 引用信源列表
     */
    private List<Reference> references;
}

/**
 * 信源引用
 */
@Data
public class Reference {
    
    /**
     * 引用序号
     */
    private Integer index;
    
    /**
     * 引用片段
     */
    private String snippet;
    
    /**
     * 信源名称（网站名）
     */
    private String source;
    
    /**
     * 文章标题
     */
    private String title;
    
    /**
     * 文章链接
     */
    private String url;
}
```

### 2.2 JSON 示例对应关系

```json
[
  {
    "question": "推荐在那个旅游平台购票",
    "answer": "二、价格 / 比价 / 抢票优先\n去哪儿（Qunar）...",
    "references": [
      {
        "index": 1,
        "snippet": "二、决策模糊克星...",
        "source": "IT之家",
        "title": "2026 出行预订平台实测...",
        "url": "https://www.ithome.com/0/927/263.htm"
      }
    ]
  }
]
```

解析代码：
```java
// 解析子任务 result
List<HotWordAnalysisResult> results = JsonUtils.jsonToObject(
    task.getResult(),
    new TypeReference<List<HotWordAnalysisResult>>() {}
);
```

### 2.3 实体类位置

```
domain/entity/hotword/
├── HotWordAnalysisResult.java    # 新增
└── Reference.java                 # 新增
```

---

## 三、分析流程详解

### 2.1 整体数据流

```
geo_analysis_template 触发
    ↓
创建 geo_analysis_result (status=PENDING)
    ↓
遍历 groups，每个 group 创建 hot_word_task
    ↓
batch_analysis 任务执行：
    - 根据 type 查询该类型下所有热词
    - 遍历热词 × models 创建 sub_analysis 子任务
    - 每个 sub_analysis 调用 AI 获取回答
    ↓
所有 sub_analysis 完成 → 触发回调
    ↓
回调时构建 batchTaskResult 结构：
{
  "deepseek": {
    "details": [
      { "question": "xxx", "answer": "xxx", "references": [...] },
      ...
    ]
  },
  "qwen": {
    "details": [...]
  }
}
    ↓
依次执行 executors
    ↓
executors 结果存入 geo_analysis_result
```

### 2.2 Executor 执行流程

```
ExecutorContext
├── templateId
├── resultId
├── type (热词类型)
├── analysisTaskParam (models, regions)
├── batchTaskResult (按模型分组的分析结果)
└── executorParams (executor 自定义参数)

     ↓ Executor 处理

ExecutorResult
├── code
├── status
├── data (统计结果)
└── error
```

### 3.3 各 Executor 详细流程

#### 通用处理模式

所有 Executor 都遵循相同的批量处理模式：

```
┌─────────────────────────────────────────────────────────────────┐
│ 输入: BatchTaskResultProvider                                    │
│   - successIds: [子任务ID列表]                                   │
│   - batchSize: 50                                                │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 初始化: 按模型分组的聚合器                                        │
│   Map<String, ModelAggregator> aggregators = new HashMap<>()    │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 分批读取 (forEachBatch)                                          │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Batch 1: successIds[0-49]                                   │ │
│ │   - 查询数据库获取这50个子任务                                │ │
│ │   - 遍历每个子任务:                                          │ │
│ │       - 获取 model (如 "deepseek")                           │ │
│ │       - 解析 result → List<HotWordAnalysisResult>           │ │
│ │       - 获取或创建 ModelAggregator                           │ │
│ │       - 聚合器处理每条 HotWordAnalysisResult                 │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                ↓                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Batch 2: successIds[50-99]                                  │ │
│ │   - ... 同上                                                │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                ↓                                 │
│ ... 重复直到所有批次处理完成                                      │
│                                ↓                                 │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 计算最终结果                                                      │
│   - 遍历所有 ModelAggregator                                     │
│   - 计算各模型的统计指标                                          │
│   - 计算加权总体指标                                              │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 输出: { models: {...}, overall: {...} }                          │
└─────────────────────────────────────────────────────────────────┘
```

#### PoiSourceMentionExecutor 流程

```
输入: BatchTaskResultProvider (successIds)

初始化:
  - Map<String, ModelMentionAggregator> aggregators = new HashMap<>()
  - ModelMentionAggregator: { modelCode, totalQuestions, brandMentionCounts }

分批处理 (forEachBatch):
  对于每批 50 个子任务:
    对于每个子任务:
      1. 获取 model (如 "deepseek")
      2. 解析 result:
         List<HotWordAnalysisResult> results = JsonUtils.jsonToObject(
             task.getResult(), new TypeReference<List<HotWordAnalysisResult>>() {}
         );
      3. 获取或创建该 model 的 ModelMentionAggregator
      4. 对于每条 HotWordAnalysisResult:
         - 检查 references 是否非空
         - 如果有，totalQuestions++
         - 对于每个品牌 brand:
           - 遍历 references，检查 reference.getSource() 是否包含品牌
           - 如果有，brandMentionCounts[brand]++
           - 一条记录只能贡献一次

计算最终结果:
  对于每个 model:
    - 计算各品牌的提及率 = count / totalQuestions
  计算加权总体:
    - 加权提及率 = Σ(模型提及率 × 模型权重) / Σ模型权重

输出: { models: {...}, overall: {...} }
```

#### PoiSourceDistributionExecutor 流程

```
输入: BatchTaskResultProvider (successIds)

初始化:
  - Map<String, ModelDistAggregator> aggregators = new HashMap<>()
  - ModelDistAggregator: { modelCode, totalSources, categoryCounts }

分批处理 (forEachBatch):
  对于每批 50 个子任务:
    对于每个子任务:
      1. 获取 model
      2. 解析 result → List<HotWordAnalysisResult>
      3. 获取或创建该 model 的 ModelDistAggregator
      4. 对于每条 HotWordAnalysisResult:
         - 获取 references 列表
         - 对于每个 Reference:
           - 提取 source (网站名)
           - 匹配信源分类:
             a. 精确匹配 sourceCategoryMap
             b. 模糊匹配 sourceCategoryRules
             c. 默认 "其他长尾"
           - categoryCounts[category]++
           - totalSources++

计算最终结果:
  对于每个 model:
    - 计算各分类占比 = count / totalSources
  计算总体:
    - 总体占比 = 各模型占比简单平均
  计算加权总体:
    - 加权占比 = Σ(模型占比 × 模型权重)

输出: { models: {...}, overall: {...}, weightedOverall: {...} }
```

#### IndustryContentExecutor 流程

```
输入: BatchTaskResultProvider (successIds)

初始化:
  - Map<String, ModelContentAggregator> aggregators = new HashMap<>()
  - ModelContentAggregator: { modelCode, totalQuestions, brandStats }
  - BrandStat: { mentionCount, ranks, firstCount }

分批处理 (forEachBatch):
  对于每批 50 个子任务:
    对于每个子任务:
      1. 获取 model
      2. 解析 result → List<HotWordAnalysisResult>
      3. 获取或创建该 model 的 ModelContentAggregator
      4. 对于每条 HotWordAnalysisResult:
         - 检查 references 和 answer 是否非空
         - 如果有，totalQuestions++
         - 从 answer 中找出品牌出现顺序:
           - 遍历品牌及其同义词
           - 找到在 answer 中首次出现的位置
           - 按位置排序得到品牌顺序列表
         - 对于每个出现的品牌:
           - mentionCount++
           - 记录排名 rank
           - 如果 rank == 1，firstCount++

计算最终结果:
  对于每个 model:
    对于每个品牌:
      - 提及率 = mentionCount / totalQuestions
      - 平均排名 = Σranks / mentionCount
      - 第一名比例 = firstCount / mentionCount

输出: { models: {...} }
```

#### IndustrySourceDistributionExecutor 流程

```
输入: BatchTaskResultProvider (successIds)

处理逻辑与 PoiSourceDistributionExecutor 完全相同
仅数据来源（type）不同

输出: { models: {...}, overall: {...}, weightedOverall: {...} }
```

---

## 三、BaseExecutor 设计

### 3.1 公共逻辑抽取

```java
/**
 * GEO 分析基础执行器
 * 提供公共数据处理能力
 */
public abstract class BaseGeoAnalysisExecutor implements GeoAnalysisExecutor {

    @Resource
    protected GeoAnalysisQConfig geoAnalysisQConfig;

    /**
     * 获取有效问题（有信源的问题）
     */
    protected List<Map<String, Object>> getValidQuestions(List<Map<String, Object>> details) {
        return details.stream()
            .filter(this::hasSources)
            .collect(Collectors.toList());
    }

    /**
     * 获取有效问题（有信源 + 有回答）- 用于内容统计
     */
    protected List<Map<String, Object>> getValidQuestionsWithAnswer(List<Map<String, Object>> details) {
        return details.stream()
            .filter(d -> hasSources(d) && hasAnswer(d))
            .collect(Collectors.toList());
    }

    /**
     * 判断问题是否有信源
     */
    protected boolean hasSources(Map<String, Object> detail) {
        Object sources = detail.get("references");
        if (sources instanceof List) {
            return !((List<?>) sources).isEmpty();
        }
        return false;
    }

    /**
     * 判断问题是否有回答
     */
    protected boolean hasAnswer(Map<String, Object> detail) {
        Object answer = detail.get("answer");
        return answer != null && StringUtils.isNotBlank(answer.toString());
    }

    /**
     * 从信源中提取网站名
     */
    protected String extractSiteName(Map<String, Object> reference) {
        String source = (String) reference.get("source");
        return source != null ? source : "";
    }

    /**
     * 判断品牌是否被信源引用
     */
    protected boolean isBrandInSource(String siteName, String brand) {
        if (StringUtils.isBlank(siteName)) {
            return false;
        }
        Map<String, List<String>> synonyms = geoAnalysisQConfig.getBrandSynonyms();
        List<String> brandSynonyms = synonyms.getOrDefault(brand, Collections.singletonList(brand));
        String siteLower = siteName.toLowerCase();
        for (String syn : brandSynonyms) {
            if (siteLower.contains(syn.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

    /**
     * 获取信源分类
     * 1. 先精确匹配 sourceCategoryMap
     * 2. 再模糊匹配 sourceCategoryRules
     * 3. 都不匹配返回 "其他长尾"
     */
    protected String getSourceCategory(String siteName) {
        if (StringUtils.isBlank(siteName)) {
            return "其他长尾";
        }

        // 1. 精确匹配
        Map<String, String> categoryMap = geoAnalysisQConfig.getSourceCategoryMap();
        if (categoryMap.containsKey(siteName)) {
            return categoryMap.get(siteName);
        }

        // 2. 模糊匹配
        List<SourceCategoryRule> rules = geoAnalysisQConfig.getSourceCategoryRules();
        String siteLower = siteName.toLowerCase();
        for (SourceCategoryRule rule : rules) {
            if (matchesRule(siteLower, rule.getKeywords())) {
                return rule.getCategory();
            }
        }

        // 3. 默认返回其他长尾
        return "其他长尾";
    }

    /**
     * 判断文本是否匹配规则关键词
     */
    private boolean matchesRule(String text, List<String> keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

    /**
     * 找出回答中品牌出现的顺序（用于排名计算）
     */
    protected List<String> findBrandOrder(String answer) {
        if (StringUtils.isBlank(answer)) {
            return Collections.emptyList();
        }

        List<String> brands = geoAnalysisQConfig.getBrands();
        Map<String, List<String>> synonyms = geoAnalysisQConfig.getBrandSynonyms();

        List<Map.Entry<String, Integer>> brandPositions = new ArrayList<>();

        for (String brand : brands) {
            List<String> brandSyns = synonyms.getOrDefault(brand, Collections.singletonList(brand));
            for (String syn : brandSyns) {
                int pos = answer.toLowerCase().indexOf(syn.toLowerCase());
                if (pos >= 0) {
                    brandPositions.add(Map.entry(brand, pos));
                    break; // 找到第一个匹配即可
                }
            }
        }

        return brandPositions.stream()
            .sorted(Map.Entry.comparingByValue())
            .map(Map.Entry::getKey)
            .distinct()
            .collect(Collectors.toList());
    }

    /**
     * 获取模型显示名称
     */
    protected String getModelDisplayName(String modelCode) {
        Map<String, String> modelNameMap = geoAnalysisQConfig.getModelNameMap();
        return modelNameMap.getOrDefault(modelCode, modelCode);
    }

    /**
     * 获取模型权重
     */
    protected double getModelWeight(String modelName) {
        Map<String, Double> modelWeights = geoAnalysisQConfig.getModelWeights();
        return modelWeights.getOrDefault(modelName, 0.25);
    }
}
```

---

## 四、四个 Executor 详细设计

### 4.1 PoiSourceMentionExecutor（POI信源提及率）

**功能**：统计各品牌在各模型下被引用为信源的比例

**输出结构**：
```json
{
  "models": {
    "DeepSeek": {
      "totalQuestions": 100,
      "brands": {
        "去哪儿": { "count": 10, "rate": 0.10 },
        "携程": { "count": 8, "rate": 0.08 }
      }
    },
    "通义千问": {
      "totalQuestions": 95,
      "brands": { ... }
    }
  },
  "overall": {
    "去哪儿": { "weightedRate": 0.12 },
    "携程": { "weightedRate": 0.09 }
  }
}
```

**核心实现**：
```java
@Slf4j
@Service("poiSourceMentionExecutor")
public class PoiSourceMentionExecutor extends BaseGeoAnalysisExecutor {

    @Override
    public String getCode() {
        return "poiSourceMentionExecutor";
    }

    @Override
    public ExecutorResult execute(ExecutorContext context) {
        Map<String, Object> batchTaskResult = context.getBatchTaskResult();
        List<String> brands = geoAnalysisQConfig.getBrands();

        Map<String, ModelMentionResult> modelResults = new LinkedHashMap<>();
        Map<String, Double> brandWeightedSum = new HashMap<>();
        Map<String, Double> brandWeightTotal = new HashMap<>();

        // 初始化
        for (String brand : brands) {
            brandWeightedSum.put(brand, 0.0);
            brandWeightTotal.put(brand, 0.0);
        }

        // 遍历每个模型
        for (String modelCode : batchTaskResult.keySet()) {
            Map<String, Object> modelData = (Map<String, Object>) batchTaskResult.get(modelCode);
            List<Map<String, Object>> details = (List<Map<String, Object>>) modelData.get("details");

            List<Map<String, Object>> validDetails = getValidQuestions(details);
            int totalQuestions = validDetails.size();

            String modelName = getModelDisplayName(modelCode);
            double weight = getModelWeight(modelName);

            ModelMentionResult modelResult = new ModelMentionResult();
            modelResult.setTotalQuestions(totalQuestions);

            // 遍历每个品牌
            for (String brand : brands) {
                int brandCount = countBrandMentions(validDetails, brand);
                double rate = totalQuestions > 0 ? (double) brandCount / totalQuestions : 0;

                modelResult.getBrands().put(brand, new BrandMentionStat(brandCount, totalQuestions, rate));

                // 累加加权计算
                brandWeightedSum.merge(brand, rate * weight, Double::sum);
                brandWeightTotal.merge(brand, weight, Double::sum);
            }

            modelResults.put(modelName, modelResult);
        }

        // 计算加权总体
        Map<String, WeightedStat> overall = new LinkedHashMap<>();
        for (String brand : brands) {
            double weightedRate = brandWeightTotal.get(brand) > 0
                ? brandWeightedSum.get(brand) / brandWeightTotal.get(brand)
                : 0;
            overall.put(brand, new WeightedStat(weightedRate));
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("models", modelResults);
        result.put("overall", overall);

        return ExecutorResult.success(getCode(), result);
    }

    /**
     * 统计品牌被信源引用的问题数
     */
    private int countBrandMentions(List<Map<String, Object>> details, String brand) {
        int count = 0;
        for (Map<String, Object> detail : details) {
            List<Map<String, Object>> references = (List<Map<String, Object>>) detail.get("references");
            for (Map<String, Object> ref : references) {
                String siteName = extractSiteName(ref);
                if (isBrandInSource(siteName, brand)) {
                    count++;
                    break; // 一个问题只算一次
                }
            }
        }
        return count;
    }
}
```

---

### 4.2 PoiSourceDistributionExecutor（POI信源分布）

**功能**：按信源类型统计占比

**输出结构**：
```json
{
  "categories": ["新闻媒体/门户", "OTA/旅行平台", "百科/知识库", "社区/UGC", "搜索/问答/工具", "官方机构", "其他长尾"],
  "models": {
    "DeepSeek": {
      "totalSources": 500,
      "distribution": {
        "新闻媒体/门户": { "count": 50, "rate": 0.10 },
        "OTA/旅行平台": { "count": 100, "rate": 0.20 }
      }
    }
  },
  "overall": {
    "新闻媒体/门户": { "rate": 0.12 },
    "OTA/旅行平台": { "rate": 0.18 }
  },
  "weightedOverall": {
    "新闻媒体/门户": { "rate": 0.11 },
    "OTA/旅行平台": { "rate": 0.19 }
  }
}
```

**核心实现**：
```java
@Slf4j
@Service("poiSourceDistributionExecutor")
public class PoiSourceDistributionExecutor extends BaseGeoAnalysisExecutor {

    @Override
    public String getCode() {
        return "poiSourceDistributionExecutor";
    }

    @Override
    public ExecutorResult execute(ExecutorContext context) {
        Map<String, Object> batchTaskResult = context.getBatchTaskResult();
        List<String> categories = geoAnalysisQConfig.getSourceCategories();

        Map<String, ModelDistResult> modelResults = new LinkedHashMap<>();
        Map<String, Integer> categoryTotalCount = new HashMap<>();
        Map<String, Double> categoryWeightedSum = new HashMap<>();
        int totalModels = 0;

        // 初始化
        for (String cat : categories) {
            categoryTotalCount.put(cat, 0);
            categoryWeightedSum.put(cat, 0.0);
        }

        // 遍历每个模型
        for (String modelCode : batchTaskResult.keySet()) {
            Map<String, Object> modelData = (Map<String, Object>) batchTaskResult.get(modelCode);
            List<Map<String, Object>> details = (List<Map<String, Object>>) modelData.get("details");

            Map<String, Integer> categoryCount = new HashMap<>();
            int totalSources = 0;

            // 统计各分类信源数
            for (Map<String, Object> detail : details) {
                List<Map<String, Object>> references = (List<Map<String, Object>>) detail.get("references");
                for (Map<String, Object> ref : references) {
                    String siteName = extractSiteName(ref);
                    String category = getSourceCategory(siteName);
                    categoryCount.merge(category, 1, Integer::sum);
                    totalSources++;
                }
            }

            String modelName = getModelDisplayName(modelCode);
            double weight = getModelWeight(modelName);

            ModelDistResult modelResult = new ModelDistResult();
            modelResult.setTotalSources(totalSources);

            Map<String, CategoryStat> distribution = new LinkedHashMap<>();
            for (String cat : categories) {
                int count = categoryCount.getOrDefault(cat, 0);
                double rate = totalSources > 0 ? (double) count / totalSources : 0;
                distribution.put(cat, new CategoryStat(count, totalSources, rate));

                categoryTotalCount.merge(cat, count, Integer::sum);
                categoryWeightedSum.merge(cat, rate * weight, Double::sum);
            }
            modelResult.setDistribution(distribution);

            modelResults.put(modelName, modelResult);
            totalModels++;
        }

        // 计算总体（简单平均）
        Map<String, SimpleStat> overall = new LinkedHashMap<>();
        for (String cat : categories) {
            double avgRate = totalModels > 0
                ? (double) categoryTotalCount.get(cat) / modelResults.values().stream().mapToInt(ModelDistResult::getTotalSources).sum()
                : 0;
            overall.put(cat, new SimpleStat(avgRate));
        }

        // 计算加权总体
        double totalWeight = geoAnalysisQConfig.getModelWeights().values().stream().mapToDouble(Double::doubleValue).sum();
        Map<String, SimpleStat> weightedOverall = new LinkedHashMap<>();
        for (String cat : categories) {
            double weightedRate = totalWeight > 0 ? categoryWeightedSum.get(cat) / totalWeight : 0;
            weightedOverall.put(cat, new SimpleStat(weightedRate));
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("categories", categories);
        result.put("models", modelResults);
        result.put("overall", overall);
        result.put("weightedOverall", weightedOverall);

        return ExecutorResult.success(getCode(), result);
    }
}
```

---

### 4.3 IndustryContentExecutor（行业词内容统计）

**功能**：统计品牌在回答中被提及的情况

**输出结构**：
```json
{
  "models": {
    "DeepSeek": {
      "totalQuestions": 100,
      "brands": {
        "去哪儿": {
          "mentionRate": 0.45,
          "mentionCount": 45,
          "avgRank": 1.8,
          "firstCount": 20,
          "firstRate": 0.20
        }
      }
    }
  },
  "overall": {
    "去哪儿": {
      "weightedMentionRate": 0.42,
      "weightedAvgRank": 1.9
    }
  }
}
```

**核心实现**：
```java
@Slf4j
@Service("industryContentExecutor")
public class IndustryContentExecutor extends BaseGeoAnalysisExecutor {

    @Override
    public String getCode() {
        return "industryContentExecutor";
    }

    @Override
    public ExecutorResult execute(ExecutorContext context) {
        Map<String, Object> batchTaskResult = context.getBatchTaskResult();
        List<String> brands = geoAnalysisQConfig.getBrands();

        Map<String, ModelContentResult> modelResults = new LinkedHashMap<>();

        // 遍历每个模型
        for (String modelCode : batchTaskResult.keySet()) {
            Map<String, Object> modelData = (Map<String, Object>) batchTaskResult.get(modelCode);
            List<Map<String, Object>> details = (List<Map<String, Object>>) modelData.get("details");

            // 获取有效问题（有信源 + 有回答）
            List<Map<String, Object>> validDetails = getValidQuestionsWithAnswer(details);
            int totalQuestions = validDetails.size();

            String modelName = getModelDisplayName(modelCode);

            ModelContentResult modelResult = new ModelContentResult();
            modelResult.setTotalQuestions(totalQuestions);

            // 遍历每个品牌
            for (String brand : brands) {
                BrandContentStat stat = calculateBrandContentStat(validDetails, brand, totalQuestions);
                modelResult.getBrands().put(brand, stat);
            }

            modelResults.put(modelName, modelResult);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("models", modelResults);

        return ExecutorResult.success(getCode(), result);
    }

    /**
     * 计算单个品牌的内容统计
     */
    private BrandContentStat calculateBrandContentStat(
            List<Map<String, Object>> details, String brand, int totalQuestions) {

        int mentionCount = 0;
        List<Integer> ranks = new ArrayList<>();
        int firstCount = 0;

        for (Map<String, Object> detail : details) {
            String answer = (String) detail.get("answer");
            List<String> brandOrder = findBrandOrder(answer);

            if (brandOrder.contains(brand)) {
                mentionCount++;
                int rank = brandOrder.indexOf(brand) + 1;
                ranks.add(rank);
                if (rank == 1) {
                    firstCount++;
                }
            }
        }

        double mentionRate = totalQuestions > 0 ? (double) mentionCount / totalQuestions : 0;
        double avgRank = ranks.isEmpty() ? 0 : ranks.stream().mapToInt(i -> i).average().orElse(0);
        double firstRate = mentionCount > 0 ? (double) firstCount / mentionCount : 0;

        return new BrandContentStat(mentionRate, mentionCount, totalQuestions, avgRank, firstCount, firstRate);
    }
}
```

---

### 4.4 IndustrySourceDistributionExecutor（行业词信源分布）

**功能**：与 PoiSourceDistributionExecutor 逻辑相同，数据来源为行业词

**实现**：直接复用 PoiSourceDistributionExecutor 的核心逻辑

```java
@Slf4j
@Service("industrySourceDistributionExecutor")
public class IndustrySourceDistributionExecutor extends BaseGeoAnalysisExecutor {

    @Override
    public String getCode() {
        return "industrySourceDistributionExecutor";
    }

    @Override
    public ExecutorResult execute(ExecutorContext context) {
        // 复用 PoiSourceDistributionExecutor 的逻辑
        // 数据来源不同，但统计逻辑相同
        return doSourceDistribution(context);
    }

    private ExecutorResult doSourceDistribution(ExecutorContext context) {
        // 与 PoiSourceDistributionExecutor 相同的实现
        // ...
    }
}
```

---

## 五、QConfig 配置结构

### 5.1 geo_analysis_config.json

```json
{
  "brands": ["去哪儿", "携程", "同程", "飞猪", "美团"],

  "brandSynonyms": {
    "去哪儿": ["去哪儿", "去哪", "qunar", "去哪儿网", "去哪儿旅行"],
    "携程": ["携程", "ctrip", "trip.com", "携程旅行", "携程网"],
    "同程": ["同程", "ly.com", "同程旅行", "同程网"],
    "飞猪": ["飞猪", "fliggy", "alitrip", "阿里飞猪", "飞猪旅行"],
    "美团": ["美团", "meituan", "美团酒店", "美团民宿"]
  },

  "modelWeights": {
    "通义千问": 0.435,
    "豆包": 0.280,
    "DeepSeek": 0.181,
    "元宝": 0.104
  },

  "modelNameMap": {
    "deepseek": "DeepSeek",
    "qwen": "通义千问",
    "doubao": "豆包",
    "yuanbao": "元宝"
  },

  "sourceCategories": [
    "新闻媒体/门户",
    "OTA/旅行平台",
    "百科/知识库",
    "社区/UGC",
    "搜索/问答/工具",
    "官方机构",
    "其他长尾"
  ],

  "sourceCategoryMap": {
    "Trip.com": "OTA/旅行平台",
    "hk.trip.com": "OTA/旅行平台",
    "booking.com": "OTA/旅行平台",
    "agoda.com": "OTA/旅行平台",
    "9xhi.com": "OTA/旅行平台",
    "去哪儿": "OTA/旅行平台",
    "携程": "OTA/旅行平台",
    "同程": "OTA/旅行平台",
    "飞猪": "OTA/旅行平台",
    "美团": "OTA/旅行平台",
    "马蜂窝": "OTA/旅行平台",
    "穷游网": "OTA/旅行平台",
    "百度百科": "百科/知识库",
    "大众点评": "社区/UGC",
    "豆瓣": "社区/UGC",
    "抖音": "社区/UGC",
    "微博": "社区/UGC",
    "北京日报": "新闻媒体/门户",
    "网易": "新闻媒体/门户",
    "新浪网": "新闻媒体/门户",
    "搜狐": "新闻媒体/门户",
    "腾讯网": "新闻媒体/门户",
    "澎湃新闻": "新闻媒体/门户",
    "百度知道": "搜索/问答/工具",
    "百度一下": "搜索/问答/工具"
  },

  "sourceCategoryRules": [
    {
      "category": "官方机构",
      "keywords": ["政府", "gov.cn", "官网", "官方网站", "博物院", "管理局", "委员会", "办公厅", "司法局", "财政局", "教育局", "旅游局", "文化局"]
    },
    {
      "category": "新闻媒体/门户",
      "keywords": ["日报", "新闻网", "新浪", "搜狐", "网易", "腾讯", "凤凰", "澎湃", "头条", "新闻", "广播", "电视", "电视台"]
    },
    {
      "category": "百科/知识库",
      "keywords": ["百科", "wiki", "知识库", "百度百科", "维基"]
    },
    {
      "category": "社区/UGC",
      "keywords": ["大众点评", "豆瓣", "小红书", "抖音", "微博", "知乎", "马蜂窝", "穷游", "社区", "论坛"]
    },
    {
      "category": "搜索/问答/工具",
      "keywords": ["百度知道", "百度一下", "问答", "搜索", "工具"]
    },
    {
      "category": "OTA/旅行平台",
      "keywords": ["携程", "去哪儿", "同程", "飞猪", "美团酒店", "booking", "agoda", "trip.com", "酒店", "民宿", "机票", "旅行", "旅游网", "景区", "景点"]
    }
  ]
}
```

### 5.2 geo_analysis_executor_config.json（更新）

```json
{
  "executors": [
    {
      "code": "poiSourceMentionExecutor",
      "beanName": "poiSourceMentionExecutor",
      "name": "POI信源提及率统计",
      "description": "统计各品牌在各模型下被引用为信源的比例",
      "dataTypes": ["城市poi词"]
    },
    {
      "code": "poiSourceDistributionExecutor",
      "beanName": "poiSourceDistributionExecutor",
      "name": "POI信源分布统计",
      "description": "按信源类型统计信源分布占比",
      "dataTypes": ["城市poi词"]
    },
    {
      "code": "industryContentExecutor",
      "beanName": "industryContentExecutor",
      "name": "行业词内容统计",
      "description": "统计品牌在回答中被提及的情况（提及率、平均排名、第一名次数）",
      "dataTypes": ["行业词"]
    },
    {
      "code": "industrySourceDistributionExecutor",
      "beanName": "industrySourceDistributionExecutor",
      "name": "行业词信源分布统计",
      "description": "按信源类型统计行业词信源分布占比",
      "dataTypes": ["行业词"]
    }
  ]
}
```

---

## 六、类结构设计

```
service/geo/analysis/executor/
├── GeoAnalysisExecutor.java               # 接口
├── BaseGeoAnalysisExecutor.java           # 抽象基类
├── GeoAnalysisExecutorFactory.java        # 工厂
├── PoiScoreExecutor.java                  # 示例执行器（保留）
├── PoiSourceMentionExecutor.java          # POI信源提及率
├── PoiSourceDistributionExecutor.java     # POI信源分布
├── IndustryContentExecutor.java           # 行业词内容统计
└── IndustrySourceDistributionExecutor.java # 行业词信源分布

infra/qconfig/
└── GeoAnalysisQConfig.java                # 更新：新增配置读取方法
```

---

## 七、GeoAnalysisQConfig 扩展

```java
@Slf4j
@Component
public class GeoAnalysisQConfig {

    // Executor 配置
    private volatile List<ExecutorConfig> executorConfigs = new ArrayList<>();
    private volatile Map<String, ExecutorConfig> executorConfigMap = new HashMap<>();

    // 业务配置
    private volatile List<String> brands = new ArrayList<>();
    private volatile Map<String, List<String>> brandSynonyms = new HashMap<>();
    private volatile Map<String, Double> modelWeights = new HashMap<>();
    private volatile Map<String, String> modelNameMap = new HashMap<>();
    private volatile List<String> sourceCategories = new ArrayList<>();
    private volatile Map<String, String> sourceCategoryMap = new HashMap<>();
    private volatile List<SourceCategoryRule> sourceCategoryRules = new ArrayList<>();

    @Data
    public static class ExecutorConfig {
        private String code;
        private String beanName;
        private String name;
        private String description;
        private List<String> dataTypes;
    }

    @Data
    public static class SourceCategoryRule {
        private String category;
        private List<String> keywords;
    }

    // ==================== QConfig 回调 ====================

    @QConfig("geo_analysis_executor_config.json")
    public void onExecutorConfigChanged(String json) {
        // ... 现有逻辑
    }

    @QConfig("geo_analysis_config.json")
    public void onAnalysisConfigChanged(String json) {
        if (StringUtils.isBlank(json)) {
            return;
        }
        try {
            GeoAnalysisConfig config = JsonUtils.jsonToObject(json, GeoAnalysisConfig.class);
            this.brands = config.getBrands();
            this.brandSynonyms = config.getBrandSynonyms();
            this.modelWeights = config.getModelWeights();
            this.modelNameMap = config.getModelNameMap();
            this.sourceCategories = config.getSourceCategories();
            this.sourceCategoryMap = config.getSourceCategoryMap();
            this.sourceCategoryRules = config.getSourceCategoryRules();
            log.info("Geo analysis config loaded");
        } catch (Exception e) {
            log.error("Failed to parse geo analysis config", e);
        }
    }

    // ==================== Getter 方法 ====================

    public List<String> getBrands() {
        return new ArrayList<>(brands);
    }

    public Map<String, List<String>> getBrandSynonyms() {
        return new HashMap<>(brandSynonyms);
    }

    public Map<String, Double> getModelWeights() {
        return new HashMap<>(modelWeights);
    }

    public Map<String, String> getModelNameMap() {
        return new HashMap<>(modelNameMap);
    }

    public List<String> getSourceCategories() {
        return new ArrayList<>(sourceCategories);
    }

    public Map<String, String> getSourceCategoryMap() {
        return new HashMap<>(sourceCategoryMap);
    }

    public List<SourceCategoryRule> getSourceCategoryRules() {
        return new ArrayList<>(sourceCategoryRules);
    }
}
```

---

## 八、Executor 触发与回调机制

### 8.1 完整触发流程

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. QSchedule 定时触发 (每分钟)                                                │
│    GeoAnalysisScheduleTask.triggerAnalysis()                                │
│    - 查询 execute_status=PENDING 且 next_execute_time <= now 的模板          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. 创建分析结果 + 批量任务                                                    │
│    GeoAnalysisResultService.triggerExecution(templateId)                    │
│    - 创建 GeoAnalysisResult (status=PENDING)                                │
│    - 遍历 groups，每个 type 创建 HotWordTask (TYPE_BATCH_ANALYSIS)           │
│    - 更新 result.params = {batchTasks: [{batchTaskId, type, status}]}       │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. 批量任务异步执行                                                           │
│    HotWordTaskService.executeBatchAnalysisTaskAsync()                       │
│    - 查询 type 下所有热词                                                     │
│    - 遍历 hotword × models 创建子任务 (TYPE_SUB_ANALYSIS)                    │
│    - 更新 batchTask.result.subTaskIds = [...]                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. 子任务异步执行                                                             │
│    AnalysisTaskExecutor.executeAsync()                                      │
│    - 调用下游 AI 接口获取问答结果                                             │
│    - 下游回调 handleCallback(downstreamTaskId, "completed", result)         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 5. 子任务回调处理                                                             │
│    HotWordTaskService.handleCallback()                                      │
│    - 更新子任务状态 + 结果                                                    │
│    - 调用 updateBatchTaskProgress(subTask)                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 6. 更新批量任务进度 (Redis 分布式锁)                                          │
│    HotWordTaskService.updateBatchTaskProgress()                             │
│    - 累加 successIds / failedIds                                            │
│    - 检测全部完成 → 更新 batchTask.status = COMPLETED                        │
│    - ✅ 触发 GEO 分析回调 (新增逻辑)                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 7. GEO 分析回调处理                                                           │
│    GeoAnalysisResultService.handleBatchTaskCallback()                       │
│    - 构建按模型分组的 batchTaskResult                                         │
│    - 执行配置的 executors                                                    │
│    - 更新 GeoAnalysisResult.result (乐观锁)                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 关键修改：HotWordTaskService

在 `updateBatchTaskProgress()` 方法中，批量任务完成时触发 GEO 分析回调：

```java
// 检查是否全部完成
if (subTaskIds != null && successIds.size() + failedIds.size() >= subTaskIds.size()) {
    batchTask.setStatus(HotWordTask.STATUS_COMPLETED);
    LOG.info("Batch task {} completed, success: {}, failed: {}",
            batchTask.getId(), successIds.size(), failedIds.size());
    
    // ✅ 新增：触发 GEO 分析回调
    triggerGeoAnalysisCallback(batchTask);
}

// 新增方法
private void triggerGeoAnalysisCallback(HotWordTask completedBatchTask) {
    // 1. 查找关联的 GeoAnalysisResult
    GeoAnalysisResult geoResult = findGeoAnalysisResultByBatchTaskId(completedBatchTask.getId());
    if (geoResult == null) {
        LOG.debug("No GeoAnalysisResult found for batch task {}", completedBatchTask.getId());
        return;
    }
    
    // 2. 构建按模型分组的 batchTaskResult
    Map<String, Object> batchTaskResult = buildBatchTaskResult(completedBatchTask);
    
    // 3. 从 batchTask.result.type 获取热词类型
    String type = extractTypeFromBatchTask(completedBatchTask);
    
    // 4. 调用 GEO 分析回调
    geoAnalysisResultService.handleBatchTaskCallback(geoResult.getId(), type, batchTaskResult);
}

/**
 * 根据 batchTaskId 查找关联的 GeoAnalysisResult
 */
private GeoAnalysisResult findGeoAnalysisResultByBatchTaskId(Long batchTaskId) {
    // 通过 params 字段中的 batchTasks 数组匹配
    return geoAnalysisResultMapper.selectByBatchTaskId(batchTaskId);
}

/**
 * 构建按模型分组的批量任务结果
 */
private Map<String, Object> buildBatchTaskResult(HotWordTask batchTask) {
    Map<String, Object> batchResult = JsonUtils.jsonToObject(
        batchTask.getResult(), new TypeReference<Map<String, Object>>(){}
    );
    
    List<Long> subTaskIds = (List<Long>) batchResult.get("subTaskIds");
    List<Long> successIds = (List<Long>) batchResult.get("successIds");
    
    Map<String, Object> result = new HashMap<>();
    
    // 获取所有成功的子任务
    List<HotWordTask> successTasks = hotWordTaskMapper.selectByIds(successIds, 1000);
    
    // 按 model 分组
    Map<String, List<Map<String, Object>>> modelDetails = new HashMap<>();
    for (HotWordTask task : successTasks) {
        String model = task.getModel();
        if (StringUtils.isBlank(model)) continue;
        
        // 解析子任务结果
        if (StringUtils.isNotBlank(task.getResult())) {
            List<Map<String, Object>> taskResult = JsonUtils.jsonToObject(
                task.getResult(), new TypeReference<List<Map<String, Object>>>(){}
            );
            modelDetails.computeIfAbsent(model, k -> new ArrayList<>()).addAll(taskResult);
        }
    }
    
    // 构建最终结构
    for (Map.Entry<String, List<Map<String, Object>>> entry : modelDetails.entrySet()) {
        Map<String, Object> modelData = new HashMap<>();
        modelData.put("details", entry.getValue());
        result.put(entry.getKey(), modelData);
    }
    
    return result;
}
```

### 8.3 GeoAnalysisResultMapper 新增方法

```java
/**
 * 根据 batchTaskId 查询关联的 GeoAnalysisResult
 */
GeoAnalysisResult selectByBatchTaskId(@Param("batchTaskId") Long batchTaskId);
```

```xml
<select id="selectByBatchTaskId" resultType="GeoAnalysisResult">
    SELECT * FROM geo_analysis_result
    WHERE params LIKE CONCAT('%"batchTaskId":', #{batchTaskId}, '%')
       OR params LIKE CONCAT('%"batchTaskId": ', #{batchTaskId}, '%')
    LIMIT 1
</select>
```

### 8.4 GeoAnalysisResultService 回调逻辑

```java
/**
 * 处理批量分析任务回调
 * 
 * @param resultId GEO 分析结果 ID
 * @param type 热词类型（城市poi词/行业词）
 * @param batchTaskResult 按模型分组的分析结果
 */
public void handleBatchTaskCallback(Long resultId, String type, Map<String, Object> batchTaskResult) {
    GeoAnalysisResult result = resultMapper.selectById(resultId);
    if (result == null) {
        LOG.warn("Result not found: {}", resultId);
        return;
    }
    
    // 获取模板配置
    GeoAnalysisTemplate template = templateMapper.selectById(result.getTemplateId());
    if (template == null) {
        LOG.warn("Template not found for result: {}", resultId);
        return;
    }
    
    // 解析配置获取 executors
    Map<String, Object> configMap = JsonUtils.jsonToObject(
        template.getConfig(), new TypeReference<Map<String, Object>>() {}
    );
    List<Map<String, Object>> groups = (List<Map<String, Object>>) configMap.get("groups");
    
    // 执行对应的 executors
    Map<String, Object> executorResults = new HashMap<>();
    for (Map<String, Object> group : groups) {
        String groupType = (String) group.get("type");
        if (!type.equals(groupType)) {
            continue;  // 跳过不匹配的 group
        }
        
        List<Map<String, Object>> executors = (List<Map<String, Object>>) group.get("executors");
        if (executors == null) {
            continue;
        }
        
        List<Map<String, Object>> typeExecutorResults = new ArrayList<>();
        for (Map<String, Object> executorConfig : executors) {
            String code = (String) executorConfig.get("code");
            try {
                GeoAnalysisExecutor executor = executorFactory.getExecutor(code);
                GeoAnalysisExecutor.ExecutorContext context = new GeoAnalysisExecutor.ExecutorContext();
                context.setTemplateId(result.getTemplateId());
                context.setResultId(resultId);
                context.setType(type);
                context.setBatchTaskResult(batchTaskResult);
                context.setExecutorParams((Map<String, Object>) executorConfig.get("params"));
                
                GeoAnalysisExecutor.ExecutorResult executorResult = executor.execute(context);
                
                Map<String, Object> resultMap = new HashMap<>();
                resultMap.put("code", executorResult.getCode());
                resultMap.put("status", executorResult.getStatus());
                resultMap.put("data", executorResult.getData());
                if (executorResult.getError() != null) {
                    resultMap.put("error", executorResult.getError());
                }
                typeExecutorResults.add(resultMap);
            } catch (Exception e) {
                LOG.error("Executor {} failed for result {}", code, resultId, e);
                Map<String, Object> errorResult = new HashMap<>();
                errorResult.put("code", code);
                errorResult.put("status", "failed");
                errorResult.put("error", e.getMessage());
                typeExecutorResults.add(errorResult);
            }
        }
        executorResults.put(type + "_executors", typeExecutorResults);
    }
    
    // 更新结果（使用乐观锁）
    updateResultWithOptimisticLock(result, executorResults);
    
    // 检查是否所有批量任务都完成
    checkAndUpdateCompletion(resultId);
}

/**
 * 使用乐观锁更新结果
 */
private void updateResultWithOptimisticLock(GeoAnalysisResult result, Map<String, Object> executorResults) {
    String currentResult = result.getResult();
    Map<String, Object> resultMap;
    if (currentResult != null && !currentResult.isEmpty()) {
        resultMap = JsonUtils.jsonToObject(currentResult, new TypeReference<Map<String, Object>>() {});
    } else {
        resultMap = new HashMap<>();
    }
    resultMap.putAll(executorResults);
    
    int rows = resultMapper.updateWithVersion(
        result.getId(),
        result.getVersion(),
        GeoAnalysisResult.STATUS_RUNNING,  // 仍为执行中，等待所有批量任务完成
        result.getParams(),
        JsonUtils.toJson(resultMap)
    );
    
    if (rows > 0) {
        LOG.info("Result {} updated with optimistic lock", result.getId());
    } else {
        LOG.warn("Optimistic lock conflict for result {}", result.getId());
    }
}

/**
 * 检查所有批量任务是否完成
 */
public void checkAndUpdateCompletion(Long resultId) {
    GeoAnalysisResult result = resultMapper.selectById(resultId);
    if (result == null || result.getStatus() == GeoAnalysisResult.STATUS_COMPLETED) {
        return;
    }
    
    // 解析 params 检查所有批量任务状态
    Map<String, Object> paramsMap = JsonUtils.jsonToObject(
        result.getParams(), new TypeReference<Map<String, Object>>() {}
    );
    List<Map<String, Object>> batchTasks = (List<Map<String, Object>>) paramsMap.get("batchTasks");
    
    if (batchTasks == null || batchTasks.isEmpty()) {
        return;
    }
    
    // 检查每个批量任务的状态
    boolean allCompleted = true;
    for (Map<String, Object> batchTask : batchTasks) {
        Long batchTaskId = ((Number) batchTask.get("batchTaskId")).longValue();
        HotWordTask task = hotWordTaskMapper.selectById(batchTaskId);
        if (task == null || task.getStatus() != HotWordTask.STATUS_COMPLETED) {
            allCompleted = false;
            break;
        }
        // 更新 params 中的状态
        batchTask.put("status", "completed");
    }
    
    if (allCompleted) {
        // 更新 params 中的状态
        resultMapper.updateWithVersion(
            result.getId(),
            result.getVersion(),
            GeoAnalysisResult.STATUS_COMPLETED,
            JsonUtils.toJson(paramsMap),
            result.getResult()
        );
        LOG.info("Geo analysis result completed: {}", resultId);
    }
}
```

### 8.5 数据流示例

**批量任务结果结构** (`batchTaskResult`)：

```json
{
  "deepseek": {
    "details": [
      {
        "question": "北京有什么好玩的地方",
        "answer": "北京有很多景点...",
        "references": [
          {"source": "去哪儿", "title": "北京旅游攻略", "url": "...", "snippet": "..."},
          {"source": "携程", "title": "故宫门票", "url": "...", "snippet": "..."}
        ]
      }
    ]
  },
  "qwen": {
    "details": [
      {
        "question": "北京有什么好玩的地方",
        "answer": "推荐以下景点...",
        "references": [...]
      }
    ]
  }
}
```

**Executor 执行结果结构** (`GeoAnalysisResult.result`)：

```json
{
  "城市poi词_executors": [
    {
      "code": "poiSourceMentionExecutor",
      "status": "success",
      "data": {
        "models": { ... },
        "overall": { ... }
      }
    },
    {
      "code": "poiSourceDistributionExecutor",
      "status": "success",
      "data": { ... }
    }
  ],
  "行业词_executors": [
    {
      "code": "industryContentExecutor",
      "status": "success",
      "data": { ... }
    }
  ]
}
```

---

## 九、手动触发接口设计

### 9.1 接口定义

**用途**：针对已完成的 GEO 分析结果记录，手动触发单个 Executor 执行。

**前置条件**：
- GeoAnalysisResult 已创建
- 关联的批量热词分析任务（HotWordTask）已完成，有 successIds

**接口路径**：`POST /api/geo/analysis/result/{resultId}/executor/execute`

**请求参数**：
```json
{
  "type": "城市poi词",        // 必填，热词类型
  "executorCode": "poiSourceMentionExecutor"  // 必填，要执行的 executor
}
```

**响应**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "resultId": 123,
    "type": "城市poi词",
    "executorCode": "poiSourceMentionExecutor",
    "status": "success",
    "data": {
      "models": { ... },
      "overall": { ... }
    },
    "executeTime": 1234,  // 执行耗时(ms)
    "processedCount": 2000,  // 处理的记录数
    "batchCount": 40     // 分批次数
  }
}
```

### 9.2 执行流程

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. 获取 GeoAnalysisResult                                        │
│    - resultMapper.selectById(resultId)                          │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. 解析 params 获取 batchTasks                                   │
│    - params: { batchTasks: [{batchTaskId, type, status}] }      │
│    - 根据 type 找到对应的 batchTaskId                            │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. 获取批量任务信息                                               │
│    - hotWordTaskMapper.selectById(batchTaskId)                  │
│    - 解析 result.successIds                                      │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. 创建 BatchTaskResultProvider                                  │
│    - 传入 successIds + batchSize                                │
│    - 提供分批读取能力                                             │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. 执行 Executor                                                 │
│    - executorFactory.getExecutor(executorCode)                  │
│    - context.setBatchTaskResultProvider(provider)               │
│    - executor.execute(context)                                  │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. 更新 GeoAnalysisResult（可选）                                 │
│    - 将 executor 结果追加到 result.result 字段                   │
│    - 使用乐观锁更新                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 9.3 Controller 实现

```java
@RestController
@RequestMapping("/api/geo/analysis/result")
public class GeoAnalysisController {
    
    /**
     * 手动触发单个 Executor 执行
     * 
     * @param resultId GEO 分析结果 ID
     * @param request 请求参数（type + executorCode）
     */
    @PostMapping("/{resultId}/executor/execute")
    public ApiResponse<Map<String, Object>> executeExecutor(
            @PathVariable Long resultId,
            @RequestBody ExecuteExecutorRequest request) {
        
        Map<String, Object> result = geoAnalysisResultService.executeExecutor(
            resultId, 
            request.getType(), 
            request.getExecutorCode()
        );
        return ApiResponse.success(result);
    }
}

@Data
public class ExecuteExecutorRequest {
    @NotBlank(message = "type 不能为空")
    private String type;  // 热词类型：城市poi词、行业词
    
    @NotBlank(message = "executorCode 不能为空")
    private String executorCode;  // 执行器代码
}
```

### 9.4 Service 实现

```java
/**
 * 手动触发单个 Executor 执行
 */
public Map<String, Object> executeExecutor(Long resultId, String type, String executorCode) {
    // 1. 获取 GeoAnalysisResult
    GeoAnalysisResult result = resultMapper.selectById(resultId);
    if (result == null) {
        throw new IllegalArgumentException("Result not found: " + resultId);
    }
    
    // 2. 解析 params 获取 batchTasks，找到对应 type 的 batchTaskId
    Map<String, Object> paramsMap = JsonUtils.jsonToObject(
        result.getParams(), new TypeReference<Map<String, Object>>(){}
    );
    List<Map<String, Object>> batchTasks = (List<Map<String, Object>>) paramsMap.get("batchTasks");
    
    Long batchTaskId = null;
    for (Map<String, Object> batchTask : batchTasks) {
        if (type.equals(batchTask.get("type"))) {
            batchTaskId = ((Number) batchTask.get("batchTaskId")).longValue();
            break;
        }
    }
    
    if (batchTaskId == null) {
        throw new IllegalArgumentException("No batch task found for type: " + type);
    }
    
    // 3. 获取批量任务信息
    HotWordTask batchTask = hotWordTaskMapper.selectById(batchTaskId);
    if (batchTask == null) {
        throw new IllegalArgumentException("Batch task not found: " + batchTaskId);
    }
    
    if (batchTask.getStatus() != HotWordTask.STATUS_COMPLETED) {
        throw new IllegalStateException("Batch task not completed, current status: " + batchTask.getStatus());
    }
    
    // 4. 解析 successIds
    Map<String, Object> batchResult = JsonUtils.jsonToObject(
        batchTask.getResult(), new TypeReference<Map<String, Object>>(){}
    );
    List<Long> successIds = (List<Long>) batchResult.get("successIds");
    
    if (successIds == null || successIds.isEmpty()) {
        throw new IllegalStateException("No successful sub tasks found");
    }
    
    // 5. 创建 BatchTaskResultProvider
    int batchSize = geoAnalysisQConfig.getBatchSize();
    BatchTaskResultProvider provider = new BatchTaskResultProvider(
        successIds, batchSize, hotWordTaskMapper
    );
    
    // 6. 获取 Executor 并执行
    GeoAnalysisExecutor executor = executorFactory.getExecutor(executorCode);
    if (executor == null) {
        throw new IllegalArgumentException("Executor not found: " + executorCode);
    }
    
    GeoAnalysisExecutor.ExecutorContext context = new GeoAnalysisExecutor.ExecutorContext();
    context.setTemplateId(result.getTemplateId());
    context.setResultId(resultId);
    context.setType(type);
    context.setBatchTaskResultProvider(provider);
    
    long startTime = System.currentTimeMillis();
    GeoAnalysisExecutor.ExecutorResult executorResult = executor.execute(context);
    long executeTime = System.currentTimeMillis() - startTime;
    
    // 7. 构建响应
    Map<String, Object> response = new LinkedHashMap<>();
    response.put("resultId", resultId);
    response.put("type", type);
    response.put("executorCode", executorCode);
    response.put("status", executorResult.getStatus());
    response.put("data", executorResult.getData());
    response.put("executeTime", executeTime);
    response.put("processedCount", successIds.size());
    response.put("batchCount", (successIds.size() + batchSize - 1) / batchSize);
    
    if (executorResult.getError() != null) {
        response.put("error", executorResult.getError());
    }
    
    // 8. 可选：更新 GeoAnalysisResult
    updateExecutorResult(result, type, executorCode, executorResult);
    
    return response;
}

/**
 * 更新 Executor 执行结果到 GeoAnalysisResult
 */
private void updateExecutorResult(GeoAnalysisResult result, String type, 
        String executorCode, GeoAnalysisExecutor.ExecutorResult executorResult) {
    
    String currentResult = result.getResult();
    Map<String, Object> resultMap;
    if (StringUtils.isNotBlank(currentResult)) {
        resultMap = JsonUtils.jsonToObject(currentResult, new TypeReference<Map<String, Object>>(){});
    } else {
        resultMap = new LinkedHashMap<>();
    }
    
    // 更新或追加 executor 结果
    String key = type + "_executors";
    List<Map<String, Object>> executorResults = (List<Map<String, Object>>) resultMap.get(key);
    if (executorResults == null) {
        executorResults = new ArrayList<>();
        resultMap.put(key, executorResults);
    }
    
    // 查找是否已存在该 executor 的结果
    boolean found = false;
    for (int i = 0; i < executorResults.size(); i++) {
        if (executorCode.equals(executorResults.get(i).get("code"))) {
            executorResults.set(i, buildExecutorResultMap(executorResult));
            found = true;
            break;
        }
    }
    if (!found) {
        executorResults.add(buildExecutorResultMap(executorResult));
    }
    
    // 乐观锁更新
    resultMapper.updateWithVersion(
        result.getId(),
        result.getVersion(),
        result.getStatus(),
        result.getParams(),
        JsonUtils.toJson(resultMap)
    );
}

private Map<String, Object> buildExecutorResultMap(GeoAnalysisExecutor.ExecutorResult executorResult) {
    Map<String, Object> map = new LinkedHashMap<>();
    map.put("code", executorResult.getCode());
    map.put("status", executorResult.getStatus());
    map.put("data", executorResult.getData());
    if (executorResult.getError() != null) {
        map.put("error", executorResult.getError());
    }
    return map;
}
```

---

## 十、Executor 批量处理逻辑设计

### 10.1 问题背景

一个批量任务可能包含大量子任务（如 4000 条），直接一次性加载所有结果会导致：
- 内存压力过大
- 数据库查询超时
- 处理时间过长

### 10.2 分批读取策略

```
HotWordTask (TYPE_BATCH_ANALYSIS)
├── result.subTaskIds: [1, 2, 3, ..., 4000]
├── result.successIds: [1, 3, 5, ..., 2000]  // 成功的子任务
└── result.failedIds: [2, 4, ...]            // 失败的子任务

分批读取策略：
1. 按 batchSize=50 分批读取 successIds
2. 每批读取后立即处理，聚合到内存
3. 最终输出聚合结果
```

### 10.3 批量结果聚合结构

**内存中的聚合结构**：

```java
// 按模型分组的聚合器
Map<String, ModelAggregator> modelAggregators = new HashMap<>();

class ModelAggregator {
    String modelName;
    List<Map<String, Object>> details = new ArrayList<>();
    
    // 流式添加，控制内存
    void addDetails(List<Map<String, Object>> batch) {
        details.addAll(batch);
    }
}
```

### 10.4 Executor 批量处理接口

```java
/**
 * GEO 分析执行器接口（支持批量处理）
 */
public interface GeoAnalysisExecutor {
    
    String getCode();
    
    /**
     * 执行分析
     * @param context 包含 BatchTaskResultProvider（惰性加载）
     */
    ExecutorResult execute(ExecutorContext context);
    
    /**
     * 批量处理上下文
     */
    class ExecutorContext {
        private Long templateId;
        private Long resultId;
        private String type;
        private BatchTaskResultProvider batchTaskResultProvider;  // 新增：惰性加载提供者
        private Map<String, Object> executorParams;
    }
}
```

### 10.5 批量任务结果提供者

```java
/**
 * 批量任务结果提供者
 * 支持分批读取，惰性加载
 */
public class BatchTaskResultProvider {
    
    private final List<Long> successIds;  // 所有成功的子任务 ID
    private final int batchSize;          // 每批大小，默认 50
    private final HotWordTaskMapper taskMapper;
    
    /**
     * 流式处理所有成功的子任务
     * @param consumer 每批数据的消费者
     */
    public void forEachBatch(BatchConsumer consumer) {
        int total = successIds.size();
        for (int offset = 0; offset < total; offset += batchSize) {
            int end = Math.min(offset + batchSize, total);
            List<Long> batchIds = successIds.subList(offset, end);
            
            // 查询这批子任务
            List<HotWordTask> tasks = taskMapper.selectByIds(batchIds, batchSize);
            
            // 解析并按模型分组
            Map<String, List<HotWordAnalysisResult>> batchByModel = new HashMap<>();
            for (HotWordTask task : tasks) {
                String model = task.getModel();
                List<HotWordAnalysisResult> results = parseTaskResult(task.getResult());
                batchByModel.computeIfAbsent(model, k -> new ArrayList<>()).addAll(results);
            }
            
            // 回调消费者处理这批数据
            consumer.accept(batchByModel, offset, end, total);
        }
    }
    
    /**
     * 解析子任务 result 字段
     */
    private List<HotWordAnalysisResult> parseTaskResult(String resultJson) {
        if (StringUtils.isBlank(resultJson)) {
            return Collections.emptyList();
        }
        try {
            return JsonUtils.jsonToObject(resultJson, 
                new TypeReference<List<HotWordAnalysisResult>>() {});
        } catch (Exception e) {
            log.warn("Failed to parse task result", e);
            return Collections.emptyList();
        }
    }
    
    @FunctionalInterface
    public interface BatchConsumer {
        /**
         * 处理一批数据
         * @param batchByModel 按模型分组的本批数据
         * @param offset 当前批次起始位置
         * @param end 当前批次结束位置
         * @param total 总记录数
         */
        void accept(Map<String, List<HotWordAnalysisResult>> batchByModel, 
                    int offset, int end, int total);
    }
}
```

### 10.6 Executor 使用示例

**PoiSourceMentionExecutor 批量处理实现**：

```java
@Override
public ExecutorResult execute(ExecutorContext context) {
    BatchTaskResultProvider provider = context.getBatchTaskResultProvider();
    List<String> brands = geoAnalysisQConfig.getBrands();
    
    // 聚合结果
    Map<String, ModelMentionAggregator> aggregators = new HashMap<>();
    
    // 分批处理
    provider.forEachBatch((batchByModel, offset, end, total) -> {
        LOG.info("Processing batch {}-{} / {}", offset, end, total);
        
        for (Map.Entry<String, List<HotWordAnalysisResult>> entry : batchByModel.entrySet()) {
            String modelCode = entry.getKey();
            List<HotWordAnalysisResult> results = entry.getValue();
            
            // 获取或创建该模型的聚合器
            ModelMentionAggregator aggregator = aggregators.computeIfAbsent(
                modelCode, k -> new ModelMentionAggregator(modelCode, brands)
            );
            
            // 处理这批数据
            for (HotWordAnalysisResult result : results) {
                aggregator.processResult(result, brands, this);
            }
        }
    });
    
    // 计算最终结果
    Map<String, Object> result = calculateFinalResult(aggregators);
    
    return ExecutorResult.success(getCode(), result);
}

/**
 * 单模型聚合器
 */
class ModelMentionAggregator {
    String modelCode;
    int totalQuestions = 0;
    Map<String, Integer> brandMentionCounts = new HashMap<>();  // brand -> count
    
    void processResult(HotWordAnalysisResult result, List<String> brands, 
                       BaseGeoAnalysisExecutor executor) {
        List<Reference> references = result.getReferences();
        if (references == null || references.isEmpty()) {
            return;
        }
        
        totalQuestions++;
        
        // 检查每个品牌是否被引用
        for (String brand : brands) {
            for (Reference ref : references) {
                String siteName = ref.getSource();
                if (executor.isBrandInSource(siteName, brand)) {
                    brandMentionCounts.merge(brand, 1, Integer::sum);
                    break;  // 一个问题只算一次
                }
            }
        }
    }
    
    ModelMentionResult toResult() {
        ModelMentionResult result = new ModelMentionResult();
        result.setTotalQuestions(totalQuestions);
        for (String brand : brandMentionCounts.keySet()) {
            int count = brandMentionCounts.get(brand);
            double rate = totalQuestions > 0 ? (double) count / totalQuestions : 0;
            result.getBrands().put(brand, new BrandMentionStat(count, totalQuestions, rate));
        }
        return result;
    }
}
```

### 10.7 分批读取配置化

```java
// QConfig 配置
{
  "batchSize": 50,          // 每批读取条数
  "maxMemoryMB": 256,       // 最大内存限制（预留）
  "progressLogInterval": 5  // 每处理几批打印一次日志
}

// GeoAnalysisQConfig 新增
public int getBatchSize() {
    return hotFileQConfig.getInt("geo.executor.batch.size", 50);
}
```

### 10.8 处理流程图

```
┌─────────────────────────────────────────────────────────────────┐
│ Executor.execute(context)                                       │
│   ↓                                                             │
│ BatchTaskResultProvider.forEachBatch(consumer)                  │
│   ↓                                                             │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Batch 1: IDs [0-49]                                         │ │
│ │   - 查询数据库 → List<HotWordTask>                          │ │
│ │   - 解析 result → Map<model, List<details>>                 │ │
│ │   - 聚合器处理 → ModelMentionAggregator.processDetail()      │ │
│ └─────────────────────────────────────────────────────────────┘ │
│   ↓                                                             │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Batch 2: IDs [50-99]                                        │ │
│ │   - ...                                                     │ │
│ └─────────────────────────────────────────────────────────────┘ │
│   ↓                                                             │
│ ... 重复直到处理完所有批次                                       │
│   ↓                                                             │
│ 计算最终结果                                                     │
│   - 遍历所有 ModelMentionAggregator                             │
│   - 计算 rate、加权总体等                                        │
│   ↓                                                             │
│ 返回 ExecutorResult                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 十一、待确认事项

1. **排名行业词区分**：当前方案是通过文件名/任务名判断，是否需要在模板配置中显式指定"是否排名行业词"？

2. **数据字段名**：确认 `references` 字段名是否正确（Python 脚本中用 `sources_found`）→ **已确认使用 `references`**

3. **长尾信源统计**：是否需要增加一个 Executor 统计"其他长尾"类别中各网站的详细分布？
