# 前端技术方案

## 一、技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Node.js | 12.16.1 | 运行环境 |
| React | 16.14.0 | UI 框架 |
| Ant Design | 4.x | 组件库 |
| React Router | 5.x | 路由管理 |
| Axios | 0.21.x | HTTP 请求 |
| Moment.js | 2.29.x | 日期处理 |

---

## 二、项目结构

```
q-geo-web/
├── public/
│   └── index.html
├── src/
│   ├── api/                    # API 接口
│   │   ├── index.js            # Axios 实例配置
│   │   ├── hotWord.js          # 热词中心接口
│   │   ├── content.js          # 内容中心接口
│   │   ├── geoMonitor.js       # GEO分析接口
│   │   ├── dataCenter.js       # 数据中心接口
│   │   └── publish.js          # 发布中心接口
│   │
│   ├── components/             # 公共组件
│   │   ├── Layout/             # 布局组件
│   │   │   ├── index.jsx
│   │   │   └── index.less
│   │   ├── SearchForm/         # 搜索表单
│   │   ├── DataTable/          # 数据表格
│   │   └── ModalForm/          # 弹窗表单
│   │
│   ├── pages/                  # 页面组件
│   │   ├── HotWord/            # 热词中心
│   │   │   ├── index.jsx       # 入口
│   │   │   ├── Manage.jsx      # 热词管理
│   │   │   ├── Dig.jsx         # 热词挖掘
│   │   │   ├── Expand.jsx      # 热词扩词
│   │   │   └── components/     # 页面私有组件
│   │   ├── Content/            # 内容中心
│   │   ├── GeoMonitor/         # GEO分析
│   │   ├── DataCenter/         # 数据中心
│   │   └── Publish/            # 发布中心
│   │
│   ├── store/                  # 状态管理
│   │   └── index.js            # React Context
│   │
│   ├── utils/                  # 工具函数
│   │   ├── request.js          # 请求封装
│   │   └── constants.js        # 常量定义
│   │
│   ├── App.jsx                 # 根组件
│   ├── index.js                # 入口文件
│   └── index.less              # 全局样式
│
├── config-overrides.js         # webpack 配置覆盖
└── package.json
```

---

## 三、API 封装

### 3.1 Axios 实例配置

```javascript
// src/api/index.js
import axios from 'axios';

const instance = axios.create({
    baseURL: '/api',
    timeout: 30000,
    headers: {
        'Content-Type': 'application/json'
    }
});

// 请求拦截器
instance.interceptors.request.use(
    config => {
        // 可添加 token
        const token = localStorage.getItem('token');
        if (token) {
            config.headers['Authorization'] = `Bearer ${token}`;
        }
        return config;
    },
    error => Promise.reject(error)
);

// 响应拦截器
instance.interceptors.response.use(
    response => {
        const { data } = response;
        if (data.code === 0) {
            return data.data;
        }
        // 业务错误处理
        return Promise.reject(new Error(data.message || '请求失败'));
    },
    error => {
        // HTTP 错误处理
        if (error.response) {
            switch (error.response.status) {
                case 401:
                    // 未授权，跳转登录
                    break;
                case 403:
                    // 无权限
                    break;
                case 500:
                    // 服务器错误
                    break;
                default:
                    break;
            }
        }
        return Promise.reject(error);
    }
);

export default instance;
```

### 3.2 接口定义示例

```javascript
// src/api/hotWord.js
import request from './index';

export default {
    // 热词列表
    list: (params) => request.get('/hotWord/list', { params }),

    // 新增热词
    add: (data) => request.post('/hotWord/add', data),

    // 批量导入
    import: (data) => request.post('/hotWord/import', data),

    // 更新热词
    update: (data) => request.post('/hotWord/update', data),

    // 删除热词
    delete: (id) => request.post('/hotWord/delete', { id })
};

// src/api/geoMonitor.js
import request from './index';

export default {
    // GEO分析列表
    list: (params) => request.get('/geoMonitor/list', { params })
};

// src/api/dataCenter.js
import request from './index';

export default {
    // 获取全部数据
    getAll: (params) => request.get('/dataCenter/all', { params })
};
```

---

## 四、页面组件示例

### 4.1 热词管理页面

