#!/usr/bin/env python3
"""Resolve deployment parameters, trigger Noah beta deployment, and query task status."""

from __future__ import annotations

import argparse
import getpass
import json
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


DEFAULT_DEPLOY_URL = "http://noah3.corp.qunar.com/api/v1/deploy/deploy-app"
DEFAULT_PORTAL_API_URL = "http://cmapi.corp.qunar.com"
DEFAULT_MAX_POLL_ATTEMPTS = 60
DEFAULT_POLL_INTERVAL = 30
STATUS_UNFINISHED = -1
STATUS_SUCCESS = 0
STATUS_TERMINATED = 1
STATUS_FAILED = 2
STATUS_NAMES = {
    STATUS_UNFINISHED: "未完成",
    STATUS_SUCCESS: "成功",
    STATUS_TERMINATED: "终止",
    STATUS_FAILED: "失败",
}


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve deployment parameters, trigger Noah beta deployment, and query task status."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    resolve_parser = subparsers.add_parser("resolve", help="Resolve deploy parameters")
    add_common_args(resolve_parser)
    resolve_parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON")

    deploy_parser = subparsers.add_parser("deploy", help="Trigger deployment")
    add_common_args(deploy_parser)
    deploy_parser.add_argument(
        "--deploy-url",
        default=DEFAULT_DEPLOY_URL,
        help="Override the Noah deploy endpoint",
    )
    deploy_parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON")

    status_parser = subparsers.add_parser("status", help="Query deployment task status")
    status_parser.add_argument("--task-id", help="Deployment task ID")
    status_parser.add_argument("--task-url", help="Portal task URL that contains the task ID")
    status_parser.add_argument(
        "--portal-api-url",
        default=DEFAULT_PORTAL_API_URL,
        help="Override the Noah portal status API base URL",
    )
    status_parser.add_argument(
        "--wait",
        action="store_true",
        help="Poll until the task reaches a terminal status",
    )
    status_parser.add_argument(
        "--max-attempts",
        type=int,
        default=DEFAULT_MAX_POLL_ATTEMPTS,
        help="Maximum polling attempts when --wait is set",
    )
    status_parser.add_argument(
        "--poll-interval",
        type=int,
        default=DEFAULT_POLL_INTERVAL,
        help="Polling interval in seconds when --wait is set",
    )
    status_parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON")

    return parser.parse_args(list(argv))


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--project-dir", help="Project directory used for detection")
    parser.add_argument("--branch", help="Git branch to deploy")
    parser.add_argument("--app-code", help="Explicit appCode")
    parser.add_argument("--env-code", help="Explicit envCode")
    parser.add_argument("--user-id", help="Explicit userId")


def find_project_root(project_dir: Optional[str]) -> Path:
    base = Path(project_dir).expanduser().resolve() if project_dir else Path.cwd().resolve()

    current = base
    while True:
        if (current / ".git").exists():
            return current
        if current.parent == current:
            return base
        current = current.parent


def run_git(project_root: Path, args: Sequence[str]) -> Optional[str]:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=str(project_root),
            capture_output=True,
            text=True,
            check=True,
        )
    except Exception:
        return None

    value = result.stdout.strip()
    return value or None


def current_branch(project_root: Path) -> Optional[str]:
    return run_git(project_root, ["rev-parse", "--abbrev-ref", "HEAD"])


def git_user(project_root: Path) -> Optional[str]:
    user = run_git(project_root, ["config", "user.name"])
    if user:
        return user

    try:
        return getpass.getuser()
    except Exception:
        return None


def parse_properties_file(path: Path) -> Dict[str, str]:
    props: Dict[str, str] = {}
    if not path.exists():
        return props

    with path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            props[key.strip()] = value.strip()
    return props


