# 数据中心功能增强实现计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增强数据中心功能，新增总览Tab和GEO分析中心Tab，展示大模型分析结果和产品指标

**Architecture:** 数据中心采用Tab结构，包含"数据总览"和"GEO分析"两个Tab；GEO分析展示多个大模型(DeepSeek、豆包、千问)的分析结果对比

**Tech Stack:** HTML/CSS/JavaScript (纯前端原型)

---

## 文件结构

```
prototype.html
├── CSS样式 (新增GEO分析相关样式)
├── 数据中心模块 (改为Tab结构)
│   ├── 数据总览Tab (现有内容重构)
│   └── GEO分析Tab (新增)
└── JavaScript逻辑 (Tab切换 + GEO数据渲染)
```

---

## Chunk 1: CSS样式和Tab结构

### Task 1: 添加GEO分析相关CSS样式

**Files:**
- Modify: `prototype.html` (CSS section)

- [ ] **Step 1: 添加GEO分析卡片和指标样式**

在 `.publish-tab.active` 样式后添加新样式：

```css
        /* 数据中心Tab */
        .data-tab {
            display: none;
        }
        .data-tab.active {
            display: block;
        }

        /* GEO分析卡片 */
        .geo-card {
            background: var(--bg-card);
            border-radius: var(--radius-lg);
            padding: 24px;
            box-shadow: var(--shadow);
        }

        .geo-card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 16px;
            border-bottom: 1px solid var(--gray-200);
        }

        .geo-model-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .geo-model-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
        }

        .geo-model-icon.deepseek {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }

        .geo-model-icon.doubao {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }

        .geo-model-icon.qianwen {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }

        .geo-model-name {
            font-size: 18px;
            font-weight: 600;
            color: var(--gray-900);
        }

        .geo-model-desc {
            font-size: 13px;
            color: var(--gray-500);
            margin-top: 2px;
        }

        /* GEO指标网格 */
        .geo-metrics {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
        }

        .geo-metric {
            background: var(--gray-50);
            border-radius: 12px;
            padding: 16px;
            text-align: center;
        }

        .geo-metric-label {
            font-size: 13px;
            color: var(--gray-500);
            margin-bottom: 8px;
        }

        .geo-metric-value {
            font-size: 28px;
            font-weight: 700;
            color: var(--gray-900);
        }

        .geo-metric-value.high {
            color: var(--success);
        }

        .geo-metric-value.medium {
            color: #f59e0b;
        }

        .geo-metric-value.low {
            color: var(--danger);
        }

        .geo-metric-change {
            font-size: 12px;
            color: var(--gray-500);
            margin-top: 4px;
        }

        /* GEO分析详情 */
        .geo-details {
            margin-top: 20px;
        }

        .geo-detail-section {
            margin-bottom: 16px;
        }

        .geo-detail-title {
            font-size: 14px;
            font-weight: 600;
            color: var(--gray-700);
            margin-bottom: 8px;
        }

        .geo-keywords {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }

        .geo-keyword {
            background: var(--primary-light);
            color: var(--primary);
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 13px;
        }

        .geo-keyword.negative {
            background: #fee2e2;
            color: var(--danger);
        }

        /* GEO对比表格 */
        .geo-comparison-table {
            width: 100%;
            border-collapse: collapse;
        }

        .geo-comparison-table th,
        .geo-comparison-table td {
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid var(--gray-200);
        }

        .geo-comparison-table th {
            background: var(--gray-50);
            font-weight: 600;
            color: var(--gray-700);
            font-size: 13px;
        }

        .geo-comparison-table td {
            font-size: 14px;
            color: var(--gray-900);
        }

        .geo-score-bar {
            height: 8px;
            background: var(--gray-200);
            border-radius: 4px;
            overflow: hidden;
            width: 120px;
        }

        .geo-score-fill {
            height: 100%;
            border-radius: 4px;
            transition: width 0.3s ease;
        }

        .geo-score-fill.high {
            background: var(--success);
        }

        .geo-score-fill.medium {
            background: #f59e0b;
        }

        .geo-score-fill.low {
            background: var(--danger);
        }
```

---

### Task 2: 重构数据中心为Tab结构

**Files:**
- Modify: `prototype.html` (数据中心模块, 约第2027行)

- [ ] **Step 1: 添加Tab导航**

将数据中心模块开头修改为：