```jsx
// src/pages/HotWord/Manage.jsx
import React, { useState, useEffect } from 'react';
import { Table, Button, Tag, Space, Modal, Form, Input, Select, message } from 'antd';
import { PlusOutlined, ImportOutlined } from '@ant-design/icons';
import hotWordApi from '../../api/hotWord';

const { Option } = Select;

const HotWordManage = () => {
    const [loading, setLoading] = useState(false);
    const [dataSource, setDataSource] = useState([]);
    const [total, setTotal] = useState(0);
    const [queryParams, setQueryParams] = useState({
        sourceType: undefined,
        page: 1,
        size: 20
    });
    const [modalVisible, setModalVisible] = useState(false);
    const [importModalVisible, setImportModalVisible] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [form] = Form.useForm();
    const [importForm] = Form.useForm();

    useEffect(() => {
        fetchData();
    }, [queryParams]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const res = await hotWordApi.list(queryParams);
            setDataSource(res.list || []);
            setTotal(res.total || 0);
        } catch (error) {
            message.error(error.message);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = () => {
        setEditingItem(null);
        form.resetFields();
        setModalVisible(true);
    };

    const handleEdit = (record) => {
        setEditingItem(record);
        form.setFieldsValue({
            word: record.word,
            tags: record.tags || []
        });
        setModalVisible(true);
    };

    const handleDelete = (id) => {
        Modal.confirm({
            title: '确认删除',
            content: '删除后无法恢复，确定要删除吗？',
            onOk: async () => {
                try {
                    await hotWordApi.delete(id);
                    message.success('删除成功');
                    fetchData();
                } catch (error) {
                    message.error(error.message);
                }
            }
        });
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            if (editingItem) {
                await hotWordApi.update({ id: editingItem.id, ...values });
                message.success('更新成功');
            } else {
                await hotWordApi.add(values);
                message.success('新增成功');
            }
            setModalVisible(false);
            fetchData();
        } catch (error) {
            message.error(error.message);
        }
    };

    const handleImport = async () => {
        try {
            const values = await importForm.validateFields();
            const words = values.words.split('\n').filter(w => w.trim());
            await hotWordApi.import({ words });
            message.success('导入成功');
            setImportModalVisible(false);
            fetchData();
        } catch (error) {
            message.error(error.message);
        }
    };

    const columns = [
        {
            title: '热词',
            dataIndex: 'word',
            key: 'word'
        },
        {
            title: '标签',
            dataIndex: 'tags',
            key: 'tags',
            render: (tags) => (
                tags?.map((tag, index) => (
                    <Tag key={index} color="blue">{tag}</Tag>
                ))
            )
        },
        {
            title: '来源',
            dataIndex: 'sourceType',
            key: 'sourceType',
            render: (type) => type === 0 ? '手动' : '挖掘'
        },
        {
            title: '操作',
            key: 'action',
            render: (_, record) => (
                <Space>
                    <Button type="link" onClick={() => handleEdit(record)}>编辑</Button>
                    <Button type="link" danger onClick={() => handleDelete(record.id)}>删除</Button>
                </Space>
            )
        }
    ];

    return (
        <div className="page-container">
            <div className="page-header">
                <Space>
                    <Select
                        style={{ width: 120 }}
                        placeholder="来源筛选"
                        allowClear
                        value={queryParams.sourceType}
                        onChange={(value) => setQueryParams({ ...queryParams, sourceType: value, page: 1 })}
                    >
                        <Option value={0}>手动</Option>
                        <Option value={1}>挖掘</Option>
                    </Select>
                </Space>
                <Space>
                    <Button icon={<ImportOutlined />} onClick={() => setImportModalVisible(true)}>
                        手动导入
                    </Button>
                    <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd}>
                        新增热词
                    </Button>
                </Space>
            </div>

            <Table
                loading={loading}
                dataSource={dataSource}
                columns={columns}
                rowKey="id"
                pagination={{
                    current: queryParams.page,
                    pageSize: queryParams.size,
                    total: total,
                    onChange: (page, size) => setQueryParams({ ...queryParams, page, size })
                }}
            />

            {/* 新增/编辑弹窗 */}
            <Modal
                title={editingItem ? '编辑热词' : '新增热词'}
                visible={modalVisible}
                onOk={handleSubmit}
                onCancel={() => setModalVisible(false)}
            >
                <Form form={form} layout="vertical">
                    <Form.Item
                        name="word"
                        label="热词内容"
                        rules={[{ required: true, message: '请输入热词内容' }]}
                    >
                        <Input placeholder="请输入热词内容" />
                    </Form.Item>
                    <Form.Item name="tags" label="标签">
                        <Select mode="tags" placeholder="输入标签后回车" />
                    </Form.Item>
                </Form>
            </Modal>

            {/* 导入弹窗 */}
            <Modal
                title="批量导入"
                visible={importModalVisible}
                onOk={handleImport}
                onCancel={() => setImportModalVisible(false)}
            >
                <Form form={importForm} layout="vertical">
                    <Form.Item
                        name="words"
                        label="热词列表"
                        rules={[{ required: true, message: '请输入热词' }]}
                        extra="每行一个热词"
                    >
                        <Input.TextArea rows={10} placeholder="每行输入一个热词" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default HotWordManage;
```

