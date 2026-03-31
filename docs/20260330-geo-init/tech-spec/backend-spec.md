# 后端技术方案

## 一、技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 8 | 开发语言 |
| Spring Boot | 2.6.6 | 应用框架 |
| QConfig | - | 配置中心（去哪儿内部） |
| QSchedule | - | 定时任务（去哪儿内部） |
| qclient-redis | - | Redis 客户端 |
| db-datasource | - | 数据库连接池 |
| MySQL | 5.7+ | 数据库 |

---

## 二、项目结构（基于现有 Demo）

```
ares_analysisterm/
├── pom.xml                                      # 父 POM
└── mkt_ares_analysisterm_web/
    ├── pom.xml
    └── src/main/
        ├── java/com/qunar/ug/flight/contact/ares/analysisterm/
        │   ├── Application.java                 # 启动类
        │   │
        │   ├── bean/                            # Bean 定义
        │   │   ├── QConfigDataSource.java       # QConfig 数据源 Bean
        │   │   ├── hotword/                     # 热词模块 Bean
        │   │   │   ├── HotWord.java
        │   │   │   └── HotWordTask.java
        │   │   ├── content/                     # 内容模块 Bean
        │   │   │   ├── Content.java
        │   │   │   └── ContentTask.java
        │   │   ├── geo/                         # GEO 模块 Bean
        │   │   │   ├── GeoProvider.java
        │   │   │   └── GeoMonitorData.java
        │   │   ├── publish/                     # 发布模块 Bean
        │   │   │   ├── PublishChannel.java
        │   │   │   └── PublishTask.java
        │   │   └── common/                      # 公共 Bean
        │   │       └── Result.java              # 统一响应
        │   │
        │   ├── controller/                      # 控制层
        │   │   ├── WelcomeController.java       # 首页（已有）
        │   │   ├── HotWordController.java       # 热词中心
        │   │   ├── HotWordTaskController.java
        │   │   ├── ContentController.java       # 内容中心
        │   │   ├── ContentTaskController.java
        │   │   ├── GeoMonitorController.java    # GEO 分析
        │   │   ├── DataCenterController.java    # 数据中心
        │   │   ├── PublishChannelController.java # 发布中心
        │   │   └── PublishTaskController.java
        │   │
        │   ├── service/                         # 服务层
        │   │   ├── qconfig/                     # QConfig 服务（已有）
        │   │   │   ├── QConfigDemoService.java
        │   │   │   └── QConfigDataSourceService.java
        │   │   ├── hotword/                     # 热词服务
        │   │   │   ├── HotWordService.java
        │   │   │   └── impl/HotWordServiceImpl.java
        │   │   ├── content/                     # 内容服务
        │   │   ├── geo/                         # GEO 服务
        │   │   │   ├── GeoMonitorService.java
        │   │   │   └── impl/GeoMonitorServiceImpl.java
        │   │   ├── datacenter/                  # 数据中心服务
        │   │   │   ├── DataCenterService.java
        │   │   │   └── impl/DataCenterServiceImpl.java
        │   │   └── publish/                     # 发布服务
        │   │
        │   ├── dao/                             # 数据访问层
        │   │   ├── hotword/
        │   │   │   ├── HotWordDao.java
        │   │   │   └── HotWordTaskDao.java
        │   │   ├── content/
        │   │   ├── geo/
        │   │   │   ├── GeoProviderDao.java
        │   │   │   └── GeoMonitorDataDao.java
        │   │   └── publish/
        │   │
        │   ├── task/                            # 定时任务
        │   │   ├── QScheduleTaskDemoTask.java   # Demo（已有）
        │   │   └── GeoMonitorTask.java          # GEO 监控数据采集
        │   │
        │   └── tcdev/factory/                   # 配置工厂
        │       ├── PXCBeanFactory.java          # DB 配置（已有）
        │       └── RedisBeanFactory.java        # Redis 配置（已有）
        │
        └── resources/
            ├── application.properties           # 应用配置
            ├── logback.xml                      # 日志配置
            └── META-INF/starter.properties
```

---

## 三、公共模块

### 3.1 统一响应封装

