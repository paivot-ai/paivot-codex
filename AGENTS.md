# Paivot Codex Skills (Manual Orchestration)

This repo contains Codex Skills migrated from the Paivot Claude agents. The skills live under `.agents/skills/`.

## Global Install

This repo can install the skills and a global `AGENTS.md` into a Codex home directory (default: `~/.codex`):

```bash
make install-global
```

To install somewhere else:

```bash
make install-global CODEX_HOME=/path/to/codex-home
```

The installed global methodology doc is sourced from `AGENTS.global.md`.

## Capabilities + Limits (Codex)

- **Single runner**: Codex does not spawn truly independent subagents with isolated context inside one run. Persona “skills” are instruction sets, not separate processes.
- **Parallelism**: we can run shell/file operations in parallel, and you can run multiple Codex invocations in parallel in separate terminals/sessions. Coordination is via `bd` only.
- **Context discipline**: each skill must re-load the story from `bd` (or pasted story text) and treat it as the only source of truth.

> `bd` evolves quickly. Treat `bd --help` as authoritative for flags/commands and update these templates when syntax changes.

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

**Append-only rule:** use `bd update <id> --append-notes "<block>"` for contract/evidence/proof. If multiple `bd_contract` blocks exist, **the last one is authoritative**.

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

## No FSM Enforcer (`piv`)

Unlike some Claude/OpenCode setups, **Codex does not use the external FSM enforcer (`piv`)**. We rely on:
- strict skill boundaries
- `bd` as the single source of truth
- the `bd_contract` evidence/proof bar

Orchestration is manual via the `orchestrator` skill and `bd` story state.

## Git Workflow (Beads-Native, Trunk-Based)

**Paivot uses trunk-based development via `beads-sync`. NO epic branches. NO feature branches per story.**

Why: Beads’ hash IDs (`bd-a1b2`) + merge semantics are designed for concurrent work on a shared branch. Feature/epic branching defeats that architecture.

Branch structure:
- `main`: protected, merges via PR
- `beads-sync`: shared sync branch where **all** story work is committed
- branches only for long experiments (> 1 week, may discard): requires `BEADS_NO_DAEMON=1` (the daemon does not handle branching workflows reliably)

Operational rules:
- Stories are tracked in `bd`, not in git branches.
- If you want parallel execution, run multiple Codex sessions in parallel, each implementing a separate story, all committing to `beads-sync`.
- Use `bd sync` before/after critical operations to force immediate synchronization.

See `paivot-codex/docs/GIT_WORKFLOW.md` for the consolidated workflow.

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
