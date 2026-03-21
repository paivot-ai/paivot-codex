---
name: retro
description: >
  Run a retrospective for a completed epic/milestone. Harvest LEARNINGS and
  OBSERVATIONS from accepted stories, distill actionable insights, and write
  vault knowledge notes for future sessions.
---

# Retro (Ephemeral, One Epic)

## Inputs

Required:
- `epic_id`: nd epic ID (preferred), OR
- `stories_text`: pasted accepted stories + notes

## Workflow

### 1) Load Accepted Stories In The Epic

If nd is available (**NEVER read `.vault/issues/` files directly** -- always use nd commands):

```bash
nd show <epic-id>
nd search "<epic-id>"
```

For each story, extract:
- `LEARNINGS` sections
- `OBSERVATIONS` sections
- repeated rejection patterns (if any)

### Never Summarize Summaries (CRITICAL)

When extracting insights, ALWAYS work from the raw source material:
- Read LEARNINGS and OBSERVATIONS from each story's delivery proof directly
- Read actual code state and test output
- Cross-reference with nd comments and story notes

NEVER compress a summary of a summary. Each level of insight must regenerate from the
level below plus actual code/test state. Compounding compression causes information
loss -- each pass silently drops details until the insight is too vague to act on.

If the epic has many stories, process them in batches but always from the raw delivery
proofs, not from a previous batch's summary.

### 2) Distill Actionable Insights

Produce:
- What went well
- What went wrong
- Root causes (process, testing, architecture, story quality)
- Concrete fixes (checklists, story templates, test mandates)
- Backlog updates needed (new stories, changed AC patterns)
- Hard-TDD effectiveness (compare rejection rates, bug discovery, overhead between `hard-tdd` and normal stories -- informs whether label scope should expand or contract)

### 3) Write Retro Output to nd

Write a structured retro note into the epic:

```bash
nd update <epic-id> --append-notes "# Retrospective: <epic-id> - <Epic Title>

## Source Stories
- PROJ-...
- PROJ-...

## Learnings (Actionable)
1. <learning> (Action: <what to change>; Applies to: <future stories>)
2. ...

## Rejection Patterns (If Any)
- <pattern> -> <prevention rule>

## Backlog Follow-Ups
- [ ] Create story: <title> (Reason: <why>)
- [ ] Update story template: <change>"
```

### 4) Capture Learnings to Vault (Mandatory)

Each actionable insight becomes a vault note with `actionable: pending` so the Sr PM can incorporate it into future stories:

```bash
vlt vault="Claude" create name="<Insight Title>" \
  path="_inbox/<Insight Title>.md" \
  content="---\ntype: pattern\nscope: project\nproject: <project>\nstatus: active\nactionable: pending\ncreated: $(date +%Y-%m-%d)\n---\n\n# <Insight Title>\n\n## Context\n<what epic/story revealed this>\n\n## Insight\n<the learning>\n\n## Action\n<what should change in future work>" silent
```

For debug insights:

```bash
vlt vault="Claude" create name="<Debug Title>" \
  path="_inbox/<Debug Title>.md" \
  content="---\ntype: debug\nscope: project\nproject: <project>\nstatus: active\nactionable: pending\ncreated: $(date +%Y-%m-%d)\n---\n\n# <Debug Title>\n\n## Symptoms\n<what was observed>\n\n## Root Cause\n<why it happened>\n\n## Fix\n<what resolved it>" silent
```

### 5) UAT Script Generation (MANDATORY for Epic Retro)

After extracting insights, generate a User Acceptance Test script for the completed
epic. This is a human-readable document that tells the user exactly how to verify
what was built.

Format:
```
## UAT: <Epic Title>

### Prerequisites
- [Setup steps: commands to run, services to start]

### Test: <Observable capability 1>
Do:
1. [Exact command or UI action]
2. [Next step]
Expected:
- [Specific observable outcome -- exact text, URL, behavior]

### Test: <Observable capability 2>
Do:
1. [Exact command or UI action]
Expected:
- [Specific observable outcome]
```

Rules for UAT scripts:
- Every step is a copy-pasteable command or specific UI action
- Every expected result describes exactly what the user should see
- Derived from the epic's stories, NOT from implementation details
- Non-blocking: generate and include in the retro output, the user tests when convenient
- Write to `.vault/knowledge/uat/` with the epic ID in the filename

### 6) Update Project Index

```bash
vlt vault="Claude" append file="projects/<project>" \
  content="## Retro: <epic-id> ($(date +%Y-%m-%d))\n- <key learnings summary>\n- <link to vault notes created>"
```

## Outputs / Evidence

- Epic notes updated with the retro summary
- Vault notes created with `actionable: pending` for Sr PM consumption

## Hard Rules

- This role does not implement code.
- Learnings must be actionable (a concrete prevention rule or backlog change), not vague.
- Every insight must be captured in the vault, not just in nd notes.

## Invocation

```bash
codex "Use skill retro. epic_id=PROJ-a1b2. Harvest learnings from accepted stories and create vault notes."
```
