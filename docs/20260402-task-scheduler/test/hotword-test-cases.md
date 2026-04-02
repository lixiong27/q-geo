# 热词模块测试用例全集

## 测试概述

**测试范围：** 热词中心全模块（管理、挖掘、扩词、分析）

**测试环境：**
- 后端：http://localhost:8080
- 前端：http://localhost:3000
- 数据库：mkt_ares_live_beta

**文档版本：** v2.0 (2026-04-02)

---

## 一、热词管理模块

### 1.1 后端接口测试

| 编号 | 用例 | 方法 | 路径 | 请求参数 | 预期结果 |
|------|------|------|------|----------|----------|
| HW-API-001 | 查询全部热词 | GET | /api/hotWord/list | page=1, size=10 | code=0, 返回分页列表 |
| HW-API-002 | 关键词搜索 | GET | /api/hotWord/list | keyword="机票" | 返回包含"机票"的热词 |
| HW-API-003 | 来源筛选-手动 | GET | /api/hotWord/list | sourceType=0 | 返回手动添加热词 |
| HW-API-004 | 来源筛选-挖掘 | GET | /api/hotWord/list | sourceType=1 | 返回挖掘热词 |
| HW-API-005 | 来源筛选-分析 | GET | /api/hotWord/list | sourceType=2 | 返回分析热词 |
| HW-API-006 | 类型筛选 | GET | /api/hotWord/list | type="travel" | 返回旅游类型热词 |
| HW-API-007 | 新增热词 | POST | /api/hotWord/add | {word:"测试词", tags:["test"]} | code=0, 返回热词对象 |
| HW-API-008 | 重复新增 | POST | /api/hotWord/add | {word:"已存在词"} | code=非0, 提示重复 |
| HW-API-009 | 空热词新增 | POST | /api/hotWord/add | {word:""} | code=非0, 参数错误 |
| HW-API-010 | 批量导入 | POST | /api/hotWord/import | {words:["词1","词2"]} | code=0, 返回导入数量 |
| HW-API-011 | 更新热词 | POST | /api/hotWord/update | {id:1, word:"新词", tags:["new"]} | code=0 |
| HW-API-012 | 更新不存在热词 | POST | /api/hotWord/update | {id:99999, word:"新词"} | code=非0 |
| HW-API-013 | 删除热词 | POST | /api/hotWord/delete | {id:1} | code=0 |
| HW-API-014 | 删除不存在热词 | POST | /api/hotWord/delete | {id:99999} | code=非0 |
| HW-API-015 | 获取所有热词 | GET | /api/hotWord/all | - | 返回全部热词列表 |

### 1.2 前端页面测试

| 编号 | 用例 | 步骤 | 预期结果 |
|------|------|------|----------|
| HW-UI-001 | 页面加载 | 访问 /hotWord | 显示热词列表表格 |
| HW-UI-002 | 热词云展示 | 查看顶部区域 | 显示最多12个热词标签 |
| HW-UI-003 | 热词云样式 | 查看标签样式 | 白色背景、紫色文字、圆角 |
| HW-UI-004 | 来源筛选-全部 | 点击"全部" | 显示所有来源热词 |
| HW-UI-005 | 来源筛选-手动 | 点击"手动" | 显示手动添加热词 |
| HW-UI-006 | 来源筛选-挖掘 | 点击"挖掘" | 显示挖掘热词 |
| HW-UI-007 | 搜索筛选 | 输入关键词搜索 | 列表过滤显示 |
| HW-UI-008 | 新增弹窗 | 点击"新增热词" | 弹出表单弹窗 |
| HW-UI-009 | 表单校验 | 空关键词提交 | 显示错误提示 |
| HW-UI-010 | 标签输入 | 输入标签后回车 | 生成蓝色标签 |
| HW-UI-011 | 新增提交 | 填写完整信息提交 | 弹窗关闭，列表刷新 |
| HW-UI-012 | 手动导入弹窗 | 点击"手动导入" | 弹出导入弹窗 |
| HW-UI-013 | 批量导入 | 输入多行热词提交 | 显示导入成功数量 |
| HW-UI-014 | 编辑弹窗 | 点击编辑按钮 | 弹出预填表单 |
| HW-UI-015 | 编辑保存 | 修改内容后保存 | 列表更新 |
| HW-UI-016 | 删除确认 | 点击删除按钮 | 弹出确认框 |
| HW-UI-017 | 确定删除 | 点击确认框确定 | 列表移除该行 |
| HW-UI-018 | 取消删除 | 点击确认框取消 | 数据不变 |
| HW-UI-019 | 分页切换 | 点击页码 | 数据正确切换 |
| HW-UI-020 | 每页条数 | 切换每页条数 | 重新分页 |