```java
package com.qunar.ug.flight.contact.ares.analysisterm.bean.common;

public class Result<T> {
    private Integer code;
    private String message;
    private T data;

    public static <T> Result<T> success(T data) {
        Result<T> result = new Result<>();
        result.setCode(0);
        result.setMessage("success");
        result.setData(data);
        return result;
    }

    public static <T> Result<T> success() {
        return success(null);
    }

    public static <T> Result<T> error(Integer code, String message) {
        Result<T> result = new Result<>();
        result.setCode(code);
        result.setMessage(message);
        return result;
    }

    public static <T> Result<T> error(String message) {
        return error(-1, message);
    }

    // getter/setter
}
```

### 3.2 QConfig 配置服务

```java
package com.qunar.ug.flight.contact.ares.analysisterm.service.qconfig;

import org.springframework.stereotype.Service;
import qunar.tc.qconfig.client.spring.QMapConfig;
import java.util.Map;

/**
 * GEO 相关 QConfig 配置
 */
@Service
public class GeoQConfigService {

    @QMapConfig("geo_provider.properties")
    private Map<String, String> providerConfig;

    /**
     * 获取 Provider Logo
     */
    public String getProviderLogo(String code) {
        return providerConfig.get("geo.provider." + code + ".logo");
    }

    /**
     * 获取 Provider 描述
     */
    public String getProviderDescription(String code) {
        return providerConfig.get("geo.provider." + code + ".description");
    }

    /**
     * 获取 Provider Icon
     */
    public String getProviderIcon(String code) {
        return providerConfig.get("geo.provider." + code + ".icon");
    }
}
```

---

## 四、Entity 实体类

### 4.1 热词实体

```java
package com.qunar.ug.flight.contact.ares.analysisterm.bean.hotword;

import java.time.LocalDateTime;

public class HotWord {
    private Long id;
    private String word;
    private Integer sourceType;      // 0-手动导入 1-热词挖掘
    private Long sourceTaskId;
    private String tags;             // JSON 数组
    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    // getter/setter
}
```

### 4.2 GEO Provider 实体

```java
package com.qunar.ug.flight.contact.ares.analysisterm.bean.geo;

import java.time.LocalDateTime;

public class GeoProvider {
    private Long id;
    private String name;
    private String code;
    private Integer sortOrder;
    private Integer status;          // 0-停用 1-启用
    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    // getter/setter
}
```

### 4.3 GEO 监控数据实体

```java
package com.qunar.ug.flight.contact.ares.analysisterm.bean.geo;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class GeoMonitorData {
    private Long id;
    private Long providerId;
    private Long productId;
    private LocalDate date;
    private BigDecimal mentionRate;       // 提及率
    private Integer priorityScore;        // 优先度
    private Integer priorityRank;         // 排名
    private BigDecimal positiveSentiment; // 正面情感
    private BigDecimal recommendScore;    // 推荐指数
    private String highFreqWords;         // 高频关联词 JSON
    private String negativeWords;         // 负面关联词 JSON
    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    // getter/setter
}
```

---

## 五、Controller 层

### 5.1 热词 Controller

```java
package com.qunar.ug.flight.contact.ares.analysisterm.controller;

import com.qunar.ug.flight.contact.ares.analysisterm.bean.common.Result;
import com.qunar.ug.flight.contact.ares.analysisterm.service.hotword.HotWordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/hotWord")
public class HotWordController {

    @Autowired
    private HotWordService hotWordService;

    @GetMapping("/list")
    public Result<Map<String, Object>> list(
            @RequestParam(required = false) Integer sourceType,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {
        return Result.success(hotWordService.list(sourceType, page, size));
    }

    @PostMapping("/add")
    public Result<Void> add(@RequestBody Map<String, Object> params) {
        hotWordService.add(params);
        return Result.success();
    }

    @PostMapping("/import")
    public Result<Void> importWords(@RequestBody Map<String, Object> params) {
        hotWordService.importWords(params);
        return Result.success();
    }

    @PostMapping("/update")
    public Result<Void> update(@RequestBody Map<String, Object> params) {
        hotWordService.update(params);
        return Result.success();
    }

    @PostMapping("/delete")
    public Result<Void> delete(@RequestBody Map<String, Long> params) {
        hotWordService.delete(params.get("id"));
        return Result.success();
    }
}
```

