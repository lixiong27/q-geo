# GEO 分析结果页增强

**需求描述：**
1. 去掉结果页轮询机制
2. 后端在 params 中写入模板名称
3. 结果页展示模板名称和 ID
4. 模板页支持跳转到对应结果页

## 进度追踪

### 后端改造
- [x] GeoAnalysisResult 实体添加 templateName 字段
- [x] GeoAnalysisResultService.triggerExecution 在 params 中写入 templateName
- [x] 修改 SQL 查询关联 template 表获取 templateName

### 前端改造
- [x] GeoAnalysisResult.jsx 移除轮询逻辑
- [x] 结果列表添加模板名称和 ID 列
- [x] GeoAnalysisTemplate.jsx 添加"查看结果"操作按钮

### 测试验证
- [ ] 后端 API 测试
- [ ] 前端页面测试

## 技术方案

### 后端改动
1. `GeoAnalysisResultService.triggerExecution()` 在构建 paramsMap 时添加 `templateName` 字段
2. `selectList` SQL 关联查询 `geo_analysis_template` 表获取模板名称

### 前端改动
1. 移除 `pollingRef`、轮询 useEffect 和相关清理逻辑
2. 表格列添加：模板ID、模板名称
3. GeoAnalysisTemplate 操作列添加"查看结果"按钮，调用 `onViewResults(record.id)`
