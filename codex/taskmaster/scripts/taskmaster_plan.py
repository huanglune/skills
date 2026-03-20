#!/usr/bin/env python3
"""
Generate `update_plan` payloads from taskmaster truth CSVs.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


STATUS_TODO = "TODO"
STATUS_IN_PROGRESS = "IN_PROGRESS"
STATUS_DONE = "DONE"
STATUS_FAILED = "FAILED"

ALLOWED_STATUSES = {
    STATUS_TODO,
    STATUS_IN_PROGRESS,
    STATUS_DONE,
    STATUS_FAILED,
}
ACTIVE_STATUSES = {STATUS_IN_PROGRESS, STATUS_FAILED}
PLAN_STATUS_BY_CSV_STATUS = {
    STATUS_TODO: "pending",
    STATUS_IN_PROGRESS: "in_progress",
    STATUS_DONE: "completed",
    STATUS_FAILED: "in_progress",
}


@dataclass(frozen=True)
class CsvShape:
    name: str
    headers: tuple[str, ...]


TODO_COMPACT = CsvShape(
    name="todo-compact",
    headers=("id", "task", "status", "completed_at", "notes"),
)
TODO_FULL = CsvShape(
    name="todo-full",
    headers=(
        "id",
        "task",
        "status",
        "acceptance_criteria",
        "validation_command",
        "completed_at",
        "retry_count",
        "notes",
    ),
)
TODO_PERF = CsvShape(
    name="todo-perf",
    headers=(
        "id",
        "task",
        "status",
        "acceptance_criteria",
        "validation_command",
        "completed_at",
        "retry_count",
        "notes",
        "metric_name",
        "target",
        "actual",
        "evidence_path",
    ),
)
SUBTASKS = CsvShape(
    name="subtasks",
    headers=(
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
    ),
)
SUPPORTED_SHAPES = (TODO_COMPACT, TODO_FULL, TODO_PERF, SUBTASKS)


def _read_csv(path: Path) -> tuple[CsvShape, list[dict[str, str]]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        fieldnames = tuple(reader.fieldnames or ())
        shape = next((item for item in SUPPORTED_SHAPES if item.headers == fieldnames), None)
        if shape is None:
            raise ValueError(f"Unsupported CSV header in {path}: {list(fieldnames)!r}")
        return shape, [dict(row) for row in reader]


def _write_csv(path: Path, shape: CsvShape, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        newline="",
        delete=False,
        dir=str(path.parent),
        prefix=f".{path.name}.",
        suffix=".tmp",
    ) as handle:
        tmp_path = Path(handle.name)
        writer = csv.DictWriter(handle, fieldnames=list(shape.headers))
        writer.writeheader()
        for row in rows:
            writer.writerow({header: row.get(header, "") for header in shape.headers})
    tmp_path.replace(path)


def _validate_rows(rows: list[dict[str, str]]) -> None:
    for index, row in enumerate(rows, start=1):
        task = str(row.get("task", "")).strip()
        status = str(row.get("status", "")).strip()
        if not task:
            raise ValueError(f"Row {index} has an empty task field.")
        if status not in ALLOWED_STATUSES:
            raise ValueError(f"Row {index} has unsupported status: {status!r}")


def _active_indexes(rows: list[dict[str, str]]) -> list[int]:
    return [index for index, row in enumerate(rows) if row.get("status") in ACTIVE_STATUSES]


def _clear_completed_at(row: dict[str, str]) -> None:
    if "completed_at" in row:
        row["completed_at"] = ""


def _normalize_rows(rows: list[dict[str, str]]) -> tuple[list[dict[str, str]], bool]:
    normalized = [dict(row) for row in rows]
    changed = False
    active_indexes = _active_indexes(normalized)
    failed_indexes = [index for index, row in enumerate(normalized) if row.get("status") == STATUS_FAILED]

    if len(failed_indexes) > 1:
        raise ValueError("Multiple FAILED rows found; resolve them manually before syncing update_plan.")
    if failed_indexes and len(active_indexes) > 1:
        raise ValueError("FAILED row cannot coexist with another active row in the same layer.")

    if len(active_indexes) > 1:
        keep_index = active_indexes[0]
        for index in active_indexes[1:]:
            normalized[index]["status"] = STATUS_TODO
            _clear_completed_at(normalized[index])
            changed = True
        if normalized[keep_index].get("status") == STATUS_IN_PROGRESS:
            before = normalized[keep_index].get("completed_at", "")
            _clear_completed_at(normalized[keep_index])
            changed = changed or bool(before)

    if not active_indexes:
        first_todo = next((row for row in normalized if row.get("status") == STATUS_TODO), None)
        if first_todo is not None:
            first_todo["status"] = STATUS_IN_PROGRESS
            _clear_completed_at(first_todo)
            changed = True

    return normalized, changed


def _ensure_rows_are_syncable(rows: list[dict[str, str]]) -> None:
    active_indexes = _active_indexes(rows)
    failed_indexes = [index for index, row in enumerate(rows) if row.get("status") == STATUS_FAILED]

    if len(failed_indexes) > 1:
        raise ValueError("Multiple FAILED rows found; resolve them manually before syncing update_plan.")
    if failed_indexes and len(active_indexes) > 1:
        raise ValueError("FAILED row cannot coexist with another active row in the same layer.")
    if len(active_indexes) > 1:
        raise ValueError("Multiple active rows found; rerun with --normalize or fix the CSV.")
    if not active_indexes and any(row.get("status") == STATUS_TODO for row in rows):
        raise ValueError("No active row found; rerun with --normalize or mark the current row explicitly.")


def _failed_reason(row: dict[str, str]) -> str:
    note = str(row.get("notes", "")).strip()
    task = str(row.get("task", "")).strip()
    item_id = str(row.get("id", "")).strip() or "?"
    if note:
        return f"#{item_id} {task}: {note}"
    return f"#{item_id} {task}: 缺少 notes 中的失败原因"


def _build_explanation(
    base: str,
    rows: list[dict[str, str]],
    *,
    normalized: bool,
) -> str:
    parts: list[str] = []
    if base.strip():
        parts.append(base.strip())

    failed_rows = [row for row in rows if row.get("status") == STATUS_FAILED]
    if failed_rows:
        reasons = "；".join(_failed_reason(row) for row in failed_rows)
        parts.append(f"失败项仍需处理：{reasons}")
    if normalized:
        parts.append("CSV 已按 taskmaster 当前层规则规范化。")
    return " ".join(parts).strip()


def _build_payload(explanation: str, rows: list[dict[str, str]]) -> dict[str, object]:
    plan = [
        {
            "step": str(row.get("task", "")).strip(),
            "status": PLAN_STATUS_BY_CSV_STATUS[str(row.get("status", "")).strip()],
        }
        for row in rows
    ]
    return {
        "explanation": explanation,
        "plan": plan,
    }


def cmd_plan(args: argparse.Namespace) -> int:
    path = Path(args.file).resolve()
    if not path.exists():
        print(f"CSV not found: {path}", file=sys.stderr)
        return 2

    try:
        shape, rows = _read_csv(path)
        _validate_rows(rows)
        normalized = False
        rows_for_plan = rows
        if args.normalize:
            rows_for_plan, normalized = _normalize_rows(rows)
            if normalized:
                _write_csv(path, shape, rows_for_plan)
        _ensure_rows_are_syncable(rows_for_plan)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    payload = _build_payload(
        _build_explanation(args.explanation or "", rows_for_plan, normalized=normalized),
        rows_for_plan,
    )
    json.dump(payload, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="taskmaster_plan.py")
    subparsers = parser.add_subparsers(dest="command", required=True)

    plan_parser = subparsers.add_parser(
        "plan",
        help="Print an update_plan-compatible JSON payload derived from a taskmaster truth CSV.",
    )
    plan_parser.add_argument("--file", required=True, help="Path to TODO.csv or SUBTASKS.csv.")
    plan_parser.add_argument("--explanation", default="", help="Base explanation for the generated payload.")
    plan_parser.add_argument(
        "--normalize",
        action="store_true",
        help="Normalize the CSV to taskmaster's single-active-row rules before printing the payload.",
    )
    plan_parser.set_defaults(func=cmd_plan)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