---

## 二、热词挖掘模块

### 2.1 后端接口测试

| 编号 | 用例 | 方法 | 路径 | 请求参数 | 预期结果 |
|------|------|------|------|----------|----------|
| HM-API-001 | 查询挖掘任务 | GET | /api/hotWord/task/list | type=dig | 返回挖掘任务列表 |
| HM-API-002 | 状态筛选 | GET | /api/hotWord/task/list | type=dig, status=2 | 返回已完成任务 |
| HM-API-003 | 分页查询 | GET | /api/hotWord/task/list | page=1, size=5 | 返回5条数据 |
| HM-API-004 | 任务详情 | GET | /api/hotWord/task/detail | id=1 | 返回任务详情 |
| HM-API-005 | 任务详情-不存在 | GET | /api/hotWord/task/detail | id=99999 | code=非0 |
| HM-API-006 | 创建挖掘任务 | POST | /api/hotWord/task/dig/create | {name, keywords, count} | 返回任务对象 |
| HM-API-007 | 取消任务-运行中 | POST | /api/hotWord/task/cancel | {id:runningTaskId} | code=0, 状态变失败 |
| HM-API-008 | 取消任务-已完成 | POST | /api/hotWord/task/cancel | {id:completedTaskId} | code=非0 |
| HM-API-009 | 重试任务-失败 | POST | /api/hotWord/task/retry | {id:failedTaskId} | code=0, 重新执行 |
| HM-API-010 | 重试任务-成功 | POST | /api/hotWord/task/retry | {id:completedTaskId} | code=非0 |
| HM-API-011 | 导入挖掘结果 | POST | /api/hotWord/task/importResults | {taskId, selectedWords} | 返回导入数量 |

### 2.2 前端页面测试

| 编号 | 用例 | 步骤 | 预期结果 |
|------|------|------|----------|
| HM-UI-001 | Tab切换 | 点击"热词挖掘"Tab | 显示任务列表 |
| HM-UI-002 | 新建按钮 | 查看顶部 | 显示"+ 新建任务"按钮 |
| HM-UI-003 | 新建弹窗 | 点击新建按钮 | 弹出创建表单 |
| HM-UI-004 | 任务名称必填 | 不填名称提交 | 显示错误提示 |
| HM-UI-005 | 关键词输入 | 输入多个关键词 | 支持逗号分隔 |
| HM-UI-006 | 预期数量选择 | 点击下拉 | 显示5/10/15/20选项 |
| HM-UI-007 | 提交成功 | 填写完整信息提交 | 任务创建成功 |
| HM-UI-008 | 任务卡片样式 | 查看任务列表 | 圆角卡片带阴影 |
| HM-UI-009 | 状态-待执行 | 查看PENDING任务 | 灰色标签 |
| HM-UI-010 | 状态-运行中 | 查看RUNNING任务 | 蓝色标签 |
| HM-UI-011 | 状态-已完成 | 查看COMPLETED任务 | 绿色标签 |
| HM-UI-012 | 状态-失败 | 查看FAILED任务 | 红色标签 |
| HM-UI-013 | 运行中操作 | 查看运行中任务 | 显示"查看""取消"按钮 |
| HM-UI-014 | 已完成操作 | 查看已完成任务 | 显示"查看"按钮 |
| HM-UI-015 | 失败操作 | 查看失败任务 | 显示"重试"按钮 |
| HM-UI-016 | 取消任务 | 点击取消按钮 | 任务变为失败状态 |
| HM-UI-017 | 重试任务 | 点击重试按钮 | 任务重新执行 |
| HM-UI-018 | 查看结果 | 点击查看按钮 | 弹出结果弹窗 |
| HM-UI-019 | 结果列表 | 查看结果弹窗 | 显示热词列表 |
| HM-UI-020 | 选择热词 | 点击checkbox | 热词被选中 |
| HM-UI-021 | 全选 | 点击全选 | 全部选中 |
| HM-UI-022 | 导入选中 | 点击导入选中 | 导入成功提示 |
| HM-UI-023 | 空列表 | 无任务时 | 显示空状态 |

