# Git Workflow (Paivot Codex)

**Paivot Codex uses a two-level branching strategy: `main -> epic/<id> -> story/<id>`**

Stories live in nd. Git branches isolate implementation work. PM review and nd state
decide when a story branch is eligible to merge to its epic branch. Epic branches
merge to main only after the completion gate (e2e tests + Anchor milestone review).

## Branch Structure

- **`main`**: protected trunk, always releasable
- **`epic/<id>`**: one branch per epic, created from `main`
- **`story/<id>`**: one branch per story, created from its epic branch

Stories merge UP to their epic branch after PM acceptance. Epic branches merge UP
to main after the completion gate. There is no cross-epic cherry-picking.

## Developer Workflow

### 1. Create Story Branch (dispatcher creates this before spawning developer)

```bash
# Ensure epic branch exists (create if needed)
git fetch origin
if ! git rev-parse --verify origin/epic/EPIC_ID >/dev/null 2>&1; then
  git checkout -b epic/EPIC_ID origin/main
  git push -u origin epic/EPIC_ID
fi

# Create story branch from epic
git checkout -b story/STORY_ID origin/epic/EPIC_ID
git push -u origin story/STORY_ID
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
git rebase origin/epic/EPIC_ID
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

## Story Merge (to Epic Branch)

After PM acceptance, the dispatcher IMMEDIATELY merges the story to the epic branch:

```bash
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID
git merge --no-ff origin/story/STORY_ID -m "merge(epic/EPIC_ID): integrate STORY_ID"
git push origin epic/EPIC_ID
```

If a merge conflict occurs, spawn a developer to resolve it. Conflict resolution
is implementation work.

After successful merge, clean up the story branch:

```bash
git branch -D story/STORY_ID
git push origin --delete story/STORY_ID
```

## Epic Merge (to Main)

After all stories in an epic are accepted and merged to the epic branch, and the
epic completion gate passes (e2e tests + Anchor milestone review):

```bash
pvg story merge EPIC_ID
```

Or manually:

```bash
git checkout main
git pull origin main
git merge --no-ff epic/EPIC_ID -m "merge(main): complete EPIC_ID"
git push origin main

# Clean up epic branch
git branch -D epic/EPIC_ID
git push origin --delete epic/EPIC_ID
```

Then clean up all story branches for this epic:

```bash
# Delete remote story branches
for branch in $(git branch -r --list "origin/story/*" | sed 's|origin/||'); do
  git push origin --delete "$branch" 2>/dev/null || true
done

# Delete local story branches
for branch in $(git branch --list "story/*"); do
  git branch -D "$branch" 2>/dev/null || true
done
```

## nd Live State

Live nd state is branch-independent and must not live inside a story branch checkout.

Why this matters: if mutable issue files live in each branch checkout, different agents
can produce divergent tracker histories for the same story. The live queue stops being
canonical the moment two branches update it independently.

Rules:
- Use `pvg nd ...` for all tracker operations
- `pvg nd` resolves the shared vault under the repo's git common dir, so all worktrees see the same live backlog
- Branch-local `.vault/issues/` is not the live source of record
- If you want a git artifact for backup or audit, create an explicit snapshot/export from the shared vault
- Developers still never use `git add .` or `git add -A`
- Developers still never commit `.vault/` runtime files

## Parallel Work

Multiple developers can work on different story branches WITHIN the same epic
at the same time:

```bash
codex "Use skill developer. story_id=PROJ-a1b2."
codex "Use skill developer. story_id=PROJ-c3d4."
```

Each story merges to the epic branch after PM acceptance. All parallelization
happens within the current epic -- never across epics.

## Dispatcher Responsibilities

The orchestrator must:
- create epic branches from `main`
- create story branches from epic branches
- merge accepted story branches to their epic branch
- run the epic completion gate (e2e + Anchor review)
- merge epic branches to `main` (solo-dev) or create PRs (team)
- clean up merged story and epic branches
- spawn developers for merge conflicts instead of resolving them directly
- use `pvg nd` so state stays canonical across worktrees

The orchestrator must not:
- write implementation code
- inspect agent worktree internals for coding decisions
- commit `.vault/` files
- query nd globally for dispatch (use `pvg loop next --json`)

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
- `pvg story merge <story-id>` is the supported merge path for accepted work; do not hand-merge story branches from stale local state.
