# 进度追踪

## 需求概述

**需求名称**：Executor 参数对象化优化 + 周维度行业词分析 Executor
**创建日期**：2026-04-16
**负责人**：Claude AI

## 当前阶段

**阶段**：技术方案设计，待用户确认

## 需求描述

### 1. 参数对象化优化
- `GeoAnalysisResultService#executeExecutor` 中 params 解析应使用强类型对象
- `DailyPubAnalysisExecutor` 内部使用对象代替 `Map<String, Object>`

### 2. 新增周维度行业词分析 Executor
- 维度 = 第一个 tag 的 tagDesc（QConfig 无匹配则用 tagCode）
- Summary 聚合同类别词（不带 tags 显示）
- 输出格式：
```
维度        平台      模型      内容提及率    平均排名    第1名次数
总体        去哪儿    DeepSeek  96.00%       1.9         37/75
预订入口类  去哪儿    DeepSeek  96.67%       2.59        7/30
```

## 现有逻辑分析

### GeoAnalysisResultService#executeExecutor
- 解析 `task.getParams()` 使用 `Map<String, Object>`
- 类型不安全，需要运行时类型转换
- 代码可读性差

### DailyPubAnalysisExecutor#processTask
- 同样使用 `Map<String, Object>` 解析 params
- 获取 hotwordId 需要 `((Number) hotwordIdObj).longValue()` 强转

### ExecutorContext 结构
```java
class ExecutorContext {
    private Long templateId;
    private Long resultId;
    private String type;
    private Map<String, Object> analysisTaskParam;
    private Map<String, Object> batchTaskResult;
    private BatchTaskResultProvider batchTaskResultProvider;
    private Map<String, Object> executorParams;
}
```

## 技术方案

### 1. 新增参数实体类

#### GeoAnalysisResultParams.java
```java
package com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.geo.analysis;

import lombok.Data;
import java.util.List;

/**
 * GEO 分析结果参数
 * 用于解析 GeoAnalysisResult.params 字段
 */
@Data
public class GeoAnalysisResultParams {
    /**
     * 批量任务列表
     */
    private List<BatchTaskInfo> batchTasks;

    /**
     * 模板名称
     */
    private String templateName;

    /**
     * 优先级
     */
    private Integer priority;
}
```

#### BatchTaskInfo.java
```java
package com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.geo.analysis;

import lombok.Data;
import java.util.List;

/**
 * 批量任务信息
 */
@Data
public class BatchTaskInfo {
    /**
     * 热词类型
     */
    private String type;

    /**
     * 模型列表
     */
    private List<String> models;

    /**
     * 批量任务ID
     */
    private Long batchTaskId;

    /**
     * 状态
     */
    private String status;
}
```

#### HotWordTaskParams.java
```java
package com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword;

import lombok.Data;

/**
 * 热词任务参数
 * 用于解析 HotWordTask.params 字段
 */
@Data
public class HotWordTaskParams {
    /**
     * 关联热词ID
     */
    private Long hotwordId;

    /**
     * 热词名称
     */
    private String hotwordName;

    /**
     * 批量任务ID
     */
    private Long batchTaskId;
}
```

### 2. 修改 GeoAnalysisResultService#triggerExecution

**优化前**：
```java
List<Map<String, Object>> batchTasks = new ArrayList<>();

for (Map<String, Object> group : groups) {
    // ...
    Map<String, Object> batchTaskInfo = new HashMap<>();
    batchTaskInfo.put("type", type);
    batchTaskInfo.put("models", models);
    batchTaskInfo.put("batchTaskId", batchTask.getId());
    batchTaskInfo.put("status", "running");
    batchTasks.add(batchTaskInfo);
}

Map<String, Object> paramsMap = new HashMap<>();
paramsMap.put("batchTasks", batchTasks);
paramsMap.put("templateName", template.getName());
paramsMap.put("priority", priority);
result.setParams(JsonUtils.toJson(paramsMap));
```

