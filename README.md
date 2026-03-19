# paivot-codex

Practical Paivot setup for OpenAI Codex.

[Paivot.ai](https://paivot.ai) has the methodology and product-level documentation. This repo is the operator guide for using Paivot with Codex CLI and the Codex desktop app: install the skills, wire Codex correctly, and run the workflow without hand-assembling prompts.

## What This Repo Is

`paivot-codex` packages the Paivot methodology for Codex:

- global Paivot skills under `.agents/skills/`
- a global `AGENTS.md` for Codex home installs
- a repo-local `.codex/config.toml` showing the recommended Codex surface
- docs for shared nd routing, story branches, and recovery

Paivot in Codex is centered on:

- `spawn_agent` orchestration for specialized roles
- `pvg` for deterministic next-step selection and tracker transitions
- `nd` for the live backlog
- `vlt` for vault-backed knowledge
- trunk-based delivery with `main` plus `story/<id>` branches

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [Codex](https://developers.openai.com/codex/cli) | CLI and desktop app runtime | [OpenAI Codex docs](https://developers.openai.com/codex/) |
| [pvg](https://github.com/paivot-ai/pvg) | Shared control plane for loops, routing, transitions, and recovery | `gh release download -R paivot-ai/pvg` or build from source |
| [nd](https://github.com/RamXX/nd) | Git-native issue tracker | `git clone && make install` |
| [vlt](https://github.com/RamXX/vlt) | Vault CLI for Obsidian-backed knowledge | `git clone && make install` |
| Obsidian vault | Persistent knowledge layer | Vault named `Claude` recommended |

Verify your environment:

```bash
make check-prereqs
```

## Quick Start

### 1. Clone and install Paivot globally into Codex

```bash
git clone https://github.com/paivot-ai/paivot-codex.git
cd paivot-codex
make install-global
```

That installs:

- Paivot skills into `~/.codex/skills/`
- the global Paivot instructions into `~/.codex/AGENTS.md`

Install somewhere else if needed:

```bash
make install-global CODEX_HOME=/path/to/codex-home
```

### 2. Verify your vault

```bash
vlt vaults
vlt vault="Claude" search query=""
```

### 3. Trust the project you want Codex to use

Codex only applies repo-local settings such as `.codex/config.toml`, repo-local custom agents, and repo-local MCP declarations for trusted projects.

In practical terms:

- untrusted project: Codex uses your global `~/.codex/config.toml`, but may ignore that repo's `.codex/` settings
- trusted project: Codex also loads the repo's `.codex/config.toml`, local agents, and repo-specific MCP entries

Codex stores that under `~/.codex/config.toml` in a `projects` table:

```toml
[projects."/absolute/path/to/repo"]
trust_level = "trusted"
```

Example:

```toml
[projects."/Users/you/src/my-app"]
trust_level = "trusted"
```

If you trust a parent directory, its children inherit that behavior. If a parent path is marked `untrusted`, child repos underneath it will stay untrusted unless you add a more specific trusted entry.

### 4. Start Codex

CLI:

```bash
cd /path/to/your/project
codex
```

Desktop app:

```bash
codex app
```

Then prompt normally:

```text
Use skill orchestrator. Use Paivot to build <description>.
```

Or:

```text
Use Paivot on this repo.
```

## Repo-Local Codex Surface

This repo includes [`.codex/config.toml`](.codex/config.toml) as the current recommended Codex baseline for Paivot-oriented work.

It sets:

- `model = "gpt-5.4"` for general work
- `review_model = "gpt-5.3-codex"` for review-heavy flows
- `approval_policy = "on-request"`
- `sandbox_mode = "workspace-write"`
- `model_reasoning_effort = "medium"`
- `plan_mode_reasoning_effort = "high"`
- `openaiDeveloperDocs` MCP at `https://developers.openai.com/mcp`
- two practical profiles:
  - `paivot_research` for live web research
  - `paivot_review` for read-only review passes

It also includes repo-local custom agents under `.codex/agents/`:

- `reviewer` for correctness-focused code review
- `docs_researcher` for read-only docs verification before making decisions

Use those repo-local config patterns as a template for the projects where you actually want Codex to run Paivot.

## How Paivot Runs In Codex

### Dispatcher Pattern

When you invoke Paivot, the main Codex session becomes a dispatcher:

- it asks `pvg loop next --json` what should happen next
- it spawns the right specialized agent
- it relays user-facing question blocks when needed
- it uses `pvg story deliver|accept|reject` for tracker transitions
- it does not implement code itself

### Role Split

| Role | Purpose |
|------|---------|
| `orchestrator` | Dispatcher and workflow coordinator |
| `business_analyst` | Business discovery and BUSINESS.md |
| `designer` | UX/API/CLI design and DESIGN.md |
| `architect` | Technical architecture and ARCHITECTURE.md |
| `sr_pm` | Backlog creation and bug triage |
| `developer` | Story implementation with proof |
| `pm_acceptor` | Evidence-based delivery review |
| `anchor` | Adversarial backlog and milestone review |
| `retro` | Learnings capture after milestones |

Specialist challenger roles are available for D&F review:

- `ba_challenger`
- `designer_challenger`
- `architect_challenger`

### Execution workflow

The execution loop (orchestrator skill) drives stories through development, review, and delivery. Two structural gates enforce quality:

**Story gate:** Every story must have passing integration tests with no mocks before the PM-Acceptor will accept it. Tests gated behind env vars or skipped tests are rejected on sight.

**Epic gate:** After all stories in an epic are accepted and merged to the epic branch, three steps run before the epic reaches main:

1. **E2e verification** -- the full test suite (unit + integration + e2e) runs on the merged epic branch. No epic is done without passing e2e tests.
2. **Anchor milestone review** -- the Anchor agent validates real delivery: no mocks in integration tests, boundary maps satisfied, skills consulted.
3. **Merge to main** -- depends on `workflow.solo_dev` setting:
   - `true` (default): merge directly to main, push, delete epic and story branches
   - `false`: create a PR for team review

Configure with: `pvg settings workflow.solo_dev=false` for team workflows.

### Skills Included

| Skill | Purpose |
|------|---------|
| `orchestrator` | Automated multi-agent dispatcher |
| `developer` | Implement one story and deliver proof |
| `pm_acceptor` | Accept or reject delivered work |
| `sr_pm` | Create or repair nd stories |
| `pvg` | Shared live backlog routing and workflow control |
| `nd` | nd tracker reference and usage patterns |
| `vlt` | Vault CLI reference and patterns |
| `vault_knowledge` | How agents should read and capture knowledge |
| `vault_capture` | Deliberate capture pass |
| `vault_evolve` | Improve vault content from experience |
| `vault_status` | Vault health overview |
| `vault_triage` | Review system-scope vault proposals |
| `vault_settings` | Project-level settings and toggles |
| `c4` | Optional architecture-as-code support |
| `intake` | Turn user feedback into backlog work |

## Shared Live Backlog Model

Paivot does not treat branch-local issue files as the live queue.

Use:

```bash
pvg nd ...
```

Not:

```bash
nd ...
```

for the live dispatcher flow.

Why:

- `pvg nd` resolves the shared vault from the repo's git common dir
- all worktrees see the same mutable backlog
- story branches stay isolated for code, not for queue state

This is the key safety rule for concurrent multi-agent execution.

## Git Workflow

Paivot Codex uses:

- `main` as the protected trunk
- `story/<id>` as the per-story branch

Typical flow:

```bash
git fetch origin
git checkout -b story/PROJ-a1b2 origin/main
```

Developer agents implement on the story branch, record evidence in nd, and deliver through:

```bash
pvg story deliver PROJ-a1b2
```

PM review then accepts or rejects:

```bash
pvg story accept PROJ-a1b2 --reason "Accepted: ..."
pvg story reject PROJ-a1b2 --feedback "EXPECTED: ... DELIVERED: ... GAP: ... FIX: ..."
```

Merge only through:

```bash
pvg story merge PROJ-a1b2
```

See [docs/GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) for the detailed branch and recovery rules.

## Practical Codex Usage

### Recommended prompts

Start the full workflow:

```text
Use skill orchestrator. Use Paivot to build <description>.
```

Advance the loop:

```text
Use skill orchestrator. Continue the Paivot loop for this repo.
```

Run a specific story:

```text
Use skill developer. story_id=PROJ-a1b2.
```

Review delivered work:

```text
Use skill pm_acceptor. story_id=PROJ-a1b2.
```

### Useful Codex profiles

General Paivot work:

```bash
codex
```

Research-heavy work:

```bash
codex -p paivot_research
```

Read-only review:

```bash
codex -p paivot_review
```

### OpenAI docs lookup

For OpenAI API, ChatGPT, or Codex-specific questions, Paivot now prefers the OpenAI Docs MCP server first, before falling back to general web search.

## If Something Goes Wrong

Use the smallest escape hatch that solves the problem:

| Situation | What to run | What it does |
|-----------|-------------|--------------|
| Stop unattended execution | `pvg loop cancel` | Stops the active loop without deleting backlog or vault data |
| Recover after crash, compaction, or orphaned worktrees | `pvg loop recover` | Rebuilds recoverable loop state safely |
| Inspect current backlog safely | `pvg nd stats` | Reads the shared live backlog |
| Verify a delivered story before PM review | `pvg story verify-delivery <story-id>` | Checks whether the delivery proof block is structurally complete |

Do not hand-edit loop state files or branch-local nd copies to recover a session.

## Development

```bash
make help
make check-prereqs
make install-global
make verify STORY=PROJ-a1b2
make bump v=1.43.1
```

Current repo-local custom Codex surface:

- `.codex/config.toml`
- `.codex/agents/reviewer.toml`
- `.codex/agents/docs-researcher.toml`

Current global Paivot install surface:

- `AGENTS.global.md`
- `.agents/skills/*`

## Relationship To Other Paivot Repos

- [paivot.ai](https://paivot.ai) is the product and methodology site
- `paivot-codex` is the Codex-specific packaging and operating guide
- `paivot-graph` is the Claude Code integration
- `paivot-opencode` is the OpenCode integration
- `pvg` is the shared control plane

## License

Apache 2.0
