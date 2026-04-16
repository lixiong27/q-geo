# 周维度 Executor 重构方案

## 需求概述

**需求名称**：三个周维度 Executor 重构
**创建日期**：2026-04-17
**负责人**：AI

## 问题分析

对比预期 Excel 输出和当前实现，发现以下问题：

### 1. weeklyIndustryAnalysisExecutor

| 问题 | 预期 | 当前实现 |
|------|------|----------|
| 品牌顺序 | 从 QConfig brands 字段顺序读取 | 动态提取，无固定顺序 |
| 模型来源 | HotWordTask.model + modelNameMap 映射 | 动态提取 |
| 内容提及率格式 | 统一格式（小数或百分比） | 混合格式（有的列小数，有的列百分比） |
| 第1名次数格式 | "3/75" 格式 | 被转换为百分比 |

### 2. weeklyIndustrySourceDistributionExecutor

| 问题 | 预期 | 当前实现 |
|------|------|----------|
| 表头结构 | 简单两行，信源类型为行 | 按维度嵌套输出 |
| 数据格式 | 小数 (0.2541) | 需确认 |

### 3. weeklyPoiSourceDistributionExecutor

| 问题 | 预期 | 当前实现 |
|------|------|----------|
| 品牌顺序 | 从 QConfig brands 字段顺序读取 | 动态提取 |
| 模型来源 | HotWordTask.model + modelNameMap 映射 | 动态提取 |

## 配置来源

| 配置项 | 来源 | 说明 |
|--------|------|------|
| 品牌列表 | `GeoAnalysisQConfig.getBrands()` | 从 QConfig geo_analysis_config.json 读取 |
| 品牌同义词 | `GeoAnalysisQConfig.getBrandSynonyms()` | 用于匹配答案中的品牌 |
| 模型显示名 | `GeoAnalysisQConfig.getModelDisplayName(modelCode)` | modelCode 来自 `HotWordTask.model` |
| 信源分类 | `GeoAnalysisQConfig.getSourceCategories()` | 信源分类列表 |

## 预期 Excel 格式

### weeklyIndustryAnalysisExecutor

```
Row 1: 行业词 | 去哪儿(合并4列) | 同程(合并4列) | 携程(合并4列) | 飞猪(合并4列) | 美团(合并4列)
Row 2: 指标   | DeepSeek | 豆包 | 通义千问 | 元宝 | DeepSeek | 豆包 | ...
Row 3+: 维度  | 内容提及率 | 数据...
       (空)   | 平均排名   | 数据...
       (空)   | 第1名次数  | 数据...
```

示例数据：
```
综合数据 (Overall) | 内容提及率 | 0.907 | 0.973 | 0.973 | 0.84  | ...
                   | 平均排名   | 3.8   | 3.2   | 4.5   | 3.8   | ...
                   | 第1名次数  | 3/75  | 6/75  | 0/75  | 1/75  | ...
```

### weeklyIndustrySourceDistributionExecutor

```
Row 1: 城市poi词（或其他标题）
Row 2: 信源类型 | 总体 | 加权总体 | DeepSeek | 豆包 | 通义千问 | 元宝
Row 3+: 新闻媒体/门户 | 0.2541 | 0.2914 | 0.1877 | 0.325 | 0.3678 | 0.1849
       OTA/旅行平台  | 0.3009 | 0.2742 | 0.2521 | 0.325 | 0.2093 | 0.4084
       ...
```

### weeklyPoiSourceDistributionExecutor

```
Row 1: 城市poi词 | 去哪儿(合并4列) | 携程(合并4列) | 同程(合并4列) | 飞猪(合并4列) | 美团(合并4列)
Row 2: 指标     | DeepSeek | 豆包 | 通义千问 | 元宝 | DeepSeek | ...
Row 3+: 综合数据 | 信源提及率 | 数据...
       1.城市线路攻略类(Overall) | 信源提及率 | 数据...
       ...
```

## 重构方案

### 数据结构重构

#### WeeklyIndustryAnalysisResult.java

修改为矩阵结构，支持按品牌->模型组织数据：

```java
@Data
public class WeeklyIndustryAnalysisResult {
    // 维度名称
    private String dimension;

    // 品牌维度 -> 模型 -> 指标数据（使用有序 Map 保证顺序）
    private Map<String, Map<String, MetricData>> brandModelData;

    @Data
    public static class MetricData {
        private double mentionRate;      // 内容提及率
        private double avgRank;          // 平均排名
        private String firstRankCount;   // 第1名次数，格式 "3/75"
    }
}
```

#### WeeklySourceDistributionResult.java

简化为单层结构，按信源类型组织：