**优化后**：
```java
List<BatchTaskInfo> batchTasks = new ArrayList<>();

for (Map<String, Object> group : groups) {
    // ...
    BatchTaskInfo batchTaskInfo = new BatchTaskInfo();
    batchTaskInfo.setType(type);
    batchTaskInfo.setModels(models);
    batchTaskInfo.setBatchTaskId(batchTask.getId());
    batchTaskInfo.setStatus("running");
    batchTasks.add(batchTaskInfo);
}

GeoAnalysisResultParams params = new GeoAnalysisResultParams();
params.setBatchTasks(batchTasks);
params.setTemplateName(template.getName());
params.setPriority(priority);
result.setParams(JsonUtils.toJson(params));
```

### 3. 修改 GeoAnalysisResultService#executeExecutor

**优化前**：
```java
Map<String, Object> paramsMap = JsonUtils.jsonToObject(
    result.getParams(), new TypeReference<Map<String, Object>>(){}
);
List<Map<String, Object>> batchTasks = (List<Map<String, Object>>) paramsMap.get("batchTasks");

Long batchTaskId = null;
for (Map<String, Object> batchTask : batchTasks) {
    if (type.equals(batchTask.get("type"))) {
        Object idObj = batchTask.get("batchTaskId");
        if (idObj instanceof Number) {
            batchTaskId = ((Number) idObj).longValue();
        }
        break;
    }
}
```

**优化后**：
```java
GeoAnalysisResultParams params = JsonUtils.jsonToObject(
    result.getParams(), new TypeReference<GeoAnalysisResultParams>(){}
);
if (params == null || CollectionUtils.isEmpty(params.getBatchTasks())) {
    throw new IllegalArgumentException("Result params is empty or has no batch tasks");
}

Long batchTaskId = params.getBatchTasks().stream()
    .filter(task -> type.equals(task.getType()))
    .map(BatchTaskInfo::getBatchTaskId)
    .findFirst()
    .orElse(null);
```

### 4. 修改 GeoAnalysisResultService#checkAndUpdateCompletion

**优化前**：
```java
Map<String, Object> paramsMap = JsonUtils.jsonToObject(
    result.getParams(),
    new TypeReference<Map<String, Object>>() {}
);
List<Map<String, Object>> batchTasks = (List<Map<String, Object>>) paramsMap.get("batchTasks");

boolean allCompleted = batchTasks.stream()
    .allMatch(task -> "completed".equals(task.get("status")));
```

**优化后**：
```java
GeoAnalysisResultParams params = JsonUtils.jsonToObject(
    result.getParams(),
    new TypeReference<GeoAnalysisResultParams>() {}
);
if (params == null || CollectionUtils.isEmpty(params.getBatchTasks())) {
    return;
}

boolean allCompleted = params.getBatchTasks().stream()
    .allMatch(task -> "completed".equals(task.getStatus()));
```

### 5. 修改 DailyPubAnalysisExecutor

**优化前**：
```java
Map<String, Object> params = JsonUtils.jsonToObject(
    task.getParams(), new TypeReference<Map<String, Object>>(){});
Object hotwordIdObj = params.get("hotwordId");
if (hotwordIdObj == null) return null;
Long hotwordId = ((Number) hotwordIdObj).longValue();
```

**优化后**：
```java
HotWordTaskParams params = JsonUtils.jsonToObject(
    task.getParams(), new TypeReference<HotWordTaskParams>(){});
if (params == null || params.getHotwordId() == null) return null;
Long hotwordId = params.getHotwordId();
```

### 4. 新增 WeeklyIndustryAnalysisExecutor

#### 4.1 实体类

**WeeklyIndustryAnalysisResult.java**
```java
package com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.geo.analysis;

import lombok.Data;
import java.util.List;

/**
 * 周维度行业词分析结果
 */
@Data
public class WeeklyIndustryAnalysisResult {

    /**
     * 维度（来自第一个 tag 的 tagDesc 或 tagCode）
     */
    private String dimension;

    /**
     * 平台
     */
    private String platform;

    /**
     * 模型
     */
    private String model;

    /**
     * 内容提及率
     */
    private double mentionRate;

    /**
     * 平均排名
     */
    private double avgRank;

    /**
     * 第1名次数（格式：7/30 表示 30 次中出现 7 次第1名）
     */
    private String firstRankCount;

    /**
     * 该维度下的热词列表（用于汇总）
     */
    private List<String> hotwords;
}
```

