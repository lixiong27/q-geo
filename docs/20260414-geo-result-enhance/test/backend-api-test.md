# GEO 分析结果页增强 - 后端接口测试

## 测试环境
- URL: http://mkt-ares-analysisterm.market-analysis.inner3.beta.qunar.com

## 测试用例

### 1. 获取结果列表 - 验证 templateName 字段

**接口:** GET /api/geo/analysis/result/list

**测试步骤:**
1. 调用接口获取结果列表
2. 验证返回数据中包含 templateId 和 templateName 字段

**预期结果:**
- 返回数据中每条记录包含 templateId（模板ID）和 templateName（模板名称）

### 2. 获取结果详情 - 验证 params 包含 templateName

**接口:** GET /api/geo/analysis/result/detail?id={id}

**测试步骤:**
1. 选择一个已执行的结果记录
2. 调用详情接口
3. 解析 params 字段为 JSON
4. 验证 params 中包含 templateName 字段

**预期结果:**
- params JSON 中包含 templateName 字段

## 测试执行记录

| 用例 | 执行时间 | 结果 | 备注 |
|-----|---------|------|------|
| 结果列表 templateName | | | |
| 结果详情 params.templateName | | | |
