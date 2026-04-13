# DailyPubAnalysisExecutor 设计文档

## 1. 概述

### 1.1 功能描述

DailyPubAnalysisExecutor 用于分析每条热词的匹配情况，产出以下指标：
- 热词对应的活动是否在答案/引用中出现
- "去哪儿"品牌是否在答案/引用中出现
- "去哪儿"在答案品牌出现顺序中的排名

### 1.2 输出示例

```json
[
  {
    "hotwordName": "哪里的机票便宜",
    "answerHasAct": true,
    "referHasAct": true,
    "answerHasQ": true,
    "rankDetail": {
      "rank": 1,
      "detail": ["去哪儿", "携程", "飞猪"]
    },
    "referHasQ": true
  }
]
```

## 2. 配置设计

### 2.1 活动映射配置

**配置位置**：HotFileQConfig（hotfile.properties）

**配置格式**：
```properties
# 前缀：dailyPubAnalysisExecutor_{tag} = 活动名称
dailyPubAnalysisExecutor_tagA=免费机票活动
dailyPubAnalysisExecutor_tagB=特价促销
dailyPubAnalysisExecutor_春节=春节大促
```

**获取逻辑**：
1. 从热词获取第一个 tag
2. 拼接 key：`dailyPubAnalysisExecutor_{tag}`
3. 从 HotFileQConfig 获取活动名称
4. 如果活动名称为空，answerHasAct 和 referHasAct 均为 false

### 2.2 去哪儿关键词配置

**配置位置**：GeoAnalysisQConfig（geo_analysis_config.json）

**配置格式**：
```json
{
  "qunarKeywords": ["去哪儿", "qunar"]
}
```

**匹配规则**：不区分大小写

### 2.3 Executor 类型限制

**配置位置**：geo_analysis_executor_config.json

**配置格式**：
```json
{
  "executors": [
    {
      "code": "dailyPubAnalysisExecutor",
      "beanName": "dailyPubAnalysisExecutor",
      "name": "每日发布分析执行器",
      "description": "分析热词活动匹配和品牌排名",
      "typeLimitList": ["industry", "citypoi"]
    }
  ]
}
```

**校验逻辑**：
- typeLimitList 为空：所有 type 都可使用
- typeLimitList 有值：仅指定 type 可使用

## 3. 实体设计

### 3.1 DailyPubAnalysisResult

```java
@Data
public class DailyPubAnalysisResult {
    /**
     * 热词名称
     */
    private String hotwordName;
    
    /**
     * 答案是否含有活动
     */
    private boolean answerHasAct;
    
    /**
     * 引用信源是否含有活动
     */
    private boolean referHasAct;
    
    /**
     * 答案是否含有"去哪儿"
     */
    private boolean answerHasQ;
    
    /**
     * 引用信源是否含有"去哪儿"
     */
    private boolean referHasQ;
    
    /**
     * 排名详情
     */
    private RankDetail rankDetail;
    
    @Data
    public static class RankDetail {
        /**
         * 去哪儿在品牌顺序中的排名，未出现为 -1
         */
        private int rank;
        
        /**
         * 按顺序出现的品牌列表
         */
        private List<String> detail;
    }
}
```

### 3.2 ExecutorConfig 扩展

```java
@Data
public static class ExecutorConfig {
    private String code;
    private String beanName;
    private String name;
    private String description;
    private List<String> dataTypes;
    
    /**
     * 类型限制列表，为空则所有类型可用
     */
    private List<String> typeLimitList;
}
```

## 4. 处理流程

### 4.1 整体流程

```
1. 遍历每条热词分析结果（通过 BatchTaskResultProvider）
   2. 获取热词信息（hotwordName, tags）
   3. 根据 tag 获取活动名称
   4. 解析 answer 和 references
   5. 计算 answerHasAct、referHasAct
   6. 计算 answerHasQ、referHasQ
   7. 计算 rankDetail（品牌出现顺序 + 去哪儿排名）
   8. 构建 DailyPubAnalysisResult
9. 汇总所有结果返回
```

