---
name: use
description: Sends a task to a worker the user names (deepseek, hydrogen, neon, carbon, orch-neon, orch-carbon, sonnet, haiku), or sets the worker for the rest of the session. Use only when the user asks for one of these workers.
argument-hint: <worker> <task>
---
Request: $ARGUMENTS

The first word is the worker. The rest is the task.

| Worker | How to run it |
|---|---|
| deepseek | cheapag `delegate` tool. Pass `model` only if the user names one. |
| hydrogen | agent `workers:antigravity`, model `gemini-4-hydrogen-medium` |
| neon | agent `workers:antigravity`, model `gemini-4-neon-high` |
| carbon | agent `workers:antigravity`, model `gemini-4-carbon-high` |
| orch-neon | agent `workers:antigravity`, model `Orchestrator (Neon)` |
| orch-carbon | agent `workers:antigravity`, model `Orchestrator (Carbon)` |
| sonnet | Agent tool, `subagent_type: general-purpose`, `model: sonnet` |
| haiku | Agent tool, `subagent_type: general-purpose`, `model: haiku` |

For `workers:antigravity`, put the Gemini model name in the prompt. Leave the Agent tool's `model` parameter unset: it selects the wrapper's Claude model.

## Rules
1. If no worker is named, use the session worker if the user set one; otherwise ask. If the first word looks like a misspelled worker, ask. Never pick one yourself.
2. "For the rest of the session" (or similar): use that worker for later delegated tasks until the user changes it. If no task is given, confirm the choice and wait. A worker named for one task does not become the session worker.
3. Before you start, check the project's `AGENTS.md` and `CLAUDE.md`. If they name another worker for this kind of work, warn the user and ask before you continue.
4. If any worker except sonnet fails (error, FAIL, PARTIAL, TIMEOUT, quota or provider error):
   - Make sure the failed worker has stopped. Inspect its partial edits (working tree, or the Cheap Agent worktree) and keep the user's own changes.
   - Give the step to a Sonnet 5.5 sub-agent without asking: Agent tool, `subagent_type: general-purpose`, `model: sonnet`, `effort: medium`. Include the partial edits and the error in the brief. This overrides Cheap Agent's instruction to ask first.
   - Report the switch, the failed worker and the reason. The session worker does not change.
   - If Sonnet fails, report it and ask the user. Do not try another worker.
   - A consent or permission refusal, or a user denial, is not a failure: stop and ask the user. Make no other switch of worker or model.
5. Give the worker a self-contained brief: goal, absolute file paths, constraints and what to report. Never send secrets, credentials or personal data, and never use `--dangerously-skip-permissions`.
6. Antigravity edits the working tree directly. Before a coding task, check `git status` and tell the user about uncommitted changes that could overlap. Afterwards, tell the user to review `git diff` and untracked files before a commit.
7. Say which worker and model did the work.
