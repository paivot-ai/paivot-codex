# Migration Guide: bd-based Paivot -> nd-based Paivot

This document covers the migration from the original bd (Beads) based Paivot Codex to the modernized nd-based version with vault integration and spawn_agent orchestration.

## What Changed

| Area | Before (bd) | After (nd) |
|------|-------------|------------|
| Issue tracker | `bd` (Beads) | `nd` (vault-backed) |
| Git workflow | `beads-sync` shared branch | `main` + `story/<id>` branches |
| Orchestration | Manual ("run this skill next") | Automated via `spawn_agent` |
| Knowledge | None (stateless across sessions) | Vault-backed (`vlt` + Obsidian) |
| Contract block | `bd_contract` | `nd_contract` |
| Story creation | `bd create` | `nd create` |
| Story updates | `bd update --append-notes` | `nd update --append-notes` |
| Story queries | `bd ready`, `bd list` | `nd ready`, `nd search` |
| Labels | `bd update --add-label` | `nd labels add` |
| Dependencies | `bd dep add` | `nd dep add` |
| Sync | `bd sync` | `git push` (issues are files) |

## Command Mapping (bd -> nd)

| bd Command | nd Equivalent | Notes |
|------------|---------------|-------|
| `bd init` | `nd` (auto-init) | nd initializes on first use |
| `bd sync` | `git push` / `git pull` | Issues are git-tracked files |
| `bd create "<title>" -t story` | `nd create "<title>" -t story` | Same flags mostly |
| `bd show <id> --json` | `nd show <id>` | nd outputs markdown by default |
| `bd update <id> --status <s>` | `nd update <id> --status=<s>` | Note the `=` syntax |
| `bd update <id> --append-notes "..."` | `nd update <id> --append-notes "..."` | Same |
| `bd update <id> --add-label <l>` | `nd labels add <id> <l>` | Separate command |
| `bd update <id> --remove-label <l>` | `nd labels rm <id> <l>` | Separate command |
| `bd update <id> --claim` | `nd update <id> --status=in_progress` | Claim = set in_progress |
| `bd close <id> --reason="..."` | `nd close <id> --reason="..."` | Same |
| `bd ready` | `nd ready` | Same semantics |
| `bd list --parent <id>` | `nd search "<id>"` or `nd dep tree <id>` | Different query model |
| `bd dep add <a> <b> --type blocks` | `nd dep add <a> <b> --type blocks` | Same |
| `bd dep tree <id>` | `nd dep tree <id>` | Same |
| `bd stats --json` | `nd stats` | Same |
| `bd list --label <l>` | `nd search "<l>"` | Search-based |

## Contract Block Migration

### Before (bd_contract)

```markdown
## bd_contract
status: delivered

### evidence
- Commands run: make test
- Summary: all pass

### proof
- [x] AC #1: endpoint returns 200
```

### After (nd_contract)

```markdown
## nd_contract
status: delivered

### evidence
- Commands run: make test
- Summary: all pass

### proof
- [x] AC #1: endpoint returns 200
```

The format is identical except for the heading name.

## Git Workflow Migration

### Before: beads-sync

```bash
git checkout beads-sync
git pull --rebase origin beads-sync
# ... work ...
bd sync
git push origin beads-sync
```

### After: story branches

```bash
git checkout -b story/<id>
# ... work ...
git push origin story/<id>
# After acceptance: PR to main, delete branch
```

## Issue Migration

If you have existing bd issues to migrate:

```bash
nd import --from-beads
```

This reads `.beads/` data and creates corresponding nd issues in `.vault/issues/`.

## New Capabilities

### Vault Knowledge (not available in bd era)

```bash
vlt vault="Claude" search query="<project>"     # Find prior knowledge
vlt vault="Claude" create name="..." path="..." content="..." silent  # Capture insights
```

### spawn_agent Orchestration (not available in bd era)

The orchestrator now automatically spawns agents instead of telling you which command to run next. Just invoke:

```bash
codex "Use skill orchestrator. Use Paivot to build <description>."
```

### New Skills

| Skill | Purpose |
|-------|---------|
| `nd` | Issue tracker operations |
| `vlt` | Vault CLI operations |
| `vault_knowledge` | Knowledge capture protocol |

## Makefile Changes

```bash
make install-global   # Now installs nd/vlt/vault_knowledge skills too
make verify           # Replaces verify-delivery.sh with nd-aware checks
make check-prereqs    # Verifies nd and vlt are installed
```
