---
name: orchestrator
description: Manual dispatcher for Paivot personas in Codex. Uses bd stories as the single source of truth, enforces the status/evidence/proof contract, and tells you exactly which skill to run next.
---

# Orchestrator (Manual)

## Purpose

The original Paivot workflow spawned personas automatically and used an external FSM to enforce correct sequencing. In this Codex Skills migration, that enforcement is not present. This skill preserves intent by manually orchestrating personas via `bd` story state.

**Hard rule:** the orchestrator does not implement code. It only decides what persona to run next and what updates must be written back into `bd`.

Notes:
- Codex skills are **not** independent subagents. If you want parallel execution, run multiple Codex sessions in parallel and coordinate solely via `bd`.
- `bd` evolves quickly. Treat `bd --help` as authoritative for the exact command/flag syntax.

## Inputs

Provide one of:
- `epic_id` (optional): `bd-...` epic you want to drive to completion
- `story_id` (optional): `bd-...` story you want to advance
- If neither is provided: orchestrate by selecting the next ready story from `bd`

Environment:
- Preferred: a repo with `.beads/` so `bd` commands work
- Fallback: paste story/epic text if `bd` is not available

## Contract: Status + Evidence + Proof (Required)

All personas coordinate through the `bd` story notes:

```markdown
## bd_contract
status: <new|in_progress|delivered|accepted|rejected>

### evidence
- ...

### proof
- [ ] AC #1: ...
```

## D&F Gate (Mandatory In Greenfield)

For greenfield work, Discovery & Framing is a hard gate. Do not move into implementation backlog authoring until D&F is complete.

Completion criteria:
- `docs/BUSINESS.md`, `docs/DESIGN.md`, and `docs/ARCHITECTURE.md` exist.
- Their corresponding D&F stories are `accepted` (and typically closed) by `pm_acceptor`.
- `anchor` backlog review has an explicit APPROVED verdict after `sr_pm` creates the backlog.

Hard prohibition:
- Do **not** run `sr_pm` to decompose implementation stories before D&F completion criteria are met.
- Do **not** run `developer` on implementation stories before the above + Anchor APPROVED.

## Decision Rules (What To Run Next)

1. **If there are delivered stories awaiting review**
   - Condition: `bd list --status in_progress --label delivered`
   - Next skill: `pm_acceptor`

2. **If there are rejected stories**
   - Condition: `bd list --status open --label rejected`
   - Next skill: `developer` (rework the specific rejected story)

3. **If there is ready work**
   - Condition: `bd ready` (blocker-aware; preferred over `bd list --ready`)
   - Next skill: `developer` (pick highest priority ready story)

4. **If backlog quality is preventing execution (post-D&F only)**
   - Condition: D&F is complete and accepted, but stories still lack context, ACs, testing requirements, or integration wiring
   - Next skill: `sr_pm` (repair story quality; make stories self-contained)

5. **If you are in Discovery & Framing (greenfield) and D&F is not complete**
   - Next skills (strict order): `business_analyst` -> `designer` -> `architect`
   - Loop each through `pm_acceptor` until accepted before advancing.

6. **If greenfield D&F is complete**
   - Next skills (strict order): `sr_pm` -> `anchor`
   - Only after Anchor APPROVED should implementation developer loops begin.

7. **If a milestone epic is complete (all stories accepted)**
   - Next skill: `retro`

## Invocation (Codex CLI Prompt Convention)

Use one prompt per step and be explicit about IDs.

```bash
codex "Use skill orchestrator. epic_id=bd-1234. Determine the next persona to run based on bd state and tell me exactly which skill to invoke next."
```

Then run the recommended persona:

```bash
codex "Use skill developer. story_id=bd-5678. Implement exactly this story and write evidence+proof to bd. Set status delivered."
```

```bash
codex "Use skill pm_acceptor. story_id=bd-5678. Review evidence only and accept or reject. Update bd status accordingly."
```

## Required bd Operations (When Available)

The orchestrator should use these commands to drive decisions:

```bash
bd sync
bd ready --pretty
bd list --status in_progress --label delivered --pretty
bd list --status open --label rejected --pretty
bd show <story-id> --json
```

If `bd` is not available, the orchestrator must request the story text and current labels/status pasted into the chat and proceed in “paste mode”.
