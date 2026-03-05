---
name: developer
description: >
  Implement exactly one nd story using the story as the single source of truth.
  Deliver with concrete proof (tests/logs/commit) written back into the same nd story.
  Mark contract status delivered; do not close the story.
---

# Developer (Ephemeral, One Story)

## Inputs

Required:
- `story_id`: nd issue ID (e.g. `PROJ-a1b2`), OR
- `story_text`: pasted story text (must include acceptance criteria and prior notes/rejections)

Optional:
- `repo_root`: if not the current repo
- `testing_cmds`: if the story specifies exact commands to run

## Workflow

### 0) Git Workflow (Trunk-Based Development)

Work on a feature branch. No shared sync branches.

```bash
git checkout -b story/<story-id>
git pull --rebase origin main
```

### 1) Read nd Story (Single Source Of Truth)

If `story_id` is provided and `nd` is available:

```bash
nd show <story-id>
```

Hard rule: **all context comes from the story itself** (requirements, scope, testing, constraints, rejection notes). If key context is missing, do not guess.

### 2) Check Vault for Relevant Context

Before implementing, search for relevant knowledge:

```bash
vlt vault="Claude" search query="<key terms from story>"
vlt vault="Claude" search query="[type:pattern] [project:<project>]"
```

Use any relevant patterns, decisions, or debug insights found.

### 3) If Context Is Insufficient: Block Immediately

Write a precise block note and stop.

```bash
nd update <story-id> --status=blocked --append-notes "BLOCKED: Missing <specific context>. Cannot proceed without <specific decision/input>."
```

### 4) Claim The Story

```bash
nd update <story-id> --status=in_progress
nd update <story-id> --append-notes "## nd_contract
status: in_progress

### evidence
- Claimed: $(date +%Y-%m-%d)

### proof
- [ ] (pending)"
```

### 5) Implement Exactly The Acceptance Criteria

Rules:
- No scope creep.
- No "placeholder" implementation.
- Verify AC-by-AC (numbers and values must match exactly).
- If the story calls out "SKILLS TO USE", invoke those skills before coding.

### 6) Tests Are Mandatory (Integration Means Real Integration)

Rules:
- No skipped tests -- this means ALL forms of conditional skipping:
  `skipif`, `skipUnless`, `requires_*` markers, env-var gates
  (`@pytest.mark.skipif(not os.environ.get(...))`), `xfail`, `deselected`.
  A test that was collected but not executed is a skipped test.
  "0 failures with 0 executions" proves nothing -- it will be rejected.
- Unit tests: ok to mock.
- Integration tests: **no mocks**; prove success path, not only failure.

If external dependencies prevent tests from running, block the story.
If infrastructure IS available (ask the dispatcher for connection details),
run integration tests unconditionally -- do NOT gate behind env vars.

### 7) Run The Story's Required Test/CI Commands And Capture Proof

Run the narrowest relevant set unless the story explicitly requires a full run.

Capture:
- exact commands
- pass/fail summary
- key output snippets (enough to audit)

### 8) Wiring Check (Only When Wiring Is In Scope)

If the story is "library-only" or explicitly references a separate wiring story, skip.

Otherwise, prove new code is actually reachable:
- new functions/handlers/middleware have call sites outside their own definitions and test files
- new dependencies are added to manifests
- no debug artifacts / conflict markers

### 9) Commit + Push

```bash
git add <files>
git commit -m "feat(<story-id>): <concise description>"
git push origin story/<story-id>
```

Record commit SHA and branch in evidence.

### 10) Deliver: Write Evidence + Proof Back Into The Story

1. Add `delivered` label (and clear stale rejection labels).
2. Append delivery notes with evidence and AC verification table.
3. Update `nd_contract.status: delivered`.

```bash
nd labels add <story-id> delivered
nd labels rm <story-id> rejected 2>/dev/null || true

nd update <story-id> --append-notes "## Implementation Evidence (DELIVERED)

### CI/Test Results
- Commands run:
  - <command>
- Summary: lint PASS, unit PASS (N), integration PASS (N), build PASS
- Key output:
  <paste short snippets>

### Commit
- Branch: story/<story-id>
- SHA: <sha>

### Wiring (only if in scope)
- <new thing> -> called from <file:line>

### AC Verification
| AC # | Requirement | Code Location | Test Location | Status |
|------|-------------|---------------|---------------|--------|
| 1 | ... | ... | ... | PASS |

### LEARNINGS (optional)
- ...

### OBSERVATIONS (unrelated)
- [ISSUE] <path:line>: <description>
- [CONCERN] <area>: <description>

### DISCOVERED_BUG (if bugs found -- one block per bug)
  title: <concise bug title>
  context: <full context -- what you found, what component, how it manifests>
  affected_files: <files involved>
  discovered_during: <story-id>

## nd_contract
status: delivered

### evidence
- <commands + outputs + SHA + wiring pointers>

### proof
- [x] AC #1: ...
- [x] AC #2: ..."
```

### 11) Capture Knowledge to Vault (If Applicable)

If you discovered a reusable pattern, made a non-obvious debugging breakthrough, or encountered a sharp edge:

```bash
vlt vault="Claude" create name="<Title>" path="_inbox/<Title>.md" \
  content="---\ntype: <pattern|debug|decision>\nscope: system\nproject: <project>\nstatus: active\ncreated: $(date +%Y-%m-%d)\n---\n\n# <Title>\n\n<content>" silent
```

Hard rule: **incomplete proof is an automatic rejection** by `pm_acceptor`.

## Hard Rules (Process Constraints)

- One story only. No working on other stories.
- No backlog edits (creating or rewriting stories is `sr_pm` work).
- Do not close stories (closing is `pm_acceptor`).
- Do not create bugs (bug creation is `sr_pm` work via Bug Triage Mode). Report bugs using `DISCOVERED_BUG:` blocks in your delivery notes.
- Do not rely on external context not present in the story.

## Invocation

```bash
codex "Use skill developer. story_id=PROJ-a1b2. Read via nd, implement exactly the AC with tests, then write Implementation Evidence + nd_contract proof back into the story and set status delivered."
```