#### 4.2 Executor 实现

**WeeklyIndustryAnalysisExecutor.java**
```java
package com.qunar.ug.flight.contact.ares.analysisterm.service.geo.analysis.executor;

import com.fasterxml.jackson.core.type.TypeReference;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.geo.analysis.WeeklyIndustryAnalysisResult;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWord;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordAnalysisResult;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordTask;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordTaskParams;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.TagConfig;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.dao.hotword.HotWordMapper;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.qconfig.HotWordQConfig;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.qconfig.GeoAnalysisQConfig;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.util.JsonUtils;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 周维度行业词分析执行器
 * 按热词标签维度和品牌维度汇总分析结果
 */
@Slf4j
@Service("weeklyIndustryAnalysisExecutor")
public class WeeklyIndustryAnalysisExecutor extends BaseGeoAnalysisExecutor {

    @Resource
    private HotWordMapper hotWordMapper;

    @Resource
    private HotWordQConfig hotWordQConfig;

    @Resource
    private GeoAnalysisQConfig geoAnalysisQConfig;

    @Override
    public String getCode() {
        return "weeklyIndustryAnalysisExecutor";
    }

    @Override
    public ExecutorResult execute(ExecutorContext context) {
        try {
            BatchTaskResultProvider provider = context.getBatchTaskResultProvider();
            if (provider == null) {
                return ExecutorResult.fail(getCode(), "No batch task result provider");
            }

            // 获取品牌配置
            List<String> brands = geoAnalysisQConfig.getBrands();
            Map<String, List<String>> brandSynonyms = geoAnalysisQConfig.getBrandSynonyms();

            // 按(维度, 品牌)分组的数据结构
            Map<String, Map<String, List<TaskAnalysisData>>> dimensionBrandDataMap = new LinkedHashMap<>();

            // 分批处理子任务
            provider.forEachBatchWithTask((tasks, offset, end, total) -> {
                for (HotWordTask task : tasks) {
                    TaskAnalysisData data = processTask(task, brands, brandSynonyms);
                    if (data != null) {
                        dimensionBrandDataMap
                            .computeIfAbsent(data.dimension, k -> new LinkedHashMap<>())
                            .computeIfAbsent(data.brand, k -> new ArrayList<>())
                            .add(data);
                    }
                }
            });

            // 生成汇总结果
            List<WeeklyIndustryAnalysisResult> results = generateResults(dimensionBrandDataMap);

            // 计算总体汇总（按品牌）
            List<WeeklyIndustryAnalysisResult> overallResults = calculateOverall(dimensionBrandDataMap);

            Map<String, Object> summary = new LinkedHashMap<>();
            summary.put("overall", overallResults);
            summary.put("dimensions", results);

            log.info("WeeklyIndustryAnalysis completed: {} dimensions, {} total hotwords",
                    results.size(), results.stream().mapToInt(r -> r.getHotwords().size()).sum());

            return ExecutorResult.success(getCode(), summary);
        } catch (Exception e) {
            log.error("WeeklyIndustryAnalysis failed", e);
            return ExecutorResult.fail(getCode(), e.getMessage());
        }
    }

    /**
     * 处理单个子任务
     */
    private TaskAnalysisData processTask(HotWordTask task, List<String> brands,
                                          Map<String, List<String>> brandSynonyms) {
        // 解析 params
        HotWordTaskParams params = JsonUtils.jsonToObject(
                task.getParams(), new TypeReference<HotWordTaskParams>(){});
        if (params == null || params.getHotwordId() == null) {
            return null;
        }

        // 获取热词信息
        HotWord hotWord = hotWordMapper.selectById(params.getHotwordId());
        if (hotWord == null) {
            return null;
        }

        // 解析分析结果
        List<HotWordAnalysisResult> analysisResults = parseTaskResult(task.getResult());
        if (CollectionUtils.isEmpty(analysisResults)) {
            return null;
        }

        HotWordAnalysisResult analysisResult = analysisResults.get(0);

        // 计算维度
        String dimension = getDimensionFromTags(hotWord.getTags());

        // 构建结果数据
        TaskAnalysisData data = new TaskAnalysisData();
        data.dimension = dimension;
        data.hotwordName = hotWord.getWord();
        data.model = task.getModel();
        data.answer = analysisResult.getAnswer();

        // 计算各品牌排名
        data.brandRanks = calculateBrandRanks(analysisResult.getAnswer(), brands, brandSynonyms);

        return data;
    }

    /**
     * 计算各品牌在答案中的排名
     * @return Map<brand, rank> rank从1开始，-1表示未出现
     */
    private Map<String, Integer> calculateBrandRanks(String answer, List<String> brands,
                                                      Map<String, List<String>> brandSynonyms) {
        Map<String, Integer> brandRanks = new LinkedHashMap<>();
        if (StringUtils.isBlank(answer)) {
            for (String brand : brands) {
                brandRanks.put(brand, -1);
            }
            return brandRanks;
        }

        // 找出答案中品牌出现的顺序
        List<BrandPosition> positions = new ArrayList<>();
        for (String brand : brands) {
            List<String> keywords = brandSynonyms.getOrDefault(brand, Collections.singletonList(brand));
            int pos = findFirstPosition(answer, keywords);
            if (pos >= 0) {
                positions.add(new BrandPosition(brand, pos));
            }
        }

        // 按位置排序
        positions.sort(Comparator.comparingInt(p -> p.position));

        // 分配排名
        int rank = 1;
        for (BrandPosition bp : positions) {
            brandRanks.put(bp.brand, rank++);
        }

        // 未出现的品牌排名为-1
        for (String brand : brands) {
            if (!brandRanks.containsKey(brand)) {
                brandRanks.put(brand, -1);
            }
        }

        return brandRanks;
    }

    /**
     * 查找关键词列表在文本中首次出现的位置
     */
    private int findFirstPosition(String text, List<String> keywords) {
        int minPos = -1;
        String lowerText = text.toLowerCase();
        for (String keyword : keywords) {
            int pos = lowerText.indexOf(keyword.toLowerCase());
            if (pos >= 0 && (minPos < 0 || pos < minPos)) {
                minPos = pos;
            }
        }
        return minPos;
    }

    /**
     * 根据 tags 获取维度名称
     * 维度 = 第一个 tag 的 tagDesc（QConfig 无匹配则用 tagCode）
     */
    private String getDimensionFromTags(String tags) {
        if (StringUtils.isBlank(tags)) {
            return "其他";
        }

        // 解析第一个 tag
        String firstTag = Arrays.stream(tags.split(","))
                .map(String::trim)
                .filter(StringUtils::isNotBlank)
                .findFirst()
                .orElse(null);

        if (firstTag == null) {
            return "其他";
        }

        // 从 QConfig 查找 tagDesc
        List<TagConfig> tagConfigs = hotWordQConfig.getTagList();
        for (TagConfig config : tagConfigs) {
            if (firstTag.equals(config.getTagCode())) {
                return StringUtils.isNotBlank(config.getTagDesc()) ? config.getTagDesc() : firstTag;
            }
        }

        // QConfig 无匹配，返回 tagCode
        return firstTag;
    }

    /**
     * 生成各维度+品牌汇总结果
     */
    private List<WeeklyIndustryAnalysisResult> generateResults(
            Map<String, Map<String, List<TaskAnalysisData>>> dimensionBrandDataMap) {

        List<WeeklyIndustryAnalysisResult> results = new ArrayList<>();

        for (Map.Entry<String, Map<String, List<TaskAnalysisData>>> dimEntry : dimensionBrandDataMap.entrySet()) {
            String dimension = dimEntry.getKey();
            Map<String, List<TaskAnalysisData>> brandDataMap = dimEntry.getValue();

            for (Map.Entry<String, List<TaskAnalysisData>> brandEntry : brandDataMap.entrySet()) {
                String brand = brandEntry.getKey();
                List<TaskAnalysisData> dataList = brandEntry.getValue();

                WeeklyIndustryAnalysisResult result = buildResult(dimension, brand, dataList);
                results.add(result);
            }
        }

        return results;
    }

    /**
     * 计算总体汇总（按品牌）
     */
    private List<WeeklyIndustryAnalysisResult> calculateOverall(
            Map<String, Map<String, List<TaskAnalysisData>>> dimensionBrandDataMap) {

        List<WeeklyIndustryAnalysisResult> overallResults = new ArrayList<>();

        // 按品牌汇总所有维度的数据
        Map<String, List<TaskAnalysisData>> brandAllDataMap = new LinkedHashMap<>();
        for (Map<String, List<TaskAnalysisData>> brandDataMap : dimensionBrandDataMap.values()) {
            for (Map.Entry<String, List<TaskAnalysisData>> entry : brandDataMap.entrySet()) {
                brandAllDataMap.computeIfAbsent(entry.getKey(), k -> new ArrayList<>())
                        .addAll(entry.getValue());
            }
        }

        // 生成各品牌总体结果
        for (Map.Entry<String, List<TaskAnalysisData>> entry : brandAllDataMap.entrySet()) {
            WeeklyIndustryAnalysisResult result = buildResult("总体", entry.getKey(), entry.getValue());
            overallResults.add(result);
        }

        return overallResults;
    }

    /**
     * 构建单条结果
     */
    private WeeklyIndustryAnalysisResult buildResult(String dimension, String brand,
                                                      List<TaskAnalysisData> dataList) {
        WeeklyIndustryAnalysisResult result = new WeeklyIndustryAnalysisResult();
        result.setDimension(dimension);
        result.setPlatform(brand);
        result.setModel(getMostFrequentModel(dataList));

        int total = dataList.size();

        // 计算内容提及率（品牌出现在答案中）
        int mentionCount = (int) dataList.stream()
                .filter(d -> d.brandRanks.getOrDefault(brand, -1) >= 0)
                .count();
        result.setMentionRate(total > 0 ? (mentionCount * 100.0 / total) : 0);

        // 计算平均排名（仅计算有排名的）
        List<Integer> ranks = dataList.stream()
                .map(d -> d.brandRanks.getOrDefault(brand, -1))
                .filter(r -> r > 0)
                .collect(Collectors.toList());
        double avgRank = ranks.isEmpty() ? 0 :
                ranks.stream().mapToInt(Integer::intValue).average().orElse(0);
        result.setAvgRank(avgRank);

        // 计算第1名次数
        int firstRankCount = (int) dataList.stream()
                .filter(d -> d.brandRanks.getOrDefault(brand, -1) == 1)
                .count();
        result.setFirstRankCount(firstRankCount + "/" + total);

        // 热词列表（不带 tags）
        result.setHotwords(dataList.stream()
                .map(d -> d.hotwordName)
                .distinct()
                .collect(Collectors.toList()));

        return result;
    }

    /**
     * 获取出现频率最高的模型
     */
    private String getMostFrequentModel(List<TaskAnalysisData> dataList) {
        return dataList.stream()
                .collect(Collectors.groupingBy(d -> d.model, Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("Unknown");
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
            log.warn("Failed to parse task result: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 内部数据类
     */
    private static class TaskAnalysisData {
        String dimension;
        String hotwordName;
        String model;
        String answer;
        Map<String, Integer> brandRanks; // 各品牌排名
    }

    private static class BrandPosition {
        String brand;
        int position;

        BrandPosition(String brand, int position) {
            this.brand = brand;
            this.position = position;
        }
    }
}
```

