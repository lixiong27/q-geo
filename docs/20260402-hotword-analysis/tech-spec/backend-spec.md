# 热词分析模块 - 后端技术规格

## 一、概述

本文档定义热词分析模块的后端实现细节，包括实体修改、Mapper 变更、Service 扩展和 Controller 接口。

---

## 二、实体层修改

### 2.1 HotWord 实体

**文件位置：** `domain/entity/hotword/HotWord.java`

**新增字段：**

```java
@Data
public class HotWord {
    // ... 现有字段 ...
    private String type;  // 热词类型（从QConfig获取）

    // 新增来源常量
    public static final int SOURCE_TYPE_ANALYSIS = 2;  // 热词分析来源
}
```

### 2.2 HotWordTask 实体

**文件位置：** `domain/entity/hotword/HotWordTask.java`

**新增字段和常量：**

```java
@Data
public class HotWordTask {
    // ... 现有字段 ...
    private String model;  // 模型标识，可选值从 QConfig 获取：deepseek/qianwen/doubao 等

    // 新增任务类型
    public static final String TYPE_ANALYSIS = "analysis";
}
```

---

## 三、QConfig 配置层

### 3.1 HotWordTypeConfig 实体

**文件位置：** `domain/entity/hotword/HotWordTypeConfig.java`

```java
package com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword;

import lombok.Data;

/**
 * 热词类型配置项
 * 与 QConfig 配置 JSON 结构对应
 */
@Data
public class HotWordTypeConfig {
    private String key;         // 类型标识，如 poiAnalysis
    private String type;        // 业务类型：analysis_query
    private String subType;     // 业务子类型：poi/platform
    private String name;        // 显示名称
    private String description; // 描述说明
}
```

### 3.2 HotWordModelConfig 实体

**文件位置：** `domain/entity/hotword/HotWordModelConfig.java`

```java
package com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword;

import lombok.Data;

/**
 * 热词分析模型配置项
 * 存储在 hotfile.properties 中，key: hotword.analysis.model.config
 */
@Data
public class HotWordModelConfig {
    private String prompt;      // 触发下游任务的 prompt 参数
    // 可扩展其他参数，如 temperature, maxTokens 等
}
```

### 3.3 HotWordQConfig 配置类

**文件位置：** `infra/qconfig/HotWordQConfig.java`

**说明：** 使用已有的 `HotFileQConfig` 获取 model 配置，JSON 格式存储在 `hotfile.properties` 中。