### 5.2 GEO 分析 Controller

```java
package com.qunar.ug.flight.contact.ares.analysisterm.controller;

import com.qunar.ug.flight.contact.ares.analysisterm.bean.common.Result;
import com.qunar.ug.flight.contact.ares.analysisterm.service.geo.GeoMonitorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/geoMonitor")
public class GeoMonitorController {

    @Autowired
    private GeoMonitorService geoMonitorService;

    @GetMapping("/list")
    public Result<Map<String, Object>> list(
            @RequestParam(required = false) Long productId,
            @RequestParam(required = false) String date,
            @RequestParam(required = false) String providerIds) {
        return Result.success(geoMonitorService.list(productId, date, providerIds));
    }
}
```

### 5.3 数据中心 Controller

```java
package com.qunar.ug.flight.contact.ares.analysisterm.controller;

import com.qunar.ug.flight.contact.ares.analysisterm.bean.common.Result;
import com.qunar.ug.flight.contact.ares.analysisterm.service.datacenter.DataCenterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/dataCenter")
public class DataCenterController {

    @Autowired
    private DataCenterService dataCenterService;

    @GetMapping("/all")
    public Result<Map<String, Object>> all(
            @RequestParam(defaultValue = "sevenDays") String timeRange,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "7") Integer trendDays) {
        return Result.success(dataCenterService.getAll(timeRange, startDate, endDate, trendDays));
    }
}
```

---

## 六、Service 层

### 6.1 GEO 监控 Service

```java
package com.qunar.ug.flight.contact.ares.analysisterm.service.geo.impl;

import com.qunar.ug.flight.contact.ares.analysisterm.bean.geo.GeoMonitorData;
import com.qunar.ug.flight.contact.ares.analysisterm.bean.geo.GeoProvider;
import com.qunar.ug.flight.contact.ares.analysisterm.dao.geo.GeoMonitorDataDao;
import com.qunar.ug.flight.contact.ares.analysisterm.dao.geo.GeoProviderDao;
import com.qunar.ug.flight.contact.ares.analysisterm.service.geo.GeoMonitorService;
import com.qunar.ug.flight.contact.ares.analysisterm.service.qconfig.GeoQConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@Service
public class GeoMonitorServiceImpl implements GeoMonitorService {

    @Autowired
    private GeoProviderDao providerDao;

    @Autowired
    private GeoMonitorDataDao monitorDataDao;

    @Autowired
    private GeoQConfigService geoQConfigService;

    @Override
    public Map<String, Object> list(Long productId, String date, String providerIds) {
        // 确定查询日期
        LocalDate queryDate = date != null ? LocalDate.parse(date) : getLatestDate(productId);

        // 查询启用的 Provider
        List<GeoProvider> providers = providerDao.findActive();

        // 过滤指定 Provider
        if (providerIds != null && !providerIds.isEmpty()) {
            Set<Long> idSet = new HashSet<>();
            for (String id : providerIds.split(",")) {
                idSet.add(Long.parseLong(id.trim()));
            }
            providers.removeIf(p -> !idSet.contains(p.getId()));
        }

        // 查询监控数据
        Long effectiveProductId = productId != null ? productId : 0L;
        List<GeoMonitorData> dataList = monitorDataDao.findByDateAndProduct(queryDate, effectiveProductId);
        Map<Long, GeoMonitorData> dataMap = new HashMap<>();
        for (GeoMonitorData data : dataList) {
            dataMap.put(data.getProviderId(), data);
        }

        // 查询前一天数据用于计算趋势
        LocalDate prevDate = queryDate.minusDays(1);
        List<GeoMonitorData> prevDataList = monitorDataDao.findByDateAndProduct(prevDate, effectiveProductId);
        Map<Long, GeoMonitorData> prevDataMap = new HashMap<>();
        for (GeoMonitorData data : prevDataList) {
            prevDataMap.put(data.getProviderId(), data);
        }

        // 组装响应
        List<Map<String, Object>> items = new ArrayList<>();
        for (GeoProvider provider : providers) {
            GeoMonitorData data = dataMap.get(provider.getId());
            GeoMonitorData prevData = prevDataMap.get(provider.getId());

            Map<String, Object> item = new HashMap<>();
            item.put("providerId", provider.getId());
            item.put("providerCode", provider.getCode());
            item.put("providerName", provider.getName());
            item.put("providerLogo", geoQConfigService.getProviderLogo(provider.getCode()));
            item.put("providerDesc", geoQConfigService.getProviderDescription(provider.getCode()));

            if (data != null) {
                item.put("mentionRate", data.getMentionRate());
                item.put("priorityScore", data.getPriorityScore());
                item.put("priorityRank", data.getPriorityRank());
                item.put("positiveSentiment", data.getPositiveSentiment());
                item.put("recommendScore", data.getRecommendScore());
                item.put("highFreqWords", parseJsonArray(data.getHighFreqWords()));
                item.put("negativeWords", parseJsonArray(data.getNegativeWords()));
                item.put("analyzeTime", data.getCreateTime());

                // 计算趋势
                if (prevData != null) {
                    BigDecimal change = data.getMentionRate().subtract(prevData.getMentionRate());
                    if (change.compareTo(BigDecimal.ZERO) > 0) {
                        item.put("trend", "up");
                        item.put("trendChange", change);
                    } else if (change.compareTo(BigDecimal.ZERO) < 0) {
                        item.put("trend", "down");
                        item.put("trendChange", change.abs());
                    } else {
                        item.put("trend", "stable");
                        item.put("trendChange", BigDecimal.ZERO);
                    }
                } else {
                    item.put("trend", "stable");
                    item.put("trendChange", BigDecimal.ZERO);
                }
            }

            items.add(item);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("date", queryDate.toString());
        result.put("items", items);
        return result;
    }

    private LocalDate getLatestDate(Long productId) {
        Long effectiveProductId = productId != null ? productId : 0L;
        GeoMonitorData latest = monitorDataDao.findLatest(effectiveProductId);
        return latest != null ? latest.getDate() : LocalDate.now();
    }

    private List<String> parseJsonArray(String json) {
        if (json == null || json.isEmpty()) {
            return new ArrayList<>();
        }
        // 使用 Jackson 或其他 JSON 库解析
        // 这里简化处理
        return Arrays.asList(json.replace("[", "").replace("]", "").replace("\"", "").split(","));
    }
}
```