```java
@Data
public class WeeklySourceDistributionResult {
    // 标题
    private String title;

    // 信源分类 -> 各模型占比
    private Map<String, CategoryData> categoryData;

    @Data
    public static class CategoryData {
        private double overallRate;          // 总体占比
        private double weightedOverallRate;  // 加权总体占比
        private Map<String, Double> modelRates; // model -> rate
    }
}
```

#### WeeklyPoiSourceDistributionResult.java

矩阵结构，支持按品牌->模型组织数据：

```java
@Data
public class WeeklyPoiSourceDistributionResult {
    // 维度列表（综合数据 + 各分类维度）
    private List<DimensionData> dimensions;

    @Data
    public static class DimensionData {
        private String dimension;            // 维度名称
        private Map<String, Map<String, Double>> brandModelRates;
        // brandModelRates: brand -> model -> sourceMentionRate
    }
}
```

### Executor 重构要点

#### 公共原则

1. **品牌**：从 `GeoAnalysisQConfig.getBrands()` 获取，保证顺序
2. **模型**：从任务中提取，通过 `getModelDisplayName()` 转换，按 modelNameMap 的顺序输出
3. **数据格式**：统一使用小数，Excel 导出时按需格式化
4. **维度**：第一个 tag 的 tagDesc（QConfig 无匹配则用 tagCode）

#### weeklyIndustryAnalysisExecutor

1. 读取品牌列表：`geoAnalysisQConfig.getBrands()`
2. 读取品牌同义词：`geoAnalysisQConfig.getBrandSynonyms()`
3. 从任务中提取 model，转换显示名
4. 按 brand -> model 组织数据
5. 输出包含：综合数据 + 各维度数据
6. 第1名次数保持 "x/y" 格式

#### weeklyIndustrySourceDistributionExecutor

1. 读取信源分类：`geoAnalysisQConfig.getSourceCategories()`
2. 按信源类型组织数据
3. 输出：信源类型 | 总体 | 加权总体 | 各模型占比
4. 数据格式统一为小数

#### weeklyPoiSourceDistributionExecutor

1. 读取品牌列表
2. 按 brand -> model 组织数据
3. 输出：综合数据 + 各维度数据
4. 数据格式统一为小数

### Excel 导出重构

#### 关键改动

1. **品牌顺序**：从 QConfig brands 字段获取
2. **模型顺序**：从 QConfig modelNameMap 获取（保持配置顺序）
3. **数据格式化**：在导出时处理，不在 Executor 中处理
4. **第1名次数**：保持 "x/y" 格式，不转换为百分比

## 更改点清单

### 后端文件修改

| 文件 | 操作 | 说明 |
|------|------|------|
| `WeeklyIndustryAnalysisResult.java` | 修改 | 改为矩阵结构 |
| `WeeklySourceDistributionResult.java` | 修改 | 简化为单层结构 |
| `WeeklyPoiSourceDistributionResult.java` | 修改 | 改为矩阵结构 |
| `WeeklyIndustryAnalysisExecutor.java` | 重构 | 使用 QConfig 配置，按 brand->model 组织数据 |
| `WeeklyIndustrySourceDistributionExecutor.java` | 重构 | 简化输出结构 |
| `WeeklyPoiSourceDistributionExecutor.java` | 重构 | 使用 QConfig 配置，按 brand->model 组织数据 |
| `WeeklyIndustryAnalysisExcelExporter.java` | 重构 | 适配新数据结构，统一格式化 |

### Excel 导出格式

| Executor | 格式化规则 |
|----------|-----------|
| weeklyIndustryAnalysis | 内容提及率：小数或百分比统一；平均排名：保留2位小数；第1名次数：x/y 格式 |
| weeklyIndustrySourceDistribution | 所有占比：小数格式 |
| weeklyPoiSourceDistribution | 信源提及率：小数格式 |

## 确认结论

| 问题 | 结论 |
|------|------|
| 内容提及率格式 | 小数形式（如 0.907） |
| 标题行 | 默认"城市poi词" |
| weeklyIndustrySourceDistribution 综合数据行 | 不需要，只输出各信源类型 |
| weeklyPoiSourceDistribution 品牌维度 | 从热词答案中提取品牌排名（使用 brandSynonyms），按品牌分组统计信源分布 |
| 模型顺序 | 严格按 QConfig modelNameMap 配置顺序 |
| weeklyIndustrySourceDistribution 维度处理 | 最终 excel 只需要一个汇总表格 |

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-17 | 创建方案文档 | 已完成 |
| 2026-04-17 | 补充待确认问题 | 已完成 |

## 下一步行动

1. 用户回答待确认问题
2. 根据回答完善方案
3. 开始重构实现
