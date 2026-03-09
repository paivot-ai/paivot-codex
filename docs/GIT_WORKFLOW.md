# Git Workflow (Paivot Codex)

**Paivot Codex uses a two-level branching strategy: `main → epic → story`**

Stories are tracked in nd (not git branches). The branch hierarchy isolates story work, gates merges via PM review, and integrates all stories on the epic branch before promoting to main.

## Branch Structure

- **`main`**: protected, represents production-ready code
- **`epic/<id>`**: one branch per epic; collects all approved stories for that epic
- **`story/<id>`**: one branch per story; created from epic branch; developer works in isolation

## Why Two Levels?

1. **Story isolation**: Developers cannot accidentally see or push to epic/main
2. **PM review gates**: Story→epic merges only after PM-Acceptor approval
3. **Epic integration**: All stories on epic branch are tested together before epic→main
4. **Clean history**: Merge commits preserve story boundaries and epic structure

## Developer Workflow

### 1. Epic Branch Setup (Orchestrator)

Before spawning a developer, ensure the epic branch exists:

```bash
git fetch origin
if ! git rev-parse --verify origin/epic/EPIC_ID >/dev/null 2>&1; then
  git checkout -b epic/EPIC_ID origin/main
  git push -u origin epic/EPIC_ID
fi
```

### 2. Checkout Epic Before Spawning (CRITICAL)

The orchestrator MUST checkout the epic branch BEFORE spawning a developer agent with `isolation: "worktree"`:

```bash
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID
```

**Why this matters**: Claude Code's `isolation: "worktree"` creates a worktree from the current HEAD. If the dispatcher is on `main`, the worktree branch is based on `main`. Merging that branch back to `epic/` requires cherry-picking or rebasing. If the dispatcher is on `epic/`, the worktree is based on `epic/`, and merging back is clean.

### 3. Developer Implementation

When spawned with worktree isolation, the developer is on an auto-created branch (e.g., `worktree-<agent-id>`). This branch is based on whatever the dispatcher was on at spawn time (should be `epic/EPIC_ID` per step 2).

Commit frequently with story ID prefix. Always add specific files:

```bash
git add <specific-files>                       # NEVER git add . or git add -A
git commit -m "feat(STORY_ID): <description>"
git commit -m "test(STORY_ID): add integration tests for feature"
```

**NEVER commit `.vault/` files** -- they are runtime state, not code.

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

PM-Acceptor reviews the delivered story using evidence-based review (developer's recorded proof, git diff, file reads). The PM does NOT need to checkout branches.

**If accepted (two steps -- both mandatory):**

```bash
nd labels add <story-id> accepted    # Enables merge gate
nd close <story-id> --reason="Accepted: <summary>" --start=<next-id>
```

**If rejected:**

```bash
nd reopen <story-id>
nd comments add <story-id> "EXPECTED: ... DELIVERED: ... GAP: ... FIX: ..."
```

Developer will re-do work and deliver again.

### 6. Developer Work → Epic Merge (Orchestrator)

After PM-Acceptor accepts and closes the story, the orchestrator merges the developer's work into the epic branch.

**With worktree isolation** (the agent result includes worktree path and branch):

```bash
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID

# Merge the worktree branch (based on epic per step 2, so this is clean)
WORKTREE_BRANCH="<branch from agent result>"
if ! git merge --no-ff $WORKTREE_BRANCH -m "merge(epic/EPIC_ID): integrate STORY_ID"; then
  echo "Merge conflict detected. Spawning developer to resolve..."
  exit 1
fi

git push origin epic/EPIC_ID

# Cleanup worktree and local branch
git worktree remove --force .claude/worktrees/<agent-id>
git branch -D $WORKTREE_BRANCH
```

**With story branches** (if used instead of worktree isolation):

```bash
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID
git merge --no-ff origin/story/STORY_ID -m "merge(epic/EPIC_ID): integrate STORY_ID"
git push origin epic/EPIC_ID
git push origin --delete story/STORY_ID
```

**Merge order**: Process in priority order (P0 first). Merge dependencies first.

**Conflict resolution**: If merge conflict occurs, spawn a developer agent to resolve (conflict resolution requires code judgment).

### 7. Epic Completion (Orchestrator)

When all stories in epic have been approved and merged to epic branch:

```bash
git fetch origin
git checkout main
git pull origin main
git merge --no-ff origin/epic/EPIC_ID -m "Merge epic/EPIC_ID to main"
git push origin main
git push origin --delete epic/EPIC_ID
```

Note: This is a solo-developer workflow -- epics merge directly to main without PRs.
PR-based review gates belong in paivot-enterprise for team workflows.

## nd State Isolation (CRITICAL)

nd issue files (`.vault/issues/`) are **filesystem-based runtime state**. They must NEVER be committed to git. The `pvg` tool automatically adds `.vault/issues/` and other runtime state to `.gitignore` when Paivot is activated.

**Why this matters**: If `.vault/issues/` files are tracked by git, `git checkout` and `git merge` operations overwrite nd state changes. A PM-Acceptor's `nd close` can be silently undone by a subsequent `git checkout epic/EPIC_ID`.

**Rules:**
- `.vault/issues/`, `.vault/.nd.yaml`, `.vault/.piv-loop-state.json`, `.vault/.dispatcher-state.json` are always gitignored
- Developers must NEVER `git add .` or `git add -A` -- always add specific files by name
- Developers must NEVER commit `.vault/` files
- nd commands work from the main working directory, not from worktrees

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
- Merge epic→main when epic is complete
- Clean up branches after merge

### You MUST NOT do:
- Write implementation code or tests
- Edit story files directly
- Inspect developer worktree internals or run git commands inside agent worktrees
- Re-close stories that PM-Acceptor already closed
- Make architectural decisions
- Skip agents to "save time"
- Commit `.vault/` files to any branch (issues, state, lock files are runtime state)

If something goes wrong, spawn the appropriate agent (developer for conflicts, PM for edge cases).

## Worktree Cleanup

After merging the developer's work to epic, clean up the worktree:

```bash
git worktree remove --force .claude/worktrees/<agent-id>
git branch -D worktree-<agent-id>
```

Always use `--force` and `-D`:
- `--force`: worktrees have build artifacts that prevent normal removal
- `-D`: branch isn't synced to origin/main yet, so `-d` would fail

**Important**: Clean up worktrees AFTER merging their changes to epic. If you clean up first, the branch and its commits are lost.

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
