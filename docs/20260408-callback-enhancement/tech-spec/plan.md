# 回调参数增强计划

## 需求概述

**需求名称**：下游任务回调参数增强
**创建日期**：2026-04-08
**目标**：请求下游服务时，将回调所需参数拼接到 prompt 中，让下游 agent 直接知道如何调用回调接口

## 方案设计

### 核心思路

将回调所需的动态参数放入 Map，转 JSON 后拼接到 prompt 末尾。下游 agent 解析 JSON 即可获取完整回调信息。

### 回调 URL 配置

回调 URL 通过 QConfig 配置获取，支持动态配置：

```java
// 配置 key
hotword.analysis.callback.url

// 默认值（QConfig 未配置时使用）
http://l-noah6b5liijvu1.auto.beta.cn0.qunar.com:8080/api/hotWord/task/callback
```

获取方式：
```java
String callbackUrl = hotFileQConfig.getString(
    "hotword.analysis.callback.url",
    "http://l-noah6b5liijvu1.auto.beta.cn0.qunar.com:8080/api/hotWord/task/callback"
);
```

### 回调参数结构

```json
{
  "callbackParams": {
    "url": "http://l-noah6b5liijvu1.auto.beta.cn0.qunar.com:8080/api/hotWord/task/callback",
    "taskId": "8078e697-4e09-4877-a271-d5c2e45c81c7",
    "type": "analysis"
  }
}
```

### 完整 prompt 示例

```
{业务 prompt 内容}

## 回调参数

任务完成后请使用以下参数调用回调接口：

**请求方式**: POST
**Content-Type**: application/json

**回调参数**:
```json
{
  "callbackParams": {
    "url": "http://l-noah6b5liijvu1.auto.beta.cn0.qunar.com:8080/api/hotWord/task/callback",
    "taskId": "8078e697-4e09-4877-a271-d5c2e45c81c7",
    "type": "analysis"
  }
}
```

**完整请求示例**:
```json
{
  "taskId": "8078e697-4e09-4877-a271-d5c2e45c81c7",
  "type": "analysis",
  "status": "completed",
  "result": {
    "total": 3,
    "words": [{"word": "关键词1", "type": "poiAnalysis"}]
  }
}
```

**curl 示例**:
```bash
curl -X POST "http://l-noah6b5liijvu1.auto.beta.cn0.qunar.com:8080/api/hotWord/task/callback" \
  -H "Content-Type: application/json" \
  -d '{"taskId":"8078e697-4e09-4877-a271-d5c2e45c81c7","type":"analysis","status":"completed","result":{"total":3,"words":[{"word":"关键词1","type":"poiAnalysis"}]}}'
```
```

## 实现方案

### 修改 AnalysisTaskExecutor

**文件**: `AnalysisTaskExecutor.java`

修改 `doExecute` 方法，拼接回调参数：

```java
// 回调 URL 配置 key
private static final String CALLBACK_URL_KEY = "hotword.analysis.callback.url";
private static final String DEFAULT_CALLBACK_URL = "http://l-noah6b5liijvu1.auto.beta.cn0.qunar.com:8080/api/hotWord/task/callback";

@Autowired
private HotFileQConfig hotFileQConfig;

@Override
protected Map<String, Object> doExecute(HotWordTask task) throws Exception {
    Map<String, Object> params = parseParams(task);
    String hotword = (String) params.get("hotword");
    String promptTemplate = (String) params.get("prompt");

    // 构造业务 prompt
    String businessPrompt = buildPrompt(promptTemplate, hotword);

    // 先生成下游任务ID
    String downstreamTaskId = UUID.randomUUID().toString();

    // 构建回调参数并拼接
    String callbackInfo = buildCallbackInfo(downstreamTaskId, task.getType());
    String fullPrompt = businessPrompt + "\n\n" + callbackInfo;

    // 调用下游服务
    String returnedTaskId = downstreamTaskClient.createTask(
        task.getName(), fullPrompt, 5, 3);

    // 保存下游任务ID
    hotWordTaskMapper.updateDownstreamTaskId(task.getId(), downstreamTaskId);

    return null;
}

/**
 * 构建回调说明信息
 */
private String buildCallbackInfo(String taskId, String taskType) {
    // 从 QConfig 获取回调 URL，取不到则使用默认值
    String callbackUrl = hotFileQConfig.getString(CALLBACK_URL_KEY, DEFAULT_CALLBACK_URL);

    // 构建回调参数 Map
    Map<String, String> callbackParams = new HashMap<>();
    callbackParams.put("url", callbackUrl);
    callbackParams.put("taskId", taskId);
    callbackParams.put("type", taskType);

    // 转成 JSON 字符串
    String callbackParamsJson = JSON.toJSONString(callbackParams);

    // 构建完整说明
    return String.format(CALLBACK_TEMPLATE, callbackParamsJson, callbackUrl, taskId, taskType);
}

private static final String CALLBACK_TEMPLATE = """
## 回调参数

任务完成后请使用以下参数调用回调接口：

**请求方式**: POST
**Content-Type**: application/json

**回调参数**:
```json
{
  "callbackParams": %s
}
```

**完整请求示例**:
```json
{
  "taskId": "%s",
  "type": "%s",
  "status": "completed",
  "result": {
    "total": 3,
    "words": [{"word": "关键词1", "type": "类型"}]
  }
}
```

**curl 示例**:
```bash
curl -X POST "%s" \\
  -H "Content-Type: application/json" \\
  -d '{"taskId":"%s","type":"%s","status":"completed","result":{"total":3,"words":[{"word":"关键词1","type":"类型"}]}}'
```
""";
```

## 任务清单

### 后端改造
- [x] 1.1 修改 `AnalysisTaskExecutor` 添加回调参数拼接逻辑
- [x] 1.2 注入 `HotFileQConfig` 依赖
- [x] 1.3 从 QConfig 获取回调 URL（key: `hotword.analysis.callback.url`）

### 配置更新
- [ ] 2.1 在 QConfig 添加回调 URL 配置（可选，有默认值兜底）

### 测试验证
- [ ] 3.1 本地测试验证 prompt 包含回调参数
- [ ] 3.2 端到端测试

## 文件变更清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `AnalysisTaskExecutor.java` | 修改 | 添加回调参数拼接逻辑，注入 HotFileQConfig |
| `hotfile.properties` | 可选修改 | 添加 `hotword.analysis.callback.url` 配置 |

## 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| prompt 长度增加 | token 消耗略增 | 影响可控 |
| 回调 URL 变更 | 需要更新配置 | 已支持 QConfig 动态配置 |