---

## 三、热词扩词模块

### 3.1 后端接口测试

| 编号 | 用例 | 方法 | 路径 | 请求参数 | 预期结果 |
|------|------|------|------|----------|----------|
| HE-API-001 | 查询扩词任务 | GET | /api/hotWord/task/list | type=expand | 返回扩词任务列表 |
| HE-API-002 | 创建扩词任务 | POST | /api/hotWord/task/expand/create | {name, hotWordIds, countPerWord, style} | 返回任务对象 |
| HE-API-003 | 创建-无热词 | POST | /api/hotWord/task/expand/create | {name, hotWordIds:[]} | code=非0 |
| HE-API-004 | 任务详情 | GET | /api/hotWord/task/detail | id=expandTaskId | 返回任务和结果 |

### 3.2 前端页面测试

| 编号 | 用例 | 步骤 | 预期结果 |
|------|------|------|----------|
| HE-UI-001 | Tab切换 | 点击"智能扩词"Tab | 显示任务列表 |
| HE-UI-002 | 新建弹窗 | 点击新建按钮 | 弹出创建表单 |
| HE-UI-003 | 热词列表 | 查看表单 | 显示可滚动热词列表 |
| HE-UI-004 | 选择热词 | 点击热词checkbox | 热词被选中 |
| HE-UI-005 | 多选热词 | 选择多个热词 | 显示已选数量 |
| HE-UI-006 | 扩词数量 | 点击下拉 | 显示3/5/8/10选项 |
| HE-UI-007 | 扩词风格 | 点击下拉 | 显示4种风格选项 |
| HE-UI-008 | 提交成功 | 选择热词后提交 | 任务创建成功 |
| HE-UI-009 | 未选热词提交 | 不选热词提交 | 显示警告 |
| HE-UI-010 | 任务卡片样式 | 查看任务列表 | 粉色图标卡片 |
| HE-UI-011 | 状态显示 | 查看不同状态 | 颜色区分状态 |
| HE-UI-012 | 查看结果 | 点击查看按钮 | 弹出扩词结果 |
| HE-UI-013 | 结果分组 | 查看结果 | 按热词分组显示 |
| HE-UI-014 | 问题列表 | 查看某热词下 | 显示扩展问题 |

---

## 四、热词分析模块（新增）

### 4.1 后端接口测试

