# Noah Deploy API Contract

This skill targets the Noah beta deployment endpoint:

- `POST http://noah3.corp.qunar.com/api/v1/deploy/deploy-app`
- `GET  http://cmapi.corp.qunar.com/api/portal/task/exec/<taskId>`

Request body:

```json
{
  "appCode": "cm_moss",
  "envCode": "noah-n3",
  "userId": "someuser",
  "branch": "feature/my-branch"
}
```

Expected response shape:

```json
{
  "status": 0,
  "msg": "success",
  "data": "..."
}
```

Observed special case:

- `status = 1201` together with a message or `data` mentioning `正在发布中`
  means there is already an ongoing deployment
- the `data` field may contain a task URL such as
  `http://portal.corp.qunar.com/servicePortal/apptask/console.html?id=12792848`

The runtime should preserve the raw JSON response and extract task metadata when
available.

Observed task status response shape:

```json
{
  "status": 0,
  "message": "success",
  "data": {
    "status": 0,
    "start_time": "2026-03-16 18:01:03",
    "end_time": "2026-03-16 18:05:21",
    "tasks": [
      {
        "app_code": "f_inter_autotest_dispatch",
        "input_revision": "bff2e7d41",
        "output_revision": "bff2e7d41",
        "env_list": [
          {
            "env_id": "noahauto-2",
            "env_profile": "betanoah",
            "deployed_hosts": [
              "l-noah6jbkdtwat1.auto.beta.cn0.qunar.com"
            ]
          }
        ]
      }
    ]
  }
}
```

Observed task status values:

- `-1`: 未完成
- `0`: 成功
- `1`: 终止
- `2`: 失败
