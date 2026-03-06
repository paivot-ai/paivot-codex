# Git Workflow (Paivot Codex)

**Paivot Codex uses a two-level branching strategy: `main → epic → story`**

Stories are tracked in nd (not git branches). The branch hierarchy isolates story work, gates merges via PM review, and integrates all stories on the epic branch before promoting to main.

## Branch Structure

- **`main`**: protected (merges via PR only), represents production-ready code
- **`epic/<id>`**: one branch per epic; collects all approved stories for that epic
- **`story/<id>`**: one branch per story; created from epic branch; developer works in isolation

## Why Two Levels?

1. **Story isolation**: Developers cannot accidentally see or push to epic/main
2. **PM review gates**: Story→epic merges only after PM-Acceptor approval
3. **Epic integration**: All stories on epic branch are tested together before epic→main
4. **Clean history**: Merge commits preserve story boundaries and epic structure

## Story Branch Workflow

### 1. Epic Branch Setup (Orchestrator)

Before spawning a developer, ensure the epic branch exists:

```bash
git fetch origin
if ! git rev-parse --verify origin/epic/EPIC_ID >/dev/null 2>&1; then
  git checkout -b epic/EPIC_ID origin/main
  git push -u origin epic/EPIC_ID
fi
```

### 2. Story Branch Creation (Orchestrator)

Create story branch from the epic branch:

```bash
git checkout -b story/STORY_ID origin/epic/EPIC_ID
git push -u origin story/STORY_ID
```

Developer receives a worktree rooted at `story/STORY_ID`. They work in isolation and cannot accidentally push to epic or main.

### 3. Developer Implementation

Developer checks out the story branch (already done by orchestrator worktree setup):

```bash
# Already in story/STORY_ID (worktree isolation)
git log --oneline -5  # Verify you're on story branch
```

Commit frequently with story ID prefix:

```bash
git add <files>
git commit -m "feat(STORY_ID): <description>"
git commit -m "test(STORY_ID): add integration tests for feature"
```

Keep story branch up to date with epic (in case other stories merged):

```bash
git fetch origin
git rebase origin/epic/EPIC_ID
git push origin story/STORY_ID --force-with-lease
```

### 4. Developer Delivery

When implementation is complete and all tests pass locally:

```bash
git push origin story/STORY_ID
```

Update nd with delivery evidence:

```bash
nd update <story-id> --append-notes "Branch: story/<story-id>, SHA: $(git rev-parse HEAD)"
nd labels add <story-id> delivered
```

### 5. PM-Acceptor Review (PM Skill)

PM-Acceptor reviews the delivered story:

```bash
# Checkout story branch to review
git checkout story/STORY_ID
git pull origin story/STORY_ID
```

Review evidence, run tests locally, verify acceptance criteria.

**If accepted:**

```bash
nd update <story-id> --status in_progress
nd labels add <story-id> accepted
```

**If rejected:**

```bash
nd update <story-id> --append-notes "Rejection: <specific criteria not met>"
nd labels add <story-id> rejected
```

Developer will re-do work and deliver again.

### 6. Story→Epic Merge (Orchestrator)

After PM-Acceptor adds `accepted` label, orchestrator merges story to epic:

```bash
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID  # Ensure latest (other stories may have merged)

# Attempt merge
if ! git merge --no-ff origin/story/STORY_ID -m "merge(epic/EPIC_ID): integrate STORY_ID"; then
  # Merge conflict detected
  echo "Merge conflict detected. Spawning developer to resolve..."
  # Spawn developer with conflict resolution context
  exit 1
fi

git push origin epic/EPIC_ID

# Cleanup story branch after successful merge
git push origin --delete story/STORY_ID
```

**Merge order**: If multiple stories waiting to merge, process in priority order (P0 first). Merge dependencies first.

**Conflict resolution**: If merge conflict occurs, spawn a developer agent to resolve (conflict resolution requires code judgment and context).

### 7. Epic Completion (Orchestrator)

When all stories in epic have been approved and merged to epic branch:

```bash
git fetch origin
gh pr create \
  --base main \
  --head epic/EPIC_ID \
  --title "epic(EPIC_ID): [epic title]" \
  --body "Completed epic with stories: $(nd children EPIC_ID --json | jq -r '.[].id' | paste -sd, -)"
```

Wait for:
- [ ] CI passes on epic branch (full test suite with all stories integrated)
- [ ] User/PM reviews PR for milestone readiness

Then merge and cleanup:

```bash
git checkout main
git pull origin main
git merge --no-ff origin/epic/EPIC_ID -m "Merge epic/EPIC_ID to main"
git push origin main
git push origin --delete epic/EPIC_ID
```

## Commit Message Convention

```
<type>(<story-id>): <concise description>

Types: feat, fix, refactor, test, docs, chore
```

Examples:
```
feat(PROJ-a1b2): add user authentication endpoint
test(PROJ-c3d4): add integration tests for payment flow
fix(PROJ-e5f6): correct rate limit header format
```

## Parallel Work

Multiple developers work simultaneously on different stories in the same epic. Each has its own `story/<id>` branch. All their work integrates on the epic branch.

```bash
# Terminal 1 (Developer 1)
codex "Use skill developer. story_id=PROJ-a1b2."

# Terminal 2 (Developer 2)
codex "Use skill developer. story_id=PROJ-c3d4."

# Both stories integrate on epic/PROJ-epic-1 before epic→main
```

## Dispatcher Responsibilities

As orchestrator, you manage the git workflow:

### You MUST do:
- Create epic branches before spawning developers
- Create story branches from the correct epic branch
- Merge story→epic after PM approval (handle merge conflicts by spawning developer if needed)
- Create PR epic→main when epic is complete
- Clean up branches after merge

### You MUST NOT do:
- Write implementation code or tests
- Edit story files directly
- Inspect developer worktree internals or run git commands inside agent worktrees
- Re-close stories that PM-Acceptor already closed
- Make architectural decisions
- Skip agents to "save time"

If something goes wrong, spawn the appropriate agent (developer for conflicts, PM for edge cases).

## Worktree Cleanup

After merging a story branch to epic, clean up the developer's worktree:

```bash
git worktree remove --force .claude/worktrees/<agent-id>
git branch -D worktree-<agent-id>
```

Always use `--force` and `-D`:
- `--force`: worktrees have build artifacts that prevent normal removal
- `-D`: branch isn't synced to origin/main yet, so `-d` would fail

## Recovering from Interruptions

If a session is interrupted and you lose track of running developers:

```bash
pvg loop recover
```

This automatically:
1. Removes all orphaned worktrees and branches
2. Resets in-progress stories to `open` (preserved `delivered` stories)
3. Shows which work is ready, delivered, or needs attention

## Migration from Trunk-Based (Single Level)

If you previously used `story/<id>` branches merged directly to main:

1. Create an epic for the work-in-progress stories
2. Create epic branch from main
3. Cherry-pick or merge story branches to epic
4. Continue with two-level model going forward

This provides a cleaner integration point and clearer epic tracking.
