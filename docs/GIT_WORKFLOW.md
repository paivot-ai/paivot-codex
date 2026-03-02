# Git Workflow (Paivot Codex)

**Paivot uses trunk-based development via `beads-sync`. This is prescriptive, not optional.**

## Core Principle

**Stories are tracked in beads (`bd`), NOT in git branches.**

Beads' hash-based IDs (e.g. `bd-a1b2`) and merge semantics are designed for concurrent work on a shared branch. Epic/feature branching defeats that design and increases conflict frequency.

## Branch Structure

- `main`: protected (merges via PR)
- `beads-sync`: shared sync branch where all story work is committed
- branches only for long experiments (> 1 week, may discard): requires `BEADS_NO_DAEMON=1`

## Initial Setup (One Time, For New Repos)

```bash
bd init --branch beads-sync
git push -u origin beads-sync
```

If `main` is protected, keep a long-lived PR from `beads-sync` to `main` and merge periodically (daily/per milestone).

## Daily Workflow (Per Session)

```bash
bd sync
git pull --rebase origin beads-sync

# ... implement stories, run tests, commit ...

bd sync
git pull --rebase origin beads-sync
git push origin beads-sync
git status  # should be up to date with origin/beads-sync
```

## When Branching Is Allowed

- Normal INVEST stories (< 2 days): work on `beads-sync`
- Experiments (> 1 week, may discard): you may branch, but must disable daemon behavior:

```bash
export BEADS_NO_DAEMON=1
```

