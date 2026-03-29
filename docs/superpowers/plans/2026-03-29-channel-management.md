# 渠道管理功能实现计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在发布中心新增渠道管理功能，支持渠道的增删改查，并与发布任务联动

**Architecture:** 在发布中心模块新增"渠道管理"Tab，包含渠道列表、新增/编辑/删除渠道功能；发布配置区域与渠道数据联动

**Tech Stack:** HTML/CSS/JavaScript (纯前端原型)

---

## 文件结构

```
prototype.html
├── CSS样式 (新增渠道管理相关样式)
├── 发布中心模块 (新增渠道管理Tab)
└── JavaScript逻辑 (渠道CRUD操作 + Tab切换)
```

---

## Chunk 1: CSS样式和Tab结构

### Task 1: 添加渠道管理相关CSS样式

**Files:**
- Modify: `prototype.html` (CSS section, 约第550-560行附近)

- [ ] **Step 1: 添加渠道管理弹窗样式**

在 `.channel-item` 样式后添加新样式：

```css
        /* 渠道管理弹窗 */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
        }

        .modal {
            background: var(--bg-card);
            border-radius: var(--radius-lg);
            padding: 24px;
            width: 480px;
            max-width: 90vw;
            box-shadow: var(--shadow-lg);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .modal-title {
            font-size: 18px;
            font-weight: 600;
            color: var(--gray-900);
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 24px;
            color: var(--gray-400);
            cursor: pointer;
            padding: 0;
            line-height: 1;
        }

        .modal-close:hover {
            color: var(--gray-600);
        }

        .modal-body {
            margin-bottom: 24px;
        }

        .modal-footer {
            display: flex;
            justify-content: flex-end;
            gap: 12px;
        }

        /* 渠道状态指示 */
        .channel-status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 6px;
        }

        .channel-status-dot.active {
            background: var(--success);
        }

        .channel-status-dot.inactive {
            background: var(--gray-400);
        }

        /* 渠道操作按钮 */
        .channel-actions {
            display: flex;
            gap: 8px;
            margin-left: auto;
        }

        .channel-action-btn {
            padding: 4px 8px;
            font-size: 12px;
            background: var(--gray-100);
            border: none;
            border-radius: 4px;
            cursor: pointer;
            color: var(--gray-600);
        }

        .channel-action-btn:hover {
            background: var(--gray-200);
        }

        .channel-action-btn.delete {
            color: var(--danger);
        }

        .channel-action-btn.delete:hover {
            background: #fee2e2;
        }

        /* 渠道图标选择器 */
        .icon-selector {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .icon-option {
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            border: 2px solid var(--gray-200);
            border-radius: var(--radius-sm);
            cursor: pointer;
            transition: all 0.2s;
        }

        .icon-option:hover {
            border-color: var(--primary-light);
        }

        .icon-option.selected {
            border-color: var(--primary);
            background: linear-gradient(135deg, #eef2ff 0%, #e0e7ff 100%);
        }
```

- [ ] **Step 2: 提交样式更改**

此步骤在Chunk 1所有修改完成后统一提交。

---

### Task 2: 新增渠道管理Tab结构

**Files:**
- Modify: `prototype.html` (发布中心模块, 约第1756-1760行)

- [ ] **Step 1: 修改Tab导航，添加"渠道管理"Tab**

将原Tab结构：
```html
                <div class="tabs">
                    <div class="tab active">发布队列</div>
                    <div class="tab">执行记录</div>
                </div>
```

修改为：
```html
                <div class="tabs">
                    <div class="tab active" data-tab="queue">发布队列</div>
                    <div class="tab" data-tab="history">执行记录</div>
                    <div class="tab" data-tab="channel">渠道管理</div>
                </div>
```

- [ ] **Step 2: 为发布队列和执行记录添加容器和class**

将发布队列内容包装到 `<div id="publish-queue" class="publish-tab active">` 中，执行记录后续添加。

找到发布队列卡片区域（约第1761-1806行），包装为：

```html
                <!-- 发布队列 -->
                <div id="publish-queue" class="publish-tab active">
                    <div class="card">
                        <!-- 原有发布队列内容 -->
                    </div>

                    <div class="card" style="margin-top: 24px;">
                        <!-- 原有发布配置内容 -->
                    </div>
                </div>
```

