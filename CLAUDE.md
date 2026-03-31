# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Chinese operational platform (运营平台) HTML prototype for Query word management, content generation, data analytics, and multi-channel publishing. The prototype is designed for SEO/GEO (Generative Engine Optimization) workflows.

## Key Files

- `prototype.html` - Main single-page application prototype (~240KB, all-in-one HTML/CSS/JS)
- `Query词中心产品设计.md` - Product design document with data models
- `docs/superpowers/plans/` - Implementation plans for completed features

## Architecture

### Single-File SPA Structure

The prototype uses a single HTML file with embedded styles and scripts:

```
prototype.html
├── <style> (CSS variables, component styles, ~800 lines)
├── <body> (HTML structure)
│   ├── .sidebar (left navigation)
│   └── .main-content (module containers)
│       ├── #query (Query词中心)
│       ├── #content (内容中心)
│       ├── #geo (GEO分析)
│       ├── #data (数据中心)
│       └── #publish (发布中心)
└── <script> (JavaScript logic)
```

### Module Navigation Pattern

Each module uses `data-module` attributes for navigation:

```html
<div class="nav-item" data-module="query">Query词中心</div>
```

JavaScript toggles `.active` class on `.module` containers based on navigation clicks.

### Tab Structure Within Modules

Modules with multiple views use a tab pattern:

```html
<div class="tabs">
    <div class="tab active" data-tab="queue">发布队列</div>
    <div class="tab" data-tab="channel">渠道管理</div>
</div>
<div id="publish-queue" class="publish-tab active">...</div>
<div id="publish-channel" class="publish-tab">...</div>
```

Each module has its own tab CSS class (e.g., `.publish-tab`, `.data-tab`, `.content-tab`).

### CSS Design System

Uses CSS variables for theming:

```css
:root {
    --primary: #4f46e5;
    --primary-light: #818cf8;
    --success: #10b981;
    --danger: #ef4444;
    --bg-main: #f8fafc;
    --bg-card: #ffffff;
    --radius: 12px;
    --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
}
```

## Data Models

Key entities defined in the product design:

- **QueryWord** - Query terms for SEO/GEO, with source tracking (manual/task)
- **Task** - Generation or expansion tasks, supports LLM and ClawAgent methods
- **PublishChannel** - Publishing destinations (WeChat, Zhihu, Weibo, etc.)
- **PublishTask** - Scheduled content publishing jobs
- **GeoAnalysis** - AI model monitoring results (DeepSeek, Doubao, Qianwen)

## JavaScript Patterns

### Module Data Pattern

Data is stored in module-scoped arrays:

```javascript
var channelData = [
    { id: 1, name: '微信公众号', icon: '📱', active: true },
    ...
];
```

### Render Functions

Dynamic content uses render functions:

```javascript
function renderChannelList() {
    var listEl = document.getElementById('channel-list');
    var html = '';
    channelData.forEach(function(channel) {
        html += '<div class="channel-item">...</div>';
    });
    listEl.innerHTML = html;
}
```

### Modal Pattern

Modals use overlay + modal structure:

```javascript
function openChannelModal(id) {
    document.getElementById('channel-modal').style.display = 'flex';
}
function closeChannelModal() {
    document.getElementById('channel-modal').style.display = 'none';
}
```

## Development Commands

No build system - this is a pure HTML prototype. Open `prototype.html` directly in a browser.

For validation:

```bash
# Check HTML tag balance (Python)
python -c "from html.parser import HTMLParser; ..."
```

## Git Commit Convention

Use conventional commits with Chinese descriptions:

```
feat: AI 发布中心新增渠道管理功能
fix: AI 修复数据中心模块嵌套错误
```

Commit messages should use English for the type prefix and Chinese for the description.

## Implementation Plan Format

Plans are stored in `docs/superpowers/plans/` with this structure:

- Goal and Architecture summary
- Chunk-based task breakdown
- Checkbox steps (`- [ ]`) for tracking
- Code snippets showing exact changes
- Each task specifies file paths and line numbers

## Key UI Components

- **Cards** - `.card` with `.card-header`, `.card-title`
- **Buttons** - `.btn`, `.btn-primary`, `.btn-secondary`, `.btn-ghost`
- **Forms** - `.input`, `.select`, `.textarea`, `.checkbox-label`
- **Tags** - `.query-tag`, `.geo-keyword`
- **Status Badges** - `.badge-success`, `.badge-error`, `.task-status.running`
- **Modals** - `.modal-overlay`, `.modal`, `.modal-header`, `.modal-body`, `.modal-footer`

## Harness Engineering (AI Agent 工程范式)

> 参考：harness/ 文件夹下的两篇文章

### 核心定义

Harness Engineering 是围绕 AI Agent 设计和构建约束与工作流程的工程实践，让 Agent 拥有强大的处理能力，同时确保输出目标的可靠性和可控性。

### 四大原则

1. **上下文原则 (Smart Zone)**

   - 前 40% token：高效区，Agent 拥有完整上下文
   - 后 40% token：低效区，容易陷入循环和错误
   - 实践：保持 AGENTS.md 简洁（~100行），详细文档放 docs/
2. **专业原则 (Specialization)**

   - 使用专注特定任务的受限权限 Agent
   - 避免全权限通用 Agent
   - 实践：每个 Agent 携带少量、精简信息
3. **持久原则 (Persistence)**

   - 状态持久化到文件系统
   - 每次会话从文件系统恢复上下文
   - 实践：使用 JSON 格式追踪 feature 状态
4. **分离原则 (Separation)**

   - 思考/规划与执行分离
   - 验证通过自动执行（Linter、CI、测试）
   - 实践：Research-Plan-Implement 循环

### AGENTS.md 最佳实践

```markdown
# AGENTS.md 结构

1. 项目概述（简洁）
2. 架构地图（指向详细文档）
3. 开发规范（关键约束）
4. 常见问题与解决方案
```

### 架构约束模板

采用六层架构，依赖方向严格验证：

```
Types → Config → Repo → Service → Runtime → UI
```

- 依赖只能"向前"
- 横切关注点（认证、日志、功能标志）通过单一接口进入
- 使用自定义 Linter 强制执行

### 代码仓库即真理

对 Agent 而言，代码仓库本地已版本化的工件是它能看到的全部：

- Google Docs、聊天记录、人们头脑中的知识 → Agent 无法访问
- 必须将知识推送到仓库中：代码、Markdown、Schema、可执行计划

### "垃圾回收"机制

定期运行后台任务：

1. 扫描偏差和不一致
2. 更新质量等级
3. 发起有针对性的重构 PR
4. 自动合并低风险修复

### 失败模式识别


| 模式       | 描述                                     | 解决方案             |
| ---------- | ---------------------------------------- | -------------------- |
| 一次性尝试 | Agent 一次性给出完整方案，失败后难以恢复 | 分步执行，增量验证   |
| 假装完成   | 标记完成但实际未实现                     | 自动化验证，测试覆盖 |
| 伪完成     | 代码生成但没有测试/验证                  | 要求测试先行         |
| 无状态重置 | 每次会话丢失上下文                       | 持久化状态到文件系统 |

### 实践建议

1. **文档即代码**：设计文档、执行计划、技术债务追踪都提交到仓库
2. **约束优于指令**：用 Linter 和 CI 强制执行规则，而非依赖文档
3. **渐进式披露**：Agent 从小而稳定的切入点开始，逐步深入
4. **品味编码化**：人类审查反馈 → 文档更新 → 规则编码到工具
