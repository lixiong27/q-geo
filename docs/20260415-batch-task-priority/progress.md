# 进度追踪

## 需求概述

**需求名称**：批量任务优先级字段
**创建日期**：2026-04-15
**负责人**：Claude AI

## 当前阶段

**阶段**：前后端开发完成，待联调测试

## 需求描述

在创建批量任务时新增优先级字段，支持任务优先级管理：

### 前端改造
1. **热词批量分析任务模块**：新增优先级选择器，从后端获取优先级配置，创建批量任务时透传优先级
2. **GEO分析模板模块**：新增优先级选项，创建任务时传递优先级

### 后端改造
1. **优先级配置接口**：使用 QConfig 承接，配置格式：
   ```json
   {
     "high": {"name": "高优先级", "priority": 20},
     "medium": {"name": "中优先级", "priority": 10},
     "low": {"name": "低优先级", "priority": 5}
   }
   ```
2. **批量任务创建**：在 geo 分析和热词分析批量创建时支持优先级字段
3. **下游接口调用**：`DownstreamTaskClient.createTask()` 已有 priority 参数，当前硬编码为 5，需改为动态传递

## 技术方案

### 调用链路分析

**热词批量分析链路：**
```
HotWordController.createBatchAnalysisTask(request)
    ↓ (priority 从 request 获取)
HotWordTaskService.createBatchAnalysisTask(type, models, createdBy, priority)
    ↓ (params 存储 priority)
HotWordTaskService.createAnalysisTask(..., priority)
    ↓ (params 存储 priority)
AnalysisTaskExecutor.doExecute(task)
    ↓ (从 params 获取 priority)
DownstreamTaskClient.createTask(..., priority, ...)
```

**GEO 分析链路：**
```
GeoAnalysisController.triggerExecution(templateId, priority)
    ↓
GeoAnalysisResultService.triggerExecution(templateId, priority)
    ↓ (存储到 params)
HotWordTaskService.createBatchAnalysisTask(type, models, createdBy, priority)
```

### 后端改动

#### 1. QConfig 配置文件
- 文件名：`priority_config.json`（hotfile 格式）
- 配置结构：
  ```java
  public class PriorityConfig {
      private String key;     // high/medium/low
      private String name;    // 高优先级/中优先级/低优先级
      private int priority;   // 20/10/5
  }
  ```

#### 2. 新增文件

**PriorityConfig.java** - 优先级配置实体
```java
@Data
public class PriorityConfig {
    private String key;
    private String name;
    private int priority;
}
```

**PriorityConfigResponse.java** - API 响应实体
```java
@Data
public class PriorityConfigResponse {
    private String key;
    private String name;
    private int priority;
}
```

#### 3. 修改文件

**HotWordQConfig.java** - 添加优先级配置加载
```java
@QConfig("priority_config.json")
private String priorityConfigJson;

private Map<String, PriorityConfig> priorityConfigMap;

@PostConstruct
public void init() {
    // 解析 priorityConfigJson 到 priorityConfigMap
}

public List<PriorityConfig> getPriorityList() {
    return new ArrayList<>(priorityConfigMap.values());
}

public int getPriority(String key) {
    PriorityConfig config = priorityConfigMap.get(key);
    return config != null ? config.getPriority() : 0;
}
```

**HotWordController.java** - 新增优先级列表接口
```java
@GetMapping("/priority/list")
public List<PriorityConfigResponse> getPriorityList() {
    return hotWordQConfig.getPriorityList().stream()
        .map(this::toResponse)
        .collect(Collectors.toList());
}
```

**BatchAnalysisTaskCreateRequest.java** - 新增 priority 字段
```java
private String priority; // high/medium/low
```

**HotWordTaskService.java** - 方法签名改动
```java
// 修改签名
public HotWordTask createBatchAnalysisTask(String type, List<String> models, String createdBy, int priority) {
    // params 中存储 priority
}

// createAnalysisTask 系列方法在 params 中存储 priority
```