### 6.2 数据中心 Service

```java
package com.qunar.ug.flight.contact.ares.analysisterm.service.datacenter.impl;

import com.qunar.ug.flight.contact.ares.analysisterm.dao.datacenter.DataCenterDao;
import com.qunar.ug.flight.contact.ares.analysisterm.service.datacenter.DataCenterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;

@Service
public class DataCenterServiceImpl implements DataCenterService {

    @Autowired
    private DataCenterDao dataCenterDao;

    @Override
    public Map<String, Object> getAll(String timeRange, String startDate, String endDate, Integer trendDays) {
        LocalDate[] dateRange = calculateDateRange(timeRange, startDate, endDate);

        Map<String, Object> result = new HashMap<>();

        // 1. 统计概览
        result.put("overview", dataCenterDao.getOverview(dateRange[0], dateRange[1]));

        // 2. 热词来源分布
        result.put("hotWordSourceDistribution",
            dataCenterDao.getHotWordSourceDistribution(dateRange[0], dateRange[1]));

        // 3. 发布渠道分布
        result.put("publishChannelDistribution",
            dataCenterDao.getPublishChannelDistribution(dateRange[0], dateRange[1]));

        // 4. 每日趋势
        int days = trendDays != null ? trendDays : 7;
        LocalDate trendEndDate = LocalDate.now().minusDays(1);
        LocalDate trendStartDate = trendEndDate.minusDays(days - 1);

        Map<String, Object> dailyTrend = new HashMap<>();
        dailyTrend.put("hotWord", dataCenterDao.getDailyTrend("hot_word", trendStartDate, trendEndDate));
        dailyTrend.put("expand", dataCenterDao.getDailyTrend("expand", trendStartDate, trendEndDate));
        dailyTrend.put("publish", dataCenterDao.getDailyTrend("publish", trendStartDate, trendEndDate));
        result.put("dailyTrend", dailyTrend);

        return result;
    }

    private LocalDate[] calculateDateRange(String timeRange, String startDate, String endDate) {
        LocalDate end = LocalDate.now();
        LocalDate start;

        if ("custom".equals(timeRange)) {
            start = LocalDate.parse(startDate);
            end = LocalDate.parse(endDate);
        } else if ("today".equals(timeRange)) {
            start = end;
        } else if ("thirtyDays".equals(timeRange)) {
            start = end.minusDays(29);
        } else {
            // sevenDays (default)
            start = end.minusDays(6);
        }

        return new LocalDate[]{start, end};
    }
}
```