| 编号 | 用例 | 方法 | 路径 | 请求参数 | 预期结果 |
|------|------|------|------|----------|----------|
| HA-API-001 | 查询分析任务 | GET | /api/hotWord/task/list | type=analysis | 返回分析任务列表 |
| HA-API-002 | 状态筛选 | GET | /api/hotWord/task/list | type=analysis, status=2 | 返回已完成分析任务 |
| HA-API-003 | 创建分析任务-正常 | POST | /api/hotWord/task/analysis/create | {hotwordId:1, name:"分析测试", type:"travel", model:"deepseek", count:10} | code=0, status=1(运行中), downstreamTaskId有值 |
| HA-API-004 | 创建分析任务-热词不存在 | POST | /api/hotWord/task/analysis/create | {hotwordId:99999, name:"测试"} | code=非0, 提示热词不存在 |
| HA-API-005 | 创建分析任务-无模型 | POST | /api/hotWord/task/analysis/create | {hotwordId:1, name:"测试", model:""} | code=0, 使用默认prompt |
| HA-API-006 | 任务详情-运行中 | GET | /api/hotWord/task/detail | id=runningTaskId | 返回任务详情，status=1, downstreamTaskId有值 |
| HA-API-007 | 任务详情-已完成 | GET | /api/hotWord/task/detail | id=completedTaskId | 返回任务详情和result |
| HA-API-008 | 回调-成功 | POST | /api/hotWord/task/callback | {taskId:"downstreamId", status:"completed", result:{words:[...]}} | code=0, 任务状态变COMPLETED |
| HA-API-009 | 回调-失败 | POST | /api/hotWord/task/callback | {taskId:"downstreamId", status:"failed", result:{error:"xxx"}} | code=0, 任务状态变FAILED |
| HA-API-010 | 回调-无效taskId | POST | /api/hotWord/task/callback | {taskId:"invalidId", status:"completed"} | code=0, 忽略处理 |
| HA-API-011 | 取消分析任务-运行中 | POST | /api/hotWord/task/cancel | {id:runningTaskId} | code=0, 状态变FAILED |
| HA-API-012 | 重试分析任务-失败 | POST | /api/hotWord/task/retry | {id:failedTaskId} | code=0, 重新提交下游 |
| HA-API-013 | 导入分析结果-全部 | POST | /api/hotWord/task/importAnalysisResults | {taskId:completedTaskId, selectedWords:null} | 导入全部结果 |
| HA-API-014 | 导入分析结果-部分 | POST | /api/hotWord/task/importAnalysisResults | {taskId:completedTaskId, selectedWords:[...]} | 导入选中结果 |
| HA-API-015 | 导入分析结果-任务未完成 | POST | /api/hotWord/task/importAnalysisResults | {taskId:runningTaskId, selectedWords:[...]} | code=非0 |
| HA-API-016 | 获取模型列表 | GET | /api/hotWord/models | - | 返回可用模型列表 |
| HA-API-017 | 获取类型列表 | GET | /api/hotWord/types | - | 返回热词类型配置 |

### 4.2 前端页面测试

| 编号 | 用例 | 步骤 | 预期结果 |
|------|------|------|----------|
| HA-UI-001 | Tab切换 | 点击"热词分析"Tab | 显示分析任务列表 |
| HA-UI-002 | 新建按钮 | 查看顶部 | 显示"+ 新建任务"按钮 |
| HA-UI-003 | 新建弹窗 | 点击新建按钮 | 弹出创建表单 |
| HA-UI-004 | 热词选择 | 查看表单 | 显示热词下拉选择 |
| HA-UI-005 | 模型选择 | 查看表单 | 显示模型下拉选项 |
| HA-UI-006 | 类型选择 | 查看表单 | 显示类型下拉选项 |
| HA-UI-007 | 数量输入 | 查看表单 | 显示数量输入框 |
| HA-UI-008 | 必填校验 | 不填热词提交 | 显示错误提示 |
| HA-UI-009 | 提交成功 | 填写完整信息提交 | 任务创建成功，状态运行中 |
| HA-UI-010 | 任务卡片样式 | 查看任务列表 | 蓝色图标卡片 |
| HA-UI-011 | 模型显示 | 查看任务卡片 | 显示使用的模型 |
| HA-UI-012 | 状态-运行中 | 查看RUNNING任务 | 蓝色标签，显示下游任务ID |
| HA-UI-013 | 状态-已完成 | 查看COMPLETED任务 | 绿色标签 |
| HA-UI-014 | 状态-失败 | 查看FAILED任务 | 红色标签 |
| HA-UI-015 | 运行中操作 | 查看运行中任务 | 显示"查看""取消"按钮 |
| HA-UI-016 | 已完成操作 | 查看已完成任务 | 显示"查看""导入"按钮 |
| HA-UI-017 | 失败操作 | 查看失败任务 | 显示"重试"按钮 |
| HA-UI-018 | 查看结果 | 点击查看按钮 | 弹出分析结果弹窗 |
| HA-UI-019 | 结果列表 | 查看结果弹窗 | 显示分析出的热词列表 |
| HA-UI-020 | 词+类型显示 | 查看结果项 | 显示词汇和类型 |
| HA-UI-021 | 选择热词 | 点击checkbox | 热词被选中 |
| HA-UI-022 | 全选/取消全选 | 点击全选链接 | 全部选中/取消 |
| HA-UI-023 | 导入结果 | 点击导入按钮 | 导入成功，热词列表更新 |
| HA-UI-024 | 空列表 | 无任务时 | 显示空状态 |
| HA-UI-025 | 加载状态 | 刷新页面 | 显示加载中 |

