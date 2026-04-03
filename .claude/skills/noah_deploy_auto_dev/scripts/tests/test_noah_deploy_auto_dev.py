#!/usr/bin/env python3
"""Unit tests for noah_deploy_auto_dev."""

from __future__ import annotations

import importlib.util
import json
import unittest
from pathlib import Path
from unittest.mock import patch


MODULE_PATH = Path(__file__).resolve().parent.parent / "noah_deploy_auto_dev.py"
SPEC = importlib.util.spec_from_file_location("noah_deploy_auto_dev", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FakeResponse:
    def __init__(self, body: object, status: int = 200, headers: dict | None = None):
        if isinstance(body, str):
            payload = body
        else:
            payload = json.dumps(body, ensure_ascii=False)
        self._body = payload.encode("utf-8")
        self.status = status
        self.headers = headers or {"Content-Type": "application/json"}

    def read(self) -> bytes:
        return self._body

    def __enter__(self) -> "FakeResponse":
        return self

    def __exit__(self, exc_type, exc, tb) -> bool:
        return False


def make_status_payload(status: int) -> dict:
    return {
        "status": 0,
        "message": "success",
        "data": {
            "status": status,
            "start_time": "2026-03-16 18:01:03",
            "end_time": "2026-03-16 18:05:21" if status != MODULE.STATUS_UNFINISHED else None,
            "tasks": [
                {
                    "app_code": "f_inter_autotest_dispatch",
                    "input_revision": "abc123",
                    "output_revision": "def456",
                    "input_tag": "feature/demo",
                    "output_tag": "b-260316-180105-user",
                    "env_list": [
                        {
                            "env_id": "noahauto-2",
                            "env_profile": "betanoah",
                            "deployed_hosts": ["l-noah6jbkdtwat1.auto.beta.cn0.qunar.com"]
                            if status == MODULE.STATUS_SUCCESS
                            else [],
                            "has_deployed_hosts": [],
                            "in_process_hosts": ["l-noah6jbkdtwat1.auto.beta.cn0.qunar.com"]
                            if status == MODULE.STATUS_UNFINISHED
                            else [],
                            "deployed_failed_hosts": [],
                        }
                    ],
                }
            ],
        },
    }


class NoahDeployAutoDevTest(unittest.TestCase):
    def test_trigger_deploy_extracts_task_metadata(self) -> None:
        payload = {
            "status": 0,
            "msg": "success",
            "data": "http://portal.corp.qunar.com/servicePortal/apptask/console.html?id=13607849",
        }
        with patch.object(MODULE, "urlopen", return_value=FakeResponse(payload)):
            result = MODULE.trigger_deploy(
                deploy_url=MODULE.DEFAULT_DEPLOY_URL,
                branch="feature/demo",
                app_code="cm_demo",
                env_code="beta-demo",
                user_id="tester",
            )

        self.assertTrue(result["success"])
        self.assertEqual(result["deployment_task"]["task_id"], "13607849")
        self.assertEqual(
            result["deployment_task"]["task_url"],
            "http://portal.corp.qunar.com/servicePortal/apptask/console.html?id=13607849",
        )

    def test_resolve_task_id_from_task_url(self) -> None:
        task_id, error = MODULE.resolve_task_id(
            None,
            "http://portal.corp.qunar.com/servicePortal/apptask/console.html?id=13607849",
        )
        self.assertIsNone(error)
        self.assertEqual(task_id, "13607849")

    def test_query_task_status_returns_summary(self) -> None:
        with patch.object(MODULE, "urlopen", return_value=FakeResponse(make_status_payload(MODULE.STATUS_SUCCESS))):
            result = MODULE.query_task_status("13607849")

        self.assertTrue(result["success"])
        self.assertEqual(result["task"]["status"], MODULE.STATUS_SUCCESS)
        self.assertEqual(result["task"]["status_name"], "成功")
        self.assertTrue(result["task"]["finished"])
        self.assertTrue(result["task"]["deployment_success"])
        self.assertEqual(
            result["deployment_info"]["host"],
            "l-noah6jbkdtwat1.auto.beta.cn0.qunar.com",
        )

    def test_poll_task_status_waits_until_terminal(self) -> None:
        responses = [
            FakeResponse(make_status_payload(MODULE.STATUS_UNFINISHED)),
            FakeResponse(make_status_payload(MODULE.STATUS_SUCCESS)),
        ]
        with patch.object(MODULE, "urlopen", side_effect=responses), patch.object(MODULE.time, "sleep") as sleep_mock:
            result = MODULE.poll_task_status(
                task_id="13607849",
                max_attempts=2,
                poll_interval=0,
            )

        self.assertTrue(result["success"])
        self.assertEqual(result["attempts"], 2)
        self.assertTrue(result["task"]["deployment_success"])
        sleep_mock.assert_called_once_with(0)

    def test_main_status_wait_returns_nonzero_on_failed_deploy(self) -> None:
        with patch.object(MODULE, "urlopen", return_value=FakeResponse(make_status_payload(MODULE.STATUS_FAILED))):
            exit_code = MODULE.main(
                [
                    "status",
                    "--task-id",
                    "13607849",
                    "--wait",
                ]
            )

        self.assertEqual(exit_code, 1)


if __name__ == "__main__":
    unittest.main()
