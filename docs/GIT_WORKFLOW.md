# Git Workflow (Paivot Codex)

**Paivot uses trunk-based development with feature branches per story.**

## Core Principle

**Stories are tracked in nd, NOT in git branches.**

Each story gets its own short-lived branch (`story/<id>`), merged to `main` via PR when accepted. This replaces the previous `beads-sync` shared branch workflow.

## Branch Structure

- `main`: protected (merges via PR only)
- `story/<id>`: one branch per story, branched from `main`
- Long experiments (> 1 week, may discard): use `experiment/<name>`

## Story Branch Workflow

### Starting a Story

```bash
git checkout main
git pull origin main
git checkout -b story/<story-id>
```

### During Implementation

```bash
# Commit frequently with story ID prefix
git add <files>
git commit -m "feat(<story-id>): <description>"

# Keep up to date with main
git pull --rebase origin main
```

### Delivering a Story

```bash
git push origin story/<story-id>

# Update nd with commit info
nd update <story-id> --append-notes "Branch: story/<story-id>, SHA: $(git rev-parse HEAD)"
nd labels add <story-id> delivered
```

### After PM Acceptance

```bash
# Create PR (or merge directly if repo allows)
gh pr create --base main --head story/<story-id> \
  --title "<story-id>: <title>" \
  --body "Closes story <story-id>. All AC verified."

# After merge, clean up
git checkout main
git pull origin main
git branch -d story/<story-id>
```

## Commit Message Convention

```
<type>(<story-id>): <concise description>

Types: feat, fix, refactor, test, docs, chore
```

Examples:
```
feat(PROJ-a1b2): add user authentication endpoint
fix(PROJ-c3d4): correct rate limit header format
test(PROJ-e5f6): add integration tests for payment flow
```

## Parallel Work

Multiple developers can work simultaneously on different stories since each has its own branch. Coordination happens through nd dependencies, not git branching.

```bash
# Terminal 1
codex "Use skill developer. story_id=PROJ-a1b2."

# Terminal 2
codex "Use skill developer. story_id=PROJ-c3d4."
```

## Migration from beads-sync

If a repo previously used `beads-sync`:

1. Merge `beads-sync` to `main` via PR
2. Delete `beads-sync` branch
3. Remove `.beads/` directory if present
4. Use `nd import --from-beads` to migrate issues (if applicable)
