# Paivot Methodology (Global Codex Setup)

This file is a *global* reference for the Paivot automated orchestration workflow in Codex.

Paivot skills are installed under `~/.codex/skills/`. Repos may carry their own `AGENTS.md`, but this doc is reusable across projects.

## The nd Contract (Status + Evidence + Proof)

All personas coordinate through nd story notes. Each skill MUST maintain a contract:

```markdown
## nd_contract
status: <new|in_progress|delivered|accepted|rejected>

### evidence
- <commands run, outputs, SHAs>

### proof
- [ ] AC #1: <verifiable statement>
```

**Append-only rule:** use `nd update <id> --append-notes "<block>"`. The last `nd_contract` block is authoritative.

## Status + Label Mapping

| Contract Status | nd Status | Labels |
|----------------|-----------|--------|
| `new` | `open` | (none) |
| `in_progress` | `in_progress` | (none) |
| `delivered` | `in_progress` | `delivered` |
| `accepted` | `closed` | `accepted` |
| `rejected` | `open` | `rejected` |

## Live Source Of Record

When multiple agents work in separate branches or worktrees, the mutable nd backlog must live outside those branch checkouts.

- Resolve the live nd vault from the repository's git common dir
- Use `pvg nd ...` (or equivalent `nd --vault <shared-path>`) for all live tracker operations
- Treat git snapshots/archives as export artifacts, not the live queue

## Role Semantics

- `developer`: reads nd story, implements exactly the AC, writes evidence + proof, sets `delivered`. Does NOT close.
- `pm_acceptor`: reads nd story + evidence, accepts (closes) or rejects with explicit criteria.
- `sr_pm`: creates/repairs nd stories to be self-contained and executable.
- `business_analyst`, `designer`, `architect`: D&F roles producing docs and backlog context.
- `anchor`: adversarial reviewer (binary outcomes: APPROVED/REJECTED or VALIDATED/GAPS_FOUND).
- `retro`: harvests learnings and writes vault knowledge notes with `actionable: pending`.
- `orchestrator`: automated dispatcher using `spawn_agent`.
- Queue selection MUST come from `pvg loop next --json`, not hand-rolled delivered/rejected/ready logic.
  `pvg loop next --json` is the SINGLE SOURCE OF TRUTH for dispatch. It enforces epic containment
  structurally -- it only returns stories scoped to the active epic in epic mode (the default).
- Story transitions should use `pvg story deliver|accept|reject`, not manual label choreography.
- For OpenAI API / ChatGPT / Codex questions, use the OpenAI Docs MCP server first when it is available.

## Vault Knowledge Protocol

The Obsidian vault ("Claude") is the persistent knowledge layer:

1. **Session start**: Search vault for project context, decisions, patterns
2. **During work**: Capture decisions, debug insights, patterns as vault notes
3. **Session end**: Update project index note

```bash
vlt vault="Claude" search query="<project>"
vlt vault="Claude" create name="<Title>" path="_inbox/<Title>.md" content="..." silent
vlt vault="Claude" append file="projects/<project>" content="..."
```

## Concurrency Limits

Heavy stacks (Rust, iOS, C#, CF Workers): max 2 dev + 1 PM + 3 total.
Light stacks (Python, TS/JS): max 4 dev + 2 PM + 6 total.

## Git Workflow (Two-Level Branch Model)

- `main`: protected trunk, always releasable
- `epic/<id>`: one branch per epic, created from `main`
- `story/<id>`: one branch per story, created from its epic branch
- Stories merge to epic after PM acceptance; epics merge to main after completion gate

## Skills

### Execution Roles
- `orchestrator`: automated dispatcher via spawn_agent
- `developer`: implement one story, deliver with proof
- `pm_acceptor`: accept/reject one delivered story
- `sr_pm`: create/repair backlog stories
- `business_analyst`, `designer`, `architect`: D&F roles
- `anchor`: adversarial reviewer
- `ba_challenger`, `designer_challenger`, `architect_challenger`: D&F specialist review challengers
- `retro`: harvest learnings
- `intake`: collect feedback, delegate to Sr. PM, execute backlog

### Tools
- `pvg`: deterministic control plane for shared nd routing, queue selection, story transitions, merge gating, and recovery
- `nd`: issue tracker operations (with resources: CLI reference, workflows, dependencies, epics, storage, patterns, troubleshooting)
- `vlt`: vault CLI operations (with references: command reference, agentic patterns, advanced techniques, vault architecture)
- `vault_knowledge`: three-tier knowledge capture protocol
- `c4`: C4 architecture model (Structurizr DSL, architecture contracts, diagram export)

### Vault Management
- `vault_capture`: deliberate knowledge capture pass (decisions, patterns, debug insights)
- `vault_evolve`: refine vault content from session experience (proposals for system, direct edits for project)
- `vault_status`: vault health overview (note counts, proposals, actionable knowledge)
- `vault_triage`: review and accept/reject pending system-scope proposals
- `vault_settings`: view and configure project-level settings (FSM, C4, scope defaults)

## Delivery Proof Preflight

```bash
pvg story verify-delivery <story-id>
```

Checks presence/shape of delivery evidence in nd notes/labels; does not validate code.

## From CLAUDE.md

```
Please refer to @AGENTS.md for all other instructions. Follow them strictly and do not deviate.
```
