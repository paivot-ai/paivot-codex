---
name: domain_model
description: >
  Canonical domain model (entities, relationships, invariants) as a machine-checkable
  twin of ARCHITECTURE.md, authored with modelith. Use when the project has
  dnf.domain_model enabled in settings, or when the user asks about the domain model,
  entities, invariants, ubiquitous language, or shared vocabulary during Discovery &
  Framing. Teaches how the Architect owns the model, how the Sr PM turns invariants into
  acceptance criteria, and how the Anchor checks coverage.
---

# Domain Model

Maintain a machine-checkable domain model alongside the narrative ARCHITECTURE.md. The model is the single, canonical source of the product's named concepts (entities), how they relate, and the rules that must always hold (invariants). The D&F documents reference it; they do not each redefine the vocabulary. This is the cure for the largest D&F failure mode: context divergence (the same concept named differently across BUSINESS.md, DESIGN.md, ARCHITECTURE.md, and the stories).

## When This Applies

Check the project setting before using this skill:

```bash
pvg settings dnf.domain_model
```

- `true` -- the Architect maintains the model; the Sr PM dereferences it into stories; the Anchor checks coverage.
- `false` (default) -- skip entirely, use the narrative ARCHITECTURE.md only.

If the setting is not enabled and the user hasn't asked for a domain model, do not use this skill.

## The tool: modelith

The model is a `*.modelith.yaml` file, linted and rendered by the `modelith` CLI (provisioned by `pvg setup` / `pvg update`; `pvg doctor` reports it). Confirm it is installed:

```bash
modelith --version    # if missing: pvg update
modelith schema       # the authoritative format reference -- read before authoring
```

The YAML is the output of a conversation, not something hand-written. The value is in the questions that pin down each concept. If a concept cannot be given a crisp two-to-four-sentence definition, that fuzziness is the signal to resolve, not paper over.

## File Layout

```
domain.modelith.yaml       # Canonical domain model (linted; the machine-checkable twin)
domain.modelith.md         # Generated Markdown + ER diagram (never hand-edited)
ARCHITECTURE.md            # Narrative architecture (always exists; references the model)
```

The `.yaml` is authored; the `.md` is regenerated with `modelith render` and committed alongside it. The model lives at the repo root, the machine-checkable twin of ARCHITECTURE.md's "Data architecture" section, exactly as `workspace.dsl` is for the c4 skill.

## Build Order -- Skeleton First

Build in passes across the whole model, not field-by-field down one entity. Stop after any pass and you still have something honest.

1. **Skeleton.** Name every entity with a crisp definition; declare `relationships` and `cardinality` (`1:1`, `1:n`, `n:1`, `n:n`) and `ownership` (`owned` = a part that cannot exist without its parent; `referenced`/omitted = an independent entity pointed at). This already renders to an ER diagram.
2. **Behavior.** Add `invariants` (rules that must always hold; each `{id, statement}`) and `scenarios` (short narratives exercising every entity, tagged with `invariants_touched`).
3. **Refinement.** Fill in `attributes`, `enums`, `actions`, `glossary` roles -- only where they add clarity.

Entity keys are PascalCase. Backtick entity names in freeform text.

## Validate and Render

After any edit:

```bash
modelith lint domain.modelith.yaml      # resolve errors; explain remaining warnings
modelith render domain.modelith.yaml    # regenerate the committed Markdown twin
```

`modelith lint` exits non-zero on errors -- that is the model telling you to fix something, not a tool failure.

## Agent Responsibilities

### Architect Agent

Owns `domain.modelith.yaml`. When enabled:
1. Author the model by conversation (skeleton first), seeded by the concepts the BA surfaced in BUSINESS.md and the user types in DESIGN.md.
2. Keep the model's entity names, relationships, and invariants consistent with ARCHITECTURE.md's data architecture. The model is canonical; ARCHITECTURE.md references its names rather than redefining them.
3. Run `modelith lint` (must pass) and `modelith render` (commit the `.md` twin) on every change.
4. The domain model is a protected, architect-owned D&F artifact: the guard blocks writes to `*.modelith.yaml` unless the architect agent is active. Only the Architect writes it.

### Sr PM Agent

When enabled, the model is the naming authority. For every story that touches a modeled concept:
- **Dereference, do not reinvent.** Use entity and attribute names verbatim from the model.
- **Turn invariants into acceptance criteria.** Each invariant the story must uphold becomes an EARS Ubiquitous AC ("The system shall ..."), referencing the invariant. Invariants map to ACs roughly one-to-one.
- Add to the story's MANDATORY SKILLS TO REVIEW section:
  - `domain_model` -- for canonical vocabulary and invariant checking.

### Developer Agent

When enabled, before coding:
1. Read the domain model for the entities and invariants the story's code paths touch.
2. Use the model's canonical names for types, tables, and fields.
3. Uphold the relevant invariants; if the implementation forces a change to a concept's definition or relationships, that is an architecture change -- raise it, do not silently diverge.

### Anchor Agent

When enabled, add to the backlog review checklist:
- Every entity in the model is touched by at least one story.
- Every invariant maps to at least one acceptance criterion in some story.
- No story renames a modeled concept (context divergence from the model is a rejection).
- The `.md` twin is in sync with the `.yaml` (regenerated, not hand-edited).

## What This Skill Does NOT Do

- Does not run when `dnf.domain_model` is `false` (default). Zero behavior change until opted in.
- Does not replace ARCHITECTURE.md -- the narrative always exists and references the model.
- Does not add a CI check; the Architect self-validates with `modelith lint` and the Anchor performs coverage review (mirrors the c4 skill).
- Does not force a domain model onto thin, infra-heavy, or mechanical work -- it is opt-in per project.

## Invocation

```bash
codex "Use skill domain_model. Draft the domain model skeleton for the current project."
codex "Use skill domain_model. Lint and render domain.modelith.yaml, then map its invariants to story acceptance criteria."
```