```html
            <!-- 数据中心模块 -->
            <div id="data" class="module">
                <div class="page-header">
                    <div>
                        <h1 class="page-title">数据中心</h1>
                        <p class="page-desc">核心指标监控与数据分析</p>
                    </div>
                    <button class="btn btn-secondary">刷新数据</button>
                </div>

                <div class="tabs">
                    <div class="tab active" data-tab="overview">数据总览</div>
                    <div class="tab" data-tab="geo">GEO分析</div>
                </div>
```

- [ ] **Step 2: 包装现有内容为数据总览Tab**

将现有的时间范围选择器和数据卡片、图表包装到 `<div id="data-overview" class="data-tab active">` 中：

```html
                <!-- 数据总览 -->
                <div id="data-overview" class="data-tab active">
                    <div class="filter-bar">
                        <span class="filter-label">时间范围:</span>
                        <div class="time-range">
                            <button class="time-btn">今天</button>
                            <button class="time-btn active">近7天</button>
                            <button class="time-btn">近30天</button>
                            <button class="time-btn">自定义</button>
                        </div>
                    </div>

                    <div class="data-cards">
                        <!-- 现有的data-card内容保持不变 -->
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px;">
                        <!-- 现有的图表内容保持不变 -->
                    </div>
                </div>
```

---

## Chunk 2: GEO分析Tab内容

### Task 3: 添加GEO分析Tab内容

**Files:**
- Modify: `prototype.html` (数据中心模块, 在数据总览后)

- [ ] **Step 1: 添加GEO分析Tab HTML结构**

在 `</div>` (数据总览Tab结束) 后添加：

