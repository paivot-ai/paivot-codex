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

Update nd with delivery evidence:

```bash
nd update <story-id> --append-notes "Branch: story/<story-id>, SHA: $(git rev-parse HEAD)"
nd labels add <story-id> delivered
```

## PM Review Gate

PM-Acceptor reviews delivered work from nd evidence.

### Accept

```bash
nd labels add <story-id> accepted
nd close <story-id> --reason="Accepted: <summary>" --start=<next-id>
```

Merge eligibility requires both:
- label `accepted`
- nd status `closed`

### Reject

```bash
nd update <story-id> --status=open
nd labels rm <story-id> delivered
nd labels add <story-id> rejected
nd comments add <story-id> "EXPECTED: ... DELIVERED: ... GAP: ... FIX: ..."
```

Rejected work returns to the developer on the same story branch.

## Merge To Main

After PM acceptance:

```bash
git fetch origin
git checkout main
git pull origin main
git merge --no-ff origin/story/STORY_ID -m "merge(story/STORY_ID): integrate STORY_ID"
git push origin main
git push origin --delete story/STORY_ID
```

If a merge conflict occurs, spawn a developer to resolve it. Conflict resolution is implementation work.

## nd State Isolation

nd issue files (`.vault/issues/`) are runtime state and must never be committed.

Why this matters: if `.vault/issues/` is tracked, branch switches and merges can overwrite nd state changes and silently corrupt workflow state.

Rules:
- `.vault/issues/`, `.vault/.nd.yaml`, `.vault/.piv-loop-state.json`, `.vault/.dispatcher-state.json` stay gitignored
- Developers never use `git add .` or `git add -A`
- Developers never commit `.vault/` files

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