```java
package com.qunar.ug.flight.contact.ares.analysisterm.infra.qconfig;

import com.fasterxml.jackson.core.type.TypeReference;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordModelConfig;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordTypeConfig;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.util.JsonUtils;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Component;
import qunar.tc.qconfig.client.spring.QConfig;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 热词配置服务
 * 从 QConfig 读取热词类型配置和模型配置
 */
@Slf4j
@Component
public class HotWordQConfig {

    @Resource
    private HotFileQConfig hotFileQConfig;

    // 热词类型配置缓存
    private Map<String, HotWordTypeConfig> typeConfigMap;

    // 模型配置缓存
    private Map<String, HotWordModelConfig> modelConfigMap;

    /**
     * QConfig 配置变更回调 - 热词类型
     * 配置文件：hotword.type.config.json
     * 配置格式：JSON
     */
    @QConfig("hotword.type.config.json")
    public void onTypeConfigChanged(String json) {
        Map<String, HotWordTypeConfig> tempMap = JsonUtils.jsonToObject(
            json,
            new TypeReference<Map<String, HotWordTypeConfig>>() {}
        );
        if (tempMap != null) {
            typeConfigMap = tempMap;
        }
    }

    /**
     * QConfig 配置变更回调 - 模型配置
     * 配置文件：hotfile.properties
     * 配置 key：hotword.analysis.model.config
     * 配置格式：JSON 字符串，如 {"deepseek":{"prompt":"xxx"},"qianwen":{"prompt":"xxx"}}
     */
    public void loadModelConfig() {
        String json = hotFileQConfig.getString("hotword.analysis.model.config", "{}");
        if (StringUtils.isNotBlank(json)) {
            Map<String, HotWordModelConfig> tempMap = JsonUtils.jsonToObject(
                json,
                new TypeReference<Map<String, HotWordModelConfig>>() {}
            );
            if (tempMap != null) {
                modelConfigMap = tempMap;
            }
        }
    }

    /**
     * 获取模型配置
     * 先尝试从缓存获取，若为空则重新加载
     */
    public HotWordModelConfig getModelConfig(String model) {
        if (modelConfigMap == null) {
            loadModelConfig();
        }
        if (modelConfigMap == null || StringUtils.isEmpty(model)) {
            return null;
        }
        return modelConfigMap.get(model);
    }

    /**
     * 获取所有模型配置列表
     */
    public List<String> getModelList() {
        if (modelConfigMap == null) {
            loadModelConfig();
        }
        if (modelConfigMap == null || modelConfigMap.isEmpty()) {
            return new ArrayList<>();
        }
        return new ArrayList<>(modelConfigMap.keySet());
    }

    /**
     * 获取所有热词类型配置列表
     */
    public List<HotWordTypeConfig> getTypeList() {
        if (typeConfigMap == null || typeConfigMap.isEmpty()) {
            return new ArrayList<>();
        }
        return new ArrayList<>(typeConfigMap.values());
    }

    /**
     * 根据 key 获取热词类型配置
     */
    public HotWordTypeConfig getTypeConfig(String key) {
        if (typeConfigMap == null || StringUtils.isEmpty(key)) {
            return null;
        }
        return typeConfigMap.get(key);
    }

    /**
     * 获取热词类型的显示名称
     */
    public String getTypeName(String key) {
        HotWordTypeConfig config = getTypeConfig(key);
        return config != null ? config.getName() : key;
    }

    /**
     * 判断热词类型是否存在
     */
    public boolean isValidType(String key) {
        return typeConfigMap != null && typeConfigMap.containsKey(key);
    }
}
```

### 3.4 QConfig 配置示例

#### 3.4.1 热词类型配置

**配置文件：** `hotword.type.config.json`

```json
{
    "poiAnalysis": {
        "key": "poiAnalysis",
        "type": "analysis_query",
        "subType": "poi",
        "name": "POI分析查询",
        "description": "针对POI相关的分析查询热词"
    },
    "platAnalysis": {
        "key": "platAnalysis",
        "type": "analysis_query",
        "subType": "platform",
        "name": "平台分析查询",
        "description": "针对平台层面的分析查询热词"
    }
}
```

#### 3.4.2 模型配置

**配置文件：** `hotfile.properties`

**配置 key：** `hotword.analysis.model.config`

**配置值（JSON 字符串）：**

```json
{
    "deepseek": {
        "prompt": "请分析以下内容，提取可能的热门搜索词..."
    },
    "qianwen": {
        "prompt": "基于以下数据，生成用户可能感兴趣的热词..."
    },
    "doubao": {
        "prompt": "分析用户查询模式，输出推荐热词..."
    }
}
```

---

## 四、Mapper 层修改

### 3.1 HotWordMapper.java

**文件位置：** `infra/dao/hotword/HotWordMapper.java`

**方法签名变更：**

```java
// selectList 方法新增 type 参数
List<HotWord> selectList(@Param("sourceType") Integer sourceType,
                         @Param("keyword") String keyword,
                         @Param("type") String type,
                         @Param("offset") Integer offset,
                         @Param("limit") Integer limit);

// selectCount 方法新增 type 参数
int selectCount(@Param("sourceType") Integer sourceType,
                @Param("keyword") String keyword,
                @Param("type") String type);
```

### 3.2 HotWordMapper.xml

**文件位置：** `resources/mapper/hotword/HotWordMapper.xml`