```html
                <!-- GEO分析 -->
                <div id="data-geo" class="data-tab">
                    <div class="filter-bar">
                        <span class="filter-label">分析产品:</span>
                        <select class="select" style="width: 200px;">
                            <option>全部产品</option>
                            <option>产品A</option>
                            <option>产品B</option>
                        </select>
                        <span class="filter-label" style="margin-left: 24px;">时间范围:</span>
                        <div class="time-range">
                            <button class="time-btn active">近7天</button>
                            <button class="time-btn">近30天</button>
                            <button class="time-btn">近90天</button>
                        </div>
                    </div>

                    <!-- 大模型分析卡片区域 -->
                    <div style="display: grid; grid-template-columns: 1fr; gap: 24px;">
                        <!-- DeepSeek分析卡片 -->
                        <div class="geo-card">
                            <div class="geo-card-header">
                                <div class="geo-model-info">
                                    <div class="geo-model-icon deepseek">🤖</div>
                                    <div>
                                        <div class="geo-model-name">DeepSeek</div>
                                        <div class="geo-model-desc">深度求索 · 智能分析引擎</div>
                                    </div>
                                </div>
                                <div style="text-align: right;">
                                    <div style="font-size: 13px; color: var(--gray-500);">分析时间</div>
                                    <div style="font-size: 14px; font-weight: 500;">2026-03-29 14:30</div>
                                </div>
                            </div>
                            <div class="geo-metrics">
                                <div class="geo-metric">
                                    <div class="geo-metric-label">产品提及率</div>
                                    <div class="geo-metric-value high">78.5%</div>
                                    <div class="geo-metric-change">↑ 5.2% 较上周</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">产品优先度</div>
                                    <div class="geo-metric-value high">92</div>
                                    <div class="geo-metric-change">排名 #2</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">正面情感</div>
                                    <div class="geo-metric-value high">85%</div>
                                    <div class="geo-metric-change">↑ 3% 较上周</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">推荐指数</div>
                                    <div class="geo-metric-value medium">7.8</div>
                                    <div class="geo-metric-change">/ 10</div>
                                </div>
                            </div>
                            <div class="geo-details">
                                <div class="geo-detail-section">
                                    <div class="geo-detail-title">高频关联词</div>
                                    <div class="geo-keywords">
                                        <span class="geo-keyword">性价比高</span>
                                        <span class="geo-keyword">功能齐全</span>
                                        <span class="geo-keyword">用户体验好</span>
                                        <span class="geo-keyword">响应速度快</span>
                                        <span class="geo-keyword">界面简洁</span>
                                    </div>
                                </div>
                                <div class="geo-detail-section">
                                    <div class="geo-detail-title">负面关联词</div>
                                    <div class="geo-keywords">
                                        <span class="geo-keyword negative">价格偏高</span>
                                        <span class="geo-keyword negative">学习成本</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 豆包分析卡片 -->
                        <div class="geo-card">
                            <div class="geo-card-header">
                                <div class="geo-model-info">
                                    <div class="geo-model-icon doubao">🎯</div>
                                    <div>
                                        <div class="geo-model-name">豆包</div>
                                        <div class="geo-model-desc">字节跳动 · 智能助手</div>
                                    </div>
                                </div>
                                <div style="text-align: right;">
                                    <div style="font-size: 13px; color: var(--gray-500);">分析时间</div>
                                    <div style="font-size: 14px; font-weight: 500;">2026-03-29 14:25</div>
                                </div>
                            </div>
                            <div class="geo-metrics">
                                <div class="geo-metric">
                                    <div class="geo-metric-label">产品提及率</div>
                                    <div class="geo-metric-value high">82.3%</div>
                                    <div class="geo-metric-change">↑ 8.1% 较上周</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">产品优先度</div>
                                    <div class="geo-metric-value high">95</div>
                                    <div class="geo-metric-change">排名 #1</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">正面情感</div>
                                    <div class="geo-metric-value high">91%</div>
                                    <div class="geo-metric-change">↑ 6% 较上周</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">推荐指数</div>
                                    <div class="geo-metric-value high">8.5</div>
                                    <div class="geo-metric-change">/ 10</div>
                                </div>
                            </div>
                            <div class="geo-details">
                                <div class="geo-detail-section">
                                    <div class="geo-detail-title">高频关联词</div>
                                    <div class="geo-keywords">
                                        <span class="geo-keyword">操作简单</span>
                                        <span class="geo-keyword">功能强大</span>
                                        <span class="geo-keyword">服务好</span>
                                        <span class="geo-keyword">更新及时</span>
                                        <span class="geo-keyword">文档完善</span>
                                    </div>
                                </div>
                                <div class="geo-detail-section">
                                    <div class="geo-detail-title">负面关联词</div>
                                    <div class="geo-keywords">
                                        <span class="geo-keyword negative">偶有卡顿</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 千问分析卡片 -->
                        <div class="geo-card">
                            <div class="geo-card-header">
                                <div class="geo-model-info">
                                    <div class="geo-model-icon qianwen">💡</div>
                                    <div>
                                        <div class="geo-model-name">通义千问</div>
                                        <div class="geo-model-desc">阿里云 · 智能问答</div>
                                    </div>
                                </div>
                                <div style="text-align: right;">
                                    <div style="font-size: 13px; color: var(--gray-500);">分析时间</div>
                                    <div style="font-size: 14px; font-weight: 500;">2026-03-29 14:20</div>
                                </div>
                            </div>
                            <div class="geo-metrics">
                                <div class="geo-metric">
                                    <div class="geo-metric-label">产品提及率</div>
                                    <div class="geo-metric-value medium">65.2%</div>
                                    <div class="geo-metric-change">↑ 2.3% 较上周</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">产品优先度</div>
                                    <div class="geo-metric-value medium">78</div>
                                    <div class="geo-metric-change">排名 #4</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">正面情感</div>
                                    <div class="geo-metric-value high">79%</div>
                                    <div class="geo-metric-change">→ 持平</div>
                                </div>
                                <div class="geo-metric">
                                    <div class="geo-metric-label">推荐指数</div>
                                    <div class="geo-metric-value medium">7.2</div>
                                    <div class="geo-metric-change">/ 10</div>
                                </div>
                            </div>
                            <div class="geo-details">
                                <div class="geo-detail-section">
                                    <div class="geo-detail-title">高频关联词</div>
                                    <div class="geo-keywords">
                                        <span class="geo-keyword">稳定可靠</span>
                                        <span class="geo-keyword">接口丰富</span>
                                        <span class="geo-keyword">社区活跃</span>
                                        <span class="geo-keyword">案例多</span>
                                    </div>
                                </div>
                                <div class="geo-detail-section">
                                    <div class="geo-detail-title">负面关联词</div>
                                    <div class="geo-keywords">
                                        <span class="geo-keyword negative">配置复杂</span>
                                        <span class="geo-keyword negative">文档分散</span>
                                        <span class="geo-keyword negative">版本更新慢</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 模型对比表格 -->
                    <div class="card" style="margin-top: 24px;">
                        <div class="card-title">模型结果对比</div>
                        <div style="margin-top: 16px; overflow-x: auto;">
                            <table class="geo-comparison-table">
                                <thead>
                                    <tr>
                                        <th>指标</th>
                                        <th>DeepSeek</th>
                                        <th>豆包</th>
                                        <th>千问</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>产品提及率</td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 78.5%;"></div>
                                                </div>
                                                <span>78.5%</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 82.3%;"></div>
                                                </div>
                                                <span>82.3%</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill medium" style="width: 65.2%;"></div>
                                                </div>
                                                <span>65.2%</span>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>产品优先度</td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 92%;"></div>
                                                </div>
                                                <span>92</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 95%;"></div>
                                                </div>
                                                <span>95</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill medium" style="width: 78%;"></div>
                                                </div>
                                                <span>78</span>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>正面情感占比</td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 85%;"></div>
                                                </div>
                                                <span>85%</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 91%;"></div>
                                                </div>
                                                <span>91%</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 79%;"></div>
                                                </div>
                                                <span>79%</span>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>推荐指数</td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill medium" style="width: 78%;"></div>
                                                </div>
                                                <span>7.8/10</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill high" style="width: 85%;"></div>
                                                </div>
                                                <span>8.5/10</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 12px;">
                                                <div class="geo-score-bar">
                                                    <div class="geo-score-fill medium" style="width: 72%;"></div>
                                                </div>
                                                <span>7.2/10</span>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
```

