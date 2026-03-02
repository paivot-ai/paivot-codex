---
name: pm_acceptor
description: >
  Evidence-based review for one delivered nd story. Accept (close) or reject (reopen)
  using the developer's recorded proof. Update nd_contract status and record explicit
  reasons and missing evidence when rejecting.
---

# PM-Acceptor (Ephemeral, One Story)

## Inputs

Required:
- `story_id`: nd issue ID (e.g. `PROJ-a1b2`), OR
- `story_text`: pasted story text including delivery evidence and ACs

Optional:
- `epic_id`: if you need to file discovered issues as children of an epic

## Core Principle: Evidence-Based Review

The developer's recorded proof in the story notes is the primary verification artifact.

Hard rules:
- If proof is complete and trustworthy: **do not re-run tests**.
- Re-run tests only when proof is missing, inconsistent, suspicious, or you have a specific doubt.
- Integration tests are mandatory when a story claims integration behavior; integration tests must not use mocks.

## Workflow (5 Phases)

### Phase 0: Load The Story

```bash
nd show <story-id>
```

Verify the story is in "delivered" state:
- label `delivered` is present
- delivery notes exist and include proof

### Phase 1: Evidence Check (Reject Early If Incomplete)

Developer proof must include:
- test/CI commands run + pass/fail summary
- integration test evidence (when applicable) and success-path proof
- commit SHA + branch (when applicable)
- AC-by-AC verification mapping (table or checklist)

If anything critical is missing: **REJECT** (do not "infer").

### Phase 2: Outcome Alignment (AC-By-AC)

For each acceptance criterion:
- confirm the implementation matches the AC exactly
- confirm the evidence proves the AC, not just "tests exist"

### Phase 3: Test Quality Review (Reject Mocked "Integration")

Reject if:
- "integration tests" are mocked
- tests prove only failures and never success
- tests are trivial or non-verifying

### Phase 4: Code Quality Spot-Check

Look for obvious blockers:
- hardcoded secrets
- debug artifacts left in
- incomplete refactors / dead code
- dangerous security mistakes

### Phase 4.5: Discovered Issues Extraction (Mandatory)

If delivery notes contain "OBSERVATIONS" or you notice unrelated issues, file them:

```bash
nd create "Bug: <clear title>" -t bug -p 2 \
  -d "Discovered during PM review of <story-id>: <details>"
nd dep add <new-id> <story-id> --type relates
```

### Phase 5: Decision (Accept Or Reject)

#### ACCEPT

When all phases pass:

```bash
nd labels rm <story-id> delivered
nd labels add <story-id> accepted

nd update <story-id> --append-notes "## PM Decision
ACCEPTED [$(date +%Y-%m-%d)]: Evidence reviewed and meets bar.

## nd_contract
status: accepted

### evidence
- Reviewed developer proof in notes

### proof
- [x] AC-by-AC verified from evidence"

nd close <story-id> --reason="Accepted: <brief summary>"
```

#### REJECT

Rejection notes MUST be explicit and actionable with four parts:

- `EXPECTED`: quote the AC/requirement
- `DELIVERED`: what the code/evidence shows
- `GAP`: why it fails the bar
- `FIX`: what must change

```bash
nd update <story-id> --status=open
nd labels rm <story-id> delivered
nd labels add <story-id> rejected

nd update <story-id> --append-notes "## PM Decision
REJECTED [$(date +%Y-%m-%d)]:
EXPECTED: ...
DELIVERED: ...
GAP: ...
FIX: ...

## nd_contract
status: rejected

### evidence
- Missing/insufficient proof: <list>

### proof
- [ ] AC #<n>: <what is still unproven>"
```

Chronic rejection policy:
- If a story has 5+ rejections (count `REJECTED [` occurrences), add label `cant_fix`, set status to `blocked`, and escalate.

## Hard Rules (Process Constraints)

- Review only. Do not implement code.
- Do not manage the backlog (that is `sr_pm`).
- Trust evidence when it is complete; do not re-run tests by default.

## Invocation

```bash
codex "Use skill pm_acceptor. story_id=PROJ-a1b2. Perform evidence-based review and accept or reject."
```
