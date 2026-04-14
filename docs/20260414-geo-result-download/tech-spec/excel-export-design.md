# GEO分析结果Excel导出技术方案

## 1. 接口设计

### 1.1 请求接口

```
GET /api/geo/analysis/result/{resultId}/executor/download
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| resultId | Long | 是 | GEO分析结果ID (路径参数) |
| type | String | 是 | 热词类型 (platAnalysis/hotQueryDaily等) |
| executorCode | String | 是 | 执行器代码 |

**响应：**
- Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
- 文件名: {type}_{executorCode}_{timestamp}.xlsx

## 2. 架构设计

### 2.1 类图

```
┌─────────────────────────────────────┐
│     GeoAnalysisController           │
│  + downloadExecutorResult()         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   GeoAnalysisResultService          │
│  + getResultDetail(id)              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  GeoAnalysisExcelExportService      │
│  + export(result, type, code)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│    ExecutorExcelExporterFactory     │
│  + getExporter(executorCode)        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│    <<interface>>                    │
│    ExecutorExcelExporter            │
│  + export(data): byte[]             │
│  + getFileName(): String            │
└──────────────┬──────────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
┌──────────────┐ ┌──────────────┐
│ DailyPub     │ │ Other        │
│ Analysis     │ │ Executor     │
│ Exporter     │ │ ...          │
└──────────────┘ └──────────────┘
```

### 2.2 核心接口

```java
/**
 * 执行器Excel导出器接口
 */
public interface ExecutorExcelExporter {

    /**
     * 获取支持的执行器代码
     */
    String getExecutorCode();

    /**
     * 导出Excel
     * @param data 执行器返回的数据 (Map或具体对象)
     * @return Excel字节数组
     */
    byte[] export(Object data) throws IOException;

    /**
     * 获取导出文件名前缀
     */
    default String getFileNamePrefix() {
        return getExecutorCode();
    }
}
```

## 3. 实现方案

### 3.1 文件结构

```
com.qunar.ug.flight.contact.ares.analysisterm
├── web
│   └── GeoAnalysisController.java          # 新增下载接口
├── service
│   └── geo
│       └── GeoAnalysisExcelExportService.java  # 导出服务
├── domain.entity.geo
│   └── excel
│       ├── DailyPubAnalysisExcelVO.java    # Excel VO
│       └── RankDetailVO.java               # 排名详情VO
└── service.geo.exporter
    ├── ExecutorExcelExporter.java          # 接口
    ├── ExecutorExcelExporterFactory.java   # 工厂
    └── DailyPubAnalysisExcelExporter.java  # 实现
```

### 3.2 Excel VO 设计

基于 `dailyPubAnalysisExecutor` 的数据结构：

| 字段 | Excel表头 | 说明 |
|------|-----------|------|
| hotwordName | 热词名称 | |
| answerHasAct | 答案是否有活动 | 是/否 |
| referHasAct | 参考资料是否有活动 | 是/否 |
| answerHasQ | 答案是否有Q | 是/否 |
| referHasQ | 参考资料是否有Q | 是/否 |
| rank | 排名 | 从rankDetail中提取 |
| rankDetail | 排名详情 | JSON字符串或平台列表 |

### 3.3 核心代码

#### 3.3.1 Controller

```java
@GetMapping("/result/{resultId}/executor/download")
public ResponseEntity<byte[]> downloadExecutorResult(
        @PathVariable Long resultId,
        @RequestParam String type,
        @RequestParam String executorCode) {
    return geoAnalysisExcelExportService.export(resultId, type, executorCode);
}
```

#### 3.3.2 ExportService

```java
@Service
public class GeoAnalysisExcelExportService {

    @Autowired
    private GeoAnalysisResultService resultService;

    @Autowired
    private ExecutorExcelExporterFactory exporterFactory;

    public ResponseEntity<byte[]> export(Long resultId, String type, String executorCode) {
        // 1. 获取结果详情
        GeoAnalysisResult result = resultService.getById(resultId);
        if (result == null) {
            throw new RuntimeException("结果不存在");
        }

        // 2. 解析params获取对应executor的数据
        Map<String, Object> params = parseParams(result.getParams());
        Map<String, Object> executorData = extractExecutorData(params, type, executorCode);

        // 3. 获取对应的导出器
        ExecutorExcelExporter exporter = exporterFactory.getExporter(executorCode);
        if (exporter == null) {
            throw new RuntimeException("不支持的执行器类型: " + executorCode);
        }

        // 4. 导出Excel
        byte[] excelBytes = exporter.export(executorData);

        // 5. 构建响应
        String filename = exporter.getFileNamePrefix() + "_" + System.currentTimeMillis() + ".xlsx";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
        headers.setContentDispositionFormData("attachment", filename);

        return new ResponseEntity<>(excelBytes, headers, HttpStatus.OK);
    }
}
```

#### 3.3.3 DailyPubAnalysisExcelExporter

```java
@Component
public class DailyPubAnalysisExcelExporter implements ExecutorExcelExporter {

