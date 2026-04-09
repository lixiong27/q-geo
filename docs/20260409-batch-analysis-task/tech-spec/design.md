# 热词分析批量创建任务 - 技术方案

## 1. 需求分析

### 1.1 功能目标

在热词分析页面新增「批量创建」功能，实现：
- 选择热词类型（如 poiAnalysis、platAnalysis）
- 选择多个分析模型（如 deepseek、qianwen、doubao）
- 批量为该类型下所有热词创建分析任务
- 任务名称格式：`{日期}-{热词类型}-{热词ID}`，如 `20260409-poiAnalysis-3000`

### 1.2 业务流程

```
┌─────────────────────────────────────────────────────────────┐
│                      用户操作流程                             │
├─────────────────────────────────────────────────────────────┤
│  1. 点击「批量创建」按钮                                       │
│  2. 弹窗选择：热词类型 + 分析模型(多选) + 预期数量               │
│  3. 确认后创建批量任务记录                                     │
│  4. 后台异步执行批量创建                                       │
│  5. 前端轮询或实时显示进度                                     │
└─────────────────────────────────────────────────────────────┘
```

## 2. 数据模型设计

### 2.1 HotWordTask 实体扩展

新增任务类型和进度追踪字段：

```java
// 新增任务类型
public static final String TYPE_BATCH_ANALYSIS = "batch_analysis";

// 新增字段（需要数据库表新增）
private Integer totalCount;       // 总子任务数
private Integer completedCount;   // 已完成数
private Integer failedCount;      // 失败数
private String subTaskIds;        // 子任务ID列表（JSON数组）
```

### 2.2 数据库变更（可选方案）

**方案A：新增字段**（推荐）
```sql
ALTER TABLE hot_word_task
ADD COLUMN total_count INT DEFAULT 0 COMMENT '总子任务数',
ADD COLUMN completed_count INT DEFAULT 0 COMMENT '已完成数',
ADD COLUMN failed_count INT DEFAULT 0 COMMENT '失败数',
ADD COLUMN sub_task_ids TEXT COMMENT '子任务ID列表JSON';
```

**方案B：利用 params/result 字段存储进度**
- params 存储：type、models、count
- result 存储：total、completed、failed、subTaskIds

**建议采用方案B**：无需数据库变更，利用现有字段。

## 3. 接口设计

### 3.1 批量创建接口

**请求**
```
POST /api/hotWord/task/batchAnalysis/create
```

**请求体**
```json
{
  "type": "poiAnalysis",
  "models": ["deepseek", "qianwen"],
  "count": 10
}
```

**响应**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "id": 123,
    "name": "20260409-poiAnalysis-批量任务",
    "type": "batch_analysis",
    "status": 1,
    "params": {
      "type": "poiAnalysis",
      "models": ["deepseek", "qianwen"],
      "count": 10
    }
  }
}
```

### 3.2 批量任务进度查询接口

**请求**
```
GET /api/hotWord/task/batchAnalysis/progress?id=123
```

**响应**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "id": 123,
    "status": 1,
    "total": 50,
    "completed": 30,
    "failed": 2,
    "subTasks": [
      {"id": 124, "name": "20260409-poiAnalysis-3000", "model": "deepseek", "status": 2},
      {"id": 125, "name": "20260409-poiAnalysis-3000", "model": "qianwen", "status": 1}
    ]
  }
}
```

## 4. 后端实现方案

### 4.1 请求实体

```java
@Data
public class BatchAnalysisTaskCreateRequest {
    private String type;           // 热词类型
    private List<String> models;   // 模型列表（多选）
    private Integer count;         // 预期数量
}
```

### 4.2 Service 核心逻辑