---

## Chunk 2: 渠道管理Tab内容

### Task 3: 添加渠道管理Tab内容

**Files:**
- Modify: `prototype.html` (发布中心模块, 在发布配置区域后)

- [ ] **Step 1: 添加渠道管理Tab的HTML结构**

在发布配置区域后（约第1847行 `</div>` 后）添加：

```html
                <!-- 渠道管理 -->
                <div id="publish-channel" class="publish-tab">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">渠道列表</h3>
                            <button class="btn btn-primary" onclick="openChannelModal()">+ 新增渠道</button>
                        </div>

                        <div class="channel-list" id="channel-list">
                            <!-- 渠道项将通过JS动态渲染 -->
                        </div>
                    </div>

                    <div class="card" style="margin-top: 24px;">
                        <div class="card-title">使用说明</div>
                        <div style="padding: 20px; background: var(--gray-50); border-radius: 8px; margin-top: 16px;">
                            <p style="color: var(--gray-600); margin-bottom: 12px;">
                                <strong>渠道配置：</strong>添加发布渠道后，可在发布任务中选择对应渠道进行发布
                            </p>
                            <p style="color: var(--gray-600); margin-bottom: 12px;">
                                <strong>状态管理：</strong>可启用/禁用渠道，禁用后不会出现在发布选项中
                            </p>
                            <p style="color: var(--gray-600);">
                                <strong>联动发布：</strong>选择"全渠道发布"时，会自动发布到所有已启用的渠道
                            </p>
                        </div>
                    </div>
                </div>
```

- [ ] **Step 2: 添加新增/编辑渠道弹窗HTML**

在 `</main>` 标签前（约第1964行）添加弹窗模板：

```html
        <!-- 渠道编辑弹窗 -->
        <div class="modal-overlay" id="channel-modal" style="display: none;">
            <div class="modal">
                <div class="modal-header">
                    <h3 class="modal-title" id="modal-title">新增渠道</h3>
                    <button class="modal-close" onclick="closeChannelModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <div class="form-group">
                        <div class="form-label">渠道名称 <span style="color: var(--danger);">*</span></div>
                        <input type="text" class="input" id="channel-name" placeholder="如：微信公众号">
                    </div>
                    <div class="form-group">
                        <div class="form-label">渠道图标</div>
                        <div class="icon-selector" id="icon-selector">
                            <div class="icon-option selected" data-icon="📱">📱</div>
                            <div class="icon-option" data-icon="📝">📝</div>
                            <div class="icon-option" data-icon="🎬">🎬</div>
                            <div class="icon-option" data-icon="📷">📷</div>
                            <div class="icon-option" data-icon="🎤">🎤</div>
                            <div class="icon-option" data-icon="📺">📺</div>
                            <div class="icon-option" data-icon="📰">📰</div>
                            <div class="icon-option" data-icon="💼">💼</div>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-label">渠道描述</div>
                        <input type="text" class="input" id="channel-desc" placeholder="渠道说明（可选）">
                    </div>
                    <div class="form-group">
                        <div class="form-label">状态</div>
                        <label class="checkbox-label">
                            <input type="checkbox" id="channel-active" checked> 启用该渠道
                        </label>
                    </div>
                    <input type="hidden" id="channel-id">
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" onclick="closeChannelModal()">取消</button>
                    <button class="btn btn-primary" onclick="saveChannel()">保存</button>
                </div>
            </div>
        </div>
```

---

## Chunk 3: JavaScript逻辑实现

### Task 4: 添加Tab切换逻辑

**Files:**
- Modify: `prototype.html` (JavaScript section, 约第1990行后)

- [ ] **Step 1: 添加publish-tab CSS类定义**

在CSS的 `.query-tab.active` 后添加：

```css
        .publish-tab {
            display: none;
        }
        .publish-tab.active {
            display: block;
        }
```

- [ ] **Step 2: 添加发布中心Tab切换JavaScript**

在内容中心Tab切换逻辑后添加：