---

## 七、DAO 层

### 7.1 GEO Provider DAO

```java
package com.qunar.ug.flight.contact.ares.analysisterm.dao.geo;

import com.qunar.ug.flight.contact.ares.analysisterm.bean.geo.GeoProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class GeoProviderDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<GeoProvider> findActive() {
        String sql = "SELECT id, name, code, sort_order, status, create_time, update_time " +
                     "FROM geo_provider WHERE status = 1 ORDER BY sort_order";
        return jdbcTemplate.query(sql, getRowMapper());
    }

    public GeoProvider findById(Long id) {
        String sql = "SELECT id, name, code, sort_order, status, create_time, update_time " +
                     "FROM geo_provider WHERE id = ?";
        List<GeoProvider> list = jdbcTemplate.query(sql, getRowMapper(), id);
        return list.isEmpty() ? null : list.get(0);
    }

    private RowMapper<GeoProvider> getRowMapper() {
        return (rs, rowNum) -> {
            GeoProvider provider = new GeoProvider();
            provider.setId(rs.getLong("id"));
            provider.setName(rs.getString("name"));
            provider.setCode(rs.getString("code"));
            provider.setSortOrder(rs.getInt("sort_order"));
            provider.setStatus(rs.getInt("status"));
            provider.setCreateTime(rs.getTimestamp("create_time").toLocalDateTime());
            provider.setUpdateTime(rs.getTimestamp("update_time").toLocalDateTime());
            return provider;
        };
    }
}
```

### 7.2 数据中心 DAO

```java
package com.qunar.ug.flight.contact.ares.analysisterm.dao.datacenter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.*;

@Repository
public class DataCenterDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public Map<String, Object> getOverview(LocalDate startDate, LocalDate endDate) {
        String sql = "SELECT " +
            "(SELECT COUNT(*) FROM hot_word WHERE create_time BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY)) as hotWordCount, " +
            "(SELECT COUNT(*) FROM hot_word WHERE DATE(create_time) = CURDATE()) as hotWordTodayNew, " +
            "(SELECT COUNT(*) FROM content WHERE status = 2 AND create_time BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY)) as publishCount, " +
            "(SELECT COUNT(*) FROM publish_channel WHERE status = 1) as activeChannelCount";

        Map<String, Object> result = new HashMap<>();
        jdbcTemplate.query(sql, rs -> {
            result.put("hotWordCount", rs.getInt("hotWordCount"));
            result.put("hotWordTodayNew", rs.getInt("hotWordTodayNew"));
            result.put("expandCount", 0);  // TODO: 计算扩词数
            result.put("expandTodayNew", 0);
            result.put("publishCount", rs.getInt("publishCount"));
            result.put("publishMonthNew", 0);
            result.put("activeChannelCount", rs.getInt("activeChannelCount"));
            result.put("activeChannelChange", "稳定");
        }, startDate, endDate, startDate, endDate);

        return result;
    }

    public List<Map<String, Object>> getHotWordSourceDistribution(LocalDate startDate, LocalDate endDate) {
        String sql = "SELECT " +
            "source, " +
            "CASE source WHEN 'weibo' THEN '微博' WHEN 'zhihu' THEN '知乎' WHEN 'baidu' THEN '百度' ELSE '手动' END as sourceName, " +
            "COUNT(*) as count " +
            "FROM hot_word " +
            "WHERE create_time BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY) " +
            "GROUP BY source " +
            "ORDER BY count DESC";

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            Map<String, Object> item = new HashMap<>();
            item.put("source", rs.getString("source"));
            item.put("sourceName", rs.getString("sourceName"));
            item.put("count", rs.getInt("count"));
            item.put("percentage", 0.0);  // 需要二次计算
            return item;
        }, startDate, endDate);
    }

    public List<Map<String, Object>> getPublishChannelDistribution(LocalDate startDate, LocalDate endDate) {
        // TODO: 实现
        return new ArrayList<>();
    }

    public List<Map<String, Object>> getDailyTrend(String metric, LocalDate startDate, LocalDate endDate) {
        String table = "hot_word";
        String extraCondition = "";

        if ("expand".equals(metric)) {
            table = "hot_word_task";
            extraCondition = " AND type = 'expand' AND status = 2";
        } else if ("publish".equals(metric)) {
            table = "content";
            extraCondition = " AND status = 2";
        }

        String sql = "SELECT " +
            "DATE(create_time) as date, " +
            "CASE DAYOFWEEK(create_time) " +
            "  WHEN 1 THEN '周日' WHEN 2 THEN '周一' WHEN 3 THEN '周二' " +
            "  WHEN 4 THEN '周三' WHEN 5 THEN '周四' WHEN 6 THEN '周五' ELSE '周六' END as dayOfWeek, " +
            "COUNT(*) as count " +
            "FROM " + table + " " +
            "WHERE create_time BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY) " + extraCondition + " " +
            "GROUP BY DATE(create_time) " +
            "ORDER BY date";

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            Map<String, Object> item = new HashMap<>();
            item.put("date", rs.getDate("date").toString());
            item.put("dayOfWeek", rs.getString("dayOfWeek"));
            item.put("count", rs.getInt("count"));
            return item;
        }, startDate, endDate);
    }
}
```

