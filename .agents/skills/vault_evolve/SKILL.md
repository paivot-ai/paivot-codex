---
name: vault_evolve
description: >
  Refine vault-backed content based on session experience. Review what happened,
  identify improvements to agent prompts, skill content, or operating mode, and
  update the relevant vault notes. System-scoped notes get proposals; project-scoped
  notes get direct edits. Use when the user says "evolve vault", "refine vault",
  "improve vault notes", or after a significant session.
---

# Vault Evolve -- Refine Vault Content from Experience

Review the current session's work and refine the vault notes that power Paivot. This closes the feedback loop: work produces experience, experience refines the vault, refined vault improves future work.

**Vault:** `vlt vault="Claude"` (resolves path dynamically)

**Scope rules:**
- `scope: system` (or no scope property) -- propose changes only; user must approve via `vault_triage`
- `scope: project` -- apply changes directly to `.vault/knowledge/` in the project repo

## Step 1: Assess What Happened

Review the conversation so far. Identify:
- What tasks were completed
- What friction was encountered (agent prompts unclear, missing context, wrong defaults)
- What patterns emerged that should be codified
- What decisions were made that should be recorded

## Step 2: Identify Vault Notes to Update

Check which vault-backed content could be improved:

### Learned knowledge (patterns/, decisions/, debug/)

```bash
vlt vault="Claude" files folder="patterns"
vlt vault="Claude" files folder="decisions"
vlt vault="Claude" files folder="debug"
```

Agent operational prompts are self-contained in skill .md files (not in the vault).
To change agent behavior, update the skill file and commit to the repo.
vault-evolve captures LEARNED KNOWLEDGE that agents can consult -- not operational rules.

### Skill content (conventions/)

```bash
vlt vault="Claude" read file="Vault Knowledge Skill" follow
```

Look for: capture patterns to update, search strategies that worked, frontmatter conventions that evolved.

### Operating mode (conventions/)

```bash
vlt vault="Claude" read file="Session Operating Mode" follow
```

Look for: instructions ignored (make explicit), useless checklist items, missing checklist items.

### Project-local knowledge (.vault/knowledge/)

```bash
vlt vault=".vault/knowledge" files
```

### Promotion candidates (project -> system)

Review project-local notes for knowledge that has proven universally useful:
```bash
vlt vault=".vault/knowledge" search query="scope: project"
```

Criteria: validated across sessions, applies broadly, improves cross-project consistency.

## Step 3: Determine Scope and Apply

### If `scope: system` (or no scope -- defaults to system):

**DO NOT modify the note directly.** Create a proposal:

```bash
vlt vault="Claude" create name="Proposal -- <Target Note>" path="_inbox/Proposal -- <Target Note>.md" content="---
type: proposal
scope: system
target: \"<full vault path of target note>\"
project: <originating-project>
status: pending
created: <YYYY-MM-DD>
---

# Proposed change: <Target Note>

## Motivation
<what session experience revealed the need>

## Change
### Before
<relevant section of the current note>

### After
<proposed replacement>

## Snapshot (for rollback)
<full content of the target note at time of proposal>

## Impact
Affects all projects using <Target Note>." silent
```

Tell the user: "Created proposal for <note>. Run vault_triage to review and apply."

### If `scope: project`:

Apply changes directly:
```bash
vlt vault=".vault/knowledge" patch file="<Note>" heading="<heading>" content="<new section content>"
```

Append to changelog:
```bash
vlt vault=".vault/knowledge" append file="changelog" content="
- <YYYY-MM-DD>: Updated <note> -- <what changed and why>"
```

### Promotion proposals (project -> system)

```bash
vlt vault="Claude" create name="Promotion -- <Note Title>" path="_inbox/Promotion -- <Note Title>.md" content="---
type: proposal
scope: system
promotion_from: project
source_project: <originating-project>
source_path: \".vault/knowledge/<subfolder>/<Note>.md\"
target_path: \"<target folder>/<Note>.md\"
status: pending
created: <YYYY-MM-DD>
---

# Promotion: <Note Title>

## Source
Project: <project-name>

## Rationale
<why universally useful>

## Content
<full content of the project-local note>" silent
```

## Step 4: Report Changes

```
## Vault Evolve Summary

### Proposals Created (system scope -- requires vault_triage)
- Proposal for <Note A>: <what would change and why>

### Changes Applied (project scope -- applied directly)
- Updated .vault/knowledge/<path>: <what changed>

### No Changes Needed
- <Notes reviewed but found adequate>
```

## Constraints

- Only modify vault notes, never modify static skill/plugin files
- Keep changes grounded in actual session experience, not hypothetical improvements
- NEVER directly modify a system-scoped note -- always create a proposal

## Invocation

```bash
codex "Use skill vault_evolve. Refine vault notes based on this session."
```
