# 进度追踪

## 需求概述

**需求名称**：发布模块改造 - 参照内容模块实现执行器模式与热配置
**创建日期**：2026-04-09
**负责人**：Claude AI

## 当前阶段

**阶段**：阶段6 - 前端适配（已完成）

## 任务清单

### 阶段1：QConfig 配置
- [x] 创建 publish_channel_config.json 配置文件
- [x] 创建 PublishChannelConfig 实体类
- [x] 创建 PublishQConfig 配置服务类

### 阶段2：实体与 Mapper 改造
- [x] PublishTask 实体新增 downstreamTaskId 字段
- [x] PublishTask 实体新增 channelCode 字段
- [x] PublishTask 实体新增 publishMethod 字段
- [x] PublishTaskMapper 新增 selectByDownstreamTaskId 方法
- [x] PublishTaskMapper 新增 updateDownstreamTaskId 方法
- [x] PublishTaskMapper.xml 新增对应 SQL

### 阶段3：执行器架构
- [x] 创建 PublishTaskExecutor 抽象执行器
- [x] 创建 PublishTaskExecutorFactory 执行器工厂
- [x] 创建 LlmExecutor 执行器
- [x] 创建 ClawExecutor 执行器

### 阶段4：服务层改造
- [x] PublishTaskService 引入执行器工厂
- [x] PublishTaskService 新增 handleCallback 回调处理方法
- [x] PublishChannelService 改为从热配置读取渠道信息

### 阶段5：Controller 改造
- [x] PublishTaskController 新增 callback 回调接口
- [x] PublishTaskController 改用 channelCode 参数
- [x] PublishChannelController 改为从热配置读取
- [x] PublishChannelController 新增 config 接口

### 阶段6：前端适配
- [x] ChannelManage 页面适配热配置（只读展示）
- [x] PublishManage 页面适配执行器模式
- [x] 新增发布渠道 API 适配（channelCode）
- [x] PublishChannel 实体新增 publishMethod/timeout/maxRetries 字段
- [x] PublishQConfig 返回完整配置信息

## 进度记录

| 日期 | 内容 | 状态 |
|------|------|------|
| 2026-04-09 | 需求分析，创建设计文档和 QConfig 配置示例 | 已完成 |
| 2026-04-09 | 完成阶段1-5后端代码改造 | 已完成 |
| 2026-04-09 | 完成阶段6前端适配 | 已完成 |
| 2026-04-09 | 完成 fastjson 替换为 Jackson | 已完成 |

## 下一步行动

1. 数据库迁移：添加 publish_task 表的 channel_code 和 publish_method 字段
2. 测试：验证执行器模式和回调机制

## 额外优化

- [x] 所有 fastjson 替换为 Jackson (使用 JsonUtils 工具类)

## 风险与问题

| 风险/问题 | 影响 | 解决方案 | 状态 |
|-----------|------|----------|------|
| 现有 DB 渠道数据需迁移 | 中 | 提供迁移脚本，将 DB 数据转为 QConfig 格式 | 待处理 |
| 前端渠道 ID 依赖 | 低 | 前端改用 channelCode 替代 channelId | 已解决 |
| publish_task 表结构变更 | 中 | 需添加 channel_code 和 publish_method 字段 | 待处理 |
