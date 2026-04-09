# 热词手动导入模块增强方案

## 需求背景

当前热词手动导入功能只支持批量输入热词文本，无法为导入的热词设置类型和标签。需要增强导入功能，支持批量设置类型和标签。

## 现状分析

### 后端现状

**HotWordImportRequest.java**
```java
@Data
public class HotWordImportRequest {
    private List<String> words;  // 仅支持热词列表
}
```

**HotWordService.batchImport()**
```java
public int batchImport(List<String> words) {
    // 导入时只设置 word、sourceType、sourceTaskId
    // 未设置 type 和 tags
}
```

### 前端现状

**HotWordManage.jsx** 导入弹窗：
- 只有 TextArea 输入热词（每行一个）
- 无类型选择
- 无标签输入

## 方案设计

### 后端方案

#### 1. 请求实体改造

**文件**: `HotWordImportRequest.java`

```java
@Data
public class HotWordImportRequest {
    private List<String> words;
    private String type;           // 新增：热词类型
    private List<String> tags;     // 新增：标签列表
}
```

#### 2. Service 方法改造

**文件**: `HotWordService.java`

```java
/**
 * 批量导入热词（支持类型和标签）
 */
public int batchImport(List<String> words, String type, List<String> tags) {
    // 将 tags 列表转为逗号分隔字符串
    String tagsStr = (tags != null && !tags.isEmpty())
        ? String.join(",", tags)
        : null;

    List<HotWord> hotWords = new ArrayList<>();
    for (String word : words) {
        if (word == null || word.trim().isEmpty()) {
            continue;
        }
        // 跳过已存在的
        if (hotWordMapper.selectByWord(word.trim()) != null) {
            continue;
        }
        HotWord hotWord = new HotWord();
        hotWord.setWord(word.trim());
        hotWord.setSourceType(HotWord.SOURCE_TYPE_MANUAL);
        hotWord.setSourceTaskId(0L);
        hotWord.setType(type);         // 设置类型
        hotWord.setTags(tagsStr);      // 设置标签
        hotWords.add(hotWord);
    }
    if (!hotWords.isEmpty()) {
        hotWordMapper.batchInsert(hotWords);
    }
    return hotWords.size();
}
```

#### 3. Controller 改造

**文件**: `HotWordController.java`

```java
@PostMapping("/import")
public HotWordImportResponse batchImport(@RequestBody HotWordImportRequest request) {
    HotWordImportResponse response = new HotWordImportResponse();
    try {
        int count = hotWordService.batchImport(
            request.getWords(),
            request.getType(),
            request.getTags()
        );
        response.setImportedCount(count);
        response.setCode(0);
        response.setMsg("success");
    } catch (Exception e) {
        response.failure(ResultEnum.SERVER_ERROR);
    }
    return response;
}
```

### 前端方案

#### 1. API 改造

**文件**: `src/api/hotWord.js`

```javascript
// 导入热词接口已有，参数结构需调整
export const importHotWord = (data) => {
    return request.post('/api/hotWord/import', data);
};
// data 结构: { words: [], type: '', tags: [] }
```

#### 2. Import Modal 改造

**文件**: `src/pages/hotword/HotWordManage.jsx`

在导入弹窗的 Form 中新增：

```jsx
{/* Import Modal */}
<Modal
    title="手动导入"
    visible={importModalVisible}
    onOk={handleImport}
    onCancel={() => {
        setImportModalVisible(false);
        importForm.resetFields();
    }}
    okText="导入"
    cancelText="取消"
    width={520}
>
    <Form form={importForm} layout="vertical">
        <Form.Item
            name="words"
            label="热词内容"
            extra="每行一个热词"
            rules={[{ required: true, message: '请输入热词' }]}
        >
            <TextArea
                rows={8}
                placeholder="北京天安门&#10;GPT-5发布&#10;智能驾驶"
            />
        </Form.Item>

        {/* 新增：类型选择 */}
        <Form.Item
            name="type"
            label="热词类型"
        >
            <Select placeholder="请选择类型（可选）" allowClear>
                {typeList.map(item => (
                    <Option key={item.key} value={item.key}>
                        {item.name}
                    </Option>
                ))}
            </Select>
        </Form.Item>

        {/* 新增：标签输入 */}
        <Form.Item
            name="tags"
            label="标签"
            extra="输入后按回车添加，所有导入的热词将共用这些标签"
        >
            <Select
                mode="tags"
                placeholder="添加标签"
                style={{ width: '100%' }}
            />
        </Form.Item>
    </Form>
</Modal>
```

#### 3. handleImport 方法调整

```javascript
const handleImport = async () => {
    try {
        const values = await importForm.validateFields();
        const words = values.words.split('\n').filter(w => w.trim());
        if (words.length === 0) {
            message.warning('请输入热词');
            return;
        }
        // 调整请求参数结构
        await importHotWord({
            words,
            type: values.type,
            tags: values.tags
        });
        message.success(`成功导入 ${words.length} 个热词`);
        setImportModalVisible(false);
        importForm.resetFields();
        fetchData();
    } catch (error) {
        if (error.errorFields) return;
        message.error(error.message);
    }
};
```

## 改动文件清单

### 后端（3个文件）

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `HotWordImportRequest.java` | 修改 | 新增 type、tags 字段 |
| `HotWordService.java` | 修改 | batchImport 方法签名和实现 |
| `HotWordController.java` | 修改 | 传递新参数 |

### 前端（1个文件）

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `HotWordManage.jsx` | 修改 | Import Modal 增加 type/tags 选择 |

## 兼容性说明

- 后端改动**向后兼容**：新增字段为可选，旧请求（只有 words）仍可正常处理
- 前端改动仅涉及 UI 层，不影响其他功能

## 测试要点

1. 导入时不选择类型和标签 → 正常导入，type/tags 为空
2. 导入时选择类型，不选标签 → 正常导入，有 type 无 tags
3. 导入时选择类型和多个标签 → 正常导入，type 和 tags 都有
4. 导入已存在的热词 → 跳过，不计入导入数量
