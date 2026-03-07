---
name: vault_settings
description: >
  View and configure paivot-graph settings for the current project -- project vault
  behavior, default scope, proposal expiry, workflow FSM, C4 architecture.
  Use when the user says "vault settings", "configure vault", "show settings",
  or wants to change project-level behavior.
---

# Vault Settings

Manage paivot-graph configuration for the current project. Settings are stored in `.vault/knowledge/.settings.yaml` and affect how knowledge governance behaves.

## Step 1: Load Current Settings

```bash
cat .vault/knowledge/.settings.yaml 2>/dev/null || echo "not found"
```

Default settings:

```yaml
project_vault_git: ask          # tracked, ignored, ask
default_scope: system           # system, project
proposal_expiry_days: 30        # days before stale warning
session_start_max_notes: 10     # max notes per subfolder at start
auto_init_project_vault: ask    # auto, ask, never
stack_detection: false           # detect tech stack at start
workflow.fsm: false              # structural enforcement of nd status transitions
workflow.sequence: open,in_progress,delivered,review,closed
workflow.exit_rules: blocked:open,in_progress;rejected:in_progress
workflow.custom_statuses: delivered,review,rejected
architecture.c4: false           # C4 model alongside ARCHITECTURE.md
dnf.specialist_review: false     # challenger review after each BLT document
dnf.max_iterations: 3            # max creator-challenger loops before escalation
bug_fast_track: false            # allow non-sr_pm agents to create bugs directly
```

## Step 2: Present Current Configuration

Show the user a table of current settings with descriptions.

## Step 3: Apply Changes

Edit `.vault/knowledge/.settings.yaml` directly. Create it if it doesn't exist:

```bash
mkdir -p .vault/knowledge
# Use yq if available, otherwise edit the YAML file directly
# Example: set workflow.fsm to true
yq -i '.workflow.fsm = true' .vault/knowledge/.settings.yaml 2>/dev/null || \
  sed -i '' 's/^workflow\.fsm:.*/workflow.fsm: true/' .vault/knowledge/.settings.yaml
```

## Step 4: Report

```
## Vault Settings Updated

Changed:
- <setting>: <old value> -> <new value>

Settings file: .vault/knowledge/.settings.yaml
```

## Invocation

```bash
codex "Use skill vault_settings. Show current project settings."
codex "Use skill vault_settings. Enable workflow FSM."
```