```javascript
            // 发布中心Tab切换
            var publishTabs = document.querySelectorAll('#publish .tabs .tab');
            publishTabs.forEach(function(tab) {
                tab.addEventListener('click', function(e) {
                    e.stopPropagation();
                    var tabId = this.getAttribute('data-tab');

                    publishTabs.forEach(function(t) { t.classList.remove('active'); });
                    this.classList.add('active');

                    // 隐藏所有publish tabs
                    document.querySelectorAll('.publish-tab').forEach(function(el) {
                        el.classList.remove('active');
                    });

                    // 显示目标tab
                    var targetTab = document.getElementById('publish-' + tabId);
                    if (targetTab) {
                        targetTab.classList.add('active');
                    }

                    // 滚动到页面顶部
                    document.querySelector('.main-content').scrollTop = 0;
                });
            });
```

---

### Task 5: 实现渠道CRUD逻辑

**Files:**
- Modify: `prototype.html` (JavaScript section)

- [ ] **Step 1: 添加渠道数据管理和CRUD函数**

在JavaScript末尾（`toggleTemplatePanel` 函数后）添加：

```javascript
        // ==================== 渠道管理 ====================

        // 渠道数据（模拟后端数据）
        var channelData = [
            { id: 1, name: '微信公众号', icon: '📱', desc: '微信公众平台', active: true },
            { id: 2, name: '知乎', icon: '📝', desc: '知乎专栏', active: true },
            { id: 3, name: '微博', icon: '🎬', desc: '新浪微博', active: false },
            { id: 4, name: '小红书', icon: '📷', desc: '小红书笔记', active: false }
        ];
        var nextChannelId = 5;
        var selectedIcon = '📱';

        // 渲染渠道列表
        function renderChannelList() {
            var listEl = document.getElementById('channel-list');
            if (!listEl) return;

            var html = '';
            channelData.forEach(function(channel) {
                html += '<div class="channel-item" data-id="' + channel.id + '">' +
                    '<div class="channel-status-dot ' + (channel.active ? 'active' : 'inactive') + '"></div>' +
                    '<div class="channel-icon">' + channel.icon + '</div>' +
                    '<div class="channel-info">' +
                        '<div class="channel-name">' + channel.name + '</div>' +
                        '<div class="channel-status">' + (channel.active ? '已启用' : '已禁用') + (channel.desc ? ' · ' + channel.desc : '') + '</div>' +
                    '</div>' +
                    '<div class="channel-actions">' +
                        '<button class="channel-action-btn" onclick="editChannel(' + channel.id + ')">编辑</button>' +
                        '<button class="channel-action-btn" onclick="toggleChannelStatus(' + channel.id + ')">' + (channel.active ? '禁用' : '启用') + '</button>' +
                        '<button class="channel-action-btn delete" onclick="deleteChannel(' + channel.id + ')">删除</button>' +
                    '</div>' +
                '</div>';
            });
            listEl.innerHTML = html;

            // 同步更新发布配置中的渠道列表
            updatePublishChannelOptions();
        }

        // 更新发布配置中的渠道选项
        function updatePublishChannelOptions() {
            var channelGrid = document.querySelector('#publish-queue .channel-grid');
            if (!channelGrid) return;

            var html = '';
            channelData.filter(function(c) { return c.active; }).forEach(function(channel) {
                html += '<div class="channel-item">' +
                    '<input type="checkbox" checked data-channel-id="' + channel.id + '">' +
                    '<div class="channel-icon">' + channel.icon + '</div>' +
                    '<div class="channel-info">' +
                        '<div class="channel-name">' + channel.name + '</div>' +
                        '<div class="channel-status">已配置</div>' +
                    '</div>' +
                '</div>';
            });
            channelGrid.innerHTML = html;
        }

        // 打开新增/编辑弹窗
        function openChannelModal(id) {
            var modal = document.getElementById('channel-modal');
            var title = document.getElementById('modal-title');
            var nameInput = document.getElementById('channel-name');
            var descInput = document.getElementById('channel-desc');
            var activeInput = document.getElementById('channel-active');
            var idInput = document.getElementById('channel-id');

            if (id) {
                // 编辑模式
                var channel = channelData.find(function(c) { return c.id === id; });
                if (channel) {
                    title.textContent = '编辑渠道';
                    nameInput.value = channel.name;
                    descInput.value = channel.desc || '';
                    activeInput.checked = channel.active;
                    idInput.value = id;
                    selectedIcon = channel.icon;
                    updateIconSelector();
                }
            } else {
                // 新增模式
                title.textContent = '新增渠道';
                nameInput.value = '';
                descInput.value = '';
                activeInput.checked = true;
                idInput.value = '';
                selectedIcon = '📱';
                updateIconSelector();
            }

            modal.style.display = 'flex';
        }

        // 关闭弹窗
        function closeChannelModal() {
            document.getElementById('channel-modal').style.display = 'none';
        }

        // 更新图标选择器状态
        function updateIconSelector() {
            document.querySelectorAll('#icon-selector .icon-option').forEach(function(el) {
                el.classList.toggle('selected', el.getAttribute('data-icon') === selectedIcon);
            });
        }

        // 保存渠道
        function saveChannel() {
            var name = document.getElementById('channel-name').value.trim();
            var desc = document.getElementById('channel-desc').value.trim();
            var active = document.getElementById('channel-active').checked;
            var id = document.getElementById('channel-id').value;

            if (!name) {
                alert('请输入渠道名称');
                return;
            }

            if (id) {
                // 编辑
                var channel = channelData.find(function(c) { return c.id === parseInt(id); });
                if (channel) {
                    channel.name = name;
                    channel.icon = selectedIcon;
                    channel.desc = desc;
                    channel.active = active;
                }
            } else {
                // 新增
                channelData.push({
                    id: nextChannelId++,
                    name: name,
                    icon: selectedIcon,
                    desc: desc,
                    active: active
                });
            }

            closeChannelModal();
            renderChannelList();
        }

        // 编辑渠道
        function editChannel(id) {
            openChannelModal(id);
        }

        // 切换渠道状态
        function toggleChannelStatus(id) {
            var channel = channelData.find(function(c) { return c.id === id; });
            if (channel) {
                channel.active = !channel.active;
                renderChannelList();
            }
        }

        // 删除渠道
        function deleteChannel(id) {
            if (confirm('确定要删除该渠道吗？')) {
                channelData = channelData.filter(function(c) { return c.id !== id; });
                renderChannelList();
            }
        }

        // 初始化图标选择器事件
        function initIconSelector() {
            document.querySelectorAll('#icon-selector .icon-option').forEach(function(el) {
                el.addEventListener('click', function() {
                    selectedIcon = this.getAttribute('data-icon');
                    updateIconSelector();
                });
            });
        }
```