---

## 五、端到端测试场景

### 5.1 热词管理 E2E

| 编号 | 场景 | 步骤 | 预期结果 |
|------|------|------|----------|
| HW-E2E-001 | 完整新增流程 | 1.点击新增热词<br>2.输入"北京旅游"<br>3.添加标签"旅游"<br>4.提交 | 热词添加成功，列表显示新热词 |
| HW-E2E-002 | 编辑流程 | 1.点击编辑某热词<br>2.修改内容<br>3.保存 | 热词更新成功 |
| HW-E2E-003 | 删除流程 | 1.点击删除某热词<br>2.确认删除 | 热词从列表移除 |
| HW-E2E-004 | 批量导入流程 | 1.点击手动导入<br>2.输入多行热词<br>3.提交 | 显示导入成功数量 |
| HW-E2E-005 | 筛选流程 | 1.点击"手动"标签<br>2.查看列表<br>3.点击"挖掘"标签 | 正确筛选显示 |

### 5.2 热词挖掘 E2E

| 编号 | 场景 | 步骤 | 预期结果 |
|------|------|------|----------|
| HM-E2E-001 | 完整挖掘流程 | 1.新建挖掘任务<br>2.输入关键词"AI,GPT"<br>3.选择数量10<br>4.提交<br>5.等待完成<br>6.查看结果<br>7.选择热词导入 | 任务创建→执行→完成→导入成功 |
| HM-E2E-002 | 取消任务 | 1.新建任务<br>2.运行中点击取消 | 任务变为失败状态 |
| HM-E2E-003 | 重试任务 | 1.找到失败任务<br>2.点击重试 | 任务重新执行 |

### 5.3 热词扩词 E2E

| 编号 | 场景 | 步骤 | 预期结果 |
|------|------|------|----------|
| HE-E2E-001 | 完整扩词流程 | 1.新建扩词任务<br>2.选择热词<br>3.选择数量和风格<br>4.提交<br>5.查看结果 | 任务创建→执行→完成→显示扩展问题 |
| HE-E2E-002 | 多热词扩词 | 1.选择多个热词<br>2.提交任务<br>3.查看结果 | 结果按热词分组显示 |

### 5.4 热词分析 E2E（新增）

