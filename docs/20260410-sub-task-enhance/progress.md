# 批量分析子任务优化

## 需求背景

1. 批量分析任务创建的子任务，type 使用 `subAnalysis` 标识，与单任务 `analysis` 区分
2. 任务列表默认展示 `batch` 和 `analysis` 类型，用户可手动勾选展示 `subAnalysis`
3. 批量父任务支持点击查看所有子任务详情（浮层展示）

## 方案概述

### 1. 后端改动

- 新增 `subAnalysis` 任务类型常量
- 批量任务创建子任务时使用 `subAnalysis` 类型
- 新增根据 ID 列表查询任务接口

### 2. 前端改动

- 任务列表默认查询 `analysis` 和 `batch_analysis`
- 新增复选框：是否展示子任务（subAnalysis）
- 批量任务卡片点击时，弹窗展示子任务列表

## 技术方案

### 1. 后端改动

#### 1.1 HotWordTask.java - 新增类型常量

```java
public static final String TYPE_ANALYSIS = "analysis";
public static final String TYPE_SUB_ANALYSIS = "subAnalysis";  // 新增：批量子任务类型
public static final String TYPE_BATCH_ANALYSIS = "batch_analysis";
```

#### 1.2 HotWordTaskMapper.java - 新增批量查询方法

```java
List<HotWordTask> selectByIds(@Param("ids") List<Long> ids, @Param("limit") Integer limit);
```

#### 1.3 HotWordTaskMapper.xml - 新增 SQL

```xml
<select id="selectByIds" resultMap="BaseResultMap">
    SELECT * FROM hot_word_task
    WHERE id IN
    <foreach collection="ids" item="id" open="(" separator="," close=")">
        #{id}
    </foreach>
    ORDER BY id DESC
    <if test="limit != null">
        LIMIT #{limit}
    </if>
</select>
```

#### 1.4 HotWordTaskService.java - 修改子任务创建逻辑

```java
// createAnalysisTask 方法新增参数 isSubTask
public HotWordTask createAnalysisTask(Long hotwordId, String name, String type,
        String model, Integer count, String createdBy, Long sourceBatchTaskId, boolean isSubTask) {
    // ...
    task.setType(isSubTask ? HotWordTask.TYPE_SUB_ANALYSIS : HotWordTask.TYPE_ANALYSIS);
    // ...
}

// 新增获取子任务列表方法（支持 limit，从 QConfig 获取最大值）
public List<HotWordTask> getSubTasks(List<Long> subTaskIds) {
    if (subTaskIds == null || subTaskIds.isEmpty()) {
        return new ArrayList<>();
    }
    int maxLimit = hotFileQConfig.getInt("subtask.query.max.limit", 1000);
    return hotWordTaskMapper.selectByIds(subTaskIds, maxLimit);
}
```

#### 1.5 HotFileQConfig 配置项

| Key | 默认值 | 说明 |
|-----|--------|------|
| `subtask.query.max.limit` | 1000 | 子任务查询最大数量 |

#### 1.6 HotWordController.java - 新增接口

```java
@GetMapping("/task/subTasks")
public Response<Map<String, Object>> getSubTasks(@RequestParam("ids") List<Long> ids) {
    List<HotWordTask> tasks = hotWordTaskService.getSubTasks(ids);
    Map<String, Object> result = new HashMap<>();
    result.put("list", tasks.stream().map(this::toDetailResponse).collect(Collectors.toList()));
    result.put("total", ids.size());  // 返回总数用于前端分页
    return Response.success(result);
}
```

### 2. 前端改动

#### 2.1 hotWord.js - 新增接口

```javascript
/**
 * 批量获取任务详情
 * @param {Array<number>} ids - Task IDs
 */
export const getTasksByIds = async (ids) => {
    const queryParams = ids.map(id => `ids=${id}`).join('&');
    return request.get(`/hotWord/task/subTasks?${queryParams}`);
};
```

#### 2.2 HotWordAnalysis.jsx - 改动点

