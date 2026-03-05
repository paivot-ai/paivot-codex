---
name: vault_capture
description: >
  Capture knowledge from the current session to the vault with auto-tagging and link suggestions.
  Use when the user says "capture knowledge", "save to vault", "vault capture", or at the end of a significant work session.
---

# Vault Capture

Capture knowledge from the current session to the appropriate vault. Auto-derives tags, validates domains, suggests related links, and triages to the correct folder.

## Step 1: Load Context

Load the vault_knowledge skill to understand the controlled domain vocabulary and note template.
Use skill vault_knowledge for reference on domains, templates, and frontmatter conventions.

Detect the current project:

```bash
project=$(git remote get-url origin 2>/dev/null | xargs basename -s .git || basename "$(pwd)")
```

## Step 2: Review Session for Capturable Knowledge

Scan the conversation for:

- **Decisions**: "chose X", "decided to", "went with", "trade-off"
- **Patterns**: "this approach", "reusable", "pattern", "anti-pattern"
- **Debug insights**: "root cause", "the issue was", "fixed by", "gotcha"
- **Concepts**: "learned that", "turns out", "works by"

For each finding, extract:
1. Title (concise, searchable)
2. Type (decision|pattern|debug|concept)
3. Summary (1-2 sentences)
4. Content (the actual knowledge)
5. Stack (technologies involved)
6. Domain (from controlled vocabulary)

## Step 3: Validate Domain

Check domain against controlled vocabulary:

```
ai-training, ai-inference, ai-agents, ai-nlp
dev-tools-cli, dev-tools-testing, dev-tools-workflow, dev-tools-knowledge
security-gateway, security-hardening, security-compliance
finance-quant, finance-fintech
frontend-ui, frontend-performance
calendar-sync
```

If domain doesn't match, suggest closest match or ask user to pick.

## Step 4: Determine Scope

Ask: "Would this knowledge help someone on a DIFFERENT project with a DIFFERENT codebase?"

- **Yes** -> Global vault, triage to folder based on type
- **No** -> Project vault `.vault/knowledge/<type>/`

## Step 5: Suggest Related Links

Before creating, search for related notes:

```bash
vlt vault="Claude" search query="<keywords from title>" --json
```

Present top 5 matches. ALWAYS include at least the project note as a related link.

## Step 6: Derive Tags

Auto-derive tags based on domain:

| Domain | Tag |
|--------|-----|
| ai-training | `#ai/training` |
| ai-inference | `#ai/inference` |
| ai-agents | `#ai/agents` |
| ai-nlp | `#ai/nlp` |
| dev-tools-cli | `#dev-tools/cli` |
| dev-tools-testing | `#dev-tools/testing` |
| dev-tools-workflow | `#dev-tools/workflow` |
| dev-tools-knowledge | `#dev-tools/knowledge` |
| security-gateway | `#security/gateway` |
| security-hardening | `#security/hardening` |
| security-compliance | `#security/compliance` |
| finance-quant | `#finance/quant` |
| finance-fintech | `#finance/fintech` |
| frontend-ui | `#frontend/ui` |
| frontend-performance | `#frontend/performance` |
| calendar-sync | `#calendar/sync` |

## Step 7: Create Note

Build using the template with frontmatter: type, project, stack, domain, status, confidence, created.
Include sections: Summary, Content, Related (at least one wikilink), Tags (at bottom).

Create in `_inbox/` first, then triage immediately.

## Step 8: Triage Immediately

Move to the correct folder based on type:

```bash
vlt vault="Claude" move path="_inbox/<Title>.md" to="<type>s/<Title>.md"
```

## Step 9: Update Project Note

Append session update with summary and captured notes.

## Step 10: Report Summary

Show captured notes, links added, and any skipped items.

## Validation Checklist

- [ ] All domains are from controlled vocabulary
- [ ] Each note has at least one wikilink in "Related"
- [ ] Tags are derived from domain, placed at bottom
- [ ] Note is triaged to correct folder
- [ ] Project note is updated