    @Override
    public String getExecutorCode() {
        return "dailyPubAnalysisExecutor";
    }

    @Override
    public byte[] export(Object data) throws IOException {
        // 解析data为具体结构
        Map<String, Object> dataMap = (Map<String, Object>) data;
        List<Map<String, Object>> results = (List<Map<String, Object>>) dataMap.get("results");

        // 转换为VO列表
        List<DailyPubAnalysisExcelVO> voList = results.stream()
            .map(this::convertToVO)
            .collect(Collectors.toList());

        // 使用EasyExcel导出
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        EasyExcel.write(outputStream, DailyPubAnalysisExcelVO.class)
            .sheet("分析结果")
            .doWrite(voList);

        return outputStream.toByteArray();
    }

    private DailyPubAnalysisExcelVO convertToVO(Map<String, Object> item) {
        DailyPubAnalysisExcelVO vo = new DailyPubAnalysisExcelVO();
        vo.setHotwordName((String) item.get("hotwordName"));
        vo.setAnswerHasAct(Boolean.TRUE.equals(item.get("answerHasAct")) ? "是" : "否");
        vo.setReferHasAct(Boolean.TRUE.equals(item.get("referHasAct")) ? "是" : "否");
        vo.setAnswerHasQ(Boolean.TRUE.equals(item.get("answerHasQ")) ? "是" : "否");
        vo.setReferHasQ(Boolean.TRUE.equals(item.get("referHasQ")) ? "是" : "否");

        // 处理rankDetail
        Map<String, Object> rankDetail = (Map<String, Object>) item.get("rankDetail");
        if (rankDetail != null) {
            vo.setRank(rankDetail.get("rank") != null ? rankDetail.get("rank").toString() : "-");
            Object detail = rankDetail.get("detail");
            if (detail != null) {
                vo.setRankDetail(detail.toString());
            }
        }
        return vo;
    }
}
```

#### 3.3.4 Excel VO

```java
@Data
public class DailyPubAnalysisExcelVO {

    @ExcelProperty("热词名称")
    private String hotwordName;

    @ExcelProperty("答案是否有活动")
    private String answerHasAct;

    @ExcelProperty("参考资料是否有活动")
    private String referHasAct;

    @ExcelProperty("答案是否有Q")
    private String answerHasQ;

    @ExcelProperty("参考资料是否有Q")
    private String referHasQ;

    @ExcelProperty("排名")
    private String rank;

    @ExcelProperty("排名详情")
    private String rankDetail;
}
```

## 4. 前端实现

### 4.1 API

```javascript
/**
 * 下载执行器结果Excel
 */
export const downloadExecutorResult = (resultId, type, executorCode) => {
    window.open(`/api/geo/analysis/result/${resultId}/executor/download?type=${type}&executorCode=${executorCode}`);
};
```

### 4.2 页面改造

在 GeoAnalysisResult.jsx 的详情弹窗中，每个执行器结果Card添加下载按钮：

```jsx
{Object.entries(result).map(([key, value]) => (
    <Card
        key={key}
        size="small"
        title={<span style={{ fontWeight: 600 }}>{key}</span>}
        extra={
            <Button
                type="link"
                size="small"
                icon={<DownloadOutlined />}
                onClick={() => handleDownload(key)}
            >
                下载Excel
            </Button>
        }
        style={{ marginBottom: 12 }}
    >
        ...
    </Card>
))}
```

## 5. 依赖配置

### 5.1 pom.xml

```xml
<!-- EasyExcel -->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>easyexcel</artifactId>
    <version>3.1.1</version>
</dependency>
```

### 5.2 QConfig

```properties
# Excel导出限制
geo.excel.download.limit=10000
```

## 6. 扩展性说明

### 6.1 新增Executor导出器

1. 实现新的Excel VO类
2. 实现 `ExecutorExcelExporter` 接口
3. 添加 `@Component` 注解，自动注册到工厂

### 6.2 工厂实现

```java
@Component
public class ExecutorExcelExporterFactory {

    private final Map<String, ExecutorExcelExporter> exporterMap = new HashMap<>();

    @Autowired
    public ExecutorExcelExporterFactory(List<ExecutorExcelExporter> exporters) {
        for (ExecutorExcelExporter exporter : exporters) {
            exporterMap.put(exporter.getExecutorCode(), exporter);
        }
    }

    public ExecutorExcelExporter getExporter(String executorCode) {
        return exporterMap.get(executorCode);
    }
}
```