def discover_resource_configs(project_root: Path) -> List[Dict[str, Optional[str]]]:
    configs: List[Dict[str, Optional[str]]] = []

    for resource_dir in sorted(project_root.rglob("src/main/resources*")):
        if not resource_dir.is_dir():
            continue

        app_props = resource_dir / "qunar-app.properties"
        env_props = resource_dir / "qunar-env.properties"
        if not app_props.exists() and not env_props.exists():
            continue

        app_code = parse_properties_file(app_props).get("name") if app_props.exists() else None
        env_data = parse_properties_file(env_props) if env_props.exists() else {}
        env_code = env_data.get("envCode") or env_data.get("name")

        try:
            relative = resource_dir.relative_to(project_root)
            source_path = str(relative)
        except ValueError:
            source_path = str(resource_dir)

        configs.append(
            {
                "source_path": source_path,
                "resources_folder": resource_dir.name,
                "appCode": app_code,
                "envCode": env_code,
            }
        )

    return configs


def resolve_target(
    project_root: Path,
    branch: Optional[str],
    app_code: Optional[str],
    env_code: Optional[str],
    user_id: Optional[str],
) -> Dict[str, object]:
    branch_value = branch or current_branch(project_root)
    user_value = user_id or git_user(project_root)
    candidates = discover_resource_configs(project_root)

    filtered = filter_candidates(candidates, app_code, env_code)
    selected, resolution_error = select_candidate(filtered, app_code, env_code)

    resolved = {
        "project_root": str(project_root),
        "branch": branch_value,
        "userId": user_value,
        "requested": {
            "appCode": app_code,
            "envCode": env_code,
        },
        "candidates": filtered,
        "selected_config": selected,
    }

    if branch_value is None:
        return error_result(
            "missing_branch",
            "Could not determine the git branch for deployment.",
            resolved,
        )

    if user_value is None:
        return error_result(
            "missing_user",
            "Could not determine the userId for deployment.",
            resolved,
        )

    if resolution_error is not None:
        return error_result(resolution_error[0], resolution_error[1], resolved)

    return {
        "success": True,
        **resolved,
    }


def filter_candidates(
    candidates: Sequence[Dict[str, Optional[str]]],
    app_code: Optional[str],
    env_code: Optional[str],
) -> List[Dict[str, Optional[str]]]:
    if not app_code and not env_code:
        return list(candidates)

    filtered: List[Dict[str, Optional[str]]] = []
    for candidate in candidates:
        if app_code and candidate.get("appCode") != app_code:
            continue
        if env_code and candidate.get("envCode") != env_code:
            continue
        filtered.append(candidate)
    return filtered


def select_candidate(
    candidates: Sequence[Dict[str, Optional[str]]],
    explicit_app_code: Optional[str],
    explicit_env_code: Optional[str],
) -> Tuple[Optional[Dict[str, Optional[str]]], Optional[Tuple[str, str]]]:
    if explicit_app_code and explicit_env_code:
        return (
            {
                "source_path": "explicit",
                "resources_folder": None,
                "appCode": explicit_app_code,
                "envCode": explicit_env_code,
            },
            None,
        )

    complete = [
        candidate
        for candidate in candidates
        if candidate.get("appCode") and candidate.get("envCode")
    ]

    if len(complete) == 1:
        selected = dict(complete[0])
        if explicit_app_code:
            selected["appCode"] = explicit_app_code
        if explicit_env_code:
            selected["envCode"] = explicit_env_code
        return selected, None

    if len(complete) > 1:
        return None, (
            "multiple_matching_configs",
            "Multiple deployment config candidates were found. User confirmation is required.",
        )

    if explicit_app_code or explicit_env_code:
        return None, (
            "missing_matching_config",
            "The explicit appCode/envCode could not be resolved to one complete deployment target.",
        )

    if not candidates:
        return None, (
            "missing_config",
            "Could not find any deployment config under src/main/resources* and no explicit appCode/envCode was provided.",
        )

    return None, (
        "incomplete_config",
        "Found deployment-related resources, but appCode/envCode is incomplete. User confirmation is required.",
    )


