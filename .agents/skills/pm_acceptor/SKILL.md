---
name: pm_acceptor
description: Evidence-based review for one delivered bd story. Accept (close) or reject (reopen) using the developer's recorded proof. Update bd_contract status accepted/rejected and record explicit reasons and missing evidence when rejecting.
---

# PM-Acceptor (Ephemeral, One Story)

## Inputs

Required:
- `story_id`: `bd-...` (preferred), OR
- `story_text`: pasted story text including delivery evidence and ACs

Optional:
- `epic_id`: if you need to file discovered issues as children of an epic

## Core Principle: Evidence-Based Review

The developer’s recorded proof in the story notes is the primary verification artifact.

Hard rules:
- If proof is complete and trustworthy: **do not re-run tests**.
- Re-run tests only when proof is missing, inconsistent, suspicious, or you have a specific doubt.
- Integration tests are mandatory when a story claims integration behavior; integration tests must not use mocks.

## Workflow (5 Phases)

### Phase 0: Load The Story

```bash
bd sync
bd show <story-id> --json
```

Verify the story is actually in “delivered” state:
- label `delivered` is present
- delivery notes exist and include proof

### Phase 1: Evidence Check (Reject Early If Incomplete)

Developer proof must include:
- test/CI commands run + pass/fail summary
- integration test evidence (when applicable) and success-path proof
- commit SHA + branch (when applicable)
- AC-by-AC verification mapping (table or checklist)

If anything critical is missing: **REJECT** (do not “infer”).

### Phase 2: Outcome Alignment (AC-By-AC)

For each acceptance criterion:
- confirm the implementation matches the AC exactly (values, durations, error codes, formats)
- confirm the evidence proves the AC, not just “tests exist”

### Phase 3: Test Quality Review (Reject Mocked “Integration”)

Reject if:
- “integration tests” are mocked
- tests prove only failures and never success
- tests are trivial or non-verifying

### Phase 4: Code Quality Spot-Check

Look for obvious blockers:
- hardcoded secrets
- debug artifacts left in
- incomplete refactors / dead code
- dangerous security mistakes

### Phase 4.5: Discovered Issues Extraction (Mandatory)

If delivery notes contain “OBSERVATIONS” or you notice unrelated issues, file them as separate bd issues so they are tracked.

Example:

```bash
bd create \"Bug: <clear title>\" -t bug -p 2 -d \"Discovered during PM review of <story-id>: <details>\" --json
bd dep add <new-issue-id> <story-id> --type discovered-from
```

### Phase 5: Decision (Accept Or Reject)

#### ACCEPT

When all phases pass:

```bash
bd update <story-id> --remove-label delivered --add-label accepted
bd update <story-id> --append-notes \"## PM Decision\nACCEPTED [YYYY-MM-DD]: Evidence reviewed and meets bar.\n\n## bd_contract\nstatus: accepted\n\n### evidence\n- Reviewed developer proof in notes\n\n### proof\n- [x] AC-by-AC verified from evidence\"
bd close <story-id> --reason \"Accepted: <brief summary of what was verified>\"
bd sync
```

#### REJECT

Rejection notes MUST be explicit and actionable with four parts:

- `EXPECTED`: quote the AC/requirement
- `DELIVERED`: what the code/evidence shows
- `GAP`: why it fails the bar
- `FIX`: what must change

```bash
bd update <story-id> --status open --remove-label delivered --add-label rejected
bd update <story-id> --append-notes \"## PM Decision\nREJECTED [YYYY-MM-DD]:\nEXPECTED: ...\nDELIVERED: ...\nGAP: ...\nFIX: ...\n\n## bd_contract\nstatus: rejected\n\n### evidence\n- Missing/insufficient proof: <list>\n\n### proof\n- [ ] AC #<n>: <what is still unproven>\"
bd sync
```

Chronic rejection policy:
- If a story has 5+ rejections (count `REJECTED [` occurrences in notes), add label `cant_fix`, set `bd` status to `blocked`, and escalate to the orchestrator/user.

## Outputs

The bd story must end in exactly one of:
- Accepted: story closed + contract `status: accepted` + label `accepted`
- Rejected: story open + contract `status: rejected` + label `rejected` + actionable rejection notes

## Hard Rules (Process Constraints)

- Review only. Do not implement code.
- Do not manage the backlog (that is `sr_pm`).
- Trust evidence when it is complete; do not re-run tests by default.

## Invocation (Codex CLI Prompt Convention)

```bash
codex "Use skill pm_acceptor. story_id=bd-1234. Perform evidence-based review and accept or reject with explicit criteria. Update bd status/labels and bd_contract."
```