---

## Chunk 3: JavaScript逻辑

### Task 4: 添加数据中心Tab切换逻辑

**Files:**
- Modify: `prototype.html` (JavaScript section)

- [ ] **Step 1: 添加数据中心Tab切换JavaScript**

在发布中心Tab切换逻辑后添加：

```javascript
            // 数据中心Tab切换
            var dataTabs = document.querySelectorAll('#data .tabs .tab');
            dataTabs.forEach(function(tab) {
                tab.addEventListener('click', function(e) {
                    e.stopPropagation();
                    var tabId = this.getAttribute('data-tab');

                    dataTabs.forEach(function(t) { t.classList.remove('active'); });
                    this.classList.add('active');

                    // 隐藏所有data tabs
                    document.querySelectorAll('.data-tab').forEach(function(el) {
                        el.classList.remove('active');
                    });

                    // 显示目标tab
                    var targetTab = document.getElementById('data-' + tabId);
                    if (targetTab) {
                        targetTab.classList.add('active');
                    }

                    // 滚动到页面顶部
                    document.querySelector('.main-content').scrollTop = 0;
                });
            });
```

- [ ] **Step 2: 添加数据中心初始化逻辑**

在初始化部分添加：

```javascript
            // 初始化data模块的第一个tab
            document.querySelectorAll('.data-tab').forEach(function(t) {
                t.classList.remove('active');
            });
            var initialDataTab = document.getElementById('data-overview');
            if (initialDataTab) {
                initialDataTab.classList.add('active');
            }
```

---

## Chunk 4: 验证和提交

### Task 5: 验证HTML结构并提交

- [ ] **Step 1: 验证HTML结构正确**

运行Python脚本验证无标签错误

- [ ] **Step 2: 提交所有更改**

```bash
git add prototype.html docs/superpowers/plans/2026-03-29-data-center-enhancement.md
git commit -m "feat: 数据中心新增GEO分析功能

- 数据中心改为Tab结构（数据总览/GEO分析）
- 新增GEO分析Tab展示大模型分析结果
- 支持DeepSeek、豆包、千问三大模型
- 展示产品提及率、优先度、情感分析等指标
- 新增模型结果对比表格

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## 功能说明

### 新增功能
1. **数据中心Tab结构** - 数据总览 + GEO分析两个Tab
2. **GEO分析卡片** - 每个大模型独立卡片展示分析结果
3. **核心指标** - 产品提及率、产品优先度、正面情感、推荐指数
4. **关联词分析** - 高频关联词和负面关联词标签展示
5. **模型对比表格** - 多模型指标横向对比，带进度条可视化

### 大模型支持
- **DeepSeek** - 深度求索智能分析引擎
- **豆包** - 字节跳动智能助手
- **千问** - 阿里云智能问答

### 交互流程
1. 用户进入数据中心 → 默认显示数据总览
2. 点击"GEO分析"Tab → 查看各大模型分析结果
3. 可筛选产品和时间范围
4. 查看模型对比表格进行横向分析