```java
/**
 * 创建批量分析任务
 */
public HotWordTask createBatchAnalysisTask(String type, List<String> models, Integer count, String createdBy) {
    // 1. 创建批量任务记录
    HotWordTask batchTask = new HotWordTask();
    batchTask.setName(LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE) + "-" + type + "-批量任务");
    batchTask.setType(HotWordTask.TYPE_BATCH_ANALYSIS);
    batchTask.setStatus(HotWordTask.STATUS_RUNNING);

    Map<String, Object> params = new HashMap<>();
    params.put("type", type);
    params.put("models", models);
    params.put("count", count);
    batchTask.setParams(JsonUtils.toJson(params));

    // 初始化进度
    Map<String, Object> result = new HashMap<>();
    result.put("total", 0);
    result.put("completed", 0);
    result.put("failed", 0);
    result.put("subTaskIds", new ArrayList<>());
    batchTask.setResult(JsonUtils.toJson(result));

    hotWordTaskMapper.insert(batchTask);

    // 2. 异步执行批量创建
    executeBatchAnalysisTaskAsync(batchTask);

    return batchTask;
}

/**
 * 异步执行批量分析任务
 */
private void executeBatchAnalysisTaskAsync(HotWordTask batchTask) {
    new Thread(() -> {
        try {
            // 解析参数
            Map<String, Object> params = JsonUtils.jsonToObject(batchTask.getParams(), ...);
            String type = (String) params.get("type");
            List<String> models = (List<String>) params.get("models");
            Integer count = (Integer) params.get("count");

            // 查询该类型的所有热词
            List<HotWord> hotWords = hotWordService.listByType(type);

            // 更新总数
            int total = hotWords.size() * models.size();
            updateBatchProgress(batchTask.getId(), total, 0, 0, new ArrayList<>());

            // 遍历创建子任务
            List<Long> subTaskIds = new ArrayList<>();
            int completed = 0, failed = 0;

            for (HotWord hotWord : hotWords) {
                for (String model : models) {
                    try {
                        // 任务名称：日期-类型-热词ID
                        String taskName = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
                            + "-" + type + "-" + hotWord.getId();

                        HotWordTask subTask = createAnalysisTask(
                            hotWord.getId(), taskName, type, model, count, "batch"
                        );
                        subTaskIds.add(subTask.getId());
                        completed++;
                    } catch (Exception e) {
                        LOG.error("Failed to create sub task for hotword {}", hotWord.getId(), e);
                        failed++;
                    }

                    // 每10个更新一次进度
                    if ((completed + failed) % 10 == 0) {
                        updateBatchProgress(batchTask.getId(), total, completed, failed, subTaskIds);
                    }
                }
            }

            // 最终更新
            updateBatchProgress(batchTask.getId(), total, completed, failed, subTaskIds);

            // 标记批量任务完成
            batchTask.setStatus(HotWordTask.STATUS_COMPLETED);
            hotWordTaskMapper.update(batchTask);

        } catch (Exception e) {
            LOG.error("Batch analysis task failed", e);
            batchTask.setStatus(HotWordTask.STATUS_FAILED);
            hotWordTaskMapper.update(batchTask);
        }
    }).start();
}
```

### 4.3 HotWordService 新增方法

```java
/**
 * 按类型查询热词列表
 */
public List<HotWord> listByType(String type) {
    return hotWordMapper.selectByType(type);
}
```

### 4.4 HotWordMapper 新增方法

```java
List<HotWord> selectByType(@Param("type") String type);
```

## 5. 前端实现方案

### 5.1 UI 变更

在 `HotWordAnalysis.jsx` 中：

1. 新增「批量创建」按钮（在「新建任务」按钮旁边）
2. 新增批量创建 Modal
3. 新增进度展示组件

### 5.2 Modal 表单字段

| 字段 | 类型 | 说明 |
|------|------|------|
| type | Select | 热词类型（单选） |
| models | Select[multiple] | 分析模型（多选） |
| count | Select | 预期数量 |

### 5.3 进度展示

```jsx
// 批量任务进度卡片
const renderBatchTaskCard = (task) => {
    const progress = JSON.parse(task.result || '{}');
    const percent = progress.total > 0
        ? Math.round((progress.completed + progress.failed) / progress.total * 100)
        : 0;

    return (
        <Card>
            <Progress percent={percent} />
            <div>总数: {progress.total} | 完成: {progress.completed} | 失败: {progress.failed}</div>
        </Card>
    );
};
```

## 6. 文件变更清单

### 后端

| 文件 | 变更 |
|------|------|
| `HotWordTask.java` | 新增 `TYPE_BATCH_ANALYSIS` 常量 |
| `BatchAnalysisTaskCreateRequest.java` | 新增请求实体 |
| `HotWordService.java` | 新增 `listByType` 方法 |
| `HotWordMapper.java` | 新增 `selectByType` 方法 |
| `HotWordMapper.xml` | 新增 SQL |
| `HotWordTaskService.java` | 新增批量创建和执行方法 |
| `HotWordController.java` | 新增批量创建接口 |

### 前端

| 文件 | 变更 |
|------|------|
| `HotWordAnalysis.jsx` | 新增批量创建按钮和 Modal |
| `hotWord.js` | 新增批量创建 API |

## 7. 测试用例

### 后端 API 测试

| 用例 | 输入 | 预期输出 |
|------|------|----------|
| 正常创建 | type=poiAnalysis, models=[deepseek,qianwen], count=10 | 返回批量任务记录，status=1 |
| 类型不存在 | type=invalid | 返回错误 |
| 模型为空 | models=[] | 返回错误 |

### 前端页面测试

| 用例 | 操作 | 预期结果 |
|------|------|----------|
| 打开批量创建弹窗 | 点击「批量创建」按钮 | 弹窗显示，表单初始化 |
| 提交批量创建 | 选择类型、多选模型、点击确定 | 提示成功，列表显示批量任务 |
| 查看进度 | 点击批量任务查看 | 显示进度条和子任务列表 |

## 8. 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| 热词数量大导致任务过多 | 数据库压力、下游服务压力 | 分批创建，每批间隔 1 秒 |
| 前端轮询频繁 | 服务端压力 | 使用较长轮询间隔（5秒），完成后停止 |
| 子任务失败影响统计 | 进度统计不准确 | 单独统计失败数量，允许部分失败 |