**变更内容：**

1. ResultMap 新增 type 字段映射
2. Base_Column_List 新增 type 列
3. INSERT 语句新增 type 字段
4. UPDATE 语句新增 type 条件
5. SELECT 语句新增 type 查询条件

```xml
<resultMap id="BaseResultMap" type="...">
    <!-- 现有映射 -->
    <result column="type" property="type"/>
</resultMap>

<sql id="Base_Column_List">
    id, word, source_type, source_task_id, tags, type, create_time, update_time
</sql>

<select id="selectList" resultMap="BaseResultMap">
    SELECT <include refid="Base_Column_List"/>
    FROM hot_word
    <where>
        <if test="sourceType != null">source_type = #{sourceType}</if>
        <if test="keyword != null and keyword != ''">AND word LIKE CONCAT('%', #{keyword}, '%')</if>
        <if test="type != null and type != ''">AND type = #{type}</if>
    </where>
    ORDER BY create_time DESC
    LIMIT #{offset}, #{limit}
</select>
```

### 3.3 HotWordTaskMapper.xml

**文件位置：** `resources/mapper/hotword/HotWordTaskMapper.xml`

**变更内容：**

1. ResultMap 新增 model 字段映射
2. Base_Column_List 新增 model 列
3. INSERT 语句新增 model 字段
4. UPDATE 语句新增 model 条件

```xml
<resultMap id="BaseResultMap" type="...">
    <!-- 现有映射 -->
    <result column="model" property="model"/>
</resultMap>

<sql id="Base_Column_List">
    id, name, type, model, params, status, result, created_by, create_time, update_time, completed_at
</sql>

<insert id="insert" ...>
    INSERT INTO hot_word_task (name, type, model, params, status, result, created_by, create_time, update_time)
    VALUES (#{name}, #{type}, #{model}, #{params}, #{status}, #{result}, #{createdBy}, NOW(), NOW())
</insert>
```

---

## 四、Service 层修改

### 4.1 HotWordService

**文件位置：** `service/hotword/HotWordService.java`

**新增/修改方法：**

```java
/**
 * 分页查询热词列表（新增 type 参数）
 */
public PageResult<HotWord> list(Integer sourceType, String keyword, String type, Integer page, Integer size) {
    int offset = (page - 1) * size;
    List<HotWord> list = hotWordMapper.selectList(sourceType, keyword, type, offset, size);
    int total = hotWordMapper.selectCount(sourceType, keyword, type);
    return PageResult.of(list, total, page, size);
}

/**
 * 新增热词（新增 type 参数）
 */
public HotWord add(String word, String tags, String type) {
    HotWord hotWord = new HotWord();
    hotWord.setWord(word);
    hotWord.setSourceType(HotWord.SOURCE_TYPE_MANUAL);
    hotWord.setSourceTaskId(0L);
    hotWord.setTags(tags);
    hotWord.setType(type);
    hotWordMapper.insert(hotWord);
    return hotWord;
}

/**
 * 添加分析任务产生的热词（新增 type 参数）
 */
public void addFromAnalysisTask(List<Map<String, String>> wordsWithType, Long taskId) {
    List<HotWord> hotWords = new ArrayList<>();
    for (Map<String, String> item : wordsWithType) {
        String word = item.get("word");
        String type = item.get("type");
        if (word == null || word.trim().isEmpty()) continue;
        if (hotWordMapper.selectByWord(word.trim()) != null) continue;

        HotWord hotWord = new HotWord();
        hotWord.setWord(word.trim());
        hotWord.setSourceType(HotWord.SOURCE_TYPE_ANALYSIS);
        hotWord.setSourceTaskId(taskId);
        hotWord.setType(type);
        hotWords.add(hotWord);
    }
    if (!hotWords.isEmpty()) {
        hotWordMapper.batchInsert(hotWords);
    }
}
```

### 4.2 任务执行器架构

#### 4.2.1 架构设计说明

