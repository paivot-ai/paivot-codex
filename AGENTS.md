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
- **nd issue tracking**: Stories are tracked in nd (not bd, not git branches). Issues are plain markdown files with YAML frontmatter.
- **Trunk-based development**: Work on feature branches, merge via PR to main. No shared sync branches.

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
- Relays questions from agents to the user
- Manages nd state transitions
- Captures knowledge to vault

The dispatcher NEVER writes code, D&F documents, or story files directly.

## Concurrency Limits

Stack-dependent limits to prevent resource exhaustion:

**Heavy stacks** (Rust, iOS, C#, CloudFlare Workers):
- Max 2 developer agents, 1 PM-Acceptor, 3 total

**Light stacks** (Python, TypeScript/JavaScript):
- Max 4 developer agents, 2 PM-Acceptor, 6 total

## Git Workflow (Trunk-Based Development)

- `main`: protected, merges via PR
- `story/<id>`: feature branches for individual stories
- No shared sync branches (beads-sync is retired)

See `docs/GIT_WORKFLOW.md` for details.

## Skills

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
| `retro` | Harvest learnings after milestone |
| `nd` | Issue tracker operations |
| `vlt` | Vault CLI operations |
| `vault_knowledge` | Knowledge capture protocol |

## Using nd (Preferred) vs Paste Mode (Fallback)

If nd is available, skills use `nd show`, `nd update`, `nd labels`, `nd ready`.

If nd is not available, skills ask you to paste story text and you update manually.

## From CLAUDE.md

```
Please refer to @AGENTS.md for all other instructions. Follow them strictly and do not deviate.
```
