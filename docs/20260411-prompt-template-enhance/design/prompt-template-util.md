# Prompt 模板工具类设计

## 一、概述

### 1.1 背景

现有 prompt 模板替换逻辑只支持单个 `{}` 占位符：

```java
// 当前实现
private String buildPrompt(String promptTemplate, String hotword) {
    return promptTemplate.replace("{}", hotword);
}
```

**局限性**：
- 只能替换一个参数
- 占位符 `{}` 无语义
- 无法通过配置扩展参数

### 1.2 目标

- 支持多个动态参数替换
- 占位符格式改为 `${变量名}`
- 参数可通过配置扩展
- 向后兼容旧格式

## 二、技术方案

### 2.1 占位符格式

**新格式**：`${变量名}`

**命名规则**：
- 仅支持字母、数字、下划线
- 正则表达式：`\$\{(\w+)\}`

**示例**：
```
原始模板：
请分析热词「${hotWord}」，参考文档：${docUrl}，任务ID：${taskId}

上下文参数：
{
  "hotWord": "北京天安门",
  "docUrl": "https://doc.example.com/poi",
  "taskId": "12345"
}

渲染结果：
请分析热词「北京天安门」，参考文档：https://doc.example.com/poi，任务ID：12345
```

### 2.2 参数来源优先级

```
任务参数 > 类型配置参数 > 系统默认值
```

### 2.3 内置参数

| 参数名 | 类型 | 说明 | 来源 |
|--------|------|------|------|
| hotWord | String | 热词内容 | 任务关联热词 |
| hotWordId | String | 热词ID | 任务关联热词 |
| taskId | String | 任务ID | 当前任务 |
| type | String | 任务类型 | 任务属性 |
| date | String | 当前日期 | 系统时间 (yyyy-MM-dd) |
| typeDisplayName | String | 类型显示名 | 类型配置 |
| callbackUrl | String | 回调地址 | QConfig 配置 |

## 三、核心代码

### 3.1 PromptTemplateUtil 工具类

```java
package com.qunar.ug.flight.contact.ares.analysisterm.infra.util;

import org.apache.commons.lang3.StringUtils;

import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Prompt 模板工具类
 * 支持 ${变量名} 格式的动态参数替换
 *
 * 示例：
 *   模板: "分析 ${hotWord}，参考 ${docUrl}"
 *   参数: {"hotWord": "北京", "docUrl": "http://..."}
 *   结果: "分析 北京，参考 http://..."
 */
public class PromptTemplateUtil {

    /**
     * 占位符正则：${变量名}
     */
    private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile("\\$\\{(\\w+)}");

    /**
     * 渲染模板
     *
     * @param template 模板字符串
     * @param context  上下文参数 (Map<String, String>)
     * @return 替换后的字符串
     */
    public static String render(String template, Map<String, String> context) {
        if (StringUtils.isEmpty(template)) {
            return template;
        }
        if (context == null || context.isEmpty()) {
            return template;
        }

        StringBuffer result = new StringBuffer();
        Matcher matcher = PLACEHOLDER_PATTERN.matcher(template);

        while (matcher.find()) {
            String key = matcher.group(1);  // 提取 ${xxx} 中的 xxx
            String value = context.get(key);
            String replacement = value != null ? Matcher.quoteReplacement(value) : "";
            matcher.appendReplacement(result, replacement);
        }
        matcher.appendTail(result);

        return result.toString();
    }

    /**
     * 兼容旧格式：将 {} 替换为 ${hotWord}
     *
     * @param legacyTemplate 旧格式模板
     * @return 新格式模板
     */
    public static String legacyToNew(String legacyTemplate) {
        if (legacyTemplate == null) {
            return null;
        }
        return legacyTemplate.replace("{}", "${hotWord}");
    }

    /**
     * 智能渲染（自动兼容旧格式）
     *
     * @param template 模板（支持新旧格式）
     * @param context 上下文参数 (Map<String, String>)
     * @return 替换后的字符串
     */
    public static String smartRender(String template, Map<String, String> context) {
        if (StringUtils.isEmpty(template)) {
            return template;
        }

        // 检测旧格式并转换
        if (template.contains("{}") && !template.contains("${")) {
            template = legacyToNew(template);
        }

        return render(template, context);
    }
}
```