**输出示例**：
```
维度        平台      模型      内容提及率    平均排名    第1名次数
总体        去哪儿    DeepSeek  96.00%       1.9         37/75
总体        携程      DeepSeek  85.00%       2.5         20/75
预订入口类  去哪儿    DeepSeek  96.67%       1.5         10/30
预订入口类  携程      DeepSeek  80.00%       2.8         5/30
```

### 5. 注册新 Executor

**GeoAnalysisExecutorFactory.java** 已有自动注册逻辑，只需确保：
1. `WeeklyIndustryAnalysisExecutor` 添加 `@Service("weeklyIndustryAnalysisExecutor")` 注解
2. 实现 `getCode()` 返回 `"weeklyIndustryAnalysisExecutor"`

## 任务清单

### 参数对象化
- [x] 新增 `GeoAnalysisResultParams.java` 实体类
- [x] 新增 `BatchTaskInfo.java` 实体类
- [x] 新增 `HotWordTaskParams.java` 实体类
- [x] 新增 `BatchTaskResult.java` 实体类
- [x] 修改 `GeoAnalysisResultService#triggerExecution` 使用对象构建 params
- [x] 修改 `GeoAnalysisResultService#executeExecutor` 使用对象解析 params
- [x] 修改 `GeoAnalysisResultService#checkAndUpdateCompletion` 使用对象解析 params
- [x] 修改 `DailyPubAnalysisExecutor#processTask` 使用 `HotWordTaskParams`