**设计目标：** 使用模板方法模式，抽象类负责公共逻辑（状态更新、异步执行、异常处理），子类实现具体业务逻辑。支持不同模块扩展新任务类型。

**架构图：**

```
HotWordTaskExecutor (抽象类)
├── 公共逻辑：状态更新、异步执行、异常处理、线程池管理
├── 模板方法：executeAsync()
├── 抽象方法：getTaskType()、doExecute()
│
├── DigTaskExecutor (挖掘任务 - 现有)
│   └── 实现挖掘逻辑
│
├── ExpandTaskExecutor (扩展任务 - 现有)
│   └── 实现扩展逻辑
│
└── AnalysisTaskExecutor (分析任务 - 新增)
    └── 实现 AI 分析逻辑
```

**现有任务类型：** `dig`、`expand`
**新增任务类型：** `analysis`

#### 4.2.2 抽象类 HotWordTaskExecutor

**文件位置：** `service/hotword/executor/HotWordTaskExecutor.java`

```java
package com.qunar.ug.flight.contact.ares.analysisterm.service.hotword.executor;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.TypeReference;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordTask;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.dao.hotword.HotWordTaskMapper;
import lombok.extern.slf4j.Slf4j;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 热词任务执行器抽象类
 * 模板方法模式：定义任务执行的标准流程，子类实现具体业务逻辑
 */
@Slf4j
public abstract class HotWordTaskExecutor {

    protected HotWordTaskMapper hotWordTaskMapper;

    // 线程池，用于异步执行任务
    protected static final ExecutorService executorService = Executors.newFixedThreadPool(5);

    /**
     * 获取任务类型
     */
    public abstract String getTaskType();

    /**
     * 执行具体业务逻辑（子类实现）
     * @param task 任务对象
     * @return 执行结果
     */
    protected abstract Map<String, Object> doExecute(HotWordTask task) throws Exception;

    /**
     * 异步执行任务（模板方法）
     */
    public void executeAsync(HotWordTask task) {
        // 更新状态为运行中
        hotWordTaskMapper.updateStatus(task.getId(), HotWordTask.STATUS_RUNNING, null);

        executorService.submit(() -> {
            try {
                log.info("Task {} started, type: {}", task.getId(), getTaskType());

                // 执行具体业务逻辑
                Map<String, Object> result = doExecute(task);

                // 更新状态为完成
                hotWordTaskMapper.updateStatus(task.getId(), HotWordTask.STATUS_COMPLETED, JSON.toJSONString(result));
                log.info("Task {} completed", task.getId());

            } catch (Exception e) {
                log.error("Task {} failed", task.getId(), e);

                // 更新状态为失败
                Map<String, Object> errorResult = new HashMap<>();
                errorResult.put("error", e.getMessage());
                hotWordTaskMapper.updateStatus(task.getId(), HotWordTask.STATUS_FAILED, JSON.toJSONString(errorResult));
            }
        });
    }

    /**
     * 解析任务参数
     */
    protected Map<String, Object> parseParams(HotWordTask task) {
        return JSON.parseObject(task.getParams(), new TypeReference<Map<String, Object>>() {});
    }

    public void setHotWordTaskMapper(HotWordTaskMapper hotWordTaskMapper) {
        this.hotWordTaskMapper = hotWordTaskMapper;
    }
}
```

#### 4.2.3 分析任务执行器 AnalysisTaskExecutor

**文件位置：** `service/hotword/executor/AnalysisTaskExecutor.java`

