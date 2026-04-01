#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import socket
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urljoin
from urllib.request import Request, urlopen

DEFAULT_BASE_URL = os.environ.get("NOAH_VARIABLES_BASE_URL", "http://noah3.corp.qunar.com")
DEFAULT_TIMEOUT = 10
MYSQL_BIN_ENV = "NOAH_MYSQL_BIN"
IGNORED_PATH_PARTS = {".git", ".idea", "node_modules", "__pycache__", ".nova", "target"}

READ_ONLY_PREFIXES = {
    "select",
    "show",
    "desc",
    "describe",
    "explain",
    "set",
    "use",
}
JDBC_KEY_RE = re.compile(r"^(?P<prefix>.+)\.jdbc\.(?P<field>[A-Za-z0-9_]+)$")


class NoahMysqlError(RuntimeError):
    pass


@dataclass
class DbConfig:
    prefix: str
    host: str
    port: int
    dbname: str
    username: str
    password: str
    namespace: str | None = None
    server_name: str | None = None
    ip: str | None = None


@dataclass
class EnvPayload:
    env_id: int | None
    env_code: str
    app_code: str
    app_name: str | None
    qconfig_profile: str | None
    raw: dict[str, Any]
    db_configs: dict[str, DbConfig]


@dataclass
class ProjectConfig:
    project_root: Path
    config_dir: Path
    app_code: str
    env_code: str
    app_path: Path | None
    env_path: Path | None


def build_url(base_url: str, path: str, params: dict[str, Any]) -> str:
    root = base_url.rstrip("/") + "/"
    return urljoin(root, path.lstrip("/")) + "?" + urlencode(params)


def fetch_json(url: str, timeout: int) -> dict[str, Any]:
    request = Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "noah-mysql-skill/1.0",
        },
    )
    try:
        with urlopen(request, timeout=timeout) as response:
            body = response.read().decode("utf-8")
    except HTTPError as exc:
        snippet = exc.read().decode("utf-8", errors="replace")[:300]
        raise NoahMysqlError(f"HTTP {exc.code} when calling {url}: {snippet}") from exc
    except URLError as exc:
        raise NoahMysqlError(f"Unable to reach {url}: {exc.reason}") from exc

    try:
        payload = json.loads(body)
    except json.JSONDecodeError as exc:
        raise NoahMysqlError(f"Non-JSON response from {url}: {body[:300]}") from exc

    if payload.get("status") != 0:
        raise NoahMysqlError(
            f"API returned status={payload.get('status')}, msg={payload.get('msg')!r}"
        )
    data = payload.get("data")
    if not isinstance(data, dict):
        raise NoahMysqlError("API response missing data object.")
    return data


def mask_secret(value: str) -> str:
    if not value:
        return ""
    if len(value) <= 4:
        return "*" * len(value)
    return value[:2] + "*" * (len(value) - 4) + value[-2:]


def ensure_beta_profile(profile: str | None) -> None:
    if not profile or not profile.startswith("beta"):
        raise NoahMysqlError(
            f"Refusing to operate on non-beta target. qconfigProfile={profile!r}"
        )


def extract_db_configs(properties: dict[str, Any]) -> dict[str, DbConfig]:
    grouped: dict[str, dict[str, str]] = {}

    for key, value in properties.items():
        if not isinstance(value, str):
            continue
        match = JDBC_KEY_RE.match(key)
        if not match:
            continue
        prefix = match.group("prefix")
        field = match.group("field")
        grouped.setdefault(prefix, {})[field] = value

    configs: dict[str, DbConfig] = {}
    required_fields = ("host", "port", "dbname", "username", "password")

    for prefix, fields in grouped.items():
        missing = [field for field in required_fields if not fields.get(field)]
        if missing:
            continue

        try:
            port = int(fields["port"])
        except ValueError:
            continue

        configs[prefix] = DbConfig(
            prefix=prefix,
            host=fields["host"],
            port=port,
            dbname=fields["dbname"],
            username=fields["username"],
            password=fields["password"],
            namespace=fields.get("namespace"),
            server_name=fields.get("ServerName"),
            ip=fields.get("IP"),
        )

    return configs


