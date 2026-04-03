---
name: noah_deploy_auto_dev
description: 'Resolve deployment parameters from the current repository or explicit input, trigger Noah beta deployment, and query deployment task status without depending on the legacy noah_deploy skill.'
---

# Noah Deploy Auto Dev

Use this skill when the agent needs a real Noah beta deployment during an
iterative development loop, or when it needs to confirm the status of an
existing Noah deployment task.

This skill is independent from the legacy `noah_deploy` skill. It does not
import, call, or depend on any files under `tcdev/noah_deploy`.

## Resource Resolution

Resolve `<skill_root>` as the directory containing this `SKILL.md`.

- Script path: `<skill_root>/scripts/noah_deploy_auto_dev.py`
- API notes: `<skill_root>/references/api-contract.md`
- Do not hardcode agent-specific directories such as `~/.codex` or `~/.claude`.

## Runtime Prerequisites

- `python3`
- corp network access to Noah
- a repository whose current or provided project directory contains the intended
  deployment config, or explicit `appCode` and `envCode`

No extra Python packages are required. The bundled script uses only the Python
standard library.

## Hard Rules

- This skill is for Noah beta deployment.
- When multiple config candidates exist and the intended target cannot be
  inferred safely, stop and ask the user to choose.
- Do not fabricate a mock deployment result.
- Do not assume fixed project paths, branch names, appCode values, or envCode
  values.

## Workflow

1. Resolve deployment parameters.

- Auto-detect `branch` from the current git repository unless the user provided
  one.
- Auto-detect `userId` from git config or the local username unless the user
  provided one.
- Auto-detect `appCode` and `envCode` by scanning `src/main/resources*` for
  `qunar-app.properties` and `qunar-env.properties`.
- Use `--project-dir <path>` when the current working directory is not the
  intended repository root.

2. Review ambiguity before deploying.

- Use `resolve` first when the target is not fully clear.
- If there are multiple matching resource folders, stop and ask the user to
  confirm the intended one instead of guessing.

3. Trigger deployment.

- Use `deploy` after `branch`, `appCode`, `envCode`, and `userId` are all known.
- The script calls the Noah deploy API directly and returns JSON.

4. Query deployment task status.

- Use `status` when a deploy task ID or task URL is already known.
- Default mode performs a single query against the Noah portal status API.
- Add `--wait` to poll until the task reaches a terminal status.

## Commands

Resolve deployment parameters from the current repository:

```bash
python3 <skill_root>/scripts/noah_deploy_auto_dev.py \
  resolve \
  --pretty
```

Resolve deployment parameters for another project:

```bash
python3 <skill_root>/scripts/noah_deploy_auto_dev.py \
  resolve \
  --project-dir /path/to/repo \
  --pretty
```

Deploy using auto-detected branch and config:

```bash
python3 <skill_root>/scripts/noah_deploy_auto_dev.py \
  deploy \
  --project-dir /path/to/repo \
  --pretty
```

Deploy with explicit parameters:

```bash
python3 <skill_root>/scripts/noah_deploy_auto_dev.py \
  deploy \
  --branch feature/my-branch \
  --app-code cm_moss \
  --env-code noah-n3 \
  --user-id someuser \
  --pretty
```

Query one deployment task by task ID:

```bash
python3 <skill_root>/scripts/noah_deploy_auto_dev.py \
  status \
  --task-id 13607849 \
  --pretty
```

Query one deployment task by task URL and wait until completion:

```bash
python3 <skill_root>/scripts/noah_deploy_auto_dev.py \
  status \
  --task-url 'http://portal.corp.qunar.com/servicePortal/apptask/console.html?id=13607849' \
  --wait \
  --max-attempts 40 \
  --poll-interval 15 \
  --pretty
```

## Output

`resolve`, `deploy`, and `status` all print JSON.

- `resolve` returns detected git info, config candidates, and the selected
  deployment target when unambiguous
- `deploy` returns the resolved target plus the Noah API response
- `status` returns the queried task state, terminal status summary, and
  extracted deployment metadata when present

When Noah reports that another deployment is already running, the result keeps
that information in the JSON output.

When the deploy API response contains a task URL, `deploy` also extracts
`deployment_task.task_id` and `deployment_task.task_url` for follow-up status
queries.

## Resources

- Script: [scripts/noah_deploy_auto_dev.py](./scripts/noah_deploy_auto_dev.py)
- API notes: [references/api-contract.md](./references/api-contract.md)
