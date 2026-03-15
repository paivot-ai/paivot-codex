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
pvg loop next --epic PROJ-epic --json
```

This is the source of truth for dispatcher queue selection:

- delivered work -> `pm_acceptor`
- rejected work -> `developer`
- ready work -> `developer`
- `wait` when only in-progress work remains
- `complete` when backlog work is done
- `blocked` when only blocked work remains
- `other` when only non-dispatcher workflow states remain

In priority-epic mode, `pvg` drains the selected epic first, then falls back to the rest of the backlog.

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
pvg loop setup --all
pvg loop setup --epic PROJ-epic --max 25
pvg loop status
pvg loop cancel
pvg loop snapshot --agent PROJ-a1b=developer
pvg loop recover
```

Use these for unattended execution and recovery. `pvg loop recover` is the supported escape hatch after context loss.

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

## Vault And Guard Operations

```bash
pvg seed
pvg seed --force
pvg guard
pvg hook session-start
```

These matter most for `paivot-graph`, but the docs and seeded runtime notes should still stay in sync with the rest of the control plane.
