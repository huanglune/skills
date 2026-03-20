from __future__ import annotations

import csv
import json
import subprocess
import sys
from pathlib import Path


SCRIPT = Path("/home/huangliang/md1/tmp/skills/codex/taskmaster/scripts/taskmaster_plan.py")
TODO_HEADER = [
    "id",
    "task",
    "status",
    "acceptance_criteria",
    "validation_command",
    "completed_at",
    "retry_count",
    "notes",
]
SUBTASK_HEADER = [
    "id",
    "task",
    "task_type",
    "status",
    "depends_on",
    "task_dir",
    "acceptance_criteria",
    "validation_command",
    "completed_at",
    "retry_count",
    "notes",
]


def _write_csv(path: Path, header: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=header)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def _run_plan(path: Path, *extra: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "plan", "--file", str(path), *extra],
        capture_output=True,
        text=True,
        check=False,
    )


def test_single_todo_maps_to_update_plan(tmp_path: Path) -> None:
    csv_path = tmp_path / "TODO.csv"
    _write_csv(
        csv_path,
        TODO_HEADER,
        [
            {
                "id": "1",
                "task": "实现桥接脚本",
                "status": "IN_PROGRESS",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
            {
                "id": "2",
                "task": "补充测试",
                "status": "TODO",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
        ],
    )
    result = _run_plan(csv_path, "--explanation", "同步当前层")
    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["explanation"] == "同步当前层"
    assert payload["plan"] == [
        {"step": "实现桥接脚本", "status": "in_progress"},
        {"step": "补充测试", "status": "pending"},
    ]


def test_subtasks_csv_maps_to_current_epic_layer(tmp_path: Path) -> None:
    csv_path = tmp_path / "SUBTASKS.csv"
    _write_csv(
        csv_path,
        SUBTASK_HEADER,
        [
            {
                "id": "1",
                "task": "实现 API",
                "task_type": "single-full",
                "status": "DONE",
                "depends_on": "",
                "task_dir": "tasks/api",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "2026-03-18 16:00 CST",
                "retry_count": "0",
                "notes": "",
            },
            {
                "id": "2",
                "task": "实现前端",
                "task_type": "single-full",
                "status": "IN_PROGRESS",
                "depends_on": "1",
                "task_dir": "tasks/frontend",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
        ],
    )
    result = _run_plan(csv_path)
    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["plan"] == [
        {"step": "实现 API", "status": "completed"},
        {"step": "实现前端", "status": "in_progress"},
    ]


def test_normalize_promotes_first_todo_and_rewrites_csv(tmp_path: Path) -> None:
    csv_path = tmp_path / "TODO.csv"
    _write_csv(
        csv_path,
        TODO_HEADER,
        [
            {
                "id": "1",
                "task": "梳理协议",
                "status": "TODO",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
            {
                "id": "2",
                "task": "更新文档",
                "status": "TODO",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
        ],
    )
    result = _run_plan(csv_path, "--normalize")
    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["explanation"] == "CSV 已按 taskmaster 当前层规则规范化。"
    assert payload["plan"][0]["status"] == "in_progress"
    with csv_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    assert rows[0]["status"] == "IN_PROGRESS"
    assert rows[1]["status"] == "TODO"


def test_failed_row_stays_visible_in_explanation_and_plan(tmp_path: Path) -> None:
    csv_path = tmp_path / "TODO.csv"
    _write_csv(
        csv_path,
        TODO_HEADER,
        [
            {
                "id": "1",
                "task": "执行验证",
                "status": "FAILED",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "2026-03-18 16:30 CST",
                "retry_count": "1",
                "notes": "pytest 失败：test_failed_row",
            },
            {
                "id": "2",
                "task": "整理收尾",
                "status": "TODO",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
        ],
    )
    result = _run_plan(csv_path, "--explanation", "同步失败状态")
    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert "失败项仍需处理" in payload["explanation"]
    assert "pytest 失败：test_failed_row" in payload["explanation"]
    assert payload["plan"][0] == {"step": "执行验证", "status": "in_progress"}
    assert payload["plan"][1] == {"step": "整理收尾", "status": "pending"}


def test_invalid_header_and_worker_output_are_rejected(tmp_path: Path) -> None:
    csv_path = tmp_path / "workers-output.csv"
    _write_csv(
        csv_path,
        ["id", "status", "summary", "changed", "evidence_path", "error"],
        [
            {
                "id": "1",
                "status": "DONE",
                "summary": "ok",
                "changed": "false",
                "evidence_path": "artifacts/1.json",
                "error": "",
            }
        ],
    )
    result = _run_plan(csv_path)
    assert result.returncode == 2
    assert "Unsupported CSV header" in result.stderr


def test_multiple_active_rows_fail_without_normalize(tmp_path: Path) -> None:
    csv_path = tmp_path / "TODO.csv"
    _write_csv(
        csv_path,
        TODO_HEADER,
        [
            {
                "id": "1",
                "task": "步骤一",
                "status": "IN_PROGRESS",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
            {
                "id": "2",
                "task": "步骤二",
                "status": "IN_PROGRESS",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
        ],
    )
    result = _run_plan(csv_path)
    assert result.returncode == 2
    assert "Multiple active rows found" in result.stderr


def test_failed_row_cannot_coexist_with_other_active_row(tmp_path: Path) -> None:
    csv_path = tmp_path / "TODO.csv"
    _write_csv(
        csv_path,
        TODO_HEADER,
        [
            {
                "id": "1",
                "task": "验证",
                "status": "FAILED",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "2026-03-18 16:35 CST",
                "retry_count": "1",
                "notes": "单测失败",
            },
            {
                "id": "2",
                "task": "收尾",
                "status": "IN_PROGRESS",
                "acceptance_criteria": "",
                "validation_command": "",
                "completed_at": "",
                "retry_count": "0",
                "notes": "",
            },
        ],
    )
    result = _run_plan(csv_path, "--normalize")
    assert result.returncode == 2
    assert "FAILED row cannot coexist" in result.stderr
