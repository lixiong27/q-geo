# 热词分析模块 - 前端技术规格

## 一、概述

本文档定义热词分析模块的前端实现细节，包括页面组件修改、API 服务扩展和新增组件。

---

## 二、文件结构

```
src/
├── pages/hotword/
│   ├── index.jsx              # 修改：新增热词分析 Tab
│   ├── HotWordManage.jsx      # 修改：新增类型筛选
│   ├── HotWordAnalysis.jsx    # 新增：热词分析任务页面
│   ├── HotWordDig.jsx         # 不变
│   └── HotWordExpand.jsx      # 不变
├── api/
│   └── hotWord.js             # 修改：新增分析任务 API
└── components/
    └── hotword/
        └── TypeFilter.jsx     # 新增：类型筛选组件
```

---

## 三、API 服务修改

### 3.1 hotWord.js 修改

**文件位置：** `src/api/hotWord.js`

#### 修改现有方法

```javascript
/**
 * Get hot word list - 新增 type 参数
 * @param {Object} params - Query parameters
 * @param {string} params.type - Hot word type filter (poiAnalysis/platAnalysis)
 */
export const getHotWordList = async (params = {}) => {
    const { sourceType, page = 1, size = 20, keyword, type } = params;
    const queryParams = new URLSearchParams({ page: String(page), size: String(size) });
    if (sourceType !== undefined && sourceType !== null) {
        queryParams.append('sourceType', String(sourceType));
    }
    if (keyword) {
        queryParams.append('keyword', keyword);
    }
    // 新增 type 参数
    if (type) {
        queryParams.append('type', type);
    }
    return request.get(`/hotWord/list?${queryParams.toString()}`);
};

/**
 * Add a new hot word - 新增 type 参数
 * @param {Object} data - Hot word data
 * @param {string} data.type - Hot word type
 */
export const addHotWord = async (data) => {
    return request.post('/hotWord/add', {
        word: data.word,
        tags: Array.isArray(data.tags) ? data.tags.join(',') : data.tags,
        type: data.type  // 新增
    });
};
```

#### 新增方法

```javascript
/**
 * 获取热词类型配置（从 QConfig）
 */
export const getHotWordTypes = async () => {
    return request.get('/hotWord/types');
};

/**
 * 获取分析模型配置（从 QConfig）
 */
export const getAnalysisModels = async () => {
    return request.get('/hotWord/models');
};

/**
 * 创建热词分析任务
 * @param {Object} data - Task data
 * @param {number} data.hotwordId - 关联热词ID（必填，从已有热词中选择）
 * @param {string} data.name - Task name
 * @param {string} data.type - Hot word type (poiAnalysis/platAnalysis)
 * @param {string} data.model - Model type (从 getAnalysisModels 获取)
 * @param {number} data.count - Expected count
 */
export const createAnalysisTask = async (data) => {
    return request.post('/hotWord/task/analysis/create', {
        hotwordId: data.hotwordId,  // 必填：关联热词ID
        name: data.name,
        type: data.type,
        model: data.model,
        count: data.count,
        createdBy: 'system'
    });
};

/**
 * 导入分析任务结果
 * @param {number} taskId - Task ID
 * @param {Array} selectedWords - Selected words to import [{ word, type }]
 */
export const importAnalysisResults = async (taskId, selectedWords) => {
    return request.post('/hotWord/task/importAnalysisResults', {
        taskId,
        selectedWords
    });
};
```

---

## 四、组件修改

### 4.1 index.jsx 修改

**文件位置：** `src/pages/hotword/index.jsx`

**变更内容：** 新增「热词分析」Tab

```jsx
import React, { useState } from 'react';
import { Tabs, Card } from 'antd';
import HotWordManage from './HotWordManage';
import HotWordDig from './HotWordDig';
import HotWordExpand from './HotWordExpand';
import HotWordAnalysis from './HotWordAnalysis';  // 新增

const { TabPane } = Tabs;

const HotWord = () => {
    const [activeKey, setActiveKey] = useState('manage');

    return (
        <div className="page-container">
            <div className="page-header">
                <div>
                    <h1 className="page-title">热词中心</h1>
                    <p className="page-desc">管理热词、热词挖掘、热词扩词、热词分析</p>
                </div>
            </div>

            <Card bordered={false}>
                <Tabs
                    activeKey={activeKey}
                    onChange={setActiveKey}
                    size="large"
                >
                    <TabPane tab="热词管理" key="manage">
                        <HotWordManage />
                    </TabPane>
                    <TabPane tab="热词挖掘" key="dig">
                        <HotWordDig />
                    </TabPane>
                    <TabPane tab="热词扩词" key="expand">
                        <HotWordExpand />
                    </TabPane>
                    {/* 新增热词分析 Tab */}
                    <TabPane tab="热词分析" key="analysis">
                        <HotWordAnalysis />
                    </TabPane>
                </Tabs>
            </Card>
        </div>
    );
};

export default HotWord;
```