def error_result(code: str, message: str, payload: Dict[str, object]) -> Dict[str, object]:
    return {
        "success": False,
        "error": code,
        "message": message,
        "need_user_confirmation": code in {
            "multiple_matching_configs",
            "missing_matching_config",
            "incomplete_config",
        },
        **payload,
    }


def trigger_deploy(
    deploy_url: str,
    branch: str,
    app_code: str,
    env_code: str,
    user_id: str,
) -> Dict[str, object]:
    payload = {
        "appCode": app_code,
        "envCode": env_code,
        "userId": user_id,
        "branch": branch,
    }
    body = json.dumps(payload).encode("utf-8")
    request = Request(
        deploy_url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urlopen(request, timeout=30) as response:
            raw = response.read().decode("utf-8", errors="replace")
            parsed = parse_json_or_raw(raw)
            result = {
                "success": 200 <= response.status < 300,
                "status_code": response.status,
                "headers": dict(response.headers),
                "response": parsed,
                "payload": payload,
                "url": deploy_url,
            }
            maybe_attach_deploy_metadata(result, parsed)
            return result
    except HTTPError as error:
        raw = error.read().decode("utf-8", errors="replace")
        parsed = parse_json_or_raw(raw)
        result = {
            "success": False,
            "status_code": error.code,
            "headers": dict(error.headers),
            "response": parsed,
            "payload": payload,
            "url": deploy_url,
            "error": str(error),
        }
        maybe_attach_deploy_metadata(result, parsed)
        return result
    except URLError as error:
        return {
            "success": False,
            "status_code": None,
            "headers": {},
            "response": None,
            "payload": payload,
            "url": deploy_url,
            "error": str(error),
        }


def parse_json_or_raw(raw: str) -> object:
    try:
        return json.loads(raw)
    except Exception:
        return {"raw": raw}


def extract_task_metadata(source: object) -> Dict[str, Optional[str]]:
    task_url = None
    task_id = None

    candidates = build_task_metadata_candidates(source)
    for candidate in candidates:
        if task_url is None:
            url_match = re.search(r"http://[^\s\"']*servicePortal/apptask/console\.html\?id=(\d+)", candidate)
            if url_match:
                task_id = url_match.group(1)
                task_url = url_match.group(0)
        if task_id is None:
            id_match = re.search(r"(?:[?&]id=|task[_\s-]*id[=: ]+)(\d+)", candidate, flags=re.IGNORECASE)
            if id_match:
                task_id = id_match.group(1)

    if task_id and task_url is None:
        task_url = f"http://portal.corp.qunar.com/servicePortal/apptask/console.html?id={task_id}"

    return {
        "task_id": task_id,
        "task_url": task_url,
    }


def build_task_metadata_candidates(source: object) -> List[str]:
    candidates: List[str] = []
    if source is None:
        return candidates
    if isinstance(source, str):
        return [source]
    if isinstance(source, dict):
        for key in ("data", "msg", "message"):
            value = source.get(key)
            if value is not None:
                candidates.extend(build_task_metadata_candidates(value))
        try:
            candidates.append(json.dumps(source, ensure_ascii=False))
        except Exception:
            candidates.append(str(source))
        return candidates
    if isinstance(source, (list, tuple, set)):
        for item in source:
            candidates.extend(build_task_metadata_candidates(item))
        return candidates
    return [str(source)]


def maybe_attach_deploy_metadata(result: Dict[str, object], parsed: object) -> None:
    task_metadata = extract_task_metadata(parsed)
    if task_metadata["task_id"] or task_metadata["task_url"]:
        result["deployment_task"] = task_metadata

    if not isinstance(parsed, dict):
        return

    status = parsed.get("status")
    message = str(parsed.get("msg", ""))
    data = str(parsed.get("data", ""))
    if status != 1201 or "正在发布中" not in (message + data):
        return

    result["ongoing_deployment"] = True
    result["ongoing_deployment_info"] = {
        **task_metadata,
        "message": message,
        "data": parsed.get("data"),
    }


def http_get(url: str, timeout: int = 30) -> Dict[str, object]:
    request = Request(url, method="GET")
    try:
        with urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8", errors="replace")
            return {
                "success": 200 <= response.status < 300,
                "status_code": response.status,
                "headers": dict(response.headers),
                "response": parse_json_or_raw(raw),
                "url": url,
            }
    except HTTPError as error:
        raw = error.read().decode("utf-8", errors="replace")
        return {
            "success": False,
            "status_code": error.code,
            "headers": dict(error.headers),
            "response": parse_json_or_raw(raw),
            "url": url,
            "error": str(error),
        }
    except URLError as error:
        return {
            "success": False,
            "status_code": None,
            "headers": {},
            "response": None,
            "url": url,
            "error": str(error),
        }


def resolve_task_id(task_id: Optional[str], task_url: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
    if task_id:
        normalized = str(task_id).strip()
        return (normalized or None, None) if normalized else (None, "task-id is empty")

    if not task_url:
        return None, "Either --task-id or --task-url is required"

    metadata = extract_task_metadata(task_url)
    if metadata["task_id"]:
        return metadata["task_id"], None
    return None, "Could not extract task ID from task URL"


def extract_deployment_info(task_data: Dict[str, object]) -> Dict[str, object]:
    tasks = task_data.get("tasks")
    if not isinstance(tasks, list) or not tasks:
        return {
            "success": False,
            "error": "No tasks found in response",
        }

    task = tasks[0] if isinstance(tasks[0], dict) else {}
    env_list = task.get("env_list")
    env = env_list[0] if isinstance(env_list, list) and env_list and isinstance(env_list[0], dict) else {}

    deployed_hosts = normalize_string_list(env.get("deployed_hosts"))
    ready_hosts = normalize_string_list(env.get("has_deployed_hosts"))
    in_process_hosts = normalize_string_list(env.get("in_process_hosts"))
    failed_hosts = normalize_string_list(env.get("deployed_failed_hosts"))
    hosts = deployed_hosts or ready_hosts or in_process_hosts or failed_hosts

    return {
        "success": True,
        "appCode": task.get("app_code"),
        "envId": env.get("env_id"),
        "envProfile": env.get("env_profile"),
        "host": hosts[0] if hosts else None,
        "hosts": hosts,
        "deployed_hosts": deployed_hosts,
        "has_deployed_hosts": ready_hosts,
        "in_process_hosts": in_process_hosts,
        "deployed_failed_hosts": failed_hosts,
        "start_time": task_data.get("start_time"),
        "end_time": task_data.get("end_time"),
        "input_revision": task.get("input_revision"),
        "output_revision": task.get("output_revision"),
        "input_tag": task.get("input_tag"),
        "output_tag": task.get("output_tag"),
    }


def normalize_string_list(value: object) -> List[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if item is not None]


def query_task_status(task_id: str, portal_api_url: str = DEFAULT_PORTAL_API_URL) -> Dict[str, object]:
    base_url = portal_api_url.rstrip("/")
    url = f"{base_url}/api/portal/task/exec/{task_id}"
    query = http_get(url, timeout=30)
    if not query.get("success"):
        return {
            "success": False,
            "error": "query_failed",
            "message": query.get("error", f"HTTP {query.get('status_code')}"),
            "task_id": task_id,
            "query": query,
        }

    response = query.get("response")
    if not isinstance(response, dict):
        return {
            "success": False,
            "error": "unexpected_response",
            "message": "Status API returned a non-JSON or unexpected payload.",
            "task_id": task_id,
            "query": query,
        }

    api_status = response.get("status")
    if api_status != 0:
        return {
            "success": False,
            "error": "api_status",
            "message": str(response.get("message", "API returned non-zero status")),
            "task_id": task_id,
            "query": query,
        }

    task_data = response.get("data")
    if not isinstance(task_data, dict):
        return {
            "success": False,
            "error": "missing_task_data",
            "message": "Status API response did not include task data.",
            "task_id": task_id,
            "query": query,
        }

    task_status = task_data.get("status")
    finished = task_status != STATUS_UNFINISHED
    deployment_info = extract_deployment_info(task_data)
    result: Dict[str, object] = {
        "success": True,
        "task_id": task_id,
        "query": query,
        "task": {
            "status": task_status,
            "status_name": STATUS_NAMES.get(task_status, f"未知({task_status})"),
            "finished": finished,
            "deployment_success": task_status == STATUS_SUCCESS,
            "start_time": task_data.get("start_time"),
            "end_time": task_data.get("end_time"),
        },
    }
    if deployment_info.get("success"):
        result["deployment_info"] = deployment_info
    return result


def poll_task_status(
    task_id: str,
    portal_api_url: str = DEFAULT_PORTAL_API_URL,
    max_attempts: int = DEFAULT_MAX_POLL_ATTEMPTS,
    poll_interval: int = DEFAULT_POLL_INTERVAL,
) -> Dict[str, object]:
    if max_attempts <= 0:
        return {
            "success": False,
            "error": "invalid_max_attempts",
            "message": "--max-attempts must be greater than 0",
            "task_id": task_id,
        }
    if poll_interval < 0:
        return {
            "success": False,
            "error": "invalid_poll_interval",
            "message": "--poll-interval must be greater than or equal to 0",
            "task_id": task_id,
        }

    last_result: Optional[Dict[str, object]] = None
    for attempt in range(1, max_attempts + 1):
        current = query_task_status(task_id, portal_api_url)
        current["attempts"] = attempt
        last_result = current
        if not current.get("success"):
            return current
        task = current.get("task")
        if isinstance(task, dict) and task.get("finished"):
            return current
        if attempt < max_attempts:
            time.sleep(poll_interval)

    return {
        "success": False,
        "error": "poll_timeout",
        "message": f"Polling timeout after {max_attempts} attempts",
        "task_id": task_id,
        "attempts": max_attempts,
        "last_result": last_result,
    }


def print_result(result: Dict[str, object], pretty: bool) -> None:
    if pretty:
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(json.dumps(result, ensure_ascii=False))


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)

    if args.command == "status":
        task_id, task_id_error = resolve_task_id(args.task_id, args.task_url)
        if task_id_error is not None:
            result = {
                "success": False,
                "error": "missing_task_id",
                "message": task_id_error,
            }
            print_result(result, getattr(args, "pretty", False))
            return 1

        if args.wait:
            result = poll_task_status(
                task_id=task_id,
                portal_api_url=args.portal_api_url,
                max_attempts=args.max_attempts,
                poll_interval=args.poll_interval,
            )
        else:
            result = query_task_status(task_id=task_id, portal_api_url=args.portal_api_url)
        print_result(result, getattr(args, "pretty", False))

        if not result.get("success"):
            return 1
        if args.wait:
            task = result.get("task") or {}
            if not isinstance(task, dict):
                return 1
            return 0 if task.get("deployment_success") else 1
        return 0

    project_root = find_project_root(args.project_dir)
    resolved = resolve_target(
        project_root=project_root,
        branch=args.branch,
        app_code=args.app_code,
        env_code=args.env_code,
        user_id=args.user_id,
    )

    if args.command == "resolve":
        print_result(resolved, getattr(args, "pretty", False))
        return 0 if resolved.get("success") else 1

    if not resolved.get("success"):
        print_result(resolved, getattr(args, "pretty", False))
        return 1

    selected = resolved.get("selected_config") or {}
    deploy = trigger_deploy(
        deploy_url=args.deploy_url,
        branch=str(resolved["branch"]),
        app_code=str(selected["appCode"]),
        env_code=str(selected["envCode"]),
        user_id=str(resolved["userId"]),
    )
    result = {
        "success": bool(deploy.get("success")),
        "resolved": resolved,
        "deploy": deploy,
    }
    print_result(result, getattr(args, "pretty", False))
    return 0 if result["success"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