def parse_properties_file(file_path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    try:
        with file_path.open("r", encoding="utf-8") as handle:
            for raw_line in handle:
                line = raw_line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                result[key.strip()] = value.strip()
    except OSError as exc:
        raise NoahMysqlError(f"Failed to read properties file {file_path}: {exc}") from exc
    return result


def find_project_root(start_dir: Path) -> Path:
    current = start_dir.resolve()
    if current.is_file():
        current = current.parent
    while current != current.parent:
        if (current / ".git").exists():
            return current
        current = current.parent
    return start_dir.resolve() if start_dir.exists() else Path.cwd().resolve()


def is_ignored_path(path: Path) -> bool:
    return any(part in IGNORED_PATH_PARTS for part in path.parts)


def config_dir_sort_key(config_dir: Path, project_root: Path) -> tuple[int, int, str]:
    try:
        rel = config_dir.relative_to(project_root)
    except ValueError:
        rel = config_dir
    parts = rel.parts
    if len(parts) >= 3 and parts[-3:] == ("src", "main", "resources"):
        kind = 0
    elif len(parts) >= 3 and parts[-3] == "src" and parts[-2] == "main" and parts[-1].startswith("resources"):
        kind = 1
    else:
        kind = 2
    return kind, len(parts), str(rel)


def discover_config_dirs(project_root: Path) -> list[Path]:
    candidates: set[Path] = set()
    for resources_root in project_root.rglob("src/main/resources*"):
        if not resources_root.is_dir() or is_ignored_path(resources_root):
            continue
        candidates.add(resources_root.resolve())
        for pattern in ("qunar-app.properties", "qunar-env.properties"):
            for match in resources_root.rglob(pattern):
                if is_ignored_path(match):
                    continue
                candidates.add(match.parent.resolve())

    return sorted(candidates, key=lambda item: config_dir_sort_key(item, project_root))


def parse_project_candidate(project_root: Path, config_dir: Path) -> ProjectConfig | None:
    app_path = config_dir / "qunar-app.properties"
    env_path = config_dir / "qunar-env.properties"

    app_code = None
    env_code = None
    if app_path.exists():
        app_code = parse_properties_file(app_path).get("name")
    else:
        app_path = None
    if env_path.exists():
        env_props = parse_properties_file(env_path)
        env_code = env_props.get("envCode") or env_props.get("name")
    else:
        env_path = None

    if not app_code and not env_code:
        return None

    return ProjectConfig(
        project_root=project_root,
        config_dir=config_dir,
        app_code=app_code or "",
        env_code=env_code or "",
        app_path=app_path,
        env_path=env_path,
    )


def format_project_candidate(candidate: ProjectConfig) -> str:
    try:
        rel_dir = candidate.config_dir.relative_to(candidate.project_root)
    except ValueError:
        rel_dir = candidate.config_dir
    parts = [f"{rel_dir}: appCode={candidate.app_code or 'N/A'}, envCode={candidate.env_code or 'N/A'}"]
    if candidate.app_path:
        try:
            parts.append(f"appPath={candidate.app_path.relative_to(candidate.project_root)}")
        except ValueError:
            parts.append(f"appPath={candidate.app_path}")
    if candidate.env_path:
        try:
            parts.append(f"envPath={candidate.env_path.relative_to(candidate.project_root)}")
        except ValueError:
            parts.append(f"envPath={candidate.env_path}")
    return ", ".join(parts)


def detect_project_config(
    project_dir: str | None,
    *,
    expected_env_code: str | None = None,
    expected_app_code: str | None = None,
) -> ProjectConfig:
    start_dir = Path(project_dir).expanduser() if project_dir else Path.cwd()
    project_root = find_project_root(start_dir)
    parsed = [
        candidate
        for config_dir in discover_config_dirs(project_root)
        if (candidate := parse_project_candidate(project_root, config_dir)) is not None
    ]
    if not parsed:
        raise NoahMysqlError(
            f"Could not auto-detect envCode/appCode from project {project_root}. "
            "Pass --env-code/--app-code explicitly."
        )

    complete = [candidate for candidate in parsed if candidate.app_code and candidate.env_code]
    if expected_app_code:
        complete = [candidate for candidate in complete if candidate.app_code == expected_app_code]
    if expected_env_code:
        complete = [candidate for candidate in complete if candidate.env_code == expected_env_code]

    by_value: dict[tuple[str, str], ProjectConfig] = {}
    for candidate in complete:
        key = (candidate.app_code, candidate.env_code)
        current = by_value.get(key)
        if current is None or config_dir_sort_key(candidate.config_dir, project_root) < config_dir_sort_key(current.config_dir, project_root):
            by_value[key] = candidate

    if len(by_value) == 1:
        return next(iter(by_value.values()))

    if len(by_value) > 1:
        details = "\n".join(f"  - {format_project_candidate(candidate)}" for candidate in by_value.values())
        raise NoahMysqlError(
            "Auto-detected multiple envCode/appCode candidates from the project. "
            "Pass --env-code/--app-code explicitly or run in the intended module directory.\n"
            f"{details}"
        )

    app_values = sorted({candidate.app_code for candidate in parsed if candidate.app_code})
    env_values = sorted({candidate.env_code for candidate in parsed if candidate.env_code})
    if len(app_values) == 1 and len(env_values) == 1:
        best = min(parsed, key=lambda candidate: config_dir_sort_key(candidate.config_dir, project_root))
        return ProjectConfig(
            project_root=project_root,
            config_dir=best.config_dir,
            app_code=app_values[0],
            env_code=env_values[0],
            app_path=best.app_path if best.app_code else next((candidate.app_path for candidate in parsed if candidate.app_code), None),
            env_path=best.env_path if best.env_code else next((candidate.env_path for candidate in parsed if candidate.env_code), None),
        )

    details = "\n".join(f"  - {format_project_candidate(candidate)}" for candidate in parsed)
    raise NoahMysqlError(
        "Could not determine a unique envCode/appCode from the project. "
        "Pass --env-code/--app-code explicitly or run in the intended module directory.\n"
        f"{details}"
    )


def resolve_env_and_app(args: argparse.Namespace) -> tuple[str, str, ProjectConfig | None]:
    env_code = args.env_code
    app_code = args.app_code
    detected = None
    if env_code and app_code:
        return env_code, app_code, detected

    detected = detect_project_config(
        args.project_dir,
        expected_env_code=env_code,
        expected_app_code=app_code,
    )
    return env_code or detected.env_code, app_code or detected.app_code, detected


def emit_detection_notice(detected: ProjectConfig | None) -> None:
    if detected is None:
        return
    details = [f"Auto-detected appCode={detected.app_code}, envCode={detected.env_code}"]
    if detected.app_path:
        details.append(f"appPath={detected.app_path}")
    if detected.env_path:
        details.append(f"envPath={detected.env_path}")
    print(" | ".join(details), file=sys.stderr)


def fetch_env_payload(
    base_url: str,
    env_code: str,
    app_code: str,
    timeout: int,
) -> EnvPayload:
    url = build_url(
        base_url,
        "/replacer/variables",
        {"envCode": env_code, "appCode": app_code},
    )
    data = fetch_json(url, timeout)
    ensure_beta_profile(data.get("qconfigProfile"))
    properties = data.get("properties") or {}
    if not isinstance(properties, dict):
        raise NoahMysqlError("API response contains invalid properties field.")

    db_configs = extract_db_configs(properties)
    if not db_configs:
        raise NoahMysqlError(
            f"No usable JDBC groups found for envCode={env_code!r}, appCode={app_code!r}."
        )

    return EnvPayload(
        env_id=data.get("envId"),
        env_code=str(data.get("envCode") or env_code),
        app_code=str(data.get("appCode") or app_code),
        app_name=data.get("appName"),
        qconfig_profile=data.get("qconfigProfile"),
        raw=data,
        db_configs=db_configs,
    )


def choose_db_config(payload: EnvPayload, db_prefix: str | None) -> DbConfig:
    if db_prefix:
        config = payload.db_configs.get(db_prefix)
        if config is None:
            raise NoahMysqlError(
                f"Unknown db prefix {db_prefix!r}. Available: {', '.join(sorted(payload.db_configs))}"
            )
        return config

    if len(payload.db_configs) == 1:
        return next(iter(payload.db_configs.values()))

    raise NoahMysqlError(
        "Multiple JDBC groups found. Specify --db-prefix explicitly. "
        f"Available: {', '.join(sorted(payload.db_configs))}"
    )


def mysql_bin() -> str:
    return os.environ.get(MYSQL_BIN_ENV, "mysql")


def ensure_mysql_cli_available() -> None:
    if not shutil_which(mysql_bin()):
        raise NoahMysqlError(
            f"MySQL client not found: {mysql_bin()!r}. "
            f"Install mysql or set {MYSQL_BIN_ENV}."
        )


def shutil_which(name: str) -> str | None:
    if os.path.sep in name:
        return name if os.path.isfile(name) and os.access(name, os.X_OK) else None
    paths = os.environ.get("PATH", "").split(os.pathsep)
    for path in paths:
        candidate = os.path.join(path, name)
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return None


def strip_leading_sql_comments(sql: str) -> str:
    remaining = sql.lstrip()
    while True:
        if remaining.startswith("--"):
            parts = remaining.splitlines()
            remaining = "\n".join(parts[1:]).lstrip()
            continue
        if remaining.startswith("#"):
            parts = remaining.splitlines()
            remaining = "\n".join(parts[1:]).lstrip()
            continue
        if remaining.startswith("/*"):
            end = remaining.find("*/")
            if end == -1:
                return ""
            remaining = remaining[end + 2 :].lstrip()
            continue
        return remaining


def sql_requires_write_permission(sql: str) -> bool:
    stripped = strip_leading_sql_comments(sql)
    if not stripped:
        return False
    match = re.match(r"([A-Za-z]+)", stripped)
    if not match:
        return True
    first = match.group(1).lower()
    return first not in READ_ONLY_PREFIXES


def tcp_check(host: str, port: int, timeout: int) -> None:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return
    except OSError as exc:
        raise NoahMysqlError(f"TCP check failed for {host}:{port}: {exc}") from exc


def mysql_base_command(config: DbConfig, connect_timeout: int) -> list[str]:
    return [
        mysql_bin(),
        "--protocol=TCP",
        f"--connect-timeout={connect_timeout}",
        "--default-character-set=utf8mb4",
        "-h",
        config.host,
        "-P",
        str(config.port),
        "-u",
        config.username,
        "-D",
        config.dbname,
    ]


def run_mysql(
    config: DbConfig,
    connect_timeout: int,
    *,
    sql: str | None = None,
    sql_file: str | None = None,
    batch: bool = False,
) -> subprocess.CompletedProcess[str]:
    ensure_mysql_cli_available()
    command = mysql_base_command(config, connect_timeout)
    if batch:
        command.extend(["--batch", "--raw"])
    input_sql = None
    if sql is not None:
        command.extend(["-e", sql])
    elif sql_file is not None:
        with open(sql_file, "r", encoding="utf-8") as handle:
            input_sql = handle.read()
    else:
        raise NoahMysqlError("One of sql or sql_file is required.")

    env = os.environ.copy()
    env["MYSQL_PWD"] = config.password
    result = subprocess.run(
        command,
        input=input_sql,
        text=True,
        capture_output=True,
        env=env,
        check=False,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise NoahMysqlError(detail or f"mysql exited with code {result.returncode}")
    return result


def format_db_config(config: DbConfig) -> str:
    lines = [
        f"db_prefix: {config.prefix}",
        f"host: {config.host}",
        f"port: {config.port}",
        f"dbname: {config.dbname}",
        f"username: {config.username}",
        f"password: {mask_secret(config.password)}",
    ]
    if config.namespace:
        lines.append(f"namespace: {config.namespace}")
    if config.server_name:
        lines.append(f"server_name: {config.server_name}")
    if config.ip:
        lines.append(f"ip: {config.ip}")
    return "\n".join(lines)


def cmd_resolve(args: argparse.Namespace) -> int:
    env_code, app_code, detected = resolve_env_and_app(args)
    emit_detection_notice(detected)
    payload = fetch_env_payload(args.base_url, env_code, app_code, args.timeout)
    if args.db_prefix:
        config = choose_db_config(payload, args.db_prefix)
        print(f"env_id: {payload.env_id}")
        print(f"env_code: {payload.env_code}")
        print(f"app_code: {payload.app_code}")
        print(f"app_name: {payload.app_name or ''}")
        print(f"qconfig_profile: {payload.qconfig_profile}")
        print(format_db_config(config))
        return 0

    print(f"env_id: {payload.env_id}")
    print(f"env_code: {payload.env_code}")
    print(f"app_code: {payload.app_code}")
    print(f"app_name: {payload.app_name or ''}")
    print(f"qconfig_profile: {payload.qconfig_profile}")
    print("db_prefixes:")
    for prefix in sorted(payload.db_configs):
        config = payload.db_configs[prefix]
        print(f"  - {prefix}: {config.host}:{config.port}/{config.dbname} user={config.username}")
    return 0


def cmd_ping(args: argparse.Namespace) -> int:
    env_code, app_code, detected = resolve_env_and_app(args)
    emit_detection_notice(detected)
    payload = fetch_env_payload(args.base_url, env_code, app_code, args.timeout)
    config = choose_db_config(payload, args.db_prefix)

    print(f"Resolved {payload.env_code}/{payload.app_code} -> {config.prefix}")
    print(f"TCP check: {config.host}:{config.port}")
    tcp_check(config.host, config.port, args.connect_timeout)
    print("TCP check passed.")

    result = run_mysql(
        config,
        args.connect_timeout,
        sql="SELECT 1 AS ok, DATABASE() AS current_db, @@hostname AS mysql_host, @@port AS mysql_port;",
        batch=True,
    )
    print(result.stdout.strip())
    print("MySQL ping passed.")
    return 0


def read_sql_text(args: argparse.Namespace) -> tuple[str | None, str | None]:
    if bool(args.sql) == bool(args.sql_file):
        raise NoahMysqlError("Use exactly one of --sql or --sql-file.")
    if args.sql:
        return args.sql, None
    return None, args.sql_file


def cmd_exec(args: argparse.Namespace) -> int:
    env_code, app_code, detected = resolve_env_and_app(args)
    emit_detection_notice(detected)
    payload = fetch_env_payload(args.base_url, env_code, app_code, args.timeout)
    config = choose_db_config(payload, args.db_prefix)
    sql, sql_file = read_sql_text(args)

    sql_text = sql
    if sql_file:
        with open(sql_file, "r", encoding="utf-8") as handle:
            sql_text = handle.read()

    if sql_text is None:
        raise NoahMysqlError("SQL text is empty.")
    if sql_requires_write_permission(sql_text) and not args.allow_write:
        raise NoahMysqlError(
            "Detected non-read-only SQL. Re-run with --allow-write only when the user explicitly requested the change."
        )

    result = run_mysql(
        config,
        args.connect_timeout,
        sql=sql,
        sql_file=sql_file,
        batch=args.batch,
    )
    if result.stdout:
        print(result.stdout.rstrip())
    if result.stderr:
        print(result.stderr.rstrip(), file=sys.stderr)
    return 0


def add_common_env_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--env-code", help="Noah envCode, e.g. qnova. Auto-detect from the project when omitted.")
    parser.add_argument("--app-code", help="Noah appCode, e.g. cm_qnova. Auto-detect from the project when omitted.")
    parser.add_argument(
        "--project-dir",
        help="Project directory used for auto-detecting envCode/appCode. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"Replacer API base URL (default: {DEFAULT_BASE_URL})",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_TIMEOUT,
        help=f"HTTP timeout seconds (default: {DEFAULT_TIMEOUT})",
    )
    parser.add_argument(
        "--db-prefix",
        help="Resolved JDBC prefix, e.g. newdb_pxc57. Required when multiple JDBC groups exist.",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Resolve Noah beta MySQL config by envCode/appCode and run SQL."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    resolve_parser = subparsers.add_parser("resolve", help="Resolve JDBC groups and connection info.")
    add_common_env_args(resolve_parser)
    resolve_parser.set_defaults(func=cmd_resolve)

    ping_parser = subparsers.add_parser("ping", help="Test TCP and SELECT 1 against the resolved MySQL.")
    add_common_env_args(ping_parser)
    ping_parser.add_argument(
        "--connect-timeout",
        type=int,
        default=5,
        help="MySQL/TCP connect timeout seconds (default: 5)",
    )
    ping_parser.set_defaults(func=cmd_ping)

    exec_parser = subparsers.add_parser("exec", help="Execute SQL against the resolved MySQL.")
    add_common_env_args(exec_parser)
    exec_parser.add_argument("--sql", help="Inline SQL to execute.")
    exec_parser.add_argument("--sql-file", help="Path to a .sql file to execute.")
    exec_parser.add_argument(
        "--allow-write",
        action="store_true",
        help="Allow non-read-only SQL such as CREATE/INSERT/UPDATE/DELETE/ALTER/DROP.",
    )
    exec_parser.add_argument(
        "--batch",
        action="store_true",
        help="Use mysql batch/raw output mode.",
    )
    exec_parser.add_argument(
        "--connect-timeout",
        type=int,
        default=5,
        help="MySQL connect timeout seconds (default: 5)",
    )
    exec_parser.set_defaults(func=cmd_exec)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return int(args.func(args))
    except NoahMysqlError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
