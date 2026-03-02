#!/usr/bin/env bash
# notify-dispatcher.sh -- Codex notify hook for dispatcher mode reinforcement
#
# Codex only supports the `notify` hook (fires on agent notifications).
# This script checks for an active dispatcher flag and injects a reminder
# into the notification context.
#
# Install: Add to codex.toml under [hooks.notify] if supported,
# or reference in AGENTS.md as a manual check.
#
# Usage: This script is called by Codex when an agent notification fires.
# It checks for .paivot-dispatcher-active in the repo root.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FLAG_FILE="$REPO_ROOT/.paivot-dispatcher-active"

if [ -f "$FLAG_FILE" ]; then
    echo "[PAIVOT DISPATCHER MODE ACTIVE]"
    echo "You are operating as a dispatcher. Do NOT:"
    echo "  - Write source code or tests directly"
    echo "  - Write D&F documents (BUSINESS.md, DESIGN.md, ARCHITECTURE.md) directly"
    echo "  - Create story files directly"
    echo "  - Make architectural or design decisions directly"
    echo ""
    echo "Instead, spawn the appropriate agent skill via spawn_agent."
    echo "Use 'nd ready' to check backlog state."
fi
