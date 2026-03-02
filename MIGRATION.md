# Claude Agents -> Codex Skills Migration (Paivot)

This folder (`paivot-codex/`) is the Codex Skills version of the Paivot agent set.

The original system relied on `Task()` spawning personas plus an external Go FSM + hooks for enforcement. In this Codex migration:
- we do **not** use the external FSM enforcer (`piv`)
- we preserve intent using `bd` story state plus strict evidence/proof conventions

> `bd` evolves quickly. Treat `bd --help` as authoritative for flags/commands.

## What Was Migrated

- Source personas: `paivot-claude/agents/*.md`
- Destination skills: `paivot-codex/.agents/skills/*/SKILL.md`

## Git Workflow (Beads-Native, Trunk-Based)

**Paivot uses trunk-based development via `beads-sync`. NO epic branches. NO feature branches per story.**

Key principle: stories are tracked in `bd`, not in git branches. To parallelize, run multiple Codex sessions in parallel (separate terminals), each implementing a different story, all committing to `beads-sync`.

Branches are allowed only for long experiments (> 1 week, may discard), and require `BEADS_NO_DAEMON=1`.

## How To Run A Skill (Codex CLI Prompt Convention)

Use a single prompt that explicitly names the skill and provides inputs. Example patterns:

```bash
codex "Use skill orchestrator. Decide what to run next for story bd-1234 (or pick the next ready story)."
```

```bash
codex "Use skill developer. story_id=bd-1234. Read the bd story, implement exactly its AC, then write evidence+proof back and set status delivered."
```

```bash
codex "Use skill pm_acceptor. story_id=bd-1234. Review evidence only and accept or reject; update bd with decision and reasons."
```

If `bd` is not available in the current environment, provide `story_text=` instead of `story_id=` and apply updates manually.

## How To Run Each Skill

1. `orchestrator`
```bash
codex "Use skill orchestrator. epic_id=bd-1234 (optional). Based on bd state, tell me exactly which persona skill to run next and which story_id to use."
```

2. `developer`
```bash
codex "Use skill developer. story_id=bd-1234. Implement exactly the story, then write Implementation Evidence + bd_contract proof back into bd and set status delivered."
```

3. `pm_acceptor`
```bash
codex "Use skill pm_acceptor. story_id=bd-1234. Evidence-based review only; accept or reject and update bd labels/status and bd_contract."
```

4. `sr_pm`
```bash
codex "Use skill sr_pm. mode=direct_invocation. Create/repair self-contained bd stories for: <paste requirement>."
```

5. `business_analyst`
```bash
codex "Use skill business_analyst. problem_statement='<paste>'. Ask multi-round questions, then update docs/BUSINESS.md and produce backlog inputs for sr_pm."
```

6. `designer`
```bash
codex "Use skill designer. product_context='<paste>'. Update docs/DESIGN.md and produce testable design requirements for sr_pm."
```

7. `architect`
```bash
codex "Use skill architect. proposal='<paste>'. Update docs/ARCHITECTURE.md and produce architecture constraints/integration points for sr_pm."
```

8. `anchor`
```bash
codex "Use skill anchor. mode=backlog_review. epic_id=bd-1234. Return APPROVED or REJECTED and write a structured gaps list back into bd."
```

9. `retro`
```bash
codex "Use skill retro. epic_id=bd-1234. Harvest learnings from accepted stories and write a structured retro summary into bd epic notes."
```

## Simulating Task()/FSM Semantics With bd

### Single Source Of Truth

All context lives in the `bd` story:
- description + acceptance criteria
- notes (delivery evidence, rejections, learnings)
- labels (delivered/accepted/rejected)

Personas must not rely on unstated memory. If it is not in `bd`, it is not real.

### Contract Fields (Write Into Story Notes)

Every skill interaction must maintain this contract in story notes:

```markdown
## bd_contract
status: <new|in_progress|delivered|accepted|rejected>

### evidence
- ...

### proof
- [ ] AC #1: ...
```

### Status + Label Mapping

`bd` has its own built-in statuses (`open`, `in_progress`, `blocked`, `deferred`, `closed`). We preserve the Paivot semantics by using labels plus the `bd_contract` status:

- Contract `new`:
  - `bd` status: `open`
  - labels: none required

- Contract `in_progress`:
  - `bd` status: `in_progress`

- Contract `delivered`:
  - `bd` status: `in_progress` (still open, not closed)
  - label: `delivered`

- Contract `accepted`:
  - `bd` status: `closed`
  - label: `accepted` (and remove `delivered`)

- Contract `rejected`:
  - `bd` status: `open`
  - label: `rejected` (and remove `delivered`)

### Manual Orchestration Loop

1. Pick work:
   - `bd sync`
   - `bd ready --pretty` (or `bd ready --json`)

2. Run `developer` on exactly one story.
3. When the story is delivered (label `delivered` + evidence/proof in notes), run `pm_acceptor`.
4. If accepted, story is closed.
5. If rejected, the story returns to `open` with actionable rejection notes; run `developer` again.

The `orchestrator` skill describes the exact handoff rules.

## PM Acceptance Evidence/Proof Format (What “Delivered” Must Contain)

`developer` must append an “Implementation Evidence” section that includes:

- CI/test commands actually run (exact commands)
- pass/fail summary and key output snippets (enough for audit)
- integration test evidence (real integration; no mocks in integration tests)
- commit SHA and branch (if applicable)
- AC-by-AC verification table mapping each AC to code + tests
- “Wiring” evidence when wiring is in scope (where new code is actually called)
- optional “LEARNINGS” and “OBSERVATIONS”

`pm_acceptor` will accept/reject using only this evidence plus the story’s ACs.

## Optional: Proof Lint (Local Helper)

To reduce PM rejection churn due to missing proof fields:

```bash
paivot-codex/verify-delivery.sh <story-id>
```
