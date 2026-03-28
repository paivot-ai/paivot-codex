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

1. Use `pvg nd ...` for live tracker operations so every worktree sees the same backlog.
2. Use `pvg loop next --json` to decide what happens next in dispatcher flows.
3. Use `pvg story deliver|accept|reject` for story transitions instead of managing labels/status by hand.
4. Use `pvg story merge` for accepted story branches. Do not hand-merge from stale local state.
5. Use `pvg loop recover` after compaction, crash, or orphaned worktrees. Do not hand-edit runtime state files.

## Shared nd Routing

```bash
pvg nd root --ensure
pvg nd ready --json
pvg nd show PROJ-a1b --json
pvg nd update PROJ-a1b --status=in_progress
```

`pvg nd` injects the correct shared `--vault` automatically. Do not pass `--vault` yourself.

## Deterministic Next Action

```bash
pvg loop next --json
```

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
pvg story merge PROJ-a1b
```

These commands own the Paivot delivery contract:

- `deliver` moves the story to `in_progress`, clears stale rejection labels, adds `delivered`, and appends the authoritative contract block
- `accept` applies `accepted`, closes the story, and appends the accepted contract
- `reject` returns the story to `open`, swaps `delivered` for `rejected`, and appends the rejected contract
- `verify-delivery` checks whether the proof block is complete enough for PM review
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
pvg rtm check    # Verify all tagged D&F requirements have covering stories
pvg lint          # Check for artifact collisions (duplicate PRODUCES)
```

These are mandatory before submitting a backlog to the Anchor. Both are deterministic
checks with exit code 0 on success, 1 on failure:

- `pvg rtm check` reads BUSINESS.md, DESIGN.md, ARCHITECTURE.md for tagged requirements
  ([NEW], [EXPANDED], [CRITICAL], [REQUIRED], [CHANGED]) and checks each has a covering
  story in the backlog. Exit code 1 on uncovered requirements.
- `pvg lint` scans all non-closed stories for PRODUCES blocks and flags any artifact
  (file path) claimed by more than one story. Exit code 1 on collisions.

## Vault And Guard Operations

```bash
pvg seed
pvg seed --force
pvg guard
pvg hook session-start
```

These matter most for `paivot-graph`, but the docs and seeded runtime notes should still stay in sync with the rest of the control plane.
