---
name: nd
description: >
  Vault-backed issue tracker storing issues as Obsidian-compatible markdown files.
  Use for multi-session work, dependency tracking, and persistent context that
  survives conversation compaction. No database server. No size limits. Git-native.
  Use when the user mentions "nd", "backlog", "stories", "issues", "create a story",
  "show ready work", "dependencies", "epics", or any issue tracking operation.
---

# nd -- Persistent Issue Memory for AI Agents

Vault-backed issue tracker that stores issues as plain markdown files with YAML frontmatter. Built on [vlt](https://github.com/RamXX/vlt) (Obsidian vault library). Issues survive compaction, sync via git, and have no size limits.

## Prerequisites

```bash
nd --version  # Verify nd is installed and in PATH
```

- **nd CLI** installed (`make install` from source)
- The vault uses [vlt](https://github.com/RamXX/vlt) for all file operations.

## CLI Reference

**Run `nd prime`** for AI-optimized project context (auto-loaded by hooks).
**Run `nd <command> --help`** for specific command usage.

Essential commands: `nd ready`, `nd create`, `nd show`, `nd update`, `nd close`, `nd dep`

## Session Protocol

1. `nd ready` -- Find unblocked work
2. `nd show <id>` -- Get full context
3. `nd update <id> --status=in_progress` -- Claim work
4. Work. Add notes as you go: `nd update <id> --append-notes "..."`
5. `nd close <id> --reason="..."` -- Complete task
6. `git push` -- Sync to remote (issues are files in git)

## Storage

Issues are markdown files in `.vault/issues/`. Each file has YAML frontmatter (id, status, priority, type, deps, follows/led_to) and markdown body (Description, Acceptance Criteria, Design, Notes, History, Links, Comments). You can `cat`, `grep`, and `git diff` them directly.

## Core Operations

| Operation | Command |
|-----------|---------|
| Find work | `nd ready`, `nd blocked`, `nd stale` |
| Create issues | `nd create`, `nd q` (quick capture) |
| Dependencies | `nd dep add/rm/relate/cycles/tree` |
| Execution paths | `nd path`, `--follows`, `--start` |
| Epics | `nd epic tree/status/close-eligible` |
| Visualization | `nd graph` (dep DAG), `nd path` (exec chains) |
| Labels | `nd labels add/rm <id> <label>` |
| Defer work | `nd defer/undefer` |
| Statistics | `nd stats`, `nd count` |
| Search | `nd search "query"` |
| Health | `nd doctor [--fix]` |
| AI context | `nd prime [--json]` |

## nd Contract (Status + Evidence + Proof)

All Paivot personas coordinate through nd story notes. Each skill MUST maintain a contract block:

```markdown
## nd_contract
status: <new|in_progress|delivered|accepted|rejected>

### evidence
- <bullet list; include commands and key output summaries>

### proof
- [ ] AC #1: <verifiable statement> (Code: <path>, Test: <path>, Evidence: <link/snippet>)
- [ ] AC #2: ...
```

**Append-only rule:** use `nd update <id> --append-notes "<block>"`. If multiple `nd_contract` blocks exist, the last one is authoritative.

## Status + Label Mapping

nd has built-in statuses (`open`, `in_progress`, `blocked`, `deferred`, `closed`). Paivot semantics use labels plus the `nd_contract` status:

| Contract Status | nd Status | Labels |
|----------------|-----------|--------|
| `new` | `open` | (none) |
| `in_progress` | `in_progress` | (none) |
| `delivered` | `in_progress` | `delivered` |
| `accepted` | `closed` | `accepted` |
| `rejected` | `open` | `rejected` |

## Invocation

```bash
codex "Use skill nd. Show me the current backlog with nd ready."
codex "Use skill nd. Create a story for: <requirement>"
```
