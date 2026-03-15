# Paivot Codex Skills (Automated Orchestration)

This repo contains Codex Skills for the Paivot methodology. Skills live under `.agents/skills/`.

## Global Install

```bash
make install-global
```

To install somewhere else:

```bash
make install-global CODEX_HOME=/path/to/codex-home
```

## Prerequisites

The following tools must be in PATH:

| Tool | Purpose | Install |
|------|---------|---------|
| `nd` | Issue tracker (vault-backed) | [github.com/RamXX/nd](https://github.com/RamXX/nd) |
| `vlt` | Obsidian vault CLI | [github.com/RamXX/vlt](https://github.com/RamXX/vlt) |

### Codex Config Requirements

Ensure `~/.codex/config.toml` includes:

```toml
[features]
enable_spawn_agent = true
enable_parallel_execution = true
```

### Vault Setup

The Paivot methodology uses an Obsidian vault named "Claude" for persistent knowledge:

```bash
vlt vaults                           # Verify vault exists
vlt vault="Claude" search query=""   # Test connectivity
```

## Capabilities

- **spawn_agent orchestration**: The orchestrator skill uses `spawn_agent`/`wait`/`resume_agent`/`close_agent` for automated multi-agent workflows.
- **Vault-backed knowledge**: All agents read from and write to the Obsidian vault for cross-session learning.
- **nd issue tracking**: Stories are tracked in nd (not bd, not git branches). Live execution state uses a branch-independent nd vault, not `.vault/issues/` inside each story branch checkout.
- **Trunk-based branching**: `main` plus `story/<id>` branches. PM review gates story merges; no shared sync branches.

## The nd Contract (Status + Evidence + Proof)

All personas coordinate through nd story notes. Each skill maintains an append-only contract:

```markdown
## nd_contract
status: <new|in_progress|delivered|accepted|rejected>

### evidence
- <commands run, outputs, SHAs>

### proof
- [ ] AC #1: <verifiable statement>
```

If multiple `nd_contract` blocks exist, the last one is authoritative.

## Autonomy Contract

Paivot is designed to involve the user at specific control points, not as a standing reviewer queue.

- **During D&F**: BLT roles can surface structured questions to the user through the orchestrator.
- **After backlog approval**: execution is autonomous. The normal loop is `developer -> pm_acceptor -> continue`.
- **PM acceptance is internal**: PM-Acceptor review is part of the unattended runtime, not a user sign-off step.
- **Milestone steering is external**: the user re-enters for milestone review, prioritization shifts, and explicit steering.
- **Break-glass is exceptional**: escalate to the user only for true blockers, `cant_fix`, policy/safety conflicts, or requested manual intervention.
- **Never ask the user to clear delivered queues** or perform routine PM acceptance for normal story flow.

## Live Source Of Record

For multi-agent work on multiple branches, the live nd backlog must be branch-independent.

- Use `paivot-nd` (installed under `~/.codex/tools/paivot/paivot-nd`) or `scripts/paivot-nd.sh`
- The wrapper resolves the live vault from `git rev-parse --git-common-dir` and stores it under the repo's shared git directory
- Do not use branch-local `.vault/issues/` as the live tracker
- If you need a git artifact, snapshot the live vault explicitly (`nd archive`) instead of treating mutable branch checkouts as canonical

## Codex Agent Notes

Recent Codex agent features make a few constraints more important:

- Repo-local `AGENTS.md` files are layered with global instructions. Keep project-specific rules here and avoid assuming the global file is the only prompt source.
- Subagents inherit the parent session's approval and sandbox defaults. Do not assume spawned agents can bypass permissions the parent does not have.
- Use `send_input` to continue an active agent. Reserve `resume_agent` for agents that were previously closed.
- If a story requires an isolated branch or worktree, create it explicitly before handing execution to a developer. Do not assume Codex created the right checkout implicitly.
- Break-glass remains operator-controlled: `pvg loop cancel` stops unattended execution and `pvg loop recover` is the only safe recovery path after interruption or compaction.

## Role Semantics

- `developer`: reads nd story, implements exactly the AC, writes evidence + proof, sets `delivered`
- `pm_acceptor`: reads nd story + evidence, accepts (closes) or rejects with explicit criteria
- `sr_pm`: creates/repairs nd stories to be self-contained and executable
- `business_analyst`, `designer`, `architect`: D&F roles that produce docs and backlog context
- `anchor`: adversarial backlog/milestone reviewer (binary outcomes only)
- `retro`: harvests learnings and writes vault knowledge notes
- `orchestrator`: automated dispatcher using spawn_agent

## Dispatcher Mode

When Paivot is invoked ("use Paivot", "Paivot this"), the orchestrator enters **dispatcher mode**:

- Spawns agents via `spawn_agent` -- does NOT do work directly
- Relays D&F questions, milestone review prompts, and break-glass escalations to the user
- Manages nd state transitions
- Captures knowledge to vault

The dispatcher NEVER writes code, D&F documents, or story files directly.
It also NEVER resolves merge conflicts (spawn a developer -- conflict resolution requires code judgment)
or edits source files for any reason, including "cleanup" or "git maintenance".
It also MUST treat PM-Acceptor as an internal execution-stage agent rather than a user approval checkpoint.

### D&F Specialist Review

When `dnf.specialist_review` is enabled (via vault_settings), the orchestrator spawns a challenger agent after each BLT document is produced. Challengers adversarially review the document and return APPROVED or REJECTED. On rejection, the creator is re-spawned with feedback (up to `dnf.max_iterations`, default 3). See the orchestrator skill for the full loop logic.

## Concurrency Limits

Stack-dependent limits to prevent resource exhaustion:

**Heavy stacks** (Rust, iOS, C#, CloudFlare Workers):
- Max 2 developer agents, 1 PM-Acceptor, 3 total

**Light stacks** (Python, TypeScript/JavaScript):
- Max 4 developer agents, 2 PM-Acceptor, 6 total

## Git Workflow (Trunk-Based)

Paivot Codex uses a trunk-based story-branch model: **`main` + `story/<id>`**

- **`main`**: protected trunk, always releasable
- **`story/<id>`**: one branch per story, created from `main`

PM review gates: story branches merge only after PM-Acceptor has accepted the story.
Accepted means the story is both `closed` in nd and labeled `accepted`.
There are no shared integration branches.

See `docs/GIT_WORKFLOW.md` for detailed procedures and the shared-vault model.

## Skills

### Execution Roles

| Skill | Purpose |
|-------|---------|
| `orchestrator` | Automated dispatcher via spawn_agent |
| `developer` | Implement one story, deliver with proof |
| `pm_acceptor` | Accept/reject one delivered story |
| `sr_pm` | Create/repair backlog stories |
| `business_analyst` | D&F: business requirements |
| `designer` | D&F: user experience design |
| `architect` | D&F: technical architecture |
| `anchor` | Adversarial backlog/milestone review |
| `ba_challenger` | D&F review: adversarial review of BUSINESS.md |
| `designer_challenger` | D&F review: adversarial review of DESIGN.md |
| `architect_challenger` | D&F review: adversarial review of ARCHITECTURE.md |
| `retro` | Harvest learnings after milestone |
| `intake` | Collect feedback, delegate to Sr. PM, execute backlog |

### Tools

| Skill | Purpose |
|-------|---------|
| `nd` | Issue tracker (with resources: CLI ref, workflows, deps, epics, storage, patterns) |
| `vlt` | Vault CLI (with references: command ref, agentic patterns, advanced techniques, architecture) |
| `vault_knowledge` | Three-tier knowledge capture protocol |
| `c4` | C4 architecture model (Structurizr DSL, contracts, diagrams) |

### Vault Management

| Skill | Purpose |
|-------|---------|
| `vault_capture` | Deliberate knowledge capture pass |
| `vault_evolve` | Refine vault content from session experience |
| `vault_status` | Vault health overview |
| `vault_triage` | Review/accept/reject pending system-scope proposals |
| `vault_settings` | View and configure project-level settings |

## Using nd (Preferred) vs Paste Mode (Fallback)

If nd is available, skills use `nd show`, `nd update`, `nd labels`, `nd ready`.

If nd is not available, skills ask you to paste story text and you update manually.

## From CLAUDE.md

```
Please refer to @AGENTS.md for all other instructions. Follow them strictly and do not deviate.
```
