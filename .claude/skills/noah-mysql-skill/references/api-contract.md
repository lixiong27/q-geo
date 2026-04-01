# Noah Replacer Variables API Contract

This skill resolves MySQL connection parameters from the Noah replacer variables API:

- `GET http://noah3.corp.qunar.com/replacer/variables?envCode={envCode}&appCode={appCode}`

## Expected response shape

The response is JSON with:

```json
{
  "status": 0,
  "msg": "success",
  "data": {
    "envId": 492098,
    "envCode": "qnova",
    "appCode": "cm_qnova",
    "qconfigProfile": "betanoah",
    "properties": {
      "newdb_pxc57.jdbc.host": "10.90.161.118",
      "newdb_pxc57.jdbc.port": "3465",
      "newdb_pxc57.jdbc.dbname": "newdb_pxc57",
      "newdb_pxc57.jdbc.username": "u492098",
      "newdb_pxc57.jdbc.password": "******"
    }
  }
}
```

## Resolution rules

- Group JDBC properties by the prefix before `.jdbc.`
  - Example: `newdb_pxc57.jdbc.host` belongs to DB prefix `newdb_pxc57`
- A usable MySQL config requires:
  - `host`
  - `port`
  - `dbname`
  - `username`
  - `password`
- Optional fields such as `namespace`, `ServerName`, and `IP` may be shown for context but are not required for connection.

## Safety rules

- Only allow returned payloads whose `qconfigProfile` starts with `beta`.
- If multiple JDBC groups are present, require an explicit DB prefix selection.
- Use the resolved password only in process environment, not as a shell-visible CLI argument.
