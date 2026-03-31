# 后端技术方案

## 一、技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 8 | 开发语言 |
| Spring Boot | 2.6.6 | 应用框架 |
| MyBatis | 3.x | ORM 框架 |
| Lombok | - | 简化实体类 |
| QConfig | - | 配置中心（去哪儿内部） |
| QSchedule | - | 定时任务（去哪儿内部） |
| qclient-redis | - | Redis 客户端 |
| pxc-datasource | - | 数据库连接池 |
| MySQL | 5.7+ | 数据库 |

---

## 二、项目结构（基于现有工程）

**后端工程位置：** `backend/ares_analysisterm/`

**分支：** `20260330-geoInit-FD-401306`

```
ares_analysisterm/
├── pom.xml
└── mkt_ares_analysisterm_web/
    ├── pom.xml
    └── src/main/
        ├── java/com/qunar/ug/flight/contact/ares/analysisterm/
        │   ├── Application.java                     # 启动类
        │   ├── CybertronConfiguration.java           # 配置类
        │   │
        │   ├── domain/                               # 领域层
        │   │   └── entity/                           # 实体类
        │   │       ├── User.java                     # 示例实体
        │   │       ├── hotword/                      # 热词模块实体
        │   │       │   ├── HotWord.java
        │   │       │   └── HotWordTask.java
        │   │       ├── content/                      # 内容模块实体
        │   │       │   ├── Content.java
        │   │       │   └── ContentTask.java
        │   │       ├── geo/                          # GEO 模块实体
        │   │       │   ├── GeoProvider.java
        │   │       │   └── GeoMonitorData.java
        │   │       ├── publish/                      # 发布模块实体
        │   │       │   ├── PublishChannel.java
        │   │       │   └── PublishTask.java
        │   │       └── common/                       # 公共实体
        │   │           └── Result.java               # 统一响应
        │   │
        │   ├── infra/                                # 基础设施层
        │   │   ├── config/                           # 配置类
        │   │   │   ├── Jsr310Config.java             # 日期时间配置
        │   │   │   └── TransactionConfig.java        # 事务配置
        │   │   ├── configuration/                    # 组件配置
        │   │   │   ├── RedisFactory.java             # Redis 工厂
        │   │   │   └── RedisProperties.java          # Redis 属性
        │   │   ├── dao/                              # Mapper 接口
        │   │   │   ├── UserMapper.java               # 示例 Mapper
        │   │   │   ├── hotword/
        │   │   │   │   ├── HotWordMapper.java
        │   │   │   │   └── HotWordTaskMapper.java
        │   │   │   ├── content/
        │   │   │   │   ├── ContentMapper.java
        │   │   │   │   └── ContentTaskMapper.java
        │   │   │   ├── geo/
        │   │   │   │   ├── GeoProviderMapper.java
        │   │   │   │   └── GeoMonitorDataMapper.java
        │   │   │   └── publish/
        │   │   │       ├── PublishChannelMapper.java
        │   │   │       └── PublishTaskMapper.java
        │   │   └── qconfig/                          # QConfig 配置服务
        │   │       ├── HotFileQConfig.java           # 示例配置
        │   │       └── GeoProviderQConfig.java       # GEO Provider 配置
        │   │
        │   ├── service/                              # 服务层
        │   │   ├── UserService.java                  # 示例服务
        │   │   ├── hotword/
        │   │   │   ├── HotWordService.java
        │   │   │   └── HotWordTaskService.java
        │   │   ├── content/
        │   │   │   ├── ContentService.java
        │   │   │   └── ContentTaskService.java
        │   │   ├── geo/
        │   │   │   └── GeoMonitorService.java
        │   │   ├── datacenter/
        │   │   │   └── DataCenterService.java
        │   │   └── publish/
        │   │       ├── PublishChannelService.java
        │   │       └── PublishTaskService.java
        │   │
        │   ├── web/                                  # 控制层
        │   │   ├── WelcomeController.java            # 首页
        │   │   ├── UserController.java               # 示例控制器
        │   │   ├── HotWordController.java
        │   │   ├── ContentController.java
        │   │   ├── GeoMonitorController.java
        │   │   ├── DataCenterController.java
        │   │   └── PublishController.java
        │   │
        │   └── task/                                 # 定时任务
        │       ├── QScheduleTaskDemoTask.java        # 示例任务
        │       └── GeoMonitorTask.java               # GEO 监控数据采集
        │
        └── resources/
            ├── application.properties                # 应用配置
            ├── tenant.properties                     # 租户配置
            ├── logback.xml                           # 日志配置
            ├── mybatis-config.xml                    # MyBatis 配置
            ├── mapper/                               # Mapper XML
            │   ├── UserMapper.xml
            │   ├── hotword/
            │   ├── content/
            │   ├── geo/
            │   └── publish/
            ├── spring-qschedule.xml                  # QSchedule 配置
            ├── spring-qmq.xml                        # QMQ 配置
            └── dubbo-consumer.xml                    # Dubbo 配置
```