### 4.2 HotWordManage.jsx 修改

**文件位置：** `src/pages/hotword/HotWordManage.jsx`

#### 变更点

1. **新增状态：** 热词类型列表、当前选中的类型
2. **修改筛选栏：** 新增类型筛选 Tag 组
3. **修改表格列：** 新增类型列
4. **修改新增/编辑弹窗：** 新增类型选择
5. **修改来源筛选：** 新增「分析」来源选项

#### 详细变更

```jsx
// 新增状态
const [typeList, setTypeList] = useState([]);
const [queryParams, setQueryParams] = useState({
    sourceType: undefined,
    type: undefined,  // 新增
    page: 1,
    size: 20
});

// 新增 useEffect 获取类型配置
useEffect(() => {
    fetchTypeList();
}, []);

const fetchTypeList = async () => {
    try {
        const res = await getHotWordTypes();
        setTypeList(res.list || []);
    } catch (error) {
        console.error('Failed to fetch type list:', error);
    }
};

// 修改来源筛选
const sourceFilters = [
    { label: '全部', value: undefined },
    { label: '手动', value: 0 },
    { label: '挖掘', value: 1 },
    { label: '分析', value: 2 }  // 新增
];

// 新增类型筛选渲染
const renderTypeFilter = () => {
    if (typeList.length === 0) return null;

    return (
        <>
            <span style={{ color: '#666', fontWeight: 500, marginLeft: '24px' }}>类型:</span>
            <div style={{ display: 'flex', gap: '8px' }}>
                <Tag
                    style={{
                        cursor: 'pointer',
                        borderRadius: '20px',
                        padding: '4px 14px',
                        background: queryParams.type === undefined ? '#4f46e5' : '#f3f4f6',
                        color: queryParams.type === undefined ? '#fff' : '#6b7280',
                        border: queryParams.type === undefined ? 'none' : '1px solid transparent'
                    }}
                    onClick={() => setQueryParams({ ...queryParams, type: undefined, page: 1 })}
                >
                    全部
                </Tag>
                {typeList.map(item => (
                    <Tag
                        key={item.key}
                        style={{
                            cursor: 'pointer',
                            borderRadius: '20px',
                            padding: '4px 14px',
                            background: queryParams.type === item.key ? '#4f46e5' : '#f3f4f6',
                            color: queryParams.type === item.key ? '#fff' : '#6b7280',
                            border: queryParams.type === item.key ? 'none' : '1px solid transparent'
                        }}
                        onClick={() => setQueryParams({ ...queryParams, type: item.key, page: 1 })}
                    >
                        {item.name}
                    </Tag>
                ))}
            </div>
        </>
    );
};

// 修改表格列
const columns = [
    {
        title: '热词',
        dataIndex: 'word',
        key: 'word',
        render: (text) => <strong>{text}</strong>
    },
    // 新增类型列
    {
        title: '类型',
        dataIndex: 'type',
        key: 'type',
        render: (type) => {
            if (!type) return <span style={{ color: '#999' }}>-</span>;
            const typeInfo = typeList.find(t => t.key === type);
            return <Tag color="purple">{typeInfo?.name || type}</Tag>;
        }
    },
    {
        title: '标签',
        dataIndex: 'tags',
        key: 'tags',
        // ... 保持不变
    },
    {
        title: '来源',
        dataIndex: 'sourceType',
        key: 'sourceType',
        render: (type) => {
            const sourceMap = {
                0: { text: '手动', color: 'purple' },
                1: { text: '挖掘', color: 'orange' },
                2: { text: '分析', color: 'cyan' }  // 新增
            };
            const item = sourceMap[type] || sourceMap[0];
            return <Tag color={item.color}>{item.text}</Tag>;
        }
    },
    // 新增任务ID列
    {
        title: '任务ID',
        dataIndex: 'sourceTaskId',
        key: 'sourceTaskId',
        render: (taskId) => taskId && taskId > 0 ? (
            <a onClick={() => viewTaskDetail(taskId)}>{taskId}</a>
        ) : (
            <span style={{ color: '#999' }}>-</span>
        )
    },
    // ... 操作列保持不变
];

// 修改新增/编辑弹窗 Form
<Form form={form} layout="vertical">
    <Form.Item
        name="word"
        label="热词内容"
        rules={[{ required: true, message: '请输入热词内容' }]}
    >
        <Input placeholder="请输入热词" />
    </Form.Item>
    {/* 新增类型选择 */}
    <Form.Item
        name="type"
        label="热词类型"
    >
        <Select placeholder="请选择类型" allowClear>
            {typeList.map(item => (
                <Option key={item.key} value={item.key}>
                    {item.name}
                </Option>
            ))}
        </Select>
    </Form.Item>
    <Form.Item
        name="tags"
        label="标签"
        extra="输入后按回车添加"
    >
        <Select mode="tags" placeholder="多个标签用逗号分隔" style={{ width: '100%' }} />
    </Form.Item>
</Form>
```