| 编号 | 场景 | 步骤 | 预期结果 |
|------|------|------|----------|
| HA-E2E-001 | 完整分析流程 | 1.新建分析任务<br>2.选择热词"北京"<br>3.选择模型"deepseek"<br>4.选择类型"travel"<br>5.提交<br>6.等待回调<br>7.查看结果<br>8.导入选中热词 | 任务创建→提交下游→回调更新→导入成功 |
| HA-E2E-002 | 下游回调成功 | 1.任务运行中<br>2.下游调用回调接口<br>3.status=completed | 任务状态变COMPLETED，result保存 |
| HA-E2E-003 | 下游回调失败 | 1.任务运行中<br>2.下游调用回调接口<br>3.status=failed | 任务状态变FAILED |
| HA-E2E-004 | 取消运行中任务 | 1.任务运行中<br>2.点击取消 | 任务变为失败状态 |
| HA-E2E-005 | 重试失败任务 | 1.任务失败<br>2.点击重试<br>3.重新提交下游 | 任务重新运行 |
| HA-E2E-006 | 不同模型测试 | 1.使用deepseek创建任务<br>2.使用qianwen创建任务<br>3.对比结果 | 不同模型prompt不同，结果不同 |
| HA-E2E-007 | 结果导入-部分 | 1.查看已完成任务结果<br>2.选择部分热词<br>3.导入 | 选中的热词导入成功 |
| HA-E2E-008 | 结果导入-全部 | 1.查看已完成任务结果<br>2.不选择直接导入 | 全部热词导入成功 |

---

## 六、回归测试场景

### 6.1 历史功能回归

| 编号 | 场景 | 验证点 | 预期结果 |
|------|------|--------|----------|
| REG-001 | 热词管理-基础CRUD | 新增/编辑/删除 | 功能正常 |
| REG-002 | 热词管理-筛选 | 来源/类型筛选 | 筛选正确 |
| REG-003 | 热词管理-批量导入 | 多行导入 | 导入成功 |
| REG-004 | 热词挖掘-创建任务 | 新建挖掘任务 | 任务创建成功 |
| REG-005 | 热词挖掘-查看结果 | 查看已完成任务结果 | 结果显示正确 |
| REG-006 | 热词挖掘-导入结果 | 选择热词导入 | 导入成功 |
| REG-007 | 热词扩词-创建任务 | 新建扩词任务 | 任务创建成功 |
| REG-008 | 热词扩词-查看结果 | 查看扩词结果 | 分组显示正确 |

### 6.2 数据一致性回归

| 编号 | 场景 | 验证点 | 预期结果 |
|------|------|--------|----------|
| REG-009 | 热词来源统计 | 挖掘导入后来源类型 | sourceType=1 |
| REG-010 | 分析热词来源 | 分析导入后来源类型 | sourceType=2 |
| REG-011 | 任务关联热词 | 分析任务params.hotwordId | 关联正确 |
| REG-012 | downstreamTaskId | 分析任务提交后 | 字段有值 |

### 6.3 兼容性回归

| 编号 | 场景 | 验证点 | 预期结果 |
|------|------|--------|----------|
| REG-013 | 老任务显示 | 挖掘/扩词任务 | 显示正常，操作正常 |
| REG-014 | 老热词显示 | 历史热词数据 | 显示正常 |
| REG-015 | 类型配置 | QConfig类型配置 | 加载正常 |
| REG-016 | 模型配置 | QConfig模型配置 | 加载正常 |

---

## 七、异常测试场景

### 7.1 后端异常

| 编号 | 场景 | 触发条件 | 预期结果 |
|------|------|----------|----------|
| ERR-001 | 下游服务不可用 | 下游域名未配置 | 创建任务失败，提示配置错误 |
| ERR-002 | 下游服务超时 | 下游服务响应超时 | 抛出异常，记录日志 |
| ERR-003 | 下游服务错误 | 下游返回非201 | 抛出异常，任务创建失败 |
| ERR-004 | 回调重复处理 | 同一taskId多次回调 | 幂等处理，不重复更新 |
| ERR-005 | 数据库连接失败 | 数据库不可用 | 返回错误响应 |
| ERR-006 | 参数校验失败 | 必填参数为空 | 返回参数错误 |

### 7.2 前端异常

| 编号 | 场景 | 触发条件 | 预期结果 |
|------|------|----------|----------|
| ERR-007 | 网络错误 | 请求超时 | 显示错误提示 |
| ERR-008 | 服务器错误 | 返回500 | 显示服务器错误 |
| ERR-009 | 空数据处理 | 列表为空 | 显示空状态 |
| ERR-010 | 表单校验 | 必填项为空 | 显示错误提示 |