### 4.2 品牌排名计算逻辑

```
输入：answer 文本，brands 列表，brandSynonyms 映射

1. 初始化品牌出现顺序列表 brandOrder = []
2. 遍历 brands：
   - 检查 brand 是否在 answer 中出现
   - 检查 brandSynonyms.get(brand) 中是否有同义词出现
   - 如果出现，记录品牌和位置到 brandOrder
3. 按 answer 中的位置排序 brandOrder
4. 提取品牌名称列表作为 detail
5. 查找"去哪儿"在 brandOrder 中的位置：
   - 如果找到，rank = 位置索引 + 1
   - 如果未找到，rank = -1
```

### 4.3 活动匹配逻辑

```
answerHasAct 计算：
1. 从热词 tags 获取第一个 tag
2. 拼接 key = "dailyPubAnalysisExecutor_" + tag
3. 从 HotFileQConfig 获取 activityName
4. 如果 activityName 为空，返回 false
5. 检查 activityName 是否在 answer 中出现（不区分大小写）

referHasAct 计算：
1-4 同上
5. 遍历 references，检查 title 和 snippet 是否包含 activityName
```

## 5. 接口设计

### 5.1 Executor 接口

```java
@Slf4j
@Service("dailyPubAnalysisExecutor")
public class DailyPubAnalysisExecutor extends BaseGeoAnalysisExecutor {
    
    @Resource
    private HotFileQConfig hotFileQConfig;
    
    @Resource
    private GeoAnalysisQConfig geoAnalysisQConfig;
    
    @Override
    public String getCode() {
        return "dailyPubAnalysisExecutor";
    }
    
    @Override
    protected ExecutorResult doExecute(ExecutorContext context) {
        // 实现逻辑
    }
}
```

### 5.2 类型校验扩展

在 GeoAnalysisExecutorFactory 中新增类型校验：

```java
public GeoAnalysisExecutor getExecutor(String code, String type) {
    ExecutorConfig config = geoAnalysisQConfig.getExecutorConfig(code);
    if (config == null) {
        throw new IllegalArgumentException("Executor not found: " + code);
    }
    
    List<String> typeLimitList = config.getTypeLimitList();
    if (typeLimitList != null && !typeLimitList.isEmpty() 
        && !typeLimitList.contains(type)) {
        throw new IllegalArgumentException(
            "Executor " + code + " not allowed for type: " + type);
    }
    
    return getExecutor(code);
}
```

## 6. 数据来源

### 6.1 热词信息获取

热词信息（hotwordName, tags）需要从 HotWordTask 中获取：
- HotWordTask.param 包含热词 ID
- 需要关联查询 HotWord 表获取 tags

### 6.2 分析结果获取

通过 BatchTaskResultProvider 分批获取：
- HotWordTask.result 解析为 HotWordAnalysisResult
- 包含 question, answer, references

## 7. 配置文件示例

### 7.1 geo_analysis_executor_config.json

```json
{
  "executors": [
    {
      "code": "dailyPubAnalysisExecutor",
      "beanName": "dailyPubAnalysisExecutor",
      "name": "每日发布分析执行器",
      "description": "分析热词活动匹配和品牌排名情况",
      "typeLimitList": []
    }
  ]
}
```

### 7.2 geo_analysis_config.json 扩展

```json
{
  "brands": ["去哪儿", "携程", "飞猪", "同程", "途牛"],
  "brandSynonyms": {
    "去哪儿": ["qunar", "Qunar", "QUNAR"],
    "携程": ["ctrip", "Ctrip", "CTRIP", "携程旅行"]
  },
  "qunarKeywords": ["去哪儿", "qunar"]
}
```

### 7.3 hotfile.properties 示例

```properties
# 每日发布分析活动映射
dailyPubAnalysisExecutor_tagA=免费机票活动
dailyPubAnalysisExecutor_tagB=特价促销
dailyPubAnalysisExecutor_春节=春节大促
dailyPubAnalysisExecutor_五一=五一特惠
```