---

## 三、现有代码模式

### 3.1 启动类

```java
@EnableTransactionManagement
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(basePackages = {"com.qunar.ug.flight.contact.ares.analysisterm"})
public class Application extends SpringBootServletInitializer {
    // 配置 WebMvcRegistrations、过滤器、Servlet 等
}
```

### 3.2 实体类（domain.entity）

```java
package com.qunar.ug.flight.contact.ares.analysisterm.domain.entity;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class User {
    private Long id;
    private String username;
    private String email;
    private String phone;
    private Integer status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
```

### 3.3 Mapper 接口（infra.dao）

```java
package com.qunar.ug.flight.contact.ares.analysisterm.infra.dao;

import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface UserMapper {
    int insert(User user);
    int update(User user);
    int deleteById(@Param("id") Long id);
    User selectById(@Param("id") Long id);
    List<User> selectAll();
}
```

### 3.4 Mapper XML（resources/mapper）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.qunar.ug.flight.contact.ares.analysisterm.infra.dao.UserMapper">

    <resultMap id="BaseResultMap" type="com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.User">
        <id column="id" property="id"/>
        <result column="username" property="username"/>
        <result column="email" property="email"/>
        <result column="phone" property="phone"/>
        <result column="status" property="status"/>
        <result column="create_time" property="createTime"/>
        <result column="update_time" property="updateTime"/>
    </resultMap>

    <sql id="Base_Column_List">
        id, username, email, phone, status, create_time, update_time
    </sql>

    <insert id="insert" parameterType="..." useGeneratedKeys="true" keyProperty="id">
        INSERT INTO user (username, email, phone, status, create_time, update_time)
        VALUES (#{username}, #{email}, #{phone}, #{status}, NOW(), NOW())
    </insert>

    <select id="selectById" resultMap="BaseResultMap">
        SELECT <include refid="Base_Column_List"/>
        FROM user
        WHERE id = #{id}
    </select>
</mapper>
```

### 3.5 Service 层

```java
package com.qunar.ug.flight.contact.ares.analysisterm.service;

import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.User;
import com.qunar.ug.flight.contact.ares.analysisterm.infra.dao.UserMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

@Service
public class UserService {

    @Resource
    private UserMapper userMapper;

    public User create(User user) {
        user.setStatus(1);
        userMapper.insert(user);
        return user;
    }

    public User getById(Long id) {
        return userMapper.selectById(id);
    }

    public List<User> listAll() {
        return userMapper.selectAll();
    }
}
```

### 3.6 Controller 层（web）

```java
package com.qunar.ug.flight.contact.ares.analysisterm.web;

import com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.User;
import com.qunar.ug.flight.contact.ares.analysisterm.service.UserService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Resource
    private UserService userService;

    @PostMapping
    public User create(@RequestBody User user) {
        return userService.create(user);
    }

    @GetMapping("/{id}")
    public User getById(@PathVariable Long id) {
        return userService.getById(id);
    }

    @GetMapping
    public List<User> listAll() {
        return userService.listAll();
    }
}
```

### 3.7 QConfig 配置服务（infra.qconfig）

```java
package com.qunar.ug.flight.contact.ares.analysisterm.infra.qconfig;

import org.springframework.stereotype.Service;
import qunar.agile.Conf;
import qunar.tc.qconfig.client.spring.QConfig;

import java.util.Map;

@Service
public class HotFileQConfig {
    private Conf conf;

    @QConfig("hotfile.properties")
    private void onChanged(Map<String, String> map) {
        this.conf = Conf.fromMap(map);
    }

    public String getString(String key, String defaultValue) {
        return conf.getString(key, defaultValue);
    }

    public Integer getInt(String key, Integer defaultValue) {
        return conf.getInt(key, defaultValue);
    }
}
```

### 3.8 Redis 配置（infra.configuration）

```java
@Configuration
public class RedisFactory {
    @Resource
    private RedisProperties redisProperties;

    @ConditionalOnClass(value = RedisProperties.class)
    @Bean
    public RedisAsyncClient redisAsyncClient() throws RedisException {
        RedisConfig redisConfig = RedisConfig.newBuilder()
                .withDiscardPolicy(RedisConfig.DiscardPolicy.RETRY_ON_RECONNECTED)
                .withReconnectCmdQueueSize(50000)
                .withStartupRetryTimes(3)
                .build();

        RedisClientBuilder redisClientBuilder = RedisClientBuilder.create(
                redisProperties.getNamespace(),
                redisProperties.getCipher()
        ).setSessionConfig(redisConfig);
        return redisClientBuilder.buildAsync();
    }
}
```

### 3.9 QSchedule 定时任务（task）

```java
package com.qunar.ug.flight.contact.ares.analysisterm.task;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import qunar.tc.qschedule.config.QSchedule;
import qunar.tc.schedule.Parameter;
import qunar.tc.schedule.TaskHolder;
import qunar.tc.schedule.TaskMonitor;