### 方法重构
- [x] 拆分 `executeExecutor` 为公开方法和私有方法
- [x] 新增 `ExecutorExecutionResponse.java` 强类型响应
- [x] 更新 `ExecuteExecutorResponse` 使用强类型

### 新增 WeeklyIndustryAnalysisExecutor
- [x] 新增 `WeeklyIndustryAnalysisResult.java` 实体类
- [x] 新增 `WeeklyIndustryAnalysisExecutor.java`
- [x] 实现维度计算逻辑（tagDesc/tagCode）
- [x] 实现汇总计算逻辑

### 新增 WeeklyIndustrySourceDistributionExecutor
- [x] 新增 `WeeklySourceDistributionResult.java` 实体类
- [x] 新增 `SourceCategoryDistribution.java` 实体类
- [x] 新增 `ModelSourceDistribution.java` 实体类
- [x] 新增 `WeeklyIndustrySourceDistributionExecutor.java`
- [x] 按维度统计信源分布，支持强类型输出

### 新增 WeeklyPoiSourceDistributionExecutor
- [x] 新增 `WeeklyPoiSourceDistributionResult.java` 实体类
- [x] 新增 `WeeklyPoiSourceDistributionExecutor.java`
- [x] 输出综合数据 + 各维度数据
- [x] 表格格式：类别(tag) | 模型 | 信源分类占比

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-16 | 需求分析，创建技术文档 | 已完成 |
| 2026-04-16 | 后端开发完成 | 已完成 |
| 2026-04-16 | 方法重构，强类型响应 | 已完成 |
| 2026-04-16 | 新增 WeeklyIndustrySourceDistributionExecutor | 已完成 |
| 2026-04-16 | 新增 WeeklyPoiSourceDistributionExecutor | 已完成 |

