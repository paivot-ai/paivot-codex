---
name: retro
description: Run a retrospective for a completed epic/milestone. Harvest LEARNINGS and OBSERVATIONS from accepted stories, distill actionable insights, and write a retro summary back into bd (and optionally a .learnings/ file).
---

# Retro (Ephemeral, One Epic)

## Inputs

Required:
- `epic_id`: `bd-...` (preferred), OR
- `stories_text`: pasted accepted stories + notes

Optional:
- `write_file=true|false` (default true): create a `.learnings/<epic-id>-retro.md` file if the repo has a `.learnings/` directory (or create it if appropriate)

## Workflow

### 1) Load Accepted Stories In The Epic

If `bd` is available:

```bash
bd sync
bd list --parent <epic-id> --status closed --pretty
bd list --parent <epic-id> --status closed --json
```

For each story, extract:
- `LEARNINGS` sections
- `OBSERVATIONS` sections
- repeated rejection patterns (if any)

### 2) Distill Actionable Insights

Produce:
- What went well
- What went wrong
- Root causes (process, testing, architecture, story quality)
- Concrete fixes (checklists, story templates, test mandates)
- Backlog updates needed (new stories, changed AC patterns)

### 3) Write Retro Output

Write a structured retro note into the epic:

```markdown
# Retrospective: <epic-id> - <Epic Title>

## Source Stories
- bd-...
- bd-...

## Learnings (Actionable)
1. <learning> (Action: <what to change>; Applies to: <future stories>)
2. ...

## Rejection Patterns (If Any)
- <pattern> -> <prevention rule>

## Backlog Follow-Ups
- [ ] Create story: <title> (Reason: <why>)
- [ ] Update story template: <change>
```

If `bd` is available:

```bash
bd update <epic-id> --append-notes "<paste retro block>"
bd sync
```

If writing a file, create/update:
- `.learnings/<epic-id>-retro.md` with the same content

## Outputs / Evidence

- Epic notes updated with the retro summary
- Optional `.learnings/<epic-id>-retro.md`

## Hard Rules

- This role does not implement code.
- Learnings must be actionable (a concrete prevention rule or backlog change), not vague.

## Invocation (Codex CLI Prompt Convention)

```bash
codex "Use skill retro. epic_id=bd-1234. Harvest learnings from accepted stories, write a structured retro into bd notes, and propose actionable follow-ups."
```
