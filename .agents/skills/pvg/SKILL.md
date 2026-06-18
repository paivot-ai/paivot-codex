---
name: pvg
description: >
  Deterministic control plane for Paivot workflow operations. Use when the user
  mentions "pvg", dispatcher mode, loop control, crash recovery, shared nd vaults,
  story delivery/acceptance/rejection, merge gating, or project settings. Prefer
  `pvg nd`, `pvg loop next --json`, and `pvg story ...` over hand-built shell
  wrappers or remembered label choreography.
---

# pvg -- Paivot Workflow Control Plane

`pvg` owns the deterministic parts of Paivot that should not live only in prompts:

- shared live `nd` routing across worktrees
- next-step selection for dispatchers
- structural story transitions
- merge gating and recovery
- vault seeding, dispatcher mode, and workflow settings

## Start Here

```bash
pvg version
pvg help
```

If `pvg` is missing or too old, stop and report that before trying to improvise the workflow manually.

## Core Rules

1. Use `pvg issues ...` (provider-abstracted) for live tracker operations so every worktree sees the same backlog. Use `pvg nd ...` only for nd-specific operations (e.g. `--append-notes`, `dep tree`, `epic close-eligible`).
2. Use `pvg loop next --json` to decide what happens next in dispatcher flows.
3. Use `pvg story deliver|accept|reject` for story transitions instead of managing labels/status by hand.
4. Use `pvg story merge` for accepted story branches. Do not hand-merge from stale local state.
5. Use `pvg loop recover` after compaction, crash, or orphaned worktrees. Do not hand-edit runtime state files.

## Shared Tracker Routing

```bash
pvg nd root --ensure                            # nd-specific bootstrap
pvg issues ready --json
pvg issues show PROJ-a1b --json
pvg story claim PROJ-a1b
pvg issues list --type epic --sort priority --json
pvg issues blocked --json                       # blocked issues with blocker info
pvg story accept PROJ-a1b --reason "Accepted: ..."
```

Both `pvg issues` and `pvg nd` inject the correct shared `--vault` automatically. Do not pass `--vault` yourself.

## Backlog Durability (Snapshots)

```bash
pvg nd sync               # Export the live vault to tracked .vault/backlog-snapshot/
pvg nd restore            # Re-import the snapshot into an empty live vault (fresh clone)
pvg nd restore --force    # Overwrite a non-empty live vault from the snapshot
```

The live nd vault lives under git-common-dir and is NOT part of git history --
a fresh clone does not contain it. `pvg nd sync` runs at each epic completion
gate; the orchestrator commits the snapshot on main. The snapshot is an export,
never the live queue.

## Deterministic Next Action

```bash
pvg loop next --json
pvg loop next --json --n 4    # wave: up to 4 distinct-story actions (max 6)
```

With `--n N`, the response carries an `actions` array of up to N distinct-story
actions (at most one pm_review per wave, then developers from the rejected/ready
queues); the `next` field still carries the first action. Use it to spawn a
parallel developer wave within the concurrency limit.

This is the SINGLE SOURCE OF TRUTH for dispatch decisions. In epic mode (the default),
it NEVER falls through to the global backlog. It returns decisions scoped to the
current epic only:

| Decision | Meaning |
|----------|---------|
| `act` | Spawn the agent specified in `next` (developer or pm_acceptor) |
| `epic_complete` | All stories closed -- run completion gate, then `pvg loop rotate <next_epic>` if present |
| `epic_blocked` | All remaining work in the current epic is blocked -- escalate |
| `wait` | Agents are working in the current epic -- do nothing |
| `complete` | All epics drained -- allow exit |
| `blocked` | All remaining work globally is blocked (--all mode) -- allow exit |

In epic mode, if the epic has in-progress work, it returns `wait`. If all stories
are closed, it returns `epic_complete`. If only blocked, `epic_blocked`. It NEVER
falls through to stories in other epics.

## Story Transitions