### 4.2 数据中心页面

```jsx
// src/pages/DataCenter/index.jsx
import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Spin } from 'antd';
import { Pie, Line } from '@ant-design/charts';
import moment from 'moment';
import dataCenterApi from '../../api/dataCenter';

const { RangePicker } = DatePicker;

const DataCenter = () => {
    const [loading, setLoading] = useState(false);
    const [timeRange, setTimeRange] = useState('sevenDays');
    const [data, setData] = useState({
        overview: {},
        hotWordSourceDistribution: [],
        publishChannelDistribution: [],
        dailyTrend: { hotWord: [], expand: [], publish: [] }
    });

    useEffect(() => {
        fetchData();
    }, [timeRange]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const res = await dataCenterApi.getAll({ timeRange });
            setData(res);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    // 饼图配置
    const pieConfig = {
        appendPadding: 10,
        angleField: 'count',
        colorField: 'sourceName',
        radius: 0.8,
        label: {
            type: 'outer',
            content: '{name} {percentage}'
        }
    };

    // 折线图配置
    const lineConfig = (title) => ({
        title: { visible: true, text: title },
        padding: 'auto',
        forceFit: true,
        xField: 'date',
        yField: 'count',
        smooth: true
    });

    return (
        <Spin spinning={loading}>
            <div className="page-container">
                {/* 筛选 */}
                <div className="page-header">
                    <Select
                        style={{ width: 150 }}
                        value={timeRange}
                        onChange={setTimeRange}
                    >
                        <Select.Option value="today">今天</Select.Option>
                        <Select.Option value="sevenDays">近7天</Select.Option>
                        <Select.Option value="thirtyDays">近30天</Select.Option>
                        <Select.Option value="custom">自定义</Select.Option>
                    </Select>
                </div>

                {/* 统计卡片 */}
                <Row gutter={16}>
                    <Col span={6}>
                        <Card>
                            <Statistic title="热词数量" value={data.overview.hotWordCount} />
                            <div style={{ color: '#999', fontSize: 12, marginTop: 8 }}>
                                今日新增: {data.overview.hotWordTodayNew}
                            </div>
                        </Card>
                    </Col>
                    <Col span={6}>
                        <Card>
                            <Statistic title="扩词总数" value={data.overview.expandCount} />
                            <div style={{ color: '#999', fontSize: 12, marginTop: 8 }}>
                                今日扩词: {data.overview.expandTodayNew}
                            </div>
                        </Card>
                    </Col>
                    <Col span={6}>
                        <Card>
                            <Statistic title="发布文章数" value={data.overview.publishCount} />
                            <div style={{ color: '#999', fontSize: 12, marginTop: 8 }}>
                                本月新增: {data.overview.publishMonthNew}
                            </div>
                        </Card>
                    </Col>
                    <Col span={6}>
                        <Card>
                            <Statistic title="活跃渠道" value={data.overview.activeChannelCount} />
                            <div style={{ color: '#999', fontSize: 12, marginTop: 8 }}>
                                {data.overview.activeChannelChange}
                            </div>
                        </Card>
                    </Col>
                </Row>

                {/* 分布图表 */}
                <Row gutter={16} style={{ marginTop: 16 }}>
                    <Col span={12}>
                        <Card title="热词来源分布">
                            <Pie
                                data={data.hotWordSourceDistribution}
                                {...pieConfig}
                                colorField="sourceName"
                            />
                        </Card>
                    </Col>
                    <Col span={12}>
                        <Card title="发布渠道分布">
                            <Pie
                                data={data.publishChannelDistribution}
                                {...pieConfig}
                                colorField="channelName"
                            />
                        </Card>
                    </Col>
                </Row>

                {/* 趋势图表 */}
                <Row gutter={16} style={{ marginTop: 16 }}>
                    <Col span={8}>
                        <Card title="热词趋势">
                            <Line data={data.dailyTrend.hotWord} {...lineConfig('热词数量')} />
                        </Card>
                    </Col>
                    <Col span={8}>
                        <Card title="扩词趋势">
                            <Line data={data.dailyTrend.expand} {...lineConfig('扩词数量')} />
                        </Card>
                    </Col>
                    <Col span={8}>
                        <Card title="发布趋势">
                            <Line data={data.dailyTrend.publish} {...lineConfig('发布数量')} />
                        </Card>
                    </Col>
                </Row>
            </div>
        </Spin>
    );
};

export default DataCenter;
```