---

## 五、新增组件

### 5.1 HotWordAnalysis.jsx

**文件位置：** `src/pages/hotword/HotWordAnalysis.jsx`

**功能说明：** 热词分析任务页面，包含任务列表、新建任务、查看结果、导入热词

```jsx
import React, { useState, useEffect } from 'react';
import {
    Button,
    Card,
    Tag,
    Space,
    Modal,
    Form,
    Input,
    Select,
    message,
    Checkbox,
    AutoComplete,
    Spin
} from 'antd';
import { getTaskList, createAnalysisTask, getTaskDetail, cancelTask, retryTask, importAnalysisResults, getHotWordTypes, getAnalysisModels, getHotWordList } from '../../api/hotWord';

const { Option } = Select;

/**
 * Hot Word Analysis - 热词分析任务
 */
const HotWordAnalysis = () => {
    const [loading, setLoading] = useState(false);
    const [taskList, setTaskList] = useState([]);
    const [typeList, setTypeList] = useState([]);  // 热词类型列表
    const [modelList, setModelList] = useState([]); // 分析模型列表（从后端动态获取）
    const [createModalVisible, setCreateModalVisible] = useState(false);
    const [resultModalVisible, setResultModalVisible] = useState(false);
    const [currentTask, setCurrentTask] = useState(null);
    const [selectedWords, setSelectedWords] = useState([]);
    const [form] = Form.useForm();

    // 热词搜索相关状态
    const [hotwordSearchLoading, setHotwordSearchLoading] = useState(false);
    const [hotwordOptions, setHotwordOptions] = useState([]);
    const [selectedHotword, setSelectedHotword] = useState(null);
    const [searchTimeout, setSearchTimeout] = useState(null);

    useEffect(() => {
        fetchTaskList();
        fetchTypeList();
        fetchModelList();
    }, []);

    const fetchTaskList = async () => {
        setLoading(true);
        try {
            const res = await getTaskList({ type: 'analysis' });
            setTaskList(res.list || []);
        } catch (error) {
            message.error(error.message);
        } finally {
            setLoading(false);
        }
    };

    const fetchTypeList = async () => {
        try {
            const res = await getHotWordTypes();
            setTypeList(res.list || []);
        } catch (error) {
            console.error('Failed to fetch type list:', error);
        }
    };

    const fetchModelList = async () => {
        try {
            const res = await getAnalysisModels();
            setModelList(res.list || []);
            // 如果有默认模型，设置默认值
            if (res.list && res.list.length > 0) {
                form.setFieldsValue({ model: res.list[0].key || res.list[0] });
            }
        } catch (error) {
            console.error('Failed to fetch model list:', error);
        }
    };

    /**
     * 热词模糊搜索
     */
    const handleHotwordSearch = (keyword) => {
        // 清除之前的定时器
        if (searchTimeout) {
            clearTimeout(searchTimeout);
        }

        if (!keyword || keyword.trim().length === 0) {
            setHotwordOptions([]);
            return;
        }

        // 防抖，延迟300ms搜索
        const timeout = setTimeout(async () => {
            setHotwordSearchLoading(true);
            try {
                const res = await getHotWordList({ keyword: keyword.trim(), size: 10 });
                const options = (res.list || []).map(item => ({
                    value: item.id,
                    label: (
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <span>{item.word}</span>
                            <Tag color="purple" style={{ fontSize: '11px' }}>
                                {typeList.find(t => t.key === item.type)?.name || item.type || '-'}
                            </Tag>
                        </div>
                    ),
                    item
                }));
                setHotwordOptions(options);
            } catch (error) {
                console.error('Failed to search hotwords:', error);
            } finally {
                setHotwordSearchLoading(false);
            }
        }, 300);

        setSearchTimeout(timeout);
    };

    /**
     * 选择热词
     */
    const handleHotwordSelect = (value, option) => {
        setSelectedHotword(option.item);
        form.setFieldsValue({ hotwordId: value });
    };

    /**
     * 清除选中的热词
     */
    const handleClearHotword = () => {
        setSelectedHotword(null);
        form.setFieldsValue({ hotwordId: undefined });
        setHotwordOptions([]);
    };

    const handleCreateTask = () => {
        form.resetFields();
        setSelectedHotword(null);
        setHotwordOptions([]);
        // 设置默认模型（如果模型列表已加载）
        const defaultModel = modelList.length > 0 ? (modelList[0].key || modelList[0]) : undefined;
        form.setFieldsValue({ model: defaultModel, count: 10 });
        setCreateModalVisible(true);
    };

    const handleSubmitTask = async () => {
        try {
            const values = await form.validateFields();

            // 验证是否选择了热词
            if (!values.hotwordId) {
                message.warning('请选择关联的热词');
                return;
            }

            await createAnalysisTask({
                hotwordId: values.hotwordId,
                name: values.name,
                type: values.type,
                model: values.model,
                count: values.count
            });
            message.success('任务创建成功');
            setCreateModalVisible(false);
            fetchTaskList();
        } catch (error) {
            if (error.errorFields) return;
            message.error(error.message);
        }
    };

    const handleViewResult = async (task) => {
        try {
            const detail = await getTaskDetail(task.id);
            setCurrentTask(detail);
            setSelectedWords(detail.result?.words?.map((_, index) => index) || []);
            setResultModalVisible(true);
        } catch (error) {
            message.error(error.message);
        }
    };

    const handleCancelTask = async (id) => {
        try {
            await cancelTask(id);
            message.success('任务已取消');
            fetchTaskList();
        } catch (error) {
            message.error(error.message);
        }
    };

    const handleRetryTask = async (id) => {
        try {
            await retryTask(id);
            message.success('任务已重新执行');
            fetchTaskList();
        } catch (error) {
            message.error(error.message);
        }
    };

    const handleImportSelected = async () => {
        if (!currentTask?.result?.words) {
            message.warning('没有可选的热词');
            return;
        }

        const wordsToImport = selectedWords.map(
            index => currentTask.result.words[index]
        ).filter(w => w);

        if (wordsToImport.length === 0) {
            message.warning('请选择要导入的热词');
            return;
        }

        try {
            await importAnalysisResults(currentTask.id, wordsToImport);
            message.success(`成功导入 ${wordsToImport.length} 个热词`);
            setResultModalVisible(false);
        } catch (error) {
            message.error(error.message);
        }
    };

    // Get model label
    const getModelLabel = (model) => {
        if (!modelList || modelList.length === 0) return model;
        const modelInfo = modelList.find(m => (m.key || m) === model);
        if (modelInfo) {
            return modelInfo.name || modelInfo.key || modelInfo;
        }
        return model;
    };

    // Get status tag
    const getStatusTag = (status) => {
        const statusMap = {
            0: { text: '待执行', color: 'default' },
            1: { text: '运行中', color: 'processing' },
            2: { text: '已完成', color: 'success' },
            3: { text: '失败', color: 'error' }
        };
        const item = statusMap[status] || statusMap[0];
        return <Tag color={item.color}>{item.text}</Tag>;
    };

    // Render task card
    const renderTaskCard = (task) => {
        const params = task.params || {};
        const wordCount = task.result?.total || 0;
        const typeInfo = typeList.find(t => t.key === params.type);

        return (
            <Card
                key={task.id}
                style={{
                    marginBottom: '16px',
                    borderRadius: '12px',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
                }}
                hoverable
            >
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    {/* Task icon */}
                    <div style={{
                        width: '48px',
                        height: '48px',
                        borderRadius: '12px',
                        background: 'linear-gradient(135deg, #c7d2fe 0%, #a5b4fc 100%)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '24px'
                    }}>
                        <span role="img" aria-label="analysis">&#128202;</span>
                    </div>

                    {/* Task info */}
                    <div style={{ flex: 1 }}>
                        <div style={{ fontSize: '16px', fontWeight: 600, marginBottom: '4px' }}>
                            {task.name}
                        </div>
                        <div style={{ fontSize: '13px', color: '#999' }}>
                            {getModelLabel(task.model)} · {typeInfo?.name || params.type} · {wordCount}个热词 · {task.createTime?.substring(0, 16) || '-'}
                        </div>
                    </div>

                    {/* Status */}
                    {getStatusTag(task.status)}

                    {/* Actions */}
                    <Space>
                        {task.status === 2 && (
                            <Button size="small" onClick={() => handleViewResult(task)}>
                                查看
                            </Button>
                        )}
                        {task.status === 1 && (
                            <>
                                <Button size="small" onClick={() => handleViewResult(task)}>
                                    查看
                                </Button>
                                <Button size="small" onClick={() => handleCancelTask(task.id)}>
                                    取消
                                </Button>
                            </>
                        )}
                        {task.status === 3 && (
                            <Button size="small" onClick={() => handleRetryTask(task.id)}>
                                重试
                            </Button>
                        )}
                    </Space>
                </div>
            </Card>
        );
    };

    return (
        <div>
            {/* Header */}
            <div style={{ marginBottom: '16px' }}>
                <div style={{ fontSize: '16px', fontWeight: 600, marginBottom: '16px' }}>
                    任务列表
                </div>
                <Button type="primary" onClick={handleCreateTask}>
                    + 新建任务
                </Button>
            </div>

            {/* Task list */}
            {loading ? (
                <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
                    加载中...
                </div>
            ) : taskList.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '60px', color: '#999' }}>
                    <div style={{ fontSize: '48px', marginBottom: '16px', opacity: 0.5 }}>
                        <span role="img" aria-label="empty">&#128196;</span>
                    </div>
                    <div>暂无任务</div>
                </div>
            ) : (
                taskList.map(task => renderTaskCard(task))
            )}

            {/* Create Task Modal */}
            <Modal
                title="新建热词分析任务"
                open={createModalVisible}
                onOk={handleSubmitTask}
                onCancel={() => setCreateModalVisible(false)}
                okText="开始执行"
                cancelText="取消"
            >
                <Form form={form} layout="vertical">
                    {/* 关联热词选择 */}
                    <Form.Item
                        name="hotwordId"
                        label="关联热词"
                        rules={[{ required: true, message: '请选择关联热词' }]}
                    >
                        {selectedHotword ? (
                            <div style={{
                                padding: '8px 12px',
                                background: '#f5f5f5',
                                borderRadius: '8px',
                                border: '1px solid #e8e8e8'
                            }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <span style={{ fontWeight: 500 }}>{selectedHotword.word}</span>
                                        <Tag color="purple" style={{ marginLeft: 8, fontSize: '11px' }}>
                                            {typeList.find(t => t.key === selectedHotword.type)?.name || selectedHotword.type || '-'}
                                        </Tag>
                                    </div>
                                    <Button type="link" size="small" onClick={handleClearHotword}>清除</Button>
                                </div>
                                <div style={{ fontSize: '12px', color: '#999', marginTop: 4 }}>
                                    热词ID: {selectedHotword.id}
                                </div>
                            </div>
                        ) : (
                            <AutoComplete
                                style={{ width: '100%' }}
                                options={hotwordOptions}
                                onSearch={handleHotwordSearch}
                                onSelect={handleHotwordSelect}
                                placeholder="输入关键词搜索已有热词..."
                                notFoundContent={hotwordSearchLoading ? <Spin size="small" /> : '未找到匹配的热词'}
                            />
                        )}
                    </Form.Item>
                    <Form.Item
                        name="name"
                        label="任务名称"
                        rules={[{ required: true, message: '请输入任务名称' }]}
                    >
                        <Input placeholder="请输入任务名称" />
                    </Form.Item>
                    <Form.Item
                        name="type"
                        label="热词类型"
                        rules={[{ required: true, message: '请选择热词类型' }]}
                    >
                        <Select placeholder="请选择类型">
                            {typeList.map(item => (
                                <Option key={item.key} value={item.key}>
                                    {item.name}
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>
                    <Form.Item
                        name="model"
                        label="分析模型"
                    >
                        <Select style={{ width: 200 }} placeholder="请选择模型">
                            {modelList.map(item => {
                                const key = item.key || item;
                                const name = item.name || item;
                                return (
                                    <Option key={key} value={key}>
                                        {name}
                                    </Option>
                                );
                            })}
                        </Select>
                    </Form.Item>
                    <Form.Item
                        name="count"
                        label="预期数量"
                        initialValue={10}
                        rules={[{ required: true, message: '请选择预期数量' }]}
                    >
                        <Select style={{ width: 150 }}>
                            <Option value={5}>5</Option>
                            <Option value={10}>10</Option>
                            <Option value={15}>15</Option>
                            <Option value={20}>20</Option>
                            <Option value={30}>30</Option>
                            <Option value={50}>50</Option>
                        </Select>
                    </Form.Item>
                </Form>
            </Modal>

            {/* Result Modal */}
            <Modal
                title={`分析结果 - ${currentTask?.name || ''}`}
                open={resultModalVisible}
                onOk={handleImportSelected}
                onCancel={() => setResultModalVisible(false)}
                okText="导入选中"
                cancelText="取消"
                width={600}
            >
                <p style={{ marginBottom: '16px', color: '#666' }}>
                    共分析 {currentTask?.result?.total || 0} 个热词
                </p>
                <div style={{
                    maxHeight: '400px',
                    overflowY: 'auto',
                    border: '1px solid #e8e8e8',
                    borderRadius: '8px',
                    padding: '12px'
                }}>
                    {currentTask?.result?.words?.map((item, index) => (
                        <div
                            key={index}
                            style={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: '8px',
                                padding: '8px 0',
                                borderBottom: index < currentTask.result.words.length - 1 ? '1px solid #f0f0f0' : 'none'
                            }}
                        >
                            <Checkbox
                                checked={selectedWords.includes(index)}
                                onChange={(e) => {
                                    if (e.target.checked) {
                                        setSelectedWords([...selectedWords, index]);
                                    } else {
                                        setSelectedWords(selectedWords.filter(i => i !== index));
                                    }
                                }}
                            />
                            <span style={{ flex: 1 }}>{item.word}</span>
                            <Tag color="purple" style={{ fontSize: '12px' }}>
                                {typeList.find(t => t.key === item.type)?.name || item.type}
                            </Tag>
                        </div>
                    ))}
                </div>
                <div style={{ marginTop: '12px' }}>
                    <a onClick={() => setSelectedWords(currentTask?.result?.words?.map((_, i) => i) || [])} style={{ color: '#4f46e5' }}>全选</a>
                    <span style={{ margin: '0 8px', color: '#999' }}>/</span>
                    <a onClick={() => setSelectedWords([])} style={{ color: '#4f46e5' }}>取消全选</a>
                </div>
            </Modal>
        </div>
    );
};

export default HotWordAnalysis;
```

