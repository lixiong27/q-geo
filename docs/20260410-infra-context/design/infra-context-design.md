# 工程上下文快速理解系统设计

## 概述

为 Claude 提供分层上下文系统，使其在处理任务时能快速了解工程全貌，避免重复造轮子。

## 目标

- **快速定位** - 业务能力 + API 清单结合，快速定位代码位置
- **技术复用** - 明确已有技术组件，避免重复造轮子
- **配置优先** - QConfig 热配优先，统一配置管理

## 文档结构

```
q-geo/
├── CLAUDE.md                    # 根目录概览（保持现有）
├── infra.md                     # 导航入口，指向 infra 目录
├── infra/
│   ├── biz/                     # 业务能力 + API 清单
│   │   ├── hotword.md           # 热词管理
│   │   ├── content.md           # 内容生成
│   │   ├── publish.md           # 多渠道发布
│   │   ├── geo.md               # GEO 分析
│   │   └── common.md            # 公共能力（跨模块交叉部分）
│   └── tec/                     # 技术组件目录
│       ├── components.md        # Redis、QConfig 等组件合集
│       └── coding-style.md      # 代码规范（后续扩展）
└── scripts/
    └── update-infra.md          # 更新脚本说明
```

## 文档职责

### infra.md（导航入口）

- 指向 infra 目录下各文档
- 提供快速导航索引

### infra/biz/*.md（业务模块）

每个模块文档结构：

```markdown
# 模块名称

## 业务入口
- Controller: XxxController
- 前端页面: pages/xxx/

## API 清单
| 接口 | 用途 |
|------|------|

## Mapper
- XxxMapper

## 前端组件
- XxxList.jsx

## 下游调用
- DownstreamTaskClient.method()

## 相关 QConfig
- xxx_config.json
```

### infra/biz/common.md（公共能力）

- 跨模块公共组件
- 公共工具类
- 公共配置

### infra/tec/components.md（技术组件）

- RedisUtil 使用方式
- QConfig 配置管理
- QSchedule 定时任务
- 其他可复用工具类

### infra/tec/coding-style.md（代码规范）

- 命名规范
- 代码风格
- 最佳实践

## 更新机制

**手动触发** - 通过 `scripts/update-infra.md` 中的命令说明，由 Claude 执行更新

## 使用场景

1. **新会话启动** - Claude 读取 infra.md 获取导航
2. **任务处理** - 按需查阅 biz/tec 详情
3. **迭代补充** - 完成新功能后更新对应模块文档
