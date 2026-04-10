# GEO 分析模块

## 业务入口

- **Controller**: `GeoMonitorController`, `GeoProviderController`
- **前端页面**: `pages/geo/`
- **Service**: `GeoMonitorService`

## API 清单

### GEO 监控

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/geoMonitor/list` | GET | 监控数据列表 |

### GEO Provider

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/geoProvider/list` | GET | Provider 列表 |

## Mapper

- `GeoMonitorDataMapper` - 监控数据
- `GeoProviderMapper` - Provider 数据

## 前端组件

| 组件 | 用途 |
|------|------|
| `MonitorView.jsx` | 监控视图页面 |
