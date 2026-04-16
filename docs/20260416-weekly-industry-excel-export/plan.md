# WeeklyIndustryAnalysisExecutor Excel 导出功能实现计划

## 需求概述

**需求名称**：WeeklyIndustryAnalysisExecutor Excel 导出
**创建日期**：2026-04-16
**负责人**：AI

## 需求背景

`WeeklyIndustryAnalysisExecutor` 执行器已完成周维度行业词分析，需要通过 `GeoAnalysisController#downloadExecutorResult` 接口导出 Excel 文件。

参考示例：`.prevpython/行业词内容统计结果示例.xlsx`

## Excel 表头结构分析

根据 Python 代码 `stat_analysis.py` 中的 `write_brand_content_excel` 函数分析：

### 表头结构（共22列）

| 行号 | 内容说明 |
|------|----------|
| Row 1 | 标题行：`行业词`（合并单元格），品牌名（去哪儿、同程、携程、飞猪、美团）各占4列 |
| Row 2 | 指标列头：`指标`，每个品牌下4个模型（DeepSeek、豆包、通义千问、元宝） |
| Row 3+ | 数据行 |

### 数据行结构

每个维度输出3行数据：
1. **内容提及率**：该品牌被提及的 query 占比
2. **平均排名**：在排名词中的平均排名位置
3. **第一名次数**：排名第一的次数占比

### 列布局

```
| 维度 | 指标 | 去哪儿(DeepSeek,豆包,通义千问,元宝) | 同程(DeepSeek,豆包,通义千问,元宝) | ... |
```

## 技术方案

### 1. 新增 Excel VO 类

**文件路径**：`backend/ares_analysisterm/mkt_ares_analysisterm_web/src/main/java/com/qunar/ug/flight/contact/ares/analysisterm/domain/entity/geo/excel/WeeklyIndustryAnalysisExcelVO.java`

由于 Excel 表头结构复杂（多行合并、动态列），采用 EasyExcel 的动态写入方式，不使用注解方式的 VO。

### 2. 新增 Excel 导出器

**文件路径**：`backend/ares_analysisterm/mkt_ares_analysisterm_web/src/main/java/com/qunar/ug/flight/contact/ares/analysisterm/service/geo/analysis/export/WeeklyIndustryAnalysisExcelExporter.java`

实现 `ExecutorExcelExporter` 接口，负责：
- 解析 `WeeklyIndustryAnalysisResult` 数据
- 构建复杂表头
- 动态生成数据行

### 3. 数据结构映射

**输入数据结构**（来自 Executor 的 summary）：
```json
{
  "results": [
    {
      "dimension": "综合统计",
      "platform": "去哪儿",
      "model": "DeepSeek",
      "mentionRate": 0.907,
      "avgRank": 3.8,
      "firstRankCount": "7/30"
    }
  ],
  "resultsByDimension": {
    "综合统计": [...]
  }
}
```

**输出 Excel 结构**：
- 使用 EasyExcel 的 `write` 方法动态写入
- 表头分两行写入
- 数据按维度分组，每个维度输出3行

## 实现步骤

### Step 1：创建 Excel 导出器类

```java
@Slf4j
@Component
public class WeeklyIndustryAnalysisExcelExporter implements ExecutorExcelExecutor {
    // 品牌列表
    private static final List<String> BRANDS = Arrays.asList("去哪儿", "同程", "携程", "飞猪", "美团");
    // 模型列表
    private static final List<String> MODELS = Arrays.asList("DeepSeek", "豆包", "通义千问", "元宝");

    @Override
    public String getExecutorCode() {
        return "weeklyIndustryAnalysisExecutor";
    }

    @Override
    public byte[] export(Object data) throws IOException {
        // 实现导出逻辑
    }
}
```

### Step 2：实现表头构建

- 第1行：标题 + 品牌合并单元格
- 第2行：指标 + 模型名称

### Step 3：实现数据转换

从 `resultsByDimension` 中提取数据，按维度、指标组织成行

### Step 4：数据格式化

- 内容提及率：保留4位小数
- 平均排名：保留2位小数
- 第一名次数：百分比格式（如 85.33%）

## 任务清单

### 后端
- [ ] 创建 `WeeklyIndustryAnalysisExcelExporter.java`
- [ ] 实现表头构建逻辑
- [ ] 实现数据转换逻辑
- [ ] 实现百分比格式化
- [ ] 单元测试验证导出结果

### 提交验证
- [ ] 后端编译通过
- [ ] 后端代码 commit + push

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-16 | 创建计划文档 | 已完成 |

## 下一步行动

1. 用户确认计划方案
2. 开始实现 `WeeklyIndustryAnalysisExcelExporter.java`

## 风险与问题

| 风险/问题 | 影响 | 解决方案 | 状态 |
|-----------|------|----------|------|
| Excel 表头合并单元格复杂 | 中等 | 使用 EasyExcel 的动态写入 API | 待处理 |