- [ ] **Step 2: 添加初始化调用**

在 DOMContentLoaded 事件末尾添加：

```javascript
            // 初始化渠道管理
            renderChannelList();
            initIconSelector();
```

---

### Task 6: 初始化发布队列Tab

**Files:**
- Modify: `prototype.html` (JavaScript section)

- [ ] **Step 1: 添加publish-queue初始化逻辑**

在初始化部分添加发布队列Tab的默认状态：

```javascript
            // 初始化publish模块的第一个tab
            document.querySelectorAll('.publish-tab').forEach(function(t) {
                t.classList.remove('active');
            });
            var initialPublishTab = document.getElementById('publish-queue');
            if (initialPublishTab) {
                initialPublishTab.classList.add('active');
            }
```

---

## Chunk 4: 最终验证和提交

### Task 7: 验证和提交

- [ ] **Step 1: 验证HTML结构正确**

运行: `python3 -c "验证脚本..."` 确保无标签错误

- [ ] **Step 2: 提交所有更改**

```bash
git add prototype.html
git commit -m "feat: 发布中心新增渠道管理功能

- 新增渠道管理Tab，支持渠道增删改查
- 渠道状态启用/禁用切换
- 发布配置与渠道数据联动
- 新增/编辑渠道弹窗组件

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## 功能说明

### 新增功能
1. **渠道管理Tab** - 在发布中心新增第三个Tab
2. **渠道列表** - 展示所有渠道，包含状态指示、图标、名称、描述
3. **渠道操作** - 编辑、启用/禁用、删除
4. **新增渠道弹窗** - 支持设置名称、图标、描述、状态
5. **联动发布** - 发布配置区域自动同步已启用的渠道

### 交互流程
1. 用户进入发布中心 → 点击"渠道管理"Tab
2. 查看渠道列表，点击"新增渠道"按钮
3. 弹窗中填写渠道信息，选择图标，保存
4. 返回"发布队列"Tab，新渠道出现在发布配置中
5. 发布时可选择指定渠道或全渠道发布