@Service
public class QScheduleTaskDemoTask {
    private static final Logger LOG = LoggerFactory.getLogger(QScheduleTaskDemoTask.class);

    @QSchedule("mkt_ares_analysisterm_test_job")
    public void demoTask(Parameter param) {
        LOG.info("job start run");
        final TaskMonitor monitor = TaskHolder.getKeeper();
        Logger logger = monitor.getLogger();

        int capacity = queryTotalCapacity();
        monitor.setRateCapacity(capacity);

        for (int i = 0; i < capacity; i = i + BATCH) {
            processOrder(i);
            monitor.addRate(BATCH);
        }
    }
}
```

---

## 四、开发规范

### 4.1 命名规范

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 实体类 | 名词，PascalCase | `HotWord`, `GeoProvider` |
| Mapper 接口 | 实体名 + Mapper | `HotWordMapper` |
| Mapper XML | 实体名 + Mapper.xml | `HotWordMapper.xml` |
| Service | 实体名 + Service | `HotWordService` |
| Controller | 模块名 + Controller | `HotWordController` |
| 定时任务 | 功能名 + Task | `GeoMonitorTask` |
| QConfig | 模块名 + QConfig | `GeoProviderQConfig` |

### 4.2 包路径规范

- **实体类：** `com.qunar.ug.flight.contact.ares.analysisterm.domain.entity.{模块}`
- **Mapper：** `com.qunar.ug.flight.contact.ares.analysisterm.infra.dao.{模块}`
- **Service：** `com.qunar.ug.flight.contact.ares.analysisterm.service.{模块}`
- **Controller：** `com.qunar.ug.flight.contact.ares.analysisterm.web`
- **定时任务：** `com.qunar.ug.flight.contact.ares.analysisterm.task`

### 4.3 接口路径规范

- 统一前缀：`/api`
- RESTful 风格
- 示例：
  - `GET /api/hotWords` - 热词列表
  - `POST /api/hotWords` - 新增热词
  - `PUT /api/hotWords/{id}` - 更新热词
  - `DELETE /api/hotWords/{id}` - 删除热词

---

## 五、待开发模块

### 5.1 热词中心

| 文件 | 路径 |
|------|------|
| HotWord.java | domain.entity.hotword |
| HotWordTask.java | domain.entity.hotword |
| HotWordMapper.java | infra.dao.hotword |
| HotWordTaskMapper.java | infra.dao.hotword |
| HotWordMapper.xml | resources.mapper.hotword |
| HotWordTaskMapper.xml | resources.mapper.hotword |
| HotWordService.java | service.hotword |
| HotWordTaskService.java | service.hotword |
| HotWordController.java | web |

### 5.2 内容中心

| 文件 | 路径 |
|------|------|
| Content.java | domain.entity.content |
| ContentTask.java | domain.entity.content |
| ContentMapper.java | infra.dao.content |
| ContentTaskMapper.java | infra.dao.content |
| ContentMapper.xml | resources.mapper.content |
| ContentTaskMapper.xml | resources.mapper.content |
| ContentService.java | service.content |
| ContentTaskService.java | service.content |
| ContentController.java | web |

### 5.3 GEO 分析

| 文件 | 路径 |
|------|------|
| GeoProvider.java | domain.entity.geo |
| GeoMonitorData.java | domain.entity.geo |
| GeoProviderMapper.java | infra.dao.geo |
| GeoMonitorDataMapper.java | infra.dao.geo |
| GeoProviderMapper.xml | resources.mapper.geo |
| GeoMonitorDataMapper.xml | resources.mapper.geo |
| GeoProviderQConfig.java | infra.qconfig |
| GeoMonitorService.java | service.geo |
| GeoMonitorController.java | web |
| GeoMonitorTask.java | task |

### 5.4 数据中心

| 文件 | 路径 |
|------|------|
| DataCenterService.java | service.datacenter |
| DataCenterController.java | web |

### 5.5 发布中心

| 文件 | 路径 |
|------|------|
| PublishChannel.java | domain.entity.publish |
| PublishTask.java | domain.entity.publish |
| PublishChannelMapper.java | infra.dao.publish |
| PublishTaskMapper.java | infra.dao.publish |
| PublishChannelMapper.xml | resources.mapper.publish |
| PublishTaskMapper.xml | resources.mapper.publish |
| PublishChannelService.java | service.publish |
| PublishTaskService.java | service.publish |
| PublishController.java | web |

---

## 六、数据库建表

详见各模块设计文档：
- `docs/20260330-geo-init/design/热词中心.md`
- `docs/20260330-geo-init/design/内容中心.md`
- `docs/20260330-geo-init/design/GEO分析.md`
- `docs/20260330-geo-init/design/发布中心.md`
