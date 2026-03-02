---
name: vault_knowledge
description: >
  Three-tier knowledge model for capturing and retrieving knowledge across sessions.
  Use when you need to "save to vault", "update vault", "capture a decision",
  "record a pattern", "log a debug insight", or when starting/ending a work session.
  Teaches when to capture, what to capture, and how to format vault notes.
---

# Vault Knowledge (Three-Tier Model)

The Obsidian vault ("Claude") is your persistent knowledge layer. Interact with it using `vlt` (the fast vault CLI) via shell commands.

**Vault path:** Resolve dynamically with `vlt vault="Claude" dir` (never hardcode).

## Three-Tier Knowledge Model

Knowledge lives in three tiers with different governance rules:

### Tier 1: System Vault (global Obsidian "Claude")

Shared across ALL projects. Changes should be deliberate.

| Folder | Contains |
|--------|----------|
| methodology/ | Agent prompts, Paivot methodology |
| conventions/ | Working conventions, checklists |
| decisions/ | Cross-project decisions |
| patterns/ | Cross-project patterns |
| debug/ | Cross-project debug insights |
| concepts/ | Language/framework knowledge |
| projects/ | One index note per project |
| people/ | Team preferences |
| _inbox/ | Unsorted capture (triage later) |

### Tier 2: Project Vault (`.vault/knowledge/` in each repo)

Scoped to a single project. Changes apply directly.

```
.vault/knowledge/
  decisions/      # Project-specific architectural decisions
  patterns/       # Project-specific reusable patterns
  debug/          # Project-specific debug insights
  conventions/    # Project-specific conventions
  changelog.md    # Log of all local knowledge changes
```

### Tier 3: Session Context

Ephemeral, per-session. Exists only in the current conversation.

## Scope Convention

Every vault note has a `scope:` frontmatter property:

- `scope: system` -- lives in the global vault
- `scope: project` -- lives in `.vault/knowledge/`
- **No `scope:` property** -- defaults to `scope: system` (conservative)

## When to Capture

- **Decisions**: chose X over Y, established a convention, made a trade-off
- **Debug insights**: solved a non-obvious bug, found a sharp edge
- **Patterns**: found a reusable solution, identified an anti-pattern
- **Session boundaries**: start (read), before compaction (save), end (update)

## How to Read

```bash
vlt vault="Claude" read file="<Note Title>"                        # Single note
vlt vault="Claude" read file="<Note Title>" follow                 # Note + linked notes
vlt vault="Claude" read file="<Note Title>" backlinks              # Note + notes linking to it
```

## How to Search

```bash
vlt vault="Claude" search query="<term>"                           # Text search
vlt vault="Claude" search query="[status:active] [type:decision]"  # Property filter
```

## How to Create Notes

**Global vault (system scope):**

```bash
vlt vault="Claude" create name="<Title>" path="_inbox/<Title>.md" \
  content="---\ntype: decision\nscope: system\nproject: <project>\nstatus: active\ncreated: <YYYY-MM-DD>\n---\n\n# <Title>\n\n<content>" silent
```

**Project vault (project scope):**

```bash
mkdir -p .vault/knowledge/decisions
cat > .vault/knowledge/decisions/<Title>.md << 'EOF'
---
type: decision
scope: project
project: <project>
status: active
created: <YYYY-MM-DD>
---

# <Title>

<content>
EOF
```

## How to Append

```bash
vlt vault="Claude" append file="<Note Title>" content="<text>"
```

## How to Move/Triage

```bash
vlt vault="Claude" move path="_inbox/<Note>.md" to="decisions/<Note>.md"
```

## Frontmatter Requirements

Every note MUST have: `type`, `scope`, `project`, `status`, `created`.
Optional: `stack`, `domain`, `confidence`.

Valid types: `methodology`, `convention`, `decision`, `pattern`, `debug`, `concept`, `project`, `person`

## Actionable Knowledge Tags

Retro insights use `actionable:` frontmatter:

| Value | Meaning |
|-------|---------|
| `pending` | Written by retro agent, not yet consumed by Sr PM |
| `incorporated` | Sr PM has read and integrated into upcoming stories |

## The Rule

Knowledge not captured is knowledge rediscovered at cost. Capture as you go, not at the end.

## Invocation

```bash
codex "Use skill vault_knowledge. Save this decision about choosing PostgreSQL over SQLite."
codex "Use skill vault_knowledge. Search vault for authentication patterns."
```
