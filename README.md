# workers

A Claude Code plugin to choose which sub-agent does a task: DeepSeek, Antigravity (Gemini), Sonnet or Haiku. You can choose a worker for one task or for the rest of a session.

| Worker | Runs on | Good for |
|---|---|---|
| `deepseek` | Cheap Agent (`delegate`) | code changes |
| `hydrogen` | Gemini 4 Hydrogen, through `agy` | bulk reading, summaries, boilerplate, drafts |
| `neon` | Gemini 4 Neon, through `agy` | coding |
| `carbon` | Gemini 4 Carbon, through `agy` | coding |
| `orch-neon` | Orchestrator (Neon), through `agy` | multi-step work that needs planning |
| `orch-carbon` | Orchestrator (Carbon), through `agy` | multi-step work that needs planning |
| `sonnet` | Claude Sonnet sub-agent | well-specified implementation, tests, docs |
| `haiku` | Claude Haiku sub-agent | mechanical work, searches |

## Requirements

- Windows with Windows PowerShell 5.1 (for `setup.ps1`), Git and Claude Code.
- Git access to this private repository, for example with the GitHub CLI (`gh`).
- For the Gemini workers: the Antigravity CLI (`agy`), installed and signed in. The Orchestrator models need a paid plan or an eligible trial.
- For `deepseek`: Cheap Agent (`cheapag`), installed separately on each computer. Run `/cheapag:allow` once for each repository.

You need only the parts for the workers that you use. Sonnet and Haiku need nothing more.

## Install

Do this on each computer.

1. Set up Git access (skip `gh auth login` if you are signed in):

   ```powershell
   gh auth login
   gh auth setup-git
   ```

2. Install the plugin:

   ```powershell
   claude plugin marketplace add https://github.com/Fudnut/agent-workers.git
   claude plugin install workers@agent-workers
   ```

3. Add the settings that a plugin cannot carry (Gemini workers only). Set `-ProjectRoot` to the folder that holds your projects:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\.claude\plugins\marketplaces\agent-workers\setup.ps1" -ProjectRoot C:\Projects
   ```

4. Start a new Claude Code session.

### What `setup.ps1` changes

- `~\.claude\settings.json`: adds an auto mode rule. The rule allows `agy` to send task prompts and source files from every project in `-ProjectRoot` to Google Gemini, except secrets, credentials and personal data. Choose a narrow folder.
- `~\.gemini\antigravity-cli\settings.json`: allows `ls`, `cat`, `grep`, `rg`, `git status`, `git diff` and `git log`. This list is not a strict read-only guarantee.

It adds only missing entries, makes a backup of an existing file before it changes it, and stops without changes if the JSON is not valid. You can run it again safely. If you run it with a different `-ProjectRoot`, it adds a second rule and keeps the first.

## Use

Send one task to a worker:

```text
/workers:use hydrogen Summarize each Markdown file in docs (top level only) in one line. Change nothing.
/workers:use neon Add input validation to src/parse.py and run its tests.
/workers:use deepseek Rename the --out option to --output in the CLI and its tests.
```

Set the worker for the session:

```text
/workers:use deepseek for the rest of the session
```

Good to know:

- **No worker named:** the session worker does the task. If you set none, Claude asks.
- **Project rules:** if the project's `AGENTS.md` or `CLAUDE.md` names another worker, Claude asks first.
- **Failure:** if any worker except Sonnet fails (error, FAIL, PARTIAL, TIMEOUT, quota or provider error), the step goes to a Sonnet sub-agent without a question, and Claude reports the switch. This uses Claude allowance. If Sonnet fails, Claude asks.
- **Refusals:** a consent or permission refusal is not a failure. Claude stops and asks.
- **Antigravity edits the working tree directly.** Review `git diff` and untracked files before you commit.
- **Say the scope exactly:** for example, "top level only" or "include subfolders". Workers can read the same words differently. Check the output: a worker can read only part of a long file.
- **Large tasks:** each Antigravity run has a fixed overhead, so use it for large tasks.
- **9-minute limit:** Claude's Bash tool stops a foreground command after 10 minutes, so the wrapper tells `agy` to stop at 9. Split longer tasks. A timeout can leave partial edits.
- **`SUCCESS` is not proof:** `agy` can report it although a command inside the run failed. Check the result.
- **Commands:** do not treat the `agy` allow list as a barrier. An Orchestrator test run reported running a command that is not on it.
- **Permission rule:** do not add `Bash(agy *)` to Claude's `permissions.allow`. It skips the auto mode check.

### Orchestrators

`orch-neon` and `orch-carbon` send the brief to an Antigravity orchestrator, which plans and does the steps itself in one run. Your Claude session stays in charge: it talks to you, reviews, commits and merges.

- Use `neon` or `carbon` for one clear coding task. Use an Orchestrator for several dependent steps.
- The whole job must fit in the 9-minute limit, planning included.
- You see the result, not each step, and Claude cannot correct it part-way. Start from a clean working tree.
- Prefer a single task to a whole session.

## Troubleshooting

Run `agy` directly to see if the problem is in `agy` or in the plugin. A sign-in or trust question means that first-run setup is not done: run `agy` alone and answer it.

```powershell
agy -p "say OK" --model gemini-4-hydrogen-medium --output-format json --print-timeout 2m
```

To check that the auto mode rule loaded:

```powershell
claude auto-mode config
```

A slow run is not always stuck: a 756-file summary took more than 10 minutes.

## Update

```powershell
claude plugin marketplace update agent-workers
claude plugin update workers@agent-workers
```

Start a new session afterwards.

## Uninstall

```powershell
claude plugin uninstall workers@agent-workers
claude plugin marketplace remove agent-workers
```

Uninstall does not remove the entries that `setup.ps1` added. Remove them from the two settings files, or restore the backups if you made no later changes.

## Status

`hydrogen` read-only runs passed on two computers (2026-11-25). Not tested yet through the plugin: the other workers (Orchestrators included), code changes, and the rollover to Sonnet.