```java
package com.qunar.ug.flight.contact.ares.analysisterm.service.hotword.executor;

import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordTask;
import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.hotword.HotWordModelConfig;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.qconfig.HotWordQConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 热词分析任务执行器
 */
@Slf4j
@Component
public class AnalysisTaskExecutor extends HotWordTaskExecutor {

    @Resource
    private HotWordQConfig hotWordQConfig;

    @Override
    public String getTaskType() {
        return HotWordTask.TYPE_ANALYSIS;
    }

    @Override
    protected Map<String, Object> doExecute(HotWordTask task) throws Exception {
        Map<String, Object> params = parseParams(task);
        String type = (String) params.get("type");
        String prompt = (String) params.get("prompt");
        int count = params.get("count") != null ? ((Number) params.get("count")).intValue() : 10;

        log.info("Analysis task executing, type: {}, model: {}, prompt: {}", type, task.getModel(), prompt);

        // TODO: 调用实际的 AI 模型服务执行分析
        // 目前使用 Mock 数据
        List<Map<String, String>> words = mockAnalysisResult(type, count);

        Map<String, Object> result = new HashMap<>();
        result.put("total", words.size());
        result.put("type", type);
        result.put("model", task.getModel());
        result.put("words", words);

        return result;
    }

    /**
     * Mock 分析结果（后续替换为真实 AI 调用）
     */
    private List<Map<String, String>> mockAnalysisResult(String type, int count) {
        List<Map<String, String>> words = new ArrayList<>();
        String[] mockWords = {
            "北京天安门门票", "故宫开放时间", "长城游玩攻略",
            "颐和园门票价格", "天坛公园怎么走", "圆明园遗址公园",
            "鸟巢水立方参观", "北京欢乐谷攻略", "香山公园红叶", "北海公园划船"
        };
        for (int i = 0; i < Math.min(count, mockWords.length); i++) {
            Map<String, String> item = new HashMap<>();
            item.put("word", mockWords[i]);
            item.put("type", type);
            words.add(item);
        }
        return words;
    }
}
```

#### 4.2.4 任务执行器工厂 TaskExecutorFactory

**文件位置：** `service/hotword/executor/TaskExecutorFactory.java`

```java
package com.qunar.ug.flight.contact.ares.analysisterm.service.hotword.executor;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 任务执行器工厂
 * 根据任务类型获取对应的执行器
 */
@Slf4j
@Component
public class TaskExecutorFactory {

    @Resource
    private List<HotWordTaskExecutor> executors;

    @Resource
    private HotWordTaskMapper hotWordTaskMapper;

    private Map<String, HotWordTaskExecutor> executorMap = new HashMap<>();

    @PostConstruct
    public void init() {
        for (HotWordTaskExecutor executor : executors) {
            // 注入 mapper
            executor.setHotWordTaskMapper(hotWordTaskMapper);
            executorMap.put(executor.getTaskType(), executor);
            log.info("Registered task executor: {} -> {}", executor.getTaskType(), executor.getClass().getSimpleName());
        }
    }

    /**
     * 根据任务类型获取执行器
     */
    public HotWordTaskExecutor getExecutor(String taskType) {
        HotWordTaskExecutor executor = executorMap.get(taskType);
        if (executor == null) {
            throw new IllegalArgumentException("Unknown task type: " + taskType);
        }
        return executor;
    }

    /**
     * 判断任务类型是否支持
     */
    public boolean isSupported(String taskType) {
        return executorMap.containsKey(taskType);
    }
}
```

### 4.3 HotWordTaskService

**文件位置：** `service/hotword/HotWordTaskService.java`

**新增方法：**