---

## 八、测试数据准备

```sql
-- 热词测试数据
INSERT INTO hot_word (word, source_type, type, tags, create_time) VALUES
('北京旅游', 0, 'travel', '["旅游","北京"]', NOW()),
('上海机票', 0, 'travel', '["机票","上海"]', NOW()),
('GPT-5发布', 1, 'tech', '["AI","科技"]', NOW()),
('特价酒店', 2, 'travel', '["酒店","旅游"]', NOW());

-- 分析任务测试数据
INSERT INTO hot_word_task (name, type, model, downstream_task_id, params, status, result, create_time) VALUES
('北京旅游分析', 'analysis', 'deepseek', 'test-downstream-001', '{"hotwordId":1,"hotword":"北京旅游","type":"travel","count":10}', 2, '{"total":5,"words":[{"word":"北京天安门门票","type":"travel"}]}', NOW()),
('上海机票分析-运行中', 'analysis', 'qianwen', 'test-downstream-002', '{"hotwordId":2,"hotword":"上海机票","type":"travel","count":10}', 1, NULL, NOW()),
('GPT分析-失败', 'analysis', 'deepseek', 'test-downstream-003', '{"hotwordId":3,"hotword":"GPT-5发布","type":"tech","count":10}', 3, '{"error":"下游服务超时"}', NOW());
```

---

## 九、测试执行记录

| 执行日期 | 版本 | 模块 | 通过 | 失败 | 阻塞 | 执行人 |
|----------|------|------|------|------|------|--------|
| - | - | - | - | - | - | - |

---

## 十、附录

### A. 接口清单

| 模块 | 接口 | 方法 | 路径 |
|------|------|------|------|
| 热词管理 | 列表 | GET | /api/hotWord/list |
| 热词管理 | 全部 | GET | /api/hotWord/all |
| 热词管理 | 新增 | POST | /api/hotWord/add |
| 热词管理 | 导入 | POST | /api/hotWord/import |
| 热词管理 | 更新 | POST | /api/hotWord/update |
| 热词管理 | 删除 | POST | /api/hotWord/delete |
| 热词管理 | 类型列表 | GET | /api/hotWord/types |
| 热词管理 | 模型列表 | GET | /api/hotWord/models |
| 任务管理 | 任务列表 | GET | /api/hotWord/task/list |
| 任务管理 | 任务详情 | GET | /api/hotWord/task/detail |
| 任务管理 | 挖掘任务 | POST | /api/hotWord/task/dig/create |
| 任务管理 | 扩词任务 | POST | /api/hotWord/task/expand/create |
| 任务管理 | 分析任务 | POST | /api/hotWord/task/analysis/create |
| 任务管理 | 取消任务 | POST | /api/hotWord/task/cancel |
| 任务管理 | 重试任务 | POST | /api/hotWord/task/retry |
| 任务管理 | 挖掘导入 | POST | /api/hotWord/task/importResults |
| 任务管理 | 分析导入 | POST | /api/hotWord/task/importAnalysisResults |
| 任务管理 | **回调接口** | POST | /api/hotWord/task/callback |

### B. 状态码说明

| 状态值 | 含义 | 说明 |
|--------|------|------|
| 0 | PENDING | 待执行 |
| 1 | RUNNING | 执行中 |
| 2 | COMPLETED | 已完成 |
| 3 | FAILED | 失败 |

### C. 下游接口契约

**创建任务:**
```
POST {downstream_host}/api/tasks
Content-Type: application/json

Request:
{
  "name": "热词分析-xxx",
  "prompt": "请分析以下热词...",
  "priority": 5,
  "maxRetries": 3
}

Response 201:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending"
}
```

**回调通知:**
```
POST /api/hotWord/task/callback
Content-Type: application/json

Request:
{
  "taskId": "550e8400-e29b-41d4-a716-446655440000",
  "type": "analysis",
  "status": "completed",
  "result": {"words": [...]}
}
```
