# Git Workflow (Paivot Codex)

**Paivot Codex uses a trunk-based strategy: `main` plus `story/<id>` branches**

Stories live in nd. Git branches isolate implementation work, while PM review and nd state decide when a story branch is eligible to merge back to trunk.

## Branch Structure

- **`main`**: protected trunk, always releasable
- **`story/<id>`**: one branch per story, created from `main`

There are no shared sync branches and no shared epic integration branches.

## Developer Workflow

### 1. Create Story Branch

```bash
git fetch origin
git checkout -b story/STORY_ID origin/main
```

### 2. Implement and Commit

Always add specific files:

```bash
git add <specific-files>
git commit -m "feat(STORY_ID): <description>"
```

Never commit `.vault/` runtime state.

### 3. Rebase Before Delivery

```bash
git fetch origin
git rebase origin/main
```

### 4. Push Story Branch

```bash
git push -u origin story/STORY_ID
```

Update nd with delivery evidence through `pvg`:

```bash
pvg nd update <story-id> --append-notes "Branch: story/<story-id>, SHA: $(git rev-parse HEAD)"
pvg story deliver <story-id>
```

## PM Review Gate

PM-Acceptor reviews delivered work from nd evidence.

### Accept

```bash
pvg story accept <story-id> --reason "Accepted: <summary>" --next <next-id>
```

Merge eligibility requires both:
- label `accepted`
- nd status `closed`

### Reject

```bash
pvg story reject <story-id> --feedback "EXPECTED: ... DELIVERED: ... GAP: ... FIX: ..."
```

Rejected work returns to the developer on the same story branch.

## Merge To Main

After PM acceptance:

```bash
pvg story merge STORY_ID
```

If a merge conflict occurs, spawn a developer to resolve it. Conflict resolution is implementation work.

## nd Live State

Live nd state is branch-independent and must not live inside a story branch checkout.

Why this matters: if mutable issue files live in each branch checkout, different agents can produce divergent tracker histories for the same story. The live queue stops being canonical the moment two branches update it independently.

Rules:
- Use `pvg nd ...` for all tracker operations
- `pvg nd` resolves the shared vault under the repo's git common dir, so all worktrees see the same live backlog
- Branch-local `.vault/issues/` is not the live source of record
- If you want a git artifact for backup or audit, create an explicit snapshot/export from the shared vault
- Developers still never use `git add .` or `git add -A`
- Developers still never commit `.vault/` runtime files

## Parallel Work

Multiple developers can work on different story branches at the same time:

```bash
codex "Use skill developer. story_id=PROJ-a1b2."
codex "Use skill developer. story_id=PROJ-c3d4."
```

Each story merges independently to `main` after PM acceptance.

## Dispatcher Responsibilities

The orchestrator must:
- create story branches from `main`
- merge accepted story branches to `main`
- clean up merged story branches
- spawn developers for merge conflicts instead of resolving them directly
- use `pvg nd` so state stays canonical across worktrees

The orchestrator must not:
- write implementation code
- inspect agent worktree internals for coding decisions
- commit `.vault/` files

## Recovery

If a session is interrupted:

```bash
pvg loop recover
```

This removes orphaned worktrees and returns in-progress stories to a recoverable state while preserving delivered work for PM review.

## If Something Goes Wrong

Use the smallest escape hatch that solves the problem:

- `pvg loop cancel` stops unattended execution without deleting backlog or vault data.
- `pvg loop recover` is the only safe way to resume after compaction, crash, or orphaned worktrees.
- `pvg nd stats` lets you inspect the shared live backlog instead of a branch-local copy.
- `pvg story merge <story-id>` is the only supported merge path for accepted work; do not hand-merge story branches from stale local state.