```java
/**
 * 创建热词分析任务
 * @param hotwordId 关联热词ID（必填，引用已有热词）
 */
public HotWordTask createAnalysisTask(Long hotwordId, String name, String type, String model, Integer count, String createdBy) {
    // 验证热词是否存在
    HotWord hotWord = hotWordMapper.selectById(hotwordId);
    if (hotWord == null) {
        throw new IllegalArgumentException("热词不存在: " + hotwordId);
    }

    HotWordTask task = new HotWordTask();
    task.setName(name);
    task.setType(HotWordTask.TYPE_ANALYSIS);
    task.setModel(model);
    task.setStatus(HotWordTask.STATUS_PENDING);

    // 从 QConfig 获取模型配置的 prompt 等参数
    Map<String, Object> params = new HashMap<>();
    params.put("hotwordId", hotwordId);  // 存储关联热词ID
    params.put("hotword", hotWord.getWord());  // 存储热词内容，方便后续分析
    params.put("type", type);
    params.put("count", count);
    if (StringUtils.isNotBlank(model)) {
        HotWordModelConfig modelConfig = hotWordQConfig.getModelConfig(model);
        if (modelConfig != null) {
            params.put("prompt", modelConfig.getPrompt());
        }
    }
    task.setParams(JSON.toJSONString(params));
    task.setCreatedBy(createdBy);

    hotWordTaskMapper.insert(task);

    // 通过执行器工厂获取对应执行器并执行
    HotWordTaskExecutor executor = taskExecutorFactory.getExecutor(HotWordTask.TYPE_ANALYSIS);
    executor.executeAsync(task);

    return task;
}

/**
 * 导入分析任务结果
 */
public int importAnalysisResults(Long taskId, List<Map<String, String>> selectedWords) {
    HotWordTask task = hotWordTaskMapper.selectById(taskId);
    if (task == null || task.getStatus() != HotWordTask.STATUS_COMPLETED) {
        return 0;
    }

    if (!HotWordTask.TYPE_ANALYSIS.equals(task.getType())) {
        throw new IllegalArgumentException("Task is not an analysis task");
    }

    if (selectedWords == null || selectedWords.isEmpty()) {
        // 从结果中提取所有热词
        Map<String, Object> result = JSON.parseObject(task.getResult(), new TypeReference<Map<String, Object>>(){});
        List<Map<String, String>> allWords = (List<Map<String, String>>) result.get("words");
        hotWordService.addFromAnalysisTask(allWords, taskId);
        return allWords.size();
    }

    hotWordService.addFromAnalysisTask(selectedWords, taskId);
    return selectedWords.size();
}
```

---

## 五、Controller 层修改

### 5.1 HotWordController

**文件位置：** `web/HotWordController.java`

**新增请求类：** `domain/entity/hotword/request/AnalysisTaskCreateRequest.java`

```java
@Data
public class AnalysisTaskCreateRequest {
    private Long hotwordId;     // 关联热词ID（必填，从已有热词中选择）
    private String name;        // 任务名称
    private String type;        // 热词类型
    private String model;       // 模型标识（可选，默认 default）
    private Integer count;      // 预期数量
    private String createdBy;   // 创建人
}
```

**新增接口：**

```java
/**
 * 获取热词类型配置列表
 */
@GetMapping("/types")
public HotWordTypeListResponse getTypes() {
    HotWordTypeListResponse response = new HotWordTypeListResponse();
    try {
        List<HotWordTypeConfig> list = hotWordQConfig.getTypeList();
        response.setList(list);
        response.setCode(0);
        response.setMsg("success");
    } catch (Exception e) {
        response.failure(ResultEnum.SERVER_ERROR);
    }
    return response;
}

/**
 * 获取分析模型配置列表
 */
@GetMapping("/models")
public HotWordModelListResponse getModels() {
    HotWordModelListResponse response = new HotWordModelListResponse();
    try {
        List<String> list = hotWordQConfig.getModelList();
        response.setList(list);
        response.setCode(0);
        response.setMsg("success");
    } catch (Exception e) {
        response.failure(ResultEnum.SERVER_ERROR);
    }
    return response;
}

/**
 * 创建热词分析任务
 */
@PostMapping("/task/analysis/create")
public HotWordTaskDetailResponse createAnalysisTask(@RequestBody AnalysisTaskCreateRequest request) {
    HotWordTaskDetailResponse response = new HotWordTaskDetailResponse();
    try {
        // 验证必填参数
        if (request.getHotwordId() == null) {
            response.failure(ResultEnum.PARAM_ERROR, "关联热词ID不能为空");
            return response;
        }

        HotWordTask task = hotWordTaskService.createAnalysisTask(
                request.getHotwordId(),
                request.getName(),
                request.getType(),
                request.getModel(),
                request.getCount(),
                request.getCreatedBy()
        );
        response.setData(task);
        response.setCode(0);
        response.setMsg("success");
    } catch (IllegalArgumentException e) {
        response.failure(ResultEnum.PARAM_ERROR, e.getMessage());
    } catch (Exception e) {
        response.failure(ResultEnum.SERVER_ERROR);
    }
    return response;
}

/**
 * 导入分析任务结果
 */
@PostMapping("/task/importAnalysisResults")
public DigResultImportResponse importAnalysisResults(@RequestBody AnalysisResultImportRequest request) {
    DigResultImportResponse response = new DigResultImportResponse();
    try {
        int count = hotWordTaskService.importAnalysisResults(request.getTaskId(), request.getSelectedWords());
        response.setImportedCount(count);
        response.setCode(0);
        response.setMsg("success");
    } catch (Exception e) {
        response.failure(ResultEnum.SERVER_ERROR);
    }
    return response;
}
```

