# 发布模块改造技术方案

## 一、背景与目标

### 1.1 背景
当前发布模块采用同步 Mock 实现，存在以下问题：
- 渠道配置存储在 DB 表，修改需要数据库操作
- 发布逻辑硬编码，扩展新渠道需要改动多处代码
- 无下游回调机制，无法对接真实 AI 发布服务

### 1.2 目标
参照内容模块的执行器模式，实现：
1. 渠道配置热化 - 从 QConfig 读取，无需修改数据库
2. 执行器模式 - 新增渠道只需添加配置 + 一个执行器类
3. 异步回调 - 支持下游 AI 服务回调更新发布状态

## 二、现状分析

### 2.1 现有数据结构

**publish_channel 表**：
| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| name | varchar | 渠道名称 |
| code | varchar | 渠道代码 |
| icon | varchar | 图标 |
| config | text | 配置 JSON |
| status | int | 状态 0禁用 1启用 |
| is_builtin | int | 是否内置 0否 1是 |

**publish_task 表**：
| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| content_id | bigint | 内容 ID |
| channel_id | bigint | 渠道 ID |
| status | int | 状态 |
| publish_url | varchar | 发布链接 |
| error_msg | varchar | 错误信息 |
| created_by | varchar | 创建人 |
| create_time | datetime | 创建时间 |
| update_time | datetime | 更新时间 |
| completed_at | datetime | 完成时间 |

### 2.2 前端展示字段
- 渠道名称 (name)
- 渠道代码 (code)
- 图标 (icon) - 前端通过 code 映射 emoji
- 类型 (isBuiltin) - 内置/自定义
- 状态 (status) - 启用/禁用

## 三、改造方案

### 3.1 QConfig 配置设计

**配置文件**：`publish_channel_config.json`

**配置结构**：
```json
{
  "channelCode": {
    "name": "渠道名称",
    "icon": "图标标识",
    "enabled": true,
    "isBuiltin": true,
    "prompt": "发布 prompt 模板",
    "callbackUrl": "回调地址",
    "apiEndpoint": "API 地址",
    "timeout": 30000,
    "maxRetries": 3,
    "extraConfig": {}
  }
}
```

**字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | String | 是 | 渠道显示名称（对应原 DB name 字段） |
| icon | String | 否 | 图标标识（对应原 DB icon 字段） |
| enabled | Boolean | 是 | 是否启用（对应原 DB status=1） |
| isBuiltin | Boolean | 否 | 是否内置渠道（对应原 DB is_builtin=1） |
| prompt | String | 是 | 发布 prompt 模板，支持 {title}, {content} 占位符 |
| callbackUrl | String | 是 | 回调地址 |
| apiEndpoint | String | 否 | 渠道 API 地址（预留） |
| timeout | Integer | 否 | 超时时间（毫秒），默认 30000 |
| maxRetries | Integer | 否 | 最大重试次数，默认 3 |
| extraConfig | Object | 否 | 渠道特定配置 |

### 3.2 代码架构

```
service/publish/
├── PublishTaskService.java          # 发布任务服务（改造）
├── PublishChannelService.java       # 渠道服务（改造）
└── executor/
    ├── PublishTaskExecutor.java     # 抽象执行器
    ├── PublishTaskExecutorFactory.java  # 执行器工厂
    ├── WeiboExecutor.java           # 微博执行器
    ├── ZhihuExecutor.java           # 知乎执行器
    ├── WechatExecutor.java          # 微信公众号执行器
    ├── XiaohongshuExecutor.java     # 小红书执行器
    ├── DouyinExecutor.java          # 抖音执行器
    └── BilibiliExecutor.java        # B站执行器

infra/qconfig/
└── PublishQConfig.java              # 渠道配置服务

domain/entity/publish/
├── PublishTask.java                 # 发布任务实体（新增字段）
└── PublishChannelConfig.java        # 渠道配置实体（新增）

web/
└── PublishTaskCallbackController.java  # 回调接口（新增）
```

### 3.3 核心类设计

#### 3.3.1 PublishChannelConfig

```java
@Data
public class PublishChannelConfig {
    private String name;
    private String icon;
    private Boolean enabled = true;
    private Boolean isBuiltin = false;
    private String prompt;
    private String callbackUrl;
    private String apiEndpoint;
    private Integer timeout = 30000;
    private Integer maxRetries = 3;
    private Map<String, Object> extraConfig;
}
```

#### 3.3.2 PublishQConfig

```java
@Slf4j
@Component
public class PublishQConfig {

    private volatile Map<String, PublishChannelConfig> channelConfigMap = new ConcurrentHashMap<>();

    @QConfig("publish_channel_config.json")
    public void onChannelConfigChanged(String json) {
        // 解析 JSON 并缓存
    }

    public PublishChannelConfig getChannelConfig(String channelCode);
    public List<String> getEnabledChannelList();
    public List<Map<String, Object>> getChannelListWithInfo();
    public boolean isEnabled(String channelCode);
}
```

#### 3.3.3 PublishTaskExecutor（抽象类）