---

## 八、定时任务

### 8.1 GEO 监控数据采集

```java
package com.qunar.ug.flight.contact.ares.analysisterm.task;

import com.qunar.ug.flight.contact.ares.analysisterm.bean.geo.GeoMonitorData;
import com.qunar.ug.flight.contact.ares.analysisterm.bean.geo.GeoProvider;
import com.qunar.ug.flight.contact.ares.analysisterm.dao.geo.GeoMonitorDataDao;
import com.qunar.ug.flight.contact.ares.analysisterm.dao.geo.GeoProviderDao;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import qunar.tc.qschedule.config.QSchedule;
import qunar.tc.schedule.Parameter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

/**
 * GEO 监控数据采集定时任务
 * 每日 00:30 执行
 */
@Service
public class GeoMonitorTask {
    private static final Logger LOG = LoggerFactory.getLogger(GeoMonitorTask.class);

    @Autowired
    private GeoProviderDao providerDao;

    @Autowired
    private GeoMonitorDataDao monitorDataDao;

    @QSchedule("mkt_ares_geo_monitor_collect_job")
    public void collectMonitorData(Parameter param) {
        LOG.info("GEO 监控数据采集任务开始执行");

        List<GeoProvider> providers = providerDao.findActive();
        LocalDate today = LocalDate.now();
        Long productId = 0L;

        for (GeoProvider provider : providers) {
            try {
                // MVP 阶段使用 Mock 数据
                GeoMonitorData data = mockMonitorData(provider, today, productId);
                monitorDataDao.insert(data);
                LOG.info("Provider {} 数据采集完成", provider.getName());
            } catch (Exception e) {
                LOG.error("Provider {} 数据采集失败", provider.getName(), e);
            }
        }

        LOG.info("GEO 监控数据采集任务执行完成");
    }

    /**
     * Mock 监控数据 (MVP 阶段)
     */
    private GeoMonitorData mockMonitorData(GeoProvider provider, LocalDate date, Long productId) {
        Random random = new Random();

        GeoMonitorData data = new GeoMonitorData();
        data.setProviderId(provider.getId());
        data.setProductId(productId);
        data.setDate(date);
        data.setMentionRate(BigDecimal.valueOf(50 + random.nextDouble() * 50).setScale(2, BigDecimal.ROUND_HALF_UP));
        data.setPriorityScore(50 + random.nextInt(51));
        data.setPriorityRank(1 + random.nextInt(10));
        data.setPositiveSentiment(BigDecimal.valueOf(50 + random.nextDouble() * 50).setScale(2, BigDecimal.ROUND_HALF_UP));
        data.setRecommendScore(BigDecimal.valueOf(5 + random.nextDouble() * 5).setScale(1, BigDecimal.ROUND_HALF_UP));
        data.setHighFreqWords("[\"性价比高\", \"功能齐全\", \"用户体验好\", \"响应速度快\"]");
        data.setNegativeWords("[\"价格偏高\", \"学习成本\"]");

        return data;
    }
}
```