**修改现有接口：**

```java
/**
 * 热词列表（新增 type 参数）
 */
@GetMapping("/list")
public HotWordListResponse list(HotWordListRequest request) {
    // ... 新增 type 参数传递
    PageResult<HotWord> result = hotWordService.list(
            request.getSourceType(),
            request.getKeyword(),
            request.getType(),  // 新增
            request.getPage(),
            request.getSize()
    );
    // ...
}

/**
 * 新增热词（新增 type 参数）
 */
@PostMapping("/add")
public HotWordDetailResponse add(@RequestBody HotWordAddRequest request) {
    // ... 新增 type 参数
    HotWord hotWord = hotWordService.add(request.getWord(), tags, request.getType());
    // ...
}
```

---

## 六、请求/响应对象修改

### 6.1 HotWordListRequest

```java
@Data
public class HotWordListRequest {
    private Integer sourceType;
    private String keyword;
    private String type;        // 新增：热词类型筛选
    private Integer page = 1;
    private Integer size = 20;
}
```

### 6.2 HotWordAddRequest

```java
@Data
public class HotWordAddRequest {
    private String word;
    private List<String> tags;
    private String type;        // 新增：热词类型
}
```

### 6.3 AnalysisResultImportRequest（新增）

```java
@Data
public class AnalysisResultImportRequest {
    private Long taskId;
    private List<Map<String, String>> selectedWords;  // 选中的热词，包含 word 和 type
}
```

### 6.4 HotWordTypeListResponse（新增）

```java
@Data
public class HotWordTypeListResponse extends BaseResponse {
    private List<HotWordTypeConfig> list;
}
```

### 6.5 HotWordModelListResponse（新增）

```java
@Data
public class HotWordModelListResponse extends BaseResponse {
    private List<String> list;  // 模型标识列表，如 ["deepseek", "qianwen", "doubao"]
}
```

---

## 七、接口清单

| 接口 | 方法 | 变更类型 | 说明 |
|------|------|----------|------|
| `/api/hotWord/list` | GET | 修改 | 新增 type 参数，支持模糊搜索 |
| `/api/hotWord/add` | POST | 修改 | 新增 type 参数 |
| `/api/hotWord/types` | GET | **新增** | 获取热词类型配置列表 |
| `/api/hotWord/models` | GET | **新增** | 获取分析模型配置列表 |
| `/api/hotWord/task/list` | GET | 不变 | type 参数支持 analysis |
| `/api/hotWord/task/detail` | GET | 不变 | - |
| `/api/hotWord/task/analysis/create` | POST | **新增** | 创建热词分析任务（需关联热词ID） |
| `/api/hotWord/task/cancel` | POST | 不变 | - |
| `/api/hotWord/task/retry` | POST | 不变 | - |
| `/api/hotWord/task/importAnalysisResults` | POST | **新增** | 导入分析结果 |

---