```bash
pvg story deliver PROJ-a1b
pvg story accept PROJ-a1b --reason "Accepted: ..." --next PROJ-a1c
pvg story reject PROJ-a1b --feedback "EXPECTED: ... DELIVERED: ... GAP: ... FIX: ..."
pvg story verify-delivery PROJ-a1b
pvg story approve-red PROJ-a1b
pvg story verify-tdd --base origin/epic/PROJ-epic
pvg story merge PROJ-a1b
```

These commands own the Paivot delivery contract:

- `deliver` moves the story to `in_progress`, clears stale rejection labels, adds `delivered`, and appends the authoritative contract block
- `accept` applies `accepted`, closes the story, and appends the accepted contract
- `reject` returns the story to `open`, swaps `delivered` for `rejected`, and appends the rejected contract
- `verify-delivery` checks whether the proof block is complete enough for PM review
- `approve-red` (hard-TDD only) removes `delivered`, adds `red-approved`, and returns the RED story to the ready queue so the loop dispatches the GREEN developer; a RED story is never closed or accepted
- `verify-tdd` is the structural hard-TDD guard: against `--range A..B` or `--base REF` (merge-base..HEAD) it fails when a non-RED, unauthorized commit **modifies or deletes** an existing test file. Adding a brand-new test file is always allowed (a pure addition cannot weaken the frozen RED tests). A RED commit carries the `tdd-red` marker; a sanctioned repair carries `[test-edit-authorized]`. It fails loudly (non-zero) when the range cannot be resolved rather than passing silently
- `merge` is allowed only when the story is both `accepted` and `closed`

## Loop Lifecycle

```bash
pvg loop setup                          # Default: auto-select highest-priority epic
pvg loop setup --epic PROJ-epic         # Target a specific epic
pvg loop setup --epic PROJ-epic --max 25  # With iteration limit
pvg loop setup --all                    # Legacy: no epic containment (not recommended)
pvg loop status
pvg loop cancel
pvg loop snapshot --agent PROJ-a1b=developer
pvg loop recover
```

**Default is single-epic mode.** `pvg loop setup` (no flags) auto-selects the
highest-priority epic with actionable work. `--all` is an opt-in escape hatch
that disables epic containment.

Use `pvg loop recover` as the first command after context loss (compaction, crash,
orphaned worktrees).

## Dispatcher And Settings

```bash
pvg dispatcher on
pvg dispatcher off
pvg dispatcher status
pvg settings
pvg settings workflow.fsm
pvg settings stack_detection=true
```

Use dispatcher commands for Claude-path coordinator mode. Use settings for project-level workflow behavior.

## Structural Gates (Pre-Anchor)

```bash
pvg rtm check                        # Verify all tagged D&F requirements have covering stories
pvg lint --backlog                   # Full backlog quality suite (collisions + structure)
pvg lint --backlog --json            # Machine-parseable findings
pvg lint --backlog --epic EPIC_ID    # Scope story-level checks to one epic
pvg lint                             # Artifact-collision check only (subset of --backlog)
```

These are mandatory before submitting a backlog to the Anchor. Both are deterministic:

- `pvg rtm check` reads BUSINESS.md, DESIGN.md, ARCHITECTURE.md for tagged requirements
  ([NEW], [EXPANDED], [CRITICAL], [REQUIRED], [CHANGED]) and checks each has a covering
  story in the backlog. Exit code 1 on uncovered requirements.
- `pvg lint --backlog` runs the artifact-collision check PLUS the backlog structure
  checks: walking-skeleton, capstone, mandatory-skills, consumes-signature,
  consumes-produces, stale-refs, external-integration, atomicity, vertical-slice,
  dep-cycles, release-gate, and paths-exist (brownfield only). Findings are `error`
  (must fix; exit 1) or `review` (judgment flag; exit 0). The Anchor runs the same
  linter FIRST and auto-rejects on any `error` finding.

Lint behavior is tunable via settings: `lint.quality_gates` (extra pipe-separated
patterns the walking-skeleton check requires in every skeleton's AC) and
`lint.brownfield` (force the paths-exist check on, instead of the >50-commits
heuristic).

## Vault And Guard Operations

```bash
pvg seed
pvg seed --force
pvg guard
pvg hook session-start
```

These matter most for `paivot-graph`, but the docs and seeded runtime notes should still stay in sync with the rest of the control plane.
