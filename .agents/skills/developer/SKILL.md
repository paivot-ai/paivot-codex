---
name: developer
description: Implement exactly one bd story using the story as the single source of truth. Deliver with concrete proof (tests/logs/commit) written back into the same bd story. Mark contract status delivered; do not close the story.
---

# Developer (Ephemeral, One Story)

## Inputs

Required:
- `story_id`: `bd-...` (preferred), OR
- `story_text`: pasted story text (must include acceptance criteria and prior notes/rejections)

Optional:
- `repo_root`: if not the current repo
- `testing_cmds`: if the story specifies exact commands to run

## Workflow

### 0) Git Workflow (Beads-Native, Trunk-Based)

**All story work commits go to `beads-sync`. No epic branches. No feature branches per story.**

If this repo uses git and has a `beads-sync` branch:

```bash
git checkout beads-sync
git pull --rebase origin beads-sync
```

### 1) Read bd Story (Single Source Of Truth)

If `story_id` is provided and `bd` works:

```bash
bd sync
bd show <story-id> --json
```

Hard rule: **all context comes from the story itself** (requirements, scope, testing, constraints, rejection notes). If key context is missing, do not guess.

### 2) If Context Is Insufficient: Block Immediately

Write a precise block note (what is missing and why it prevents implementation) and stop.

```bash
bd update <story-id> --status blocked --append-notes "BLOCKED: Missing <specific context>. Cannot proceed without <specific decision/input>."
bd sync
```

### 3) Claim The Story

```bash
bd update <story-id> --claim
bd update <story-id> --append-notes \"## bd_contract\nstatus: in_progress\n\n### evidence\n- Claimed (atomic): <YYYY-MM-DD>\n\n### proof\n- [ ] (pending)\"
bd sync
```

If `--claim` fails because the story is already claimed, stop and do not proceed.

### 4) Implement Exactly The Acceptance Criteria

Rules:
- No scope creep.
- No “placeholder” implementation.
- Verify AC-by-AC (numbers and values must match exactly).
- If the story calls out “SKILLS TO USE”, you must invoke those skills before coding.

### 5) Tests Are Mandatory (Integration Means Real Integration)

Rules:
- No skipped tests.
- Unit tests: ok to mock.
- Integration tests: **no mocks**; prove success path, not only failure.

If external dependencies prevent tests from running (missing keys, down services), block the story. Do not “soften” tests to make them pass.

### 6) Run The Story’s Required Test/CI Commands And Capture Proof

Run the narrowest relevant set unless the story explicitly requires a full run.

Capture:
- exact commands
- pass/fail summary
- key output snippets (enough to audit)

### 7) Wiring Check (Only When Wiring Is In Scope)

If the story is “library-only” or explicitly references a separate wiring story, do not wire up.

Otherwise, prove new code is actually reachable:
- new functions/handlers/middleware have call sites outside their own definitions and test files
- new dependencies are added to manifests
- no debug artifacts / conflict markers

### 8) Commit + Push (If This Repo Uses Git)

Record commit SHA and branch in evidence.

Trunk-based default:

```bash
git status
git rev-parse --abbrev-ref HEAD   # should be beads-sync
git rev-parse HEAD                # record SHA
git push origin beads-sync
```

### 9) Deliver: Write Evidence + Proof Back Into The Story And Mark Delivered

1. Add `delivered` label (and clear stale rejection labels if present).
2. Append delivery notes containing evidence and an AC verification table.
3. Update `bd_contract.status: delivered`.

```bash
bd update <story-id> --remove-label rejected --remove-label verification-failed --add-label delivered
bd update <story-id> --append-notes \"## Implementation Evidence (DELIVERED)\n\n### CI/Test Results\n- Commands run:\n  - <command>\n  - <command>\n- Summary: lint PASS, unit PASS (N), integration PASS (N), build PASS\n- Key output:\n  <paste short snippets>\n\n### Commit\n- Branch: beads-sync\n- SHA: <sha>\n\n### Wiring (only if in scope)\n- <new thing> -> called from <file:line>\n\n### AC Verification\n| AC # | Requirement | Code Location | Test Location | Status |\n|------|-------------|---------------|---------------|--------|\n| 1 | ... | ... | ... | PASS |\n\n### LEARNINGS (optional)\n- ...\n\n### OBSERVATIONS (unrelated)\n- [ISSUE] <path:line>: <description>\n- [CONCERN] <area>: <description>\n\n## bd_contract\nstatus: delivered\n\n### evidence\n- <commands + outputs + SHA + wiring pointers>\n\n### proof\n- [x] AC #1: ...\n- [x] AC #2: ...\"
bd sync
```

Hard rule: **incomplete proof is an automatic rejection** by `pm_acceptor`.

## Outputs / Evidence

The only accepted output is a `bd` story updated with:
- `delivered` label
- “Implementation Evidence (DELIVERED)” section
- `bd_contract` status/evidence/proof updated to `delivered`

## Hard Rules (Process Constraints)

- One story only. No working on other stories.
- No backlog edits (creating or rewriting stories is `sr_pm` work).
- Do not close stories (closing is `pm_acceptor`).
- Do not rely on external context not present in the story.

## Invocation (Codex CLI Prompt Convention)

```bash
codex "Use skill developer. story_id=bd-1234. Read via bd, implement exactly the AC with tests, then write Implementation Evidence + bd_contract proof back into the story and set status delivered."
```