```java
@Slf4j
public abstract class PublishTaskExecutor {

    protected PublishTaskMapper publishTaskMapper;

    @Resource
    protected PublishQConfig publishQConfig;

    @Resource
    protected DownstreamTaskClient downstreamTaskClient;

    @Resource
    protected ContentMapper contentMapper;

    /**
     * 获取渠道类型
     */
    public abstract String getChannelCode();

    /**
     * 执行发布（子类可实现特殊逻辑）
     */
    protected Map<String, Object> doExecute(PublishTask task, PublishChannelConfig config) throws Exception;

    /**
     * 异步执行（模板方法）
     */
    public void executeAsync(PublishTask task);

    /**
     * 提交到下游服务
     */
    protected Map<String, Object> submitToDownstream(PublishTask task, PublishChannelConfig config);
}
```

#### 3.3.4 具体执行器示例

```java
@Slf4j
@Component
public class ZhihuExecutor extends PublishTaskExecutor {

    @Override
    public String getChannelCode() {
        return "zhihu";
    }

    // 默认使用父类 submitToDownstream，可覆盖实现特殊逻辑
}
```

### 3.4 实体改造

**PublishTask 新增字段**：
```java
private String downstreamTaskId;  // 下游任务 ID，用于回调关联
private String channelCode;       // 渠道代码（替代 channelId）
```

**Mapper 新增方法**：
```java
PublishTask selectByDownstreamTaskId(@Param("downstreamTaskId") String downstreamTaskId);
int updateDownstreamTaskId(@Param("id") Long id, @Param("downstreamTaskId") String downstreamTaskId);
```

### 3.5 回调接口

```java
@RestController
@RequestMapping("/api/publishTask")
public class PublishTaskCallbackController {

    @PostMapping("/callback")
    public Map<String, Object> callback(@RequestBody Map<String, Object> request) {
        String taskId = (String) request.get("taskId");
        String status = (String) request.get("status");
        Object result = request.get("result");

        publishTaskService.handleCallback(taskId, status, result);

        return Map.of("success", true);
    }
}
```

## 四、数据兼容性

### 4.1 渠道数据迁移

现有 `publish_channel` 表数据可通过脚本导出为 QConfig JSON 格式：

```sql
SELECT JSON_OBJECTAGG(
    code,
    JSON_OBJECT(
        'name', name,
        'icon', IFNULL(icon, code),
        'enabled', IF(status = 1, true, false),
        'isBuiltin', IF(is_builtin = 1, true, false),
        'prompt', '',
        'callbackUrl', 'http://l-noah6b5liijvu1.auto.beta.cn0.qunar.com:8080/api/publishTask/callback',
        'timeout', 30000,
        'maxRetries', 3
    )
) FROM publish_channel;
```

### 4.2 任务数据兼容

`publish_task` 表保留 `channel_id` 字段用于历史数据查询，新增 `channel_code` 字段用于新逻辑。

## 五、文件清单

| 操作 | 文件路径 |
|-----|---------|
| 新增 | `domain/entity/publish/PublishChannelConfig.java` |
| 新增 | `infra/qconfig/PublishQConfig.java` |
| 新增 | `service/publish/executor/PublishTaskExecutor.java` |
| 新增 | `service/publish/executor/PublishTaskExecutorFactory.java` |
| 新增 | `service/publish/executor/WeiboExecutor.java` |
| 新增 | `service/publish/executor/ZhihuExecutor.java` |
| 新增 | `service/publish/executor/WechatExecutor.java` |
| 新增 | `service/publish/executor/XiaohongshuExecutor.java` |
| 新增 | `service/publish/executor/DouyinExecutor.java` |
| 新增 | `service/publish/executor/BilibiliExecutor.java` |
| 修改 | `domain/entity/publish/PublishTask.java` |
| 修改 | `infra/dao/publish/PublishTaskMapper.java` |
| 修改 | `infra/dao/publish/PublishTaskMapper.xml` |
| 修改 | `service/publish/PublishTaskService.java` |
| 修改 | `service/publish/PublishChannelService.java` |
| 新增 | `web/PublishTaskCallbackController.java` |
| 新增 | QConfig 文件 `publish_channel_config.json` |

## 六、执行顺序

1. **阶段1：QConfig 配置**
   - 创建 PublishChannelConfig 实体
   - 创建 PublishQConfig 配置服务
   - 创建 QConfig 配置文件

2. **阶段2：实体与 Mapper**
   - PublishTask 新增字段
   - Mapper 新增方法
   - XML 新增 SQL

3. **阶段3：执行器架构**
   - 创建抽象执行器
   - 创建执行器工厂
   - 创建各渠道执行器

4. **阶段4：服务层**
   - 改造 PublishTaskService
   - 改造 PublishChannelService

5. **阶段5：Controller**
   - 新增回调接口
   - 改造渠道接口

6. **阶段6：前端适配**
   - 改用 channelCode
   - 适配热配置接口

## 七、新增渠道步骤

1. 在 `publish_channel_config.json` 添加渠道配置
2. 创建继承 `PublishTaskExecutor` 的执行器类
3. 无需修改其他代码，自动注册生效
