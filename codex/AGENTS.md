# Global Agent Rules

## Language

Default to Chinese in user-facing replies unless the user explicitly requests another language.

## Timezone

- Default to `Asia/Shanghai` for task names, task logs, date formatting, and time-related reasoning unless the user explicitly requests another timezone.
- When the runtime environment uses another timezone, convert explicitly and include the timezone label when the date or time could be ambiguous.

## Response Style

Do not propose follow-up tasks or enhancement at the end of your final answer.

## Turn Focus

- Treat the newest user message in the current turn as the authoritative request.
- Use prior task summaries, `task_complete` events, and earlier final answers as background only; never reuse them as the new turn's answer.
- If the user switches from implementation work to a read-only question, explanation, or review, answer that new request directly and only reference prior task state when it helps explain the answer.
- Before sending the final answer, silently verify that it explicitly addresses the latest user ask and any named terms, files, or metrics.

## Debug-First Policy (No Silent Fallbacks)

- Do **not** introduce new boundary rules / guardrails / blockers / caps (e.g. max-turns), fallback behaviors, or silent degradation **just to make it run**.
- Do **not** add mock/simulation fake success paths (e.g. returning `(mock) ok`, templated outputs that bypass real execution, or swallowing errors).
- Do **not** add defensive fallback paths, compatibility branches, or "best effort" continuations that hide the real failure.
- Prefer **full exposure**: let failures surface clearly (explicit errors, exceptions, logs, failing tests) so bugs are visible and can be fixed at the root cause.
- Prefer explicit validation, fail-fast guards, and visible error handling when they make boundary failures easier to detect and debug.
- If a boundary rule or fallback is truly necessary (security/safety/privacy, or the user explicitly requests it), it must be:
  - explicit (never silent),
  - documented,
  - easy to disable,
  - and agreed by the user beforehand.

## Engineering Quality Baseline

- Follow SOLID, DRY, separation of concerns, and YAGNI.
- Use clear naming and pragmatic abstractions; add concise comments only for critical or non-obvious logic.
- Remove dead code and obsolete compatibility paths when changing behavior, unless compatibility is explicitly required by the user.
- Consider time/space complexity and optimize heavy IO or memory usage when relevant.
- Handle edge cases explicitly; do not hide failures.

## Code Metrics (Default Limits)

- Treat these as default limits for production code and business logic.
- For tests, migrations, generated code, or framework glue, follow the spirit of these limits and keep any exception narrow and justified.

- **Function length**: 50 lines (excluding blanks). If exceeded, extract a helper immediately.
- **File size**: 300 lines. If exceeded, split by responsibility.
- **Nesting depth**: 3 levels. Use early returns / guard clauses to flatten.
- **Parameters**: 3 positional. If more are needed, use a config/options object.
- **Cyclomatic complexity**: 10 per function. If exceeded, decompose branching logic.
- **No magic numbers**: extract to named constants (`MAX_RETRIES = 3`, not bare `3`).

## Decoupling & Immutability

- **Dependency injection**: business logic never `new`s or hard-imports concrete implementations; inject via parameters or interfaces.
- **Immutable-first**: prefer `readonly`, `frozen=True`, `const`, immutable data structures. Never mutate function parameters or global state; return new values.

## Security Baseline

- Never hardcode secrets, API keys, or credentials in source code; use environment variables or secret managers.
- Use parameterized queries for all database access; never concatenate user input into SQL/commands.
- Validate and sanitize all external input (user input, API responses, file content) at system boundaries.
- **Conversation keys vs code leaks**: When the user shares an API key in conversation (e.g. configuring a provider or debugging a connection), treat that as normal workflow and do **not** emit "secret leaked" warnings. Only alert when a key is written into a source code file. Frontend display is already masked; no need to remind repeatedly.

## Testing and Validation

- Keep code testable and verify with automated checks whenever feasible.
- When running backend unit tests, enforce a hard timeout of 60 seconds to avoid stuck tasks.
- Prefer static checks, formatting, and reproducible verification over ad-hoc manual confidence.

## Python / UV

- When a task involves Python, default to using `uv` for environment, dependency, tool, and Python version management.
- Prefer uv's normal project workflow for uv-managed repositories.
- For uv-specific command choices, version-sensitive behavior, migration details, or MCP integration, load and follow the `uv` skill instead of duplicating those rules here.
- Only use another Python workflow when the user explicitly requests it, or when the project already has a clearly established alternative such as `poetry`, `pipenv`, `conda`, or a committed non-uv workflow that should be preserved.

## Skills

Skills are stored in `~/.codex/skills/` (personal) and optionally `.codex/skills/` (project-shared).

Before starting a task:

- Scan available skills.
- If a skill matches, read its `SKILL.md` and follow it.
- Announce which skill(s) are being used.
- Prefer `taskmaster` by default for any task with 3+ ordered steps that produce file changes.
- Keep the matching skill set minimal; do not load unrelated skills.

Routing table:

| Scenario | Skill | Trigger |
|----------|-------|---------|
| Multi-step task tracking / autonomous execution | `taskmaster` | 3+ ordered steps that produce file changes, or "track tasks", "make a plan", "track progress", "long task", "big project", "autonomous", "从零开始", "长时任务" |
| Lightweight project change with CSV + `update_plan` sync | `todo-list-csv` | A file-changing task where project-root CSV tracking should stay in sync with `update_plan` |
| Python package / environment / tool / runtime / MCP work | `uv` | Queries about `uv`, `uvx`, Python package management, virtual environments, Python versions, CLI tools, or MCP servers |
| Create or update a reusable skill | `skill-creator` | The user asks to create, revise, package, or improve a skill |

## Taskmaster Notes

- `taskmaster` v5 supports `Single / Epic / Batch`; shape selection belongs in `SKILL.md`, not in this global file.
- For homogeneous row-level batch work inside `taskmaster`, prefer `spawn_agents_on_csv`.
- Keep task-tracking CSV and batch-worker CSV separated.
