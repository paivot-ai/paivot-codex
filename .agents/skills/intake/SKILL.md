---
name: intake
description: >
  Capture UX/visual/functional feedback and turn it into a prioritized backlog
  of high-quality stories using the Sr. PM agent. Use when the user says "intake",
  "feedback", "I have issues to report", "create stories from feedback",
  or provides a batch of product feedback items.
---

# Intake -- Feedback to Backlog

Collect user feedback about the current state of the product, then delegate to the Sr. PM agent to create properly structured stories.

**Vault:** `vlt vault="Claude"` (resolves path dynamically)

## Phase 1: Collect Raw Feedback

Say: "Ready for feedback. Describe each issue -- include screenshots if you have them. Say 'that's all' when done."

For each issue the user describes:
1. Acknowledge it in your own words to confirm understanding
2. Ask clarifying questions if the desired outcome is ambiguous
3. Record it in a running list (DO NOT create nd issues yet -- the Sr. PM will do that)

Keep collecting until the user says "that's all" or equivalent.

## Phase 2: Gather Context Before Delegating

Before spawning the Sr. PM agent, YOU must gather context and pass it in the prompt. The agent cannot be trusted to do this on its own.

### 2a. Fetch vault knowledge

```bash
vlt vault="Claude" read file="Session Operating Mode" follow
vlt vault="Claude" read file="<project-name>" follow
```

### 2b. Detect the project's tech stack

Identify the language, framework, and platform from the codebase.

### 2c. Build the skill mapping

Based on the detected stack, determine which skills apply to the stories.

## Phase 3: Delegate to Sr. PM Agent

Spawn the `sr_pm` agent (via `spawn_agent`). The prompt MUST include:

1. **The complete list of raw feedback items**
2. **The project name and working directory**
3. **All vault knowledge fetched in Phase 2a** -- paste actual content
4. **The tech stack and applicable skills**
5. **Any DESIGN.md, ARCHITECTURE.md, or similar doc paths**

The sr_pm agent will:
1. Read the relevant source code
2. Use the vault knowledge to avoid rediscovering known patterns
3. Create properly structured stories with full context, AC, testing requirements
4. Establish dependencies between stories
5. Return the complete backlog

**DO NOT create stories yourself.** The Sr. PM produces higher quality stories.

## Phase 4: Present Backlog for Triage

After the Sr. PM returns, present the backlog to the user:

1. Show all stories sorted by priority in a table
2. Ask: "This is the proposed backlog. Want to reorder, cut, merge, or add anything?"
3. Wait for user approval. Adjust if requested.

## Phase 5: Execute

### Concurrency Limits (HARD RULE)

Stack-dependent limits:

**Heavy stacks** (Rust, iOS/Swift, C#, CloudFlare Workers):
- Max 2 developer agents, 1 PM-Acceptor, 3 total

**Light stacks** (Python, non-CF TypeScript/JavaScript):
- Max 4 developer agents, 2 PM-Acceptor, 6 total

### Execution Loop

Work through the approved backlog top-to-bottom. For each story:

1. **Spawn a developer agent** to implement the story
2. **Spawn a PM-Acceptor agent** to review the delivered story
3. **Capture learnings** to the vault
4. If a discovered issue arises, quick-capture it: `nd q "Discovered: <description>" --type=bug`
5. Move to the next story

## Constraints

- No speculative refactoring. Only fix what is in the backlog.
- Every UI change must follow platform conventions.
- If a fix reveals a deeper problem, create a NEW story rather than scope-creeping.
- After completing all stories, run `vault_evolve` to refine vault content.

## Invocation

```bash
codex "Use skill intake. I have feedback about the app."
```