**AnalysisTaskExecutor.java** - 从 params 获取 priority
```java
@Override
protected Map<String, Object> doExecute(HotWordTask task) throws Exception {
    Map<String, Object> params = parseParams(task);
    int priority = params.containsKey("priority")
        ? ((Number) params.get("priority")).intValue()
        : 5; // 默认值

    downstreamTaskClient.createTask(name, prompt, priority, maxRetries, type);
}
```

**GeoAnalysisController.java** - 新增 priority 参数
```java
@PostMapping("/trigger")
public GeoAnalysisResultDetailResponse triggerExecution(
    @RequestParam Long templateId,
    @RequestParam(defaultValue = "medium") String priority) {
    // ...
}
```

**GeoAnalysisResultService.java** - 方法签名改动
```java
public GeoAnalysisResult triggerExecution(Long templateId, int priority) {
    // params 中存储 priority
    hotWordTaskService.createBatchAnalysisTask(type, models, "geo-analysis", priority);
}
```

### 前端改动

#### 1. api/hotword.js - 新增接口
```javascript
export function getPriorityList() {
    return request('/api/hotword/priority/list');
}
```

#### 2. HotWordAnalysis.jsx - 批量创建 Modal
```jsx
// 新增 state
const [priorityList, setPriorityList] = useState([]);
const [selectedPriority, setSelectedPriority] = useState('medium');

// 获取优先级列表
useEffect(() => {
    getPriorityList().then(res => setPriorityList(res));
}, []);

// Modal 中添加优先级选择
<Form.Item label="优先级">
    <Select value={selectedPriority} onChange={setSelectedPriority}>
        {priorityList.map(p => (
            <Option key={p.key} value={p.key}>{p.name}</Option>
        ))}
    </Select>
</Form.Item>

// 提交时传递 priority
createBatchAnalysisTask({ type, models, priority: selectedPriority });
```

#### 3. GeoAnalysisTemplate.jsx - 执行时传递优先级
```jsx
// 方案A：模板配置中保存优先级
// 方案B：执行时弹出确认框选择优先级
```

## 任务清单

### 后端改造
- [x] 新增 PriorityConfig.java 实体类
- [x] HotFileQConfig 添加优先级配置加载（复用 hotfile.properties）
- [x] HotWordController 新增优先级列表接口
- [x] BatchAnalysisTaskCreateRequest 新增 priority 字段
- [x] HotWordTaskService.createBatchAnalysisTask 新增 priority 参数
- [x] HotWordTaskService.createAnalysisTask 在 params 中存储 priority
- [x] AnalysisTaskExecutor.doExecute 从 params 获取 priority 传递给下游
- [x] GeoAnalysisController.triggerExecution 新增 priority 参数
- [x] GeoAnalysisResultService.triggerExecution 新增 priority 参数
- [x] GeoAnalysisScheduleTask 从模板配置解析 priority

### 前端改造
- [x] api/hotword.js 新增 getPriorityList 接口
- [x] HotWordAnalysis.jsx 新增优先级选择器
- [x] GeoAnalysisTemplate.jsx 执行时选择优先级（保存到模板配置）
- [x] api/geo.js triggerExecution 支持 priority 参数

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-15 | 需求分析，创建设计文档 | 已完成 |
| 2026-04-15 | 代码分析，完成技术方案 | 已完成 |
| 2026-04-15 | 后端改造完成（优先级配置、接口、透传逻辑） | 已完成 |
| 2026-04-15 | 前端改造完成（API、批量创建、模板配置） | 已完成 |

## 下一步行动

1. 在 QConfig 平台配置 `hotfile.properties` 添加优先级配置项
2. 联调测试验证功能

## Bug 修复记录

| 日期 | 问题 | 原因 | 解决方案 |
|------|------|------|----------|
| 2026-04-15 | 优先级下拉框为空 | 后端返回裸数组，前端 axios 拦截器期望 `{code: 0, data/list}` 格式 | 1. 后端新增 `PriorityConfigListResponse` 包装类 2. 前端使用 `res.list` 提取数据 |
