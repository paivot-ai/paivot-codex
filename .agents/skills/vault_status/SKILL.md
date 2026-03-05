---
name: vault_status
description: >
  Show Obsidian vault health -- note counts by folder, recent notes, project vault
  status, pending proposals, and actionable knowledge. Use when the user says
  "vault status", "vault health", "show vault", or wants an overview of vault state.
---

# Vault Status

Show the current state and health of both the global Obsidian vault and the project-local vault.

**Global vault:** `vlt vault="Claude"` (resolves path dynamically)
**Project vault path:** `.vault/knowledge/` (relative to project root)

## Steps

1. **Check vault accessibility**:
   ```bash
   vlt vault="Claude" files total
   ```

2. **Gather global vault statistics** by counting files per folder:
   ```bash
   vlt vault="Claude" files folder="methodology" total
   vlt vault="Claude" files folder="conventions" total
   vlt vault="Claude" files folder="decisions" total
   vlt vault="Claude" files folder="patterns" total
   vlt vault="Claude" files folder="debug" total
   vlt vault="Claude" files folder="concepts" total
   vlt vault="Claude" files folder="projects" total
   vlt vault="Claude" files folder="people" total
   vlt vault="Claude" files folder="_inbox" total
   ```

   Also check vault health:
   ```bash
   vlt vault="Claude" orphans
   vlt vault="Claude" unresolved
   ```

3. **Check project vault status**:
   ```bash
   test -d .vault/knowledge && echo "exists" || echo "not initialized"
   ```

   If it exists, count notes per subfolder:
   ```bash
   vlt vault=".vault/knowledge" files folder="decisions" total
   vlt vault=".vault/knowledge" files folder="patterns" total
   vlt vault=".vault/knowledge" files folder="debug" total
   vlt vault=".vault/knowledge" files folder="conventions" total
   ```

4. **Check for actionable knowledge** (retro insights awaiting incorporation):
   ```bash
   vlt vault=".vault/knowledge" search query="actionable: pending"
   ```

5. **Check for pending proposals**:
   ```bash
   vlt vault="Claude" search query="type: proposal"
   ```

6. **Present the report**:

   ```
   ## Vault Status

   ### Global Vault (system scope)
   | Folder        | Count | Purpose                              |
   |---------------|-------|--------------------------------------|
   | methodology/  | N     | Paivot methodology (agent prompts)   |
   | conventions/  | N     | Working conventions                  |
   | decisions/    | N     | Architectural decisions              |
   | patterns/     | N     | Reusable solutions                   |
   | debug/        | N     | Problems and resolutions             |
   | concepts/     | N     | Language/framework knowledge         |
   | projects/     | N     | Project index notes                  |
   | people/       | N     | Team preferences                     |
   | _inbox/       | N     | Unsorted (needs triage)              |
   | **Total**     | **N** |                                      |

   ### Project Vault (.vault/knowledge/)
   Status: <exists | not initialized>

   ### Pending Proposals
   N proposals awaiting review.

   ### Health
   - Inbox items: N
   - Most recent notes: <list of last 5>

   ### Recommendations
   - <actionable suggestions>
   ```

## Invocation

```bash
codex "Use skill vault_status. Show me vault health."
```