### 3.2 HotWordTypeConfig 扩展

```java
@Data
public class HotWordTypeConfig {
    private String key;   // 类型标识
    private String name;  // 显示名称

    /**
     * prompt 扩展参数
     * 用于模板中的 ${xxx} 替换
     */
    private Map<String, String> promptParams;
}
```

### 3.3 AnalysisTaskExecutor 改造

```java
/**
 * 构造完整 prompt（支持多参数）
 */
private String buildPrompt(String promptTemplate, Map<String, String> context) {
    if (StringUtils.isEmpty(promptTemplate)) {
        String hotWord = context.getOrDefault("hotWord", "");
        return "请分析以下热词，生成相关的搜索词：\n热词：" + hotWord;
    }

    // 使用智能渲染，兼容新旧格式
    return PromptTemplateUtil.smartRender(promptTemplate, context);
}

/**
 * 构建 prompt 上下文参数
 */
private Map<String, String> buildPromptContext(HotWordTask task, HotWord hotWord) {
    Map<String, String> context = new HashMap<>();

    // 1. 系统内置参数
    context.put("hotWord", hotWord.getWord());
    context.put("hotWordId", String.valueOf(hotWord.getId()));
    context.put("taskId", String.valueOf(task.getId()));
    context.put("type", task.getType());
    context.put("date", LocalDate.now().toString());

    // 2. 回调地址
    String callbackUrl = hotFileQConfig.getString(CALLBACK_URL_KEY, DEFAULT_CALLBACK_URL);
    context.put("callbackUrl", callbackUrl);

    // 3. 从类型配置加载扩展参数
    HotWordTypeConfig typeConfig = hotWordQConfig.getTypeConfig(task.getType());
    if (typeConfig != null) {
        context.put("typeDisplayName", typeConfig.getName());

        // 合并类型配置的 promptParams
        if (typeConfig.getPromptParams() != null) {
            context.putAll(typeConfig.getPromptParams());
        }
    }

    return context;
}
```

### 3.4 调用方式变更

```java
// 旧方式
String prompt = buildPrompt(promptTemplate, hotWord.getWord());

// 新方式
Map<String, String> context = buildPromptContext(task, hotWord);
String prompt = buildPrompt(promptTemplate, context);
```

## 四、配置示例

### 4.1 hotword_type_config.json

```json
{
  "poiAnalysis": {
    "key": "poiAnalysis",
    "name": "POI分析",
    "promptParams": {
      "docUrl": "https://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=123456",
      "apiDoc": "https://api.doc.example.com/poi",
      "environment": "production"
    }
  },
  "platAnalysis": {
    "key": "platAnalysis",
    "name": "平台分析",
    "promptParams": {
      "docUrl": "https://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=789012",
      "apiDoc": "https://api.doc.example.com/plat"
    }
  }
}
```

**说明**：`promptParams` 为 `Map<String, String>` 类型，所有值均为字符串。

### 4.2 hotword_model_config.json

```json
{
  "deepseek": {
    "prompt": "请分析热词「${hotWord}」的相关信息。\n\n任务信息：\n- 任务ID：${taskId}\n- 任务类型：${typeDisplayName}\n- 创建日期：${date}\n\n参考文档：${docUrl}\n\n完成后请回调：${callbackUrl}",
    "taskType": "analysis"
  },
  "qianwen": {
    "prompt": "热词：${hotWord}\n\n请根据上述热词生成相关分析内容。\n\n文档参考：${docUrl}\n回调地址：${callbackUrl}",
    "taskType": "analysis"
  },
  "doubao": {
    "prompt": "分析任务 [${taskId}]：请对「${hotWord}」进行深度分析，完成后回调 ${callbackUrl}",
    "taskType": "analysis"
  }
}
```

## 五、兼容性策略

### 5.1 向后兼容

| 场景 | 旧格式 | 新格式 | 处理方式 |
|------|--------|--------|----------|
| 现有配置 | `分析 {}` | - | 自动转换为 `分析 ${hotWord}` |
| 新配置 | - | `分析 ${hotWord}` | 直接使用 |
| 混合格式 | `分析 {}，参考 ${docUrl}` | - | 不支持，需人工修正 |