---

## 五、路由配置

```jsx
// src/App.jsx
import React from 'react';
import { BrowserRouter as Router, Route, Switch, Redirect } from 'react-router-dom';
import Layout from './components/Layout';
import HotWord from './pages/HotWord';
import Content from './pages/Content';
import GeoMonitor from './pages/GeoMonitor';
import DataCenter from './pages/DataCenter';
import Publish from './pages/Publish';
import './index.less';

const App = () => {
    return (
        <Router>
            <Layout>
                <Switch>
                    <Route path="/hotWord" component={HotWord} />
                    <Route path="/content" component={Content} />
                    <Route path="/geoMonitor" component={GeoMonitor} />
                    <Route path="/dataCenter" component={DataCenter} />
                    <Route path="/publish" component={Publish} />
                    <Redirect from="/" to="/dataCenter" exact />
                </Switch>
            </Layout>
        </Router>
    );
};

export default App;
```

---

## 六、样式规范

```less
// src/index.less
@import '~antd/dist/antd.less';

// 主题变量
@primary-color: #4f46e5;

// 全局样式
body {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial;
    background-color: #f0f2f5;
}

// 页面容器
.page-container {
    padding: 24px;
    background-color: #fff;
    min-height: calc(100vh - 64px);
}

// 页面头部
.page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
}

// 卡片统一样式
.ant-card {
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
```

---

## 七、环境配置

### package.json

```json
{
    "name": "q-geo-web",
    "version": "1.0.0",
    "scripts": {
        "start": "react-app-rewired start",
        "build": "react-app-rewired build",
        "test": "react-app-rewired test"
    },
    "dependencies": {
        "react": "^16.14.0",
        "react-dom": "^16.14.0",
        "react-router-dom": "^5.2.0",
        "antd": "^4.18.0",
        "axios": "^0.21.4",
        "moment": "^2.29.1",
        "@ant-design/icons": "^4.7.0",
        "@ant-design/charts": "^1.2.0"
    },
    "devDependencies": {
        "react-app-rewired": "^2.1.8",
        "customize-cra": "^1.0.0",
        "less": "^4.1.0",
        "less-loader": "^7.3.0"
    },
    "browserslist": {
        "production": [
            ">0.2%",
            "not dead",
            "not op_mini all"
        ],
        "development": [
            "last 1 chrome version",
            "last 1 firefox version",
            "last 1 safari version"
        ]
    }
}
```

### config-overrides.js (支持 Less)

```javascript
const { override, addLessLoader } = require('customize-cra');

module.exports = override(
    addLessLoader({
        lessOptions: {
            javascriptEnabled: true,
            modifyVars: {
                '@primary-color': '#4f46e5'
            }
        }
    })
);
```

---

## 八、接口对接清单

| 模块 | 接口 | 方法 | 说明 |
|------|------|------|------|
| **热词中心** | `/api/hotWord/list` | GET | 热词列表 |
| | `/api/hotWord/add` | POST | 新增热词 |
| | `/api/hotWord/import` | POST | 批量导入 |
| | `/api/hotWord/update` | POST | 更新热词 |
| | `/api/hotWord/delete` | POST | 删除热词 |
| | `/api/hotWordTask/list` | GET | 任务列表 |
| | `/api/hotWordTask/add` | POST | 新建任务 |
| | `/api/hotWordTask/cancel` | POST | 取消任务 |
| | `/api/hotWordTask/retry` | POST | 重试任务 |
| **内容中心** | `/api/content/list` | GET | 内容列表 |
| | `/api/content/add` | POST | 新增内容 |
| | `/api/content/update` | POST | 更新内容 |
| | `/api/content/delete` | POST | 删除内容 |
| | `/api/contentTask/list` | GET | 任务列表 |
| | `/api/contentTask/add` | POST | 新建任务 |
| **GEO分析** | `/api/geoMonitor/list` | GET | 分析列表 |
| **数据中心** | `/api/dataCenter/all` | GET | 全部数据 |
| **发布中心** | `/api/publishChannel/list` | GET | 渠道列表 |
| | `/api/publishChannel/add` | POST | 新增渠道 |
| | `/api/publishChannel/update` | POST | 更新渠道 |
| | `/api/publishChannel/delete` | POST | 删除渠道 |
| | `/api/publishTask/list` | GET | 发布任务列表 |
| | `/api/publishTask/add` | POST | 新建发布任务 |