## 八、文件变更清单

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `HotWord.java` | 修改 | 新增 type 字段、SOURCE_TYPE_ANALYSIS 常量 |
| `HotWordTask.java` | 修改 | 新增 model 字段、TYPE_ANALYSIS 常量 |
| `HotWordTypeConfig.java` | **新增** | 热词类型配置实体 |
| `HotWordModelConfig.java` | **新增** | 热词分析模型配置实体 |
| `HotWordQConfig.java` | **新增** | QConfig 配置服务，获取类型配置和模型配置 |
| `HotWordMapper.java` | 修改 | selectList/selectCount 新增 type 参数 |
| `HotWordMapper.xml` | 修改 | 新增 type 字段映射和查询条件 |
| `HotWordTaskMapper.xml` | 修改 | 新增 model 字段映射 |
| `HotWordService.java` | 修改 | 方法新增 type 参数，新增 addFromAnalysisTask |
| `HotWordTaskService.java` | 修改 | 新增 createAnalysisTask、importAnalysisResults |
| `HotWordTaskExecutor.java` | **新增** | 任务执行器抽象类（模板方法模式） |
| `AnalysisTaskExecutor.java` | **新增** | 分析任务执行器实现类 |
| `TaskExecutorFactory.java` | **新增** | 任务执行器工厂 |
| `HotWordController.java` | 修改 | 新增分析任务接口、类型配置接口、模型配置接口，修改现有接口参数 |
| `HotWordListRequest.java` | 修改 | 新增 type 字段 |
| `HotWordAddRequest.java` | 修改 | 新增 type 字段 |
| `AnalysisTaskCreateRequest.java` | **新增** | 分析任务创建请求 |
| `AnalysisResultImportRequest.java` | **新增** | 分析结果导入请求 |
| `HotWordTypeListResponse.java` | **新增** | 热词类型列表响应 |
| `HotWordModelListResponse.java` | **新增** | 分析模型列表响应 |

---

## 九、QConfig 配置说明

### 9.1 配置文件

| 配置文件 | 配置 Key | 说明 |
|----------|----------|------|
| `hotword.type.config.json` | - | 热词类型配置（JSON格式） |
| `hotfile.properties` | `hotword.analysis.model.config` | 模型配置（JSON字符串） |

### 9.2 配置格式

#### 9.2.1 热词类型配置（hotword.type.config.json）

```json
{
    "poiAnalysis": {
        "key": "poiAnalysis",
        "type": "analysis_query",
        "subType": "poi",
        "name": "POI分析查询",
        "description": "针对POI相关的分析查询热词"
    },
    "platAnalysis": {
        "key": "platAnalysis",
        "type": "analysis_query",
        "subType": "platform",
        "name": "平台分析查询",
        "description": "针对平台层面的分析查询热词"
    }
}
```

#### 9.2.2 模型配置（hotfile.properties 中的 hotword.analysis.model.config）

```json
{
    "deepseek": {
        "prompt": "请分析以下内容，提取可能的热门搜索词..."
    },
    "qianwen": {
        "prompt": "基于以下数据，生成用户可能感兴趣的热词..."
    },
    "doubao": {
        "prompt": "分析用户查询模式，输出推荐热词..."
    }
}
```

### 9.3 配置字段说明

#### 9.3.1 热词类型配置字段

| 字段 | 类型 | 说明 |
|------|------|------|
| key | String | 类型标识，存储在 hot_word.type 字段 |
| type | String | 业务类型：analysis_query 等 |
| subType | String | 业务子类型：poi/platform 等 |
| name | String | 显示名称，用于前端展示 |
| description | String | 描述说明 |

#### 9.3.2 模型配置字段

| 字段 | 类型 | 说明 |
|------|------|------|
| prompt | String | 触发下游任务的 prompt 参数 |

### 9.4 依赖

- `JsonUtils` - JSON 工具类（项目中已存在）
- `HotFileQConfig` - 热词配置文件服务（项目中已存在）
