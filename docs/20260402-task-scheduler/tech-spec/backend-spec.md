# 任务调度模块 - 后端技术规格

## 1. 配置层

### 1.1 HotWordQConfig 新增配置

**文件**: `HotWordQConfig.java`

```java
/**
 * 获取下游服务域名
 */
public String getDownstreamHost() {
    return hotfileProperties.getProperty("hotword.analysis.downstream.host", "");
}

/**
 * 获取模型 prompt 模板
 */
public String getModelPrompt(String model) {
    return hotfileProperties.getProperty("hotword.model.prompt." + model, "");
}
```

**QConfig 配置示例** (`hotfile.properties`):

```properties
# 下游服务域名
hotword.analysis.downstream.host=http://ai-service.internal.corp.qunar.com

# 模型 prompt 模板
hotword.model.prompt.deepseek=请分析以下热词，生成相关词汇列表：
hotword.model.prompt.qianwen=基于以下热词进行扩展分析：
hotword.model.prompt.doubao=对以下热词进行深度分析：
```

---

## 2. 实体层

### 2.1 HotWordTask 新增字段

**文件**: `HotWordTask.java`

```java
// 新增字段
private String downstreamTaskId;    // 下游任务ID
```

---

## 3. Mapper 层

### 3.1 HotWordTaskMapper.xml

**修改内容**:
- Base_Column_List 新增 `downstream_task_id`
- INSERT 新增字段
- 新增 updateDownstreamTaskId 方法
- 新增 selectByDownstreamTaskId 方法

```xml
<update id="updateDownstreamTaskId">
    UPDATE hot_word_task
    SET downstream_task_id = #{downstreamTaskId},
        update_time = NOW()
    WHERE id = #{id}
</update>

<select id="selectByDownstreamTaskId" resultMap="BaseResultMap">
    SELECT <include refid="Base_Column_List"/>
    FROM hot_word_task
    WHERE downstream_task_id = #{downstreamTaskId}
</select>
```

---

## 4. 下游服务客户端

### 4.1 DownstreamTaskClient

**文件**: `DownstreamTaskClient.java`

```java
@Component
public class DownstreamTaskClient {

    @Resource
    private HotWordQConfig hotWordQConfig;

    /**
     * 创建下游任务
     */
    public String createTask(String name, String prompt, int priority, int maxRetries) {
        String host = hotWordQConfig.getDownstreamHost();
        if (StringUtils.isEmpty(host)) {
            throw new RuntimeException("下游服务域名未配置");
        }

        String url = host + "/api/tasks";
        // 构造请求体，调用下游接口
        // 返回下游任务ID
    }
}
```

### 4.2 下游接口契约

**创建任务**:
```
POST {host}/api/tasks
Content-Type: application/json

Request:
{
  "name": "热词分析-xxx",
  "prompt": "请分析以下热词...\n热词：北京",
  "priority": 5,
  "maxRetries": 3
}

Response 201:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "热词分析-xxx",
  "prompt": "...",
  "status": "pending",
  "priority": 5,
  "maxRetries": 3,
  "retryCount": 0,
  "createdAt": "2026-04-02T08:00:00.000Z"
}
```

---

## 5. Service 层

### 5.1 HotWordTaskService 修改

**新增方法**:

```java
/**
 * 提交分析任务到下游
 */
public void submitAnalysisTask(Long taskId) {
    HotWordTask task = getById(taskId);
    if (task == null || !TYPE_ANALYSIS.equals(task.getType())) {
        return;
    }

    // 1. 获取关联热词
    HotWord hotWord = hotWordService.getById(getHotwordIdFromParams(task.getParams()));
    if (hotWord == null) {
        throw new RuntimeException("关联热词不存在");
    }

    // 2. 构造 prompt
    String model = task.getModel();
    String promptTemplate = hotWordQConfig.getModelPrompt(model);
    String prompt = promptTemplate + "\n热词：" + hotWord.getWord();

    // 3. 调用下游创建任务
    String downstreamTaskId = downstreamTaskClient.createTask(
        task.getName(),
        prompt,
        5,  // priority
        3   // maxRetries
    );

    // 4. 更新任务
    task.setDownstreamTaskId(downstreamTaskId);
    task.setStatus(STATUS_RUNNING);
    updateDownstreamTaskId(task);
}

/**
 * 处理下游回调
 */
public void handleCallback(String downstreamTaskId, String type, String status, Object result) {
    HotWordTask task = getByDownstreamTaskId(downstreamTaskId);
    if (task == null) {
        return;
    }

    if ("completed".equals(status)) {
        task.setStatus(STATUS_COMPLETED);
        task.setResult(JSON.toJSONString(result));
        task.setCompletedAt(new Date());
    } else if ("failed".equals(status)) {
        task.setStatus(STATUS_FAILED);
    }
    update(task);
}
```

---

## 6. Controller 层

### 6.1 新增回调接口

**文件**: `HotWordController.java`

```java
/**
 * 任务回调接口
 */
@PostMapping("/task/callback")
public BaseResponse taskCallback(@RequestBody TaskCallbackRequest request) {
    BaseResponse response = new BaseResponse();
    try {
        hotWordTaskService.handleCallback(
            request.getTaskId(),
            request.getType(),
            request.getStatus(),
            request.getResult()
        );
        response.setCode(0);
        response.setMsg("success");
    } catch (Exception e) {
        response.failure(ResultEnum.SERVER_ERROR);
    }
    return response;
}
```

### 6.2 TaskCallbackRequest

**文件**: `TaskCallbackRequest.java`

```java
@Data
public class TaskCallbackRequest {
    private String taskId;      // 下游任务ID
    private String type;        // 任务类型：analysis
    private String status;      // completed/failed
    private Object result;      // 结果数据
}
```

---

## 实现清单

| 序号 | 任务 | 文件 |
|------|------|------|
| 1 | 数据库变更 | migration.sql |
| 2 | 实体新增字段 | HotWordTask.java |
| 3 | Mapper 新增 | HotWordTaskMapper.java/xml |
| 4 | QConfig 新增配置 | HotWordQConfig.java |
| 5 | 下游客户端 | DownstreamTaskClient.java |
| 6 | 下游请求/响应 | DownstreamTaskRequest.java, DownstreamTaskResponse.java |
| 7 | Service 修改 | HotWordTaskService.java |
| 8 | 回调请求类 | TaskCallbackRequest.java |
| 9 | Controller 新增接口 | HotWordController.java |