### 5.2 参数缺失处理

```java
// 参数缺失时替换为空字符串
context.put("docUrl", null);  // ${docUrl} → ""
context 不包含 "docUrl";      // ${docUrl} → ""
```

### 5.3 特殊字符转义

```java
// 使用 Matcher.quoteReplacement 处理特殊字符
// 如 $、\ 等字符会被正确处理
context.put("hotWord", "价格$100");  // 正确渲染，不会将 $1 当作分组引用
```

## 六、测试用例

### 6.1 单元测试

```java
@Test
public void testRender() {
    Map<String, String> context = new HashMap<>();
    context.put("hotWord", "北京天安门");
    context.put("docUrl", "https://example.com");

    String result = PromptTemplateUtil.render(
        "请分析 ${hotWord}，参考 ${docUrl}",
        context
    );

    assertEquals("请分析 北京天安门，参考 https://example.com", result);
}

@Test
public void testLegacyToNew() {
    assertEquals("分析 ${hotWord}", PromptTemplateUtil.legacyToNew("分析 {}"));
}

@Test
public void testSmartRender() {
    Map<String, String> context = new HashMap<>();
    context.put("hotWord", "测试热词");

    // 旧格式自动转换
    String result = PromptTemplateUtil.smartRender("分析 {}", context);
    assertEquals("分析 测试热词", result);

    // 新格式直接渲染
    result = PromptTemplateUtil.smartRender("分析 ${hotWord}", context);
    assertEquals("分析 测试热词", result);
}

@Test
public void testMissingParam() {
    Map<String, String> context = new HashMap<>();
    context.put("hotWord", "测试");

    String result = PromptTemplateUtil.render("${hotWord} - ${missing}", context);
    assertEquals("测试 - ", result);  // 缺失参数替换为空字符串
}

@Test
public void testSpecialChars() {
    Map<String, String> context = new HashMap<>();
    context.put("hotWord", "价格$100\\折扣");

    String result = PromptTemplateUtil.render("${hotWord}", context);
    assertEquals("价格$100\\折扣", result);  // 特殊字符正确处理
}
```

## 七、扩展性设计

### 7.1 参数扩展点

```
┌─────────────────────────────────────────────────────────┐
│                    Prompt 渲染流程                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │ 系统内置参数 │ →  │ 类型配置参数 │ →  │ 任务参数    │ │
│  │ hotWord     │    │ docUrl      │    │ (预留)      │ │
│  │ taskId      │    │ baseUrl     │    │             │ │
│  │ date        │    │             │    │             │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
│         ↓                  ↓                  ↓         │
│  ┌─────────────────────────────────────────────────────┐│
│  │              上下文参数合并            ││
│  └─────────────────────────────────────────────────────┘│
│                          ↓                              │
│  ┌─────────────────────────────────────────────────────┐│
│  │              PromptTemplateUtil.render()             ││
│  └─────────────────────────────────────────────────────┘│
│                          ↓                              │
│                   最终 Prompt                           │
└─────────────────────────────────────────────────────────┘
```

### 7.2 未来扩展方向

1. **任务级参数覆盖**：允许创建任务时传入自定义参数
2. **参数默认值**：配置中定义参数默认值
3. **条件参数**：根据条件选择不同的参数值
4. **参数转换器**：支持日期格式化、字符串处理等

## 八、影响范围

### 8.1 代码变更

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| PromptTemplateUtil.java | 新增 | 模板渲染工具类 |
| HotWordTypeConfig.java | 修改 | 新增 promptParams 字段 |
| HotWordQConfig.java | 修改 | 无需改动，JSON 自动解析 |
| AnalysisTaskExecutor.java | 修改 | buildPrompt 方法改造 |

### 8.2 配置变更

| 配置文件 | 变更类型 | 说明 |
|----------|----------|------|
| hotword_type_config.json | 扩展 | 新增 promptParams 字段（可选） |
| hotword_model_config.json | 扩展 | prompt 格式升级（向后兼容） |

### 8.3 兼容性

- ✅ 完全向后兼容旧配置
- ✅ 无需修改现有 prompt 模板
- ✅ 增量式升级，不影响已有功能
