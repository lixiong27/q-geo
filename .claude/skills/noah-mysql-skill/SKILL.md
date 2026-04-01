---
name: noah-mysql-skill
description: 'Resolve Noah beta MySQL credentials from `noah3.corp.qunar.com/replacer/variables` using `envCode` and `appCode`, or auto-detect them from the current project `src/main/resources*` config, then inspect connectivity or execute SQL. Use this skill for requests like "查一下 noah 环境 MySQL", "根据 envCode/appCode 连 MySQL", "在 noah 环境执行 SQL / 建表 / 查表"; refuse non-beta targets and require explicit write intent for non-read-only SQL.'
---

# Noah MySQL Skill

## Overview

Use this skill when the user wants to connect to a Noah environment MySQL instance by
first resolving credentials from:

`GET http://noah3.corp.qunar.com/replacer/variables?envCode=<envCode>&appCode=<appCode>`

This skill is for remote operational database work, not repository-local config edits.

## Resource Resolution

Resolve `<skill_root>` as the directory containing this `SKILL.md`.

- Script path: `<skill_root>/scripts/noah_mysql.py`
- API notes: `<skill_root>/references/api-contract.md`
- Do not hardcode agent-specific directories such as `~/.codex` or `~/.claude`.

## Runtime Prerequisites

- `python3`
- `mysql` CLI in `PATH`
- Corp network access to `noah3.corp.qunar.com` and the resolved MySQL host
- No extra Python packages are required; the bundled script uses only the standard library

## Hard Guardrails

- Refuse any target whose returned `qconfigProfile` is not beta-prefixed, such as `betanoah`.
- If the resolved payload contains multiple `.jdbc.*` groups and the user did not specify which one to use, stop and ask for the DB prefix.
- Never print the raw password in normal output.
- Treat non-read-only SQL as a write operation. Only run it when the user clearly asked for the change, and pass `--allow-write`.

## Workflow

1. Resolve env variables.

- Use `resolve` first when `envCode`, `appCode`, or the DB prefix is not fully clear.
- If `envCode` / `appCode` are omitted, the script auto-detects them from the current project by scanning `src/main/resources*` for `qunar-app.properties` and `qunar-env.properties`.
- Use `--project-dir <path>` when the current working directory is not the intended project root.
- If multiple source-side configurations are found, stop and ask the user to confirm instead of guessing.
- The script extracts JDBC groups from `data.properties`, such as `newdb_pxc57.jdbc.host`.

2. Verify connectivity before changing data.

- Use `ping` to perform both TCP reachability and a real `SELECT 1`.

3. Execute SQL.

- Use `exec --sql ...` for short statements.
- Use `exec --sql-file ...` for longer SQL.
- Add `--allow-write` for `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `DROP`, and similar statements.

## Commands

Resolve the available JDBC groups:

```bash
python3 <skill_root>/scripts/noah_mysql.py \
  resolve \
  --env-code qnova \
  --app-code cm_qnova
```

Resolve using the current project's `qunar-*.properties`:

```bash
python3 <skill_root>/scripts/noah_mysql.py \
  resolve
```

Test connectivity for a specific JDBC group:

```bash
python3 <skill_root>/scripts/noah_mysql.py \
  ping \
  --env-code qnova \
  --app-code cm_qnova \
  --db-prefix newdb_pxc57
```

Run a read-only query:

```bash
python3 <skill_root>/scripts/noah_mysql.py \
  exec \
  --env-code qnova \
  --app-code cm_qnova \
  --db-prefix newdb_pxc57 \
  --sql "SHOW TABLES;"
```

Run a write statement:

```bash
python3 <skill_root>/scripts/noah_mysql.py \
  exec \
  --env-code qnova \
  --app-code cm_qnova \
  --db-prefix newdb_pxc57 \
  --allow-write \
  --sql "CREATE TABLE IF NOT EXISTS test (id BIGINT PRIMARY KEY);"
```

Run a SQL file:

```bash
python3 <skill_root>/scripts/noah_mysql.py \
  exec \
  --env-code qnova \
  --app-code cm_qnova \
  --db-prefix newdb_pxc57 \
  --allow-write \
  --sql-file /tmp/change.sql
```

## Resources

- Script: [scripts/noah_mysql.py](./scripts/noah_mysql.py)
- API notes: [references/api-contract.md](./references/api-contract.md)