1. **状态新增**
```jsx
const [showSubTasks, setShowSubTasks] = useState(false);  // 是否展示子任务
const [subTaskModalVisible, setSubTaskModalVisible] = useState(false);  // 子任务浮层
const [currentBatchTask, setCurrentBatchTask] = useState(null);  // 当前查看的批量任务
const [subTasks, setSubTasks] = useState([]);  // 子任务列表
const [subTaskTotal, setSubTaskTotal] = useState(0);  // 子任务总数（用于前端分页）
const [subTaskLoading, setSubTaskLoading] = useState(false);
```

2. **查询类型变化**
```jsx
const fetchTaskList = async () => {
    const types = ['analysis', 'batch_analysis'];
    if (showSubTasks) {
        types.push('subAnalysis');
    }
    const res = await getTaskList({ types, name: searchName, page, size });
    // ...
};
```

3. **批量任务卡片点击查看子任务**
```jsx
const handleViewSubTasks = async (task) => {
    const subTaskIds = task.result?.subTaskIds || [];
    if (subTaskIds.length === 0) {
        message.info('暂无子任务');
        return;
    }

    setSubTaskLoading(true);
    setSubTaskModalVisible(true);
    setCurrentBatchTask(task);
    setSubTaskTotal(subTaskIds.length);  // 保存总数用于分页

    try {
        const res = await getTasksByIds(subTaskIds);
        setSubTasks(res.list || []);
    } catch (error) {
        message.error(error.message);
    } finally {
        setSubTaskLoading(false);
    }
};
```

4. **UI 新增复选框和子任务浮层（带前端分页）**
```jsx
{/* 复选框：展示子任务 */}
<Checkbox
    checked={showSubTasks}
    onChange={(e) => {
        setShowSubTasks(e.target.checked);
        setPage(1);
    }}
>
    展示子任务
</Checkbox>

{/* 批量任务卡片操作按钮 */}
<Button size="small" onClick={() => handleViewSubTasks(task)}>
    查看子任务
</Button>

{/* 子任务浮层 Modal（前端分页） */}
<Modal
    title={`子任务列表 - ${currentBatchTask?.name} (共 ${subTaskTotal} 个)`}
    visible={subTaskModalVisible}
    onCancel={() => setSubTaskModalVisible(false)}
    footer={null}
    width={800}
>
    {subTaskLoading ? <Spin /> : (
        <>
            {/* 子任务列表展示（前端分页，每页10条） */}
            <List
                dataSource={subTasks}
                pagination={{
                    pageSize: 10,
                    showSizeChanger: false,
                    showTotal: (total) => `共 ${total} 条`
                }}
                renderItem={subTask => (
                    <List.Item>
                        {/* 子任务卡片内容 */}
                    </List.Item>
                )}
            />
        </>
    )}
</Modal>
```

---

## 任务清单

### 后端
- [x] HotWordTask 新增 TYPE_SUB_ANALYSIS 常量
- [x] HotWordTaskMapper 新增 selectByIds 方法（支持 limit 参数）
- [x] HotWordTaskMapper.xml 新增 SQL（支持 limit）
- [x] HotWordTaskService 修改 createAnalysisTask 支持 isSubTask 参数
- [x] HotWordTaskService 新增 getSubTasks 方法（从 QConfig 读取 maxLimit）
- [x] HotWordController 新增 /task/subTasks 接口（返回 list + total）
- [x] 编译验证

### 前端
- [x] hotWord.js 新增 getSubTasks 接口
- [x] HotWordAnalysis.jsx 新增 showSubTasks 状态和复选框
- [x] HotWordAnalysis.jsx 新增子任务浮层 Modal（前端分页，每页10条）
- [x] HotWordAnalysis.jsx 批量任务卡片新增查看子任务按钮
- [ ] 前端编译验证（Node.js 环境问题，代码已修改完成）

### 提交
- [ ] 提交后端代码
- [ ] 提交前端代码
- [ ] 更新外部仓库

## 当前进度

**阶段：** 代码已完成
**下一步：** 提交代码到三个仓库
