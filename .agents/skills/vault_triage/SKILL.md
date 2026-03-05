---
name: vault_triage
description: >
  Triage notes in _inbox to their proper folders and check vault health.
  Use when the user says "triage vault", "clean inbox", "vault triage", or when _inbox has accumulated notes.
---

# Vault Triage

Review notes in `_inbox/` and move them to the correct folders. Also check for orphan notes and broken wikilinks.

**Vault:** `vlt vault="Claude"` (resolves path dynamically)

## Step 1: Check Inbox

List all notes in `_inbox/`:

```bash
vlt vault="Claude" files folder="_inbox" --json
```

If empty:
```
## Vault Triage
_inbox/ is empty. Nothing to triage.
```

## Step 2: For Each Inbox Note

Read each note and determine:

1. **Type** (from frontmatter): decision, pattern, debug, concept, convention, methodology
2. **Target folder** based on type
3. **Domain validation**: Check domain is from controlled vocabulary
4. **Missing links**: Check if "Related" section exists with at least one wikilink

Present to user with issues identified.

### User Decision

1. **Move** -> triage to correct folder
2. **Edit** -> fix issues before moving
3. **Delete** -> remove if not vault-worthy
4. **Skip** -> leave for later

## Step 3: Apply Triage

### Move Note

```bash
vlt vault="Claude" move path="_inbox/<Note>.md" to="<folder>/<Note>.md"
```

### Fix Missing Links

Search for related notes and add to Related section.

### Fix Missing Tags

Derive tags from domain and add to body.

## Step 4: Check Vault Health

```bash
# Orphans (notes with no incoming links)
vlt vault="Claude" orphans --json

# Broken wikilinks
vlt vault="Claude" unresolved --json
```

Report health metrics and fix issues.

## Step 5: Report Summary

```
## Vault Triage Summary

### Moved
- [[Note A]] -> decisions/
- [[Note B]] -> patterns/

### Fixed
- Added Related section to [[Note C]]
- Added tags to [[Note D]]

### Vault Health
- _inbox: 0
- Orphans: N
- Broken links: 0
```

## Controlled Domain Vocabulary

Valid domains:
- ai-training, ai-inference, ai-agents, ai-nlp
- dev-tools-cli, dev-tools-testing, dev-tools-workflow, dev-tools-knowledge
- security-gateway, security-hardening, security-compliance
- finance-quant, finance-fintech
- frontend-ui, frontend-performance
- calendar-sync

## Constraints

- Every note must have at least one wikilink (no orphans)
- Every note must have domain from controlled vocabulary
- Tags go in body, not frontmatter
- _inbox/ should be empty after triage
