---
name: vlt
description: >
  Obsidian vault CLI for reading, creating, searching, and managing notes in the
  knowledge vault. Use when the user mentions "vault", "vlt", "read a vault note",
  "create a note", "search the vault", "manage frontmatter", "find backlinks",
  "append to a note", "move a note", or any Obsidian vault operation.
---

# vlt -- Obsidian Vault CLI for Coding Agents

vlt is a fast, zero-dependency CLI for Obsidian vault operations. It reads and writes vault files directly on the filesystem without requiring the Obsidian desktop app.

## Vault Discovery

```bash
vlt vault="Claude" read file="Note"        # By vault name
vlt vault="/absolute/path" read file="Note"  # By absolute path
vlt vaults                                   # List all discovered vaults
```

Environment variables `VLT_VAULT` and `VLT_VAULT_PATH` set defaults.

## Note Resolution

vlt resolves note titles using a two-pass algorithm:
1. **Fast pass** -- exact filename match (`<title>.md`), no file I/O
2. **Alias pass** -- checks frontmatter `aliases` field (case-insensitive)

## Command Quick Reference

### File Operations

| Command | Purpose | Key Parameters |
|---------|---------|----------------|
| `read` | Print note content | `file=`, `heading=`, `follow`, `backlinks` |
| `create` | Create a new note | `name=`, `path=`, `content=`, `silent`, `timestamps` |
| `append` | Add content to end | `file=`, `content=` (or stdin) |
| `prepend` | Insert after frontmatter | `file=`, `content=` (or stdin) |
| `write` | Replace body, keep frontmatter | `file=`, `content=` (or stdin) |
| `patch` | Edit by heading, line, or old/new | `file=`, `heading=`/`line=`, `content=`/`delete`, `old=`/`new=` |
| `delete` | Trash or hard-delete | `file=`, `permanent` (optional) |
| `move` | Rename with link repair | `path=`, `to=` |
| `daily` | Create/read daily note | `date=` (optional) |
| `files` | List vault files | `folder=`, `ext=`, `total` (optional) |

### Properties

| Command | Purpose | Key Parameters |
|---------|---------|----------------|
| `properties` | Show frontmatter | `file=` |
| `property:set` | Set a property | `file=`, `name=`, `value=` |
| `property:remove` | Remove a property | `file=`, `name=` |

### Search

| Command | Purpose | Key Parameters |
|---------|---------|----------------|
| `search` | Find by title, content, properties | `query=`, `regex=`, `context=` |
| `tags` | List all tags | `counts`, `sort="count"` |
| `tag` | Notes with a tag (hierarchical) | `tag=` |

### Links and Navigation

| Command | Purpose | Key Parameters |
|---------|---------|----------------|
| `backlinks` | Notes linking to a note | `file=` |
| `links` | Outgoing links | `file=` |
| `orphans` | Notes with no incoming links | (none) |
| `unresolved` | Broken wikilinks vault-wide | (none) |

## Agentic Session Workflow

### Session Start -- Load Context

```bash
vlt vault="Claude" search query="<project-name>"
vlt vault="Claude" search query="[type:decision] [project:<name>]"
vlt vault="Claude" search query="[type:pattern] [status:active]"
```

### During Work -- Capture Knowledge

```bash
vlt vault="Claude" create name="Decision Title" \
  path="decisions/Decision Title.md" \
  content="---\ntype: decision\nproject: my-app\nstatus: active\ncreated: $(date +%Y-%m-%d)\n---\n\n# Decision Title\n\n## Context\n...\n## Decision\n...\n## Alternatives\n..." silent timestamps
```

### Session End -- Update Project Index

```bash
vlt vault="Claude" append file="projects/my-app" \
  content="## Session $(date +%Y-%m-%d)\n- What was accomplished\n- Links to new notes"
```

## Search Patterns

```bash
vlt vault="V" search query="authentication"                    # Text search
vlt vault="V" search query="[status:active] [type:decision]"   # Property filter
vlt vault="V" search regex="TODO|FIXME|HACK" context="2"       # Regex with context
```

## Content Manipulation

```bash
vlt vault="V" patch file="Note" heading="## Status" content="Completed."  # Replace section
vlt vault="V" patch file="Note" old="old text" new="new text"             # Find and replace
vlt vault="V" patch file="Note" heading="## Deprecated" delete            # Delete section
```

## Important Behaviors

- **Exit codes**: 0 on success, 1 on error
- **Link repair on move**: `move` updates all wikilinks vault-wide
- **Timestamps**: Opt-in via `timestamps` flag or `VLT_TIMESTAMPS=1`
- **Path traversal protection**: All paths validated against vault boundary

## Invocation

```bash
codex "Use skill vlt. Search the vault for testing patterns."
codex "Use skill vlt. Create a decision note about choosing WebSockets over SSE."
```
