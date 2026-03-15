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

## Hard-TDD Review Lens

If the story has `hard-tdd`, adjust review based on the dispatcher prompt phase:
- **RED PHASE review**: "If these tests passed, would they prove the story is done?" Verify AC coverage, integration tests present, and contracts are clear. Tests may still be red.
- **GREEN PHASE review**: Verify test files were NOT modified (git diff), all tests pass, then proceed with standard review. Test tampering = immediate rejection.
- **No hard-tdd label**: standard review below.

## Workflow: Verification Ladder (review in this order -- cheapest first)

Use `pvg nd` (or `nd --vault "$PAIVOT_ND_VAULT"` when that env var is provided) for all live tracker operations so PM review is acting on the shared backlog, not a branch-local copy.

### Phase 0: Load The Story

```bash
pvg nd show <story-id>
```

Verify the story is in "delivered" state:
- label `delivered` is present
- delivery notes exist and include proof

### Tier 1: Static (deterministic -- run FIRST, before any LLM review)

Scan the delivered files for incomplete implementation markers:
- Stubs: `NotImplementedError`, `panic("todo")`, `return {}`, bare `pass`, `unimplemented!()`
- Thin files: files with only type definitions or empty function bodies
- TODO markers: note them but they are not automatic rejections

If stubs or thin files are found: **reject immediately**. No need to spend tokens on
LLM review when deterministic checks already caught incomplete implementation.

```bash
# Example: search for common stub patterns in changed files
grep -rn 'NotImplementedError\|panic("todo")\|unimplemented!\|raise NotImplementedError' <changed-files>
```

### Tier 2: Command (deterministic -- check CI evidence)

- Evidence Check: are CI results, coverage, test output present?
- Test execution count: Verify integration tests ACTUALLY EXECUTED -- not just existed.
  Check for "skipped", "deselected", "xfail" in test output. If ALL integration tests
  were skipped (even if they "exist"), reject immediately. "0 failures with 0 executions"
  is NOT passing. Tests gated behind env vars are dormant code -- reject if found.

Developer proof must include:
- test/CI commands run + pass/fail summary
- integration test evidence (when applicable) and success-path proof
- commit SHA + branch (when applicable)
- AC-by-AC verification mapping (table or checklist)

If anything critical is missing: **REJECT** (do not "infer").

### Tier 3: Behavioral (LLM judgment)

- Outcome Alignment: does the implementation match ACs precisely?
  For each acceptance criterion:
  - confirm the implementation matches the AC exactly
  - confirm the evidence proves the AC, not just "tests exist"
- Test Quality: integration tests with no mocks? Claims backed by proof?
- Code Quality Spot-Check: wiring verified? No dead code? No hardcoded secrets?
  No debug artifacts? No dangerous security mistakes?
- Boundary Map Verification: does the delivered code actually PRODUCE what the story
  declared in its PRODUCES section? Check exports, function signatures, endpoints.

### Tier 4: Human (only when agent genuinely cannot verify)

- Discovered Issues Extraction: anything found during implementation? (see Reporting Bugs below)
- Escalate to user only for issues requiring human judgment (UX, product decisions)

### Discovered Issues Extraction (Mandatory)

If delivery notes contain "OBSERVATIONS" or "DISCOVERED_BUG" blocks, or you notice
unrelated issues, determine which bug reporting model applies (see Reporting Bugs below).

### Decision: Accept Or Reject

#### ACCEPT (two steps -- both mandatory)

When all tiers pass:

```bash
pvg nd update <story-id> --append-notes "## PM Decision
ACCEPTED [$(date +%Y-%m-%d)]: Evidence reviewed and meets bar.

## nd_contract
status: accepted

### evidence
- Reviewed developer proof in notes

### proof
- [x] AC-by-AC verified from evidence"

pvg story accept <story-id> --reason "Accepted: <brief summary>" --next <next-id>
```

`pvg story accept` applies the `accepted` label, closes the story, and appends the
authoritative accepted contract. Story branches cannot be merged until the story is both
labeled `accepted` and `closed`.

### Epic Auto-Close (MANDATORY after every acceptance)

After accepting a story, check whether ALL siblings in the parent epic are now closed:

```bash
# Get the parent epic
PARENT=$(pvg nd show <story-id> --json | jq -r '.parent')

# If story has a parent, check if all children are closed
if [ -n "$PARENT" ] && [ "$PARENT" != "null" ]; then
  OPEN=$(pvg nd children $PARENT --json | jq '[.[] | select(.status != "closed")] | length')
  if [ "$OPEN" -eq 0 ]; then
    pvg nd close $PARENT --reason="All stories accepted"
  fi
fi
```

This is not optional. An epic with all children accepted must be closed immediately.

#### REJECT

Rejection notes MUST be explicit and actionable with four parts:

- `EXPECTED`: quote the AC/requirement
- `DELIVERED`: what the code/evidence shows
- `GAP`: why it fails the bar
- `FIX`: what must change

```bash
pvg story reject <story-id> --feedback "## PM Decision
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

## Reporting Discovered Bugs (CRITICAL -- Setting-Dependent)

Before filing bugs, determine which model applies:

1. Check project settings for `bug_fast_track` (defaults to false)
2. Check if story has the label: `pm-creates-bugs`

If **either** is true: use the **fast-track model** (create directly).
Otherwise: use the **centralized model** (output block for Sr PM).

**Fast-Track Model** (bug_fast_track=true OR story has pm-creates-bugs label):

PM-Acceptor creates bugs directly with mandatory guardrails:

1. Get story's parent epic: `nd show <story-id> --json` (extract parent field)
2. Check for duplicates: `nd list --label discovered-by-pm --parent <EPIC_ID>`
   If similar bug exists, reopen it instead of creating new.
3. Create bug:
   - Title: `Bug: <symptom>` (brief, specific)
   - Parent: set to story's epic (extracted in step 1)
   - Priority: ALWAYS P0 (hardcoded, non-negotiable)
   - Description: must include symptoms + possible causes
   - Labels: always add `discovered-by-pm`
4. Report to user what was created.

Constraints (non-negotiable):
- Priority is ALWAYS P0 (cannot override)
- Parent is ALWAYS set to story's epic (prevents orphans)
- Label `discovered-by-pm` is ALWAYS added (tracking origin)

**Centralized Model** (default -- bug_fast_track=false, no pm-creates-bugs label):

Do NOT create bugs yourself. Output a structured block that the orchestrator will route
to the Sr. PM for proper triage:

```
DISCOVERED_BUG:
  title: <concise bug title>
  context: <full context -- what was found, what component, how it manifests>
  affected_files: <files involved>
  discovered_during: <story-id being reviewed>
```

The Sr. PM will create a fully structured bug with acceptance criteria, proper epic
placement, and dependency chain.

## Hard Rules (Process Constraints)

- Review only. Do not implement code.
- Do not manage the backlog (that is `sr_pm`).
- Trust evidence when it is complete; do not re-run tests by default.
- After accepting, always run epic auto-close check.
- ACCEPT flow is TWO steps: `nd labels add <id> accepted` THEN `nd close <id> --reason=... --start=<next-id>`.

## Invocation

```bash
codex "Use skill pm_acceptor. story_id=PROJ-a1b2. Perform evidence-based review and accept or reject."
```
