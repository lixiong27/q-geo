# 进度追踪

## 需求概述

**需求名称**：热词标签优化
**创建日期**：2026-04-16
**负责人**：Claude AI

## 当前阶段

**阶段**：技术方案设计，待用户确认

## 需求描述

优化热词标签（tag）逻辑，支持从 QConfig 配置标签列表，前端通过接口获取标签并支持模糊匹配选择。

### 功能需求

1. **后端**：
   - QConfig 配置标签列表，结构：`{"tagList":[{"tagCode":"用户意图","tagDesc":"用户意图类型的tag","enabled":true}]}`
   - 新增 tagList 接口，返回启用的标签列表，支持模糊匹配

2. **前端**：
   - 热词管理模块：新增/编辑/导入热词时，从 tagList 接口获取标签，支持模糊选择
   - 热词挖掘模块：导入结果时选择标签，支持模糊选择
   - 复用现有 Select 组件样式

## 现有逻辑分析

### 后端现状

1. **数据存储**：
   - `HotWord.tags` 字段存储为逗号分隔字符串（如 `"tag1,tag2,tag3"`）
   - `HotWordVO.parseTags()` 将字符串转换为 `[{tagName: "xxx"}]` 格式返回前端

2. **接口**：
   - 新增/更新/导入热词时，tags 作为字符串直接存储
   - 无标签校验，支持任意输入

### 前端现状

1. **热词管理（HotWordManage.jsx）**：
   - 新增/编辑 Modal：使用 `Select mode="tags"` 支持自由输入
   - 批量导入 Modal：同样使用 `Select mode="tags"`

2. **热词挖掘（HotWordDig.jsx）**：
   - 导入结果时无标签选择

## 技术方案

### 后端改造

#### 1. QConfig 配置

**配置文件**：`hotword_tag_config.json`（独立配置文件，便于后续扩展）
**配置格式**：
```json
{
  "tagList": [
    {"tagCode": "用户意图", "tagDesc": "用户意图类型的tag", "enabled": true},
    {"tagCode": "地理位置", "tagDesc": "地理位置相关的tag", "enabled": true},
    {"tagCode": "时间相关", "tagDesc": "时间相关的tag", "enabled": false}
  ]
}
```

#### 2. 新增实体类

**TagConfig.java**
```java
@Data
public class TagConfig {
    private String tagCode;   // 标签代码（显示值）
    private String tagDesc;   // 标签描述
    private boolean enabled;  // 是否启用
}
```

**TagListResponse.java**
```java
@Data
public class TagListResponse extends BaseResponse {
    private List<TagConfig> list;
}
```

#### 3. 修改 HotWordQConfig

```java
// 新增字段
private List<TagConfig> tagConfigList = new ArrayList<>();

// 新增配置回调
@QConfig("hotword_tag_config.json")
public void onTagConfigChanged(String json) {
    // 解析 JSON，过滤 enabled=true 的标签
}

// 新增方法
public List<TagConfig> getTagList() {
    return tagConfigList;
}

public List<TagConfig> getTagListByKeyword(String keyword) {
    if (StringUtils.isBlank(keyword)) {
        return tagConfigList;
    }
    return tagConfigList.stream()
        .filter(tag -> tag.getTagCode().contains(keyword) ||
                       tag.getTagDesc().contains(keyword))
        .collect(Collectors.toList());
}
```

#### 4. 修改 HotWordController

```java
/**
 * 获取标签列表
 * @param keyword 模糊匹配关键词（可选）
 */
@GetMapping("/tag/list")
public TagListResponse getTagList(@RequestParam(required = false) String keyword) {
    TagListResponse response = new TagListResponse();
    try {
        List<TagConfig> list = StringUtils.isNotBlank(keyword)
            ? hotWordQConfig.getTagListByKeyword(keyword)
            : hotWordQConfig.getTagList();
        response.setList(list);
        response.setCode(0);
        response.setMsg("success");
    } catch (Exception e) {
        log.error("Failed to get tag list", e);
        response.failure(ResultEnum.SERVER_ERROR);
    }
    return response;
}
```

### 前端改造

#### 1. 新增 API（api/hotWord.js）

```javascript
/**
 * 获取标签列表
 * @param {string} keyword - 模糊匹配关键词（可选）
 */
export const getTagList = async (keyword = '') => {
    const params = keyword ? `?keyword=${encodeURIComponent(keyword)}` : '';
    return request.get(`/hotWord/tag/list${params}`);
};
```

#### 2. 修改 HotWordManage.jsx

```jsx
// 新增 state
const [tagList, setTagList] = useState([]);

// 获取标签列表
const fetchTagList = async () => {
    try {
        const res = await getTagList();
        setTagList(res.list || []);
    } catch (error) {
        console.error('Failed to fetch tag list:', error);
    }
};

useEffect(() => {
    fetchTagList();
}, []);

// 修改 Select 组件，支持模糊搜索
<Form.Item name="tags" label="标签">
    <Select
        mode="multiple"
        placeholder="请选择或输入标签"
        style={{ width: '100%' }}
        filterOption={(input, option) =>
            option.children.toLowerCase().includes(input.toLowerCase())
        }
        allowClear
    >
        {tagList.map(tag => (
            <Option key={tag.tagCode} value={tag.tagCode}>
                {tag.tagCode}
            </Option>
        ))}
    </Select>
</Form.Item>
```

#### 3. 修改 HotWordDig.jsx

在导入结果 Modal 中添加标签选择，复用相同逻辑。

#### 4. 修改 HotWordAnalysis.jsx

在导入分析结果时添加标签选择。

## 任务清单

### 后端改造
- [x] 新增 TagConfig.java 实体类
- [x] 新增 TagListResponse.java 响应类
- [x] HotWordQConfig 添加标签配置解析（独立配置文件 hotword_tag_config.json）
- [x] HotWordController 新增 tagList 接口

### 前端改造
- [x] api/hotWord.js 新增 getTagList 接口
- [x] HotWordManage.jsx 标签选择器改造（支持自定义输入 + 显示 tagDesc）

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-16 | 需求分析，创建技术文档 | 已完成 |
| 2026-04-16 | 用户确认方案 | 已完成 |
| 2026-04-16 | 后端开发完成 | 已完成 |
| 2026-04-16 | 前端开发完成 | 已完成 |

## 下一步行动

1. 后端开发
2. 前端开发
3. 联调测试

## 注意事项

1. **兼容性**：保留 `mode="tags"` 支持用户输入自定义标签
2. **显示优化**：下拉选项显示 tagCode + tagDesc
3. **配置独立**：使用独立 QConfig 文件便于后续扩展