---

## 六、文件变更清单

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `src/pages/hotword/index.jsx` | 修改 | 新增「热词分析」Tab |
| `src/pages/hotword/HotWordManage.jsx` | 修改 | 新增类型筛选、类型列、来源「分析」选项 |
| `src/pages/hotword/HotWordAnalysis.jsx` | 新增 | 热词分析任务页面（模型列表动态获取） |
| `src/api/hotWord.js` | 修改 | 新增 getHotWordTypes、getAnalysisModels、createAnalysisTask、importAnalysisResults |

---

## 七、依赖说明

### 7.1 后端接口依赖

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/hotWord/list` | GET | 支持 type 参数 |
| `/api/hotWord/add` | POST | 支持 type 参数 |
| `/api/hotWord/types` | GET | 新增：获取热词类型配置 |
| `/api/hotWord/models` | GET | 新增：获取分析模型配置 |
| `/api/hotWord/task/list` | GET | 支持 type=analysis |
| `/api/hotWord/task/analysis/create` | POST | 新增：创建分析任务 |
| `/api/hotWord/task/importAnalysisResults` | POST | 新增：导入分析结果 |

### 7.2 组件依赖

- React 16
- Ant Design 4.x (Table, Modal, Form, Select, Tag, Button, Card, Checkbox)
- axios

---

## 八、状态管理

本模块使用 React Hooks 进行状态管理，无需引入额外的状态管理库。

### 状态结构

```javascript
// HotWordManage.jsx
const [typeList, setTypeList] = useState([]);        // 热词类型列表
const [queryParams, setQueryParams] = useState({
    sourceType: undefined,
    type: undefined,    // 热词类型筛选
    page: 1,
    size: 20
});

// HotWordAnalysis.jsx
const [taskList, setTaskList] = useState([]);        // 任务列表
const [typeList, setTypeList] = useState([]);        // 热词类型列表
const [modelList, setModelList] = useState([]);      // 分析模型列表（动态获取）
const [currentTask, setCurrentTask] = useState(null); // 当前查看的任务
const [selectedWords, setSelectedWords] = useState([]); // 选中的热词索引
```
