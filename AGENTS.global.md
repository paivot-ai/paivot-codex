# Paivot Methodology (Global Codex Setup)

This file is a *global* reference for the Paivot “manual orchestration” workflow when using Codex.

The Paivot skills are installed under `~/.codex/skills/` (not per-repo). Repos may optionally carry their own `AGENTS.md`, but this doc is meant to be reusable across projects.

## The bd Contract (Status + Evidence + Proof)

All personas coordinate through a single source of truth: the `bd` story.

Each skill MUST keep a minimal contract inside the story notes (append-only), using these fields:

- `status`: one of `new`, `in_progress`, `delivered`, `accepted`, `rejected`
- `evidence`: commands run, logs/test output summaries, commit SHAs/branches, links if any
- `proof`: a structured checklist that a reviewer can evaluate (especially AC-by-AC)

Canonical notes block (copy/paste into `bd update <id> --append-notes ...`):

```markdown
## bd_contract
status: <new|in_progress|delivered|accepted|rejected>

### evidence
- <bullet list; include commands and key output summaries>

### proof
- [ ] AC #1: <verifiable statement> (Code: <path>, Test: <path>, Evidence: <link/snippet>)
- [ ] AC #2: ...
```

**Append-only rule:** prefer `bd update <id> --append-notes "<block>"`. If multiple `bd_contract` blocks exist, the last one is authoritative.

## Role Semantics (Preserved From Task()/FSM)

- `developer` skill:
  - reads the `bd` story as the only source of truth (or requests it pasted)
  - implements exactly that story
  - writes “Implementation Evidence” + the `bd_contract` block
  - sets contract `status: delivered` and adds the `delivered` label
  - does NOT close the story

- `pm_acceptor` skill:
  - reads the `bd` story + evidence only
  - accepts or rejects with explicit criteria
  - sets contract `status: accepted` or `rejected`
  - updates labels accordingly (`accepted` or `rejected`)
  - closes the story when accepted

The original Go FSM + Claude hooks are not part of this repo; orchestration is manual via the `orchestrator` skill and `bd` story state.

## Skills

- `orchestrator`: manual dispatcher for which persona to run next based on `bd` status/labels
- `developer`: implement one story and deliver with proof
- `pm_acceptor`: accept/reject one delivered story using evidence-based review
- `sr_pm`: create/repair backlog stories so they are self-contained and executable
- `business_analyst`, `designer`, `architect`: Discovery & Framing roles that produce/update docs and translate into backlog context
- `anchor`: adversarial backlog/milestone review (binary outcomes)
- `retro`: harvest learnings after an epic/milestone completes

## Using bd (Preferred) vs Paste Mode (Fallback)

If `bd` is available and the repo has a `.beads/` database, skills should use `bd show`, `bd update`, labels, and `bd sync`.

If `bd` is not available or the project is not a beads repo, skills will ask you to paste:
- the full story text (including ACs and any rejection notes)
- current status/labels
and you will update `bd` (or your tracker) manually.

## From CLAUDE.md

```
Please refer to @AGENTS.md for all other instructions. Follow them strictly and do not deviate.
```

## Optional Tooling: Delivery Proof Preflight

To reduce “rejected for missing evidence” churn, there is a lightweight verifier:

- Run: `~/.codex/tools/paivot/verify-delivery.sh <story-id>`
- Example: `~/.codex/tools/paivot/verify-delivery.sh bd-a1b2`

This only checks the presence/shape of delivery evidence in `bd` notes/labels; it does not validate code correctness.
