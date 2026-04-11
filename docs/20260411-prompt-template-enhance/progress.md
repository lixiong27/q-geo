# 进度追踪

## 需求概述

**需求名称**：Prompt 模板动态参数增强
**创建日期**：2026-04-11
**负责人**：Claude AI

## 当前阶段

**阶段**：开发完成，待测试验证

## 相关文档

- [Prompt 模板工具类设计](design/prompt-template-util.md)

## 需求描述

现有 prompt 模板只支持单个 `{}` 占位符替换热词，无法满足多个动态参数替换的需求。

改进目标：
1. 支持多个动态参数替换
2. 占位符格式改为 `${变量名}`，语义更清晰
3. 参数可通过配置扩展，无需修改代码

## 业务流程

```
创建分析任务
    ↓
构建上下文参数（hotWord, taskId, date 等）
    ↓
从类型配置加载扩展参数（docUrl, baseUrl 等）
    ↓
渲染 prompt 模板，替换所有 ${xxx} 占位符
    ↓
发送给下游服务
```

## 核心逻辑

### 1. 占位符格式

**旧格式**：`{}` - 只能替换一个参数，无语义

**新格式**：`${变量名}` - 支持多个参数，语义清晰

**示例**：
```
请分析热词「${hotWord}」，参考文档：${docUrl}，任务ID：${taskId}
```

### 2. 参数来源

| 参数来源 | 参数示例 | 说明 |
|---------|---------|------|
| 系统内置 | hotWord, taskId, date | 任务执行时自动注入 |
| 类型配置 | docUrl, baseUrl | 从 hotword_type_config.json 配置 |
| 模型配置 | count, style | 预留扩展 |

### 3. 内置参数列表

| 参数名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| hotWord | String | 热词内容 | 北京天安门 |
| hotWordId | String | 热词ID | 3000 |
| taskId | String | 任务ID | 12345 |
| type | String | 任务类型 | poiAnalysis |
| date | String | 当前日期 | 2026-04-11 |
| typeDisplayName | String | 类型显示名 | POI分析 |
| callbackUrl | String | 回调地址 | http://xxx/callback |

**说明**：所有参数均为 String 类型，通过 `Map<String, String>` 传递。

## 数据设计

### 热词类型配置扩展

**文件**：`hotword_type_config.json`

```json
{
  "poiAnalysis": {
    "name": "POI分析",
    "promptParams": {
      "docUrl": "https://doc.example.com/poi",
      "baseUrl": "https://api.example.com"
    }
  },
  "platAnalysis": {
    "name": "平台分析",
    "promptParams": {
      "docUrl": "https://doc.example.com/plat",
      "baseUrl": "https://api.example.com"
    }
  }
}
```

### 模型配置示例

**文件**：`hotword_model_config.json`

```json
{
  "deepseek": {
    "prompt": "请分析热词「${hotWord}」的相关信息，参考文档：${docUrl}，任务ID：${taskId}",
    "taskType": "analysis"
  },
  "qianwen": {
    "prompt": "热词：${hotWord}，请生成相关问题，时间：${date}",
    "taskType": "analysis"
  }
}
```

## 任务清单

### 后端改造
- [x] 新增 PromptTemplateUtil 工具类
- [x] HotWordTypeConfig 新增 promptParams 字段
- [x] HotWordQConfig 支持读取 promptParams（JSON 自动解析）
- [x] AnalysisTaskExecutor 改造：buildPrompt 支持多参数
- [x] AnalysisTaskExecutor 新增 buildPromptContext 方法
- [x] 向后兼容：自动转换旧格式 `{}` → `${hotWord}`

### 配置更新
- [ ] 更新 hotword_type_config.json 配置示例
- [ ] 更新 hotword_model_config.json 配置示例

### 测试验证
- [ ] 单元测试：PromptTemplateUtil
- [ ] 集成测试：分析任务创建

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-11 | 需求分析，完成方案设计 | 已完成 |
| 2026-04-11 | 后端代码开发完成 | 已完成 |

## 下一步行动

测试验证后端功能

## 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| 旧配置不兼容 | 已有 prompt 模板失效 | 工具类自动转换 `{}` → `${hotWord}` |
| 参数缺失 | prompt 中 ${xxx} 未替换 | 缺失参数替换为空字符串 |