## 下一步行动

1. 提交代码（已完成）
2. 集成测试

## 文件清单

| 文件 | 操作 |
|------|------|
| `domain/entity/geo/analysis/GeoAnalysisResultParams.java` | 新增 |
| `domain/entity/geo/analysis/BatchTaskInfo.java` | 新增 |
| `domain/entity/hotword/HotWordTaskParams.java` | 新增 |
| `domain/entity/hotword/BatchTaskResult.java` | 新增 |
| `domain/entity/geo/analysis/WeeklyIndustryAnalysisResult.java` | 新增 |
| `domain/entity/geo/analysis/ExecutorExecutionResponse.java` | 新增 |
| `domain/entity/geo/analysis/response/ExecuteExecutorResponse.java` | 修改 |
| `domain/entity/geo/analysis/WeeklySourceDistributionResult.java` | 新增 |
| `domain/entity/geo/analysis/SourceCategoryDistribution.java` | 新增 |
| `domain/entity/geo/analysis/ModelSourceDistribution.java` | 新增 |
| `domain/entity/geo/analysis/WeeklyPoiSourceDistributionResult.java` | 新增 |
| `service/geo/analysis/executor/WeeklyIndustryAnalysisExecutor.java` | 新增 |
| `service/geo/analysis/executor/WeeklyIndustrySourceDistributionExecutor.java` | 新增 |
| `service/geo/analysis/executor/WeeklyPoiSourceDistributionExecutor.java` | 新增 |
| `service/geo/analysis/executor/DailyPubAnalysisExecutor.java` | 修改 |
| `service/geo/analysis/GeoAnalysisResultService.java` | 修改 |
| `web/GeoAnalysisController.java` | 修改 |

## 注意事项

1. **向后兼容**：`HotWordTaskParams` 字段可以为空，解析失败返回 null
2. **QConfig 查询**：使用 `HotWordQConfig#getTagList()` 获取标签配置
3. **维度排序**：结果按维度名称排序，"总体"始终在第一位
