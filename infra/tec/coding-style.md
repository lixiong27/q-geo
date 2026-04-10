# 代码规范

## 命名规范

### 类命名

- **Controller**: `XxxController` - REST 接口层
- **Service**: `XxxService` - 业务逻辑层
- **Mapper**: `XxxMapper` - 数据访问层
- **Entity**: 领域实体，如 `HotWord`, `HotWordTask`
- **Config**: `XxxQConfig` - QConfig 配置类
- **Executor**: `XxxExecutor` - 任务执行器

### 方法命名

- 查询: `get`, `list`, `find`
- 新增: `add`, `create`
- 更新: `update`, `modify`
- 删除: `delete`, `remove`

## 分层架构

```
web/          - Controller 层，处理 HTTP 请求
service/      - Service 层，业务逻辑
domain/       - 领域模型
  ├── entity/ - 实体类
  └── request/response/ - 请求响应对象
infra/        - 基础设施
  ├── dao/    - Mapper 接口
  ├── qconfig/ - QConfig 配置
  ├── client/ - 外部服务客户端
  └── util/   - 工具类
```

## Git 提交规范

- **类型**: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test
- **格式**: `<type>: AI <subject>`
- **标题**: 英文

## QConfig 使用原则

1. 新增可配置项优先使用 QConfig
2. 避免硬编码，便于动态调整
3. 配置变更无需重启服务

## 待补充

后续迭代过程中补充：
- 异常处理规范
- 日志规范
- 接口返回格式规范