---

## 九、接口文档

### 9.1 热词中心

| 接口 | 方法 | 参数 | 说明 |
|------|------|------|------|
| `/api/hotWord/list` | GET | sourceType, page, size | 热词列表 |
| `/api/hotWord/add` | POST | {word, tags[]} | 新增热词 |
| `/api/hotWord/import` | POST | {words[]} | 批量导入 |
| `/api/hotWord/update` | POST | {id, word, tags[]} | 更新热词 |
| `/api/hotWord/delete` | POST | {id} | 删除热词 |
| `/api/hotWordTask/list` | GET | type, page, size | 任务列表 |
| `/api/hotWordTask/add` | POST | {name, type, params} | 新建任务 |
| `/api/hotWordTask/cancel` | POST | {id} | 取消任务 |
| `/api/hotWordTask/retry` | POST | {id} | 重试任务 |

### 9.2 内容中心

| 接口 | 方法 | 参数 | 说明 |
|------|------|------|------|
| `/api/content/list` | GET | sourceType, status, page, size | 内容列表 |
| `/api/content/add` | POST | {title, body, attachments} | 新增内容 |
| `/api/content/update` | POST | {id, title, body, status} | 更新内容 |
| `/api/content/delete` | POST | {id} | 删除内容 |
| `/api/contentTask/list` | GET | status, page, size | 任务列表 |
| `/api/contentTask/add` | POST | {name, generateMethod, inputData, templateCode} | 新建任务 |

### 9.3 GEO 分析

| 接口 | 方法 | 参数 | 说明 |
|------|------|------|------|
| `/api/geoMonitor/list` | GET | productId, date, providerIds | 分析列表 |

### 9.4 数据中心

| 接口 | 方法 | 参数 | 说明 |
|------|------|------|------|
| `/api/dataCenter/all` | GET | timeRange, startDate, endDate, trendDays | 全部数据 |

### 9.5 发布中心

| 接口 | 方法 | 参数 | 说明 |
|------|------|------|------|
| `/api/publishChannel/list` | GET | status, page, size | 渠道列表 |
| `/api/publishChannel/add` | POST | {name, type, config} | 新增渠道 |
| `/api/publishChannel/update` | POST | {id, name, status, config} | 更新渠道 |
| `/api/publishChannel/delete` | POST | {id} | 删除渠道 |
| `/api/publishTask/list` | GET | status, page, size | 发布任务列表 |
| `/api/publishTask/add` | POST | {contentId, channelId, scheduledAt} | 新建发布任务 |

---

## 十、QConfig 配置

### geo_provider.properties

```properties
# DeepSeek
geo.provider.deepseek.logo=https://cdn.example.com/logo/deepseek.png
geo.provider.deepseek.description=深度求索 · 智能分析引擎
geo.provider.deepseek.icon=🤖

# 豆包
geo.provider.doubao.logo=https://cdn.example.com/logo/doubao.png
geo.provider.doubao.description=字节跳动 · 智能助手
geo.provider.doubao.icon=🎯

# 通义千问
geo.provider.qianwen.logo=https://cdn.example.com/logo/qianwen.png
geo.provider.qianwen.description=阿里云 · 智能问答
geo.provider.qianwen.icon=💡
```

---

## 十一、数据库建表

详见各模块设计文档：
- `docs/20260330-geo-init/GEO分析.md`
- `docs/20260330-geo-init/数据中心.md`
- `docs/20260330-geo-init/热词中心.md`
- `docs/20260330-geo-init/内容中心.md`
