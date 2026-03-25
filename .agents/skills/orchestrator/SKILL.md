---
name: orchestrator
description: >
  Automated dispatcher for Paivot personas in Codex. Uses spawn_agent for multi-agent
  orchestration, nd stories as the single source of truth, and vault knowledge for
  context. Enforces one-epic-at-a-time containment, D&F gates, status/evidence/proof
  contracts, concurrency limits, the Sr PM / Anchor iterative loop, and the epic
  completion gate (e2e tests + Anchor milestone review) before merging to main.
---

# Orchestrator (Automated via spawn_agent)

## Purpose

The orchestrator coordinates Paivot personas using Codex's `spawn_agent` for automated
multi-agent orchestration. It drains one epic at a time -- all stories accepted, merged,
e2e verified -- before rotating to the next. Parallelization happens WITHIN the current
epic, not across epics.

**Hard rule:** the orchestrator does not implement code. It only dispatches agents
and manages workflow state.

## Defaults and Settings

| Setting | Default | Override |
|---------|---------|----------|
| Epic selection | Auto (highest-priority with actionable work) | `epic_id=EPIC_ID` input |
| Scope | Single epic at a time | `--all` (legacy, no containment) |
| Auto-rotate | On (rotate to next epic after completion gate) | Inherent to epic mode |
| Max iterations | 50 | `--max N` (0 = unlimited) |
| Concurrency | Within current epic only | Stack-dependent limits |

The dispatcher NEVER picks stories from outside the current epic. `pvg loop next --json`
enforces this structurally -- it only returns stories scoped to the active epic.

## Inputs

Provide one of:
- `epic_id` (optional): nd epic to drive to completion
- `story_id` (optional): nd story to advance
- `mode` (optional): `dispatcher` to enter full dispatcher mode for a project
- If none provided: `pvg loop setup` auto-selects the highest-priority epic with actionable work

## Dispatcher Mode

When the user invokes Paivot (phrases like "use Paivot", "Paivot this", "run Paivot"),
you MUST operate as dispatcher-only for the remainder of the session.

In dispatcher mode you are a coordinator, NOT a producer. You:
- Spawn agents via `spawn_agent` and manage their lifecycle
- Relay QUESTIONS_FOR_USER blocks from agents to the user
- Summarize agent outputs
- Manage the nd backlog through `pvg loop next` and `pvg story` transitions
- Capture knowledge to the vault

You NEVER:
- Write BUSINESS.md, DESIGN.md, or ARCHITECTURE.md yourself
- Write source code or tests yourself
- Create story files or bugs yourself
- Make architectural or design decisions yourself
- Skip agents to "save time"
- Resolve merge conflicts yourself (spawn a developer -- conflict resolution requires code judgment)
- Edit source files for any reason, including "cleanup" or "git maintenance"
- Inspect agent worktree internals (cd into worktree dirs, run git log, read source there)
- Re-close stories that the PM-Acceptor already closed (it closes on acceptance -- just read its output)
- Query nd globally for dispatch decisions (use `pvg loop next --json` instead)

### Infrastructure Context (MANDATORY before first developer spawn)

Before spawning the first developer agent in a session, discover what infrastructure
is available locally and include connection details in ALL developer agent prompts.

**Discovery protocol:**
1. `docker ps --format '{{.Names}} {{.Ports}}'` -- running containers
2. Check for docker-compose files, .env files with connection strings
3. Check project README/docs for infrastructure requirements

**Include in developer prompts:**
- List of running services with host:port
- Database connection details
- Required env vars with values (or instructions to obtain them)
- Explicit instruction: "Infrastructure is running. Do NOT gate tests behind env
  vars. Run integration tests directly against these services."

Without this context, developers will reasonably gate tests behind env vars --
creating dormant tests that satisfy no testing gate.

### Context Injection Protocol (MANDATORY before developer spawn)

Before spawning ANY developer agent, the dispatcher MUST enrich the prompt with
concrete codebase context. Advisory instructions like "search for existing modules"
are unreliable -- subagents skip them. Instead, the dispatcher reads the codebase
and INJECTS the context directly into the developer prompt.

**Step 1: Parse the story's CONSUMES block**

Read the story and extract all CONSUMES entries. Each entry names an upstream module.

**Step 2: Extract API signatures from consumed modules**

For each consumed module/file, read it and extract:
- Module name and one-line summary
- All type specifications / signatures on public functions
- Key usage examples

Include as "CODEBASE CONTEXT" in the `spawn_agent` prompt.

**Step 3: Scan ACs for cross-cutting keywords**

Scan ACs for: DLP, rate limit, audit, config, security, telemetry.
For each keyword, grep the codebase for relevant modules. Read discovered modules
and inject their public APIs into the `spawn_agent` prompt.

**Step 4: Inject existing patterns from accepted stories**

If the story follows a walking skeleton, read one accepted module as a TEMPLATE
and inject the first ~30 lines showing module structure and annotations.

The developer receives everything needed to implement WITHOUT searching the codebase.

### Bug Triage Protocol

When a Developer or PM-Acceptor agent outputs `DISCOVERED_BUG:` blocks:
1. Collect all DISCOVERED_BUG blocks from the agent output
2. Spawn `sr_pm` in `mode=bug_triage` with all collected reports
3. Sr PM creates fully structured bugs with AC, epic placement, and chain
4. Wait for Sr PM to finish before continuing (bugs may affect priorities)
5. All bugs are P0. No exceptions.

### Epic Auto-Close

After `pm_acceptor` accepts a story, it checks if all siblings in the parent epic are
closed. If so, it closes the epic. When `pvg loop next --json` detects all stories are
accepted and merged, it returns `epic_complete` -- triggering the completion gate.

### Epic Completion (All Stories Merged)

When `pvg loop next --json` returns `epic_complete`, the epic enters a three-step
completion gate before merging to main. All three steps are structural -- no step
may be skipped.

**Step 1: Epic Verification Gate (STRUCTURAL -- always on)**

Run the FULL test suite on the merged epic branch. This catches integration
failures that passed in isolation on individual story branches but break when
combined. **No epic is done without passing e2e tests. Period.**

```bash
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID

# Run the project's full test suite (unit + integration + e2e)
# Use the project's standard test command (make test, pytest, go test ./..., etc.)
```

**After running the test suite, verify e2e tests exist and ran:**

```bash
pvg verify --check-e2e
```

If `pvg verify --check-e2e` reports zero e2e test files, the gate FAILS --
even if all other tests passed. "0 e2e failures" with 0 e2e tests is not
passing, it is missing. Spawn a developer to write the e2e tests before
proceeding.

Every test must pass -- unit, integration, AND e2e. If any test fails:

1. Spawn developer with:
   ```
   EPIC VERIFICATION FIX. Tests fail on the merged epic/EPIC_ID branch after
   all stories were integrated. Your task: fix the failing tests on the epic
   branch directly. This is NOT a story -- do not create nd issues. Run the
   full test suite after fixing and report results.

   Failing tests: <paste test output>
   Infrastructure: <paste connection details>
   ```
2. After the developer fix, re-run the full test suite.
3. If tests still fail after 2 developer attempts, escalate to user.

Do NOT skip this gate. Do NOT proceed to Step 2 with failing tests.

**Step 2: Anchor Milestone Review**

Spawn anchor in milestone review mode:

```
MILESTONE REVIEW for epic EPIC_ID.

Validate that the completed epic delivered real value:
- Inspect tests for mocks in integration/e2e tests (forbidden)
- Verify skills were consulted where stories required them
- Check that boundary maps are satisfied (PRODUCES/CONSUMES)
- Validate hard-TDD two-commit pattern where applicable

Epic branch: epic/EPIC_ID
```

If the Anchor returns GAPS_FOUND, address the gaps (spawn developer to fix,
or escalate to user) before proceeding. Do NOT merge to main with open gaps.

**Step 3: Merge to Main**

Check the project workflow setting:

```bash
pvg settings workflow.solo_dev
```

**If `workflow.solo_dev=true`** (default -- solo developer, no PRs):

```bash
# Safety: ensure we have the latest main
git checkout main
git pull origin main

# Merge with --no-ff to preserve epic history
git merge --no-ff epic/EPIC_ID -m "merge(main): complete EPIC_ID"
git push origin main

# Clean up epic branch (local + remote)
git branch -D epic/EPIC_ID
git push origin --delete epic/EPIC_ID
```

**If `workflow.solo_dev=false`** (team workflow, PRs required):

```bash
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID

# Create PR for epic -> main (requires gh CLI)
gh pr create --base main --head "epic/EPIC_ID" \
  --title "merge(main): complete EPIC_ID" \
  --body "All stories accepted. Full test suite passing. Anchor review: VALIDATED."
```

## Branch Management (Two-Level Model)

Paivot uses a two-level branching strategy: `main -> epic -> story`.

**Your responsibilities as dispatcher:**

### Story Branch Setup

Before spawning a developer:

```bash
# Ensure epic branch exists (create if needed)
git fetch origin
if ! git rev-parse --verify origin/epic/EPIC_ID >/dev/null 2>&1; then
  git checkout -b epic/EPIC_ID origin/main
  git push -u origin epic/EPIC_ID
fi

# Create story branch from epic
git checkout -b story/STORY_ID origin/epic/EPIC_ID
git push -u origin story/STORY_ID
```

Developer receives a checkout on `story/STORY_ID`. They work in isolation,
cannot accidentally push to epic or main.

### Story Merge (After PM Approves)

**CRITICAL:** Merging is your IMMEDIATE next step after PM acceptance. Complete
the merge (including conflict resolution) before moving to the next priority item.
A story that is accepted in nd but not merged in git is incomplete work.

After PM-Acceptor adds `accepted` and closes the delivered story:

**Step 1: Attempt the merge**

```bash
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID
git merge --no-ff origin/story/STORY_ID -m "merge(epic/EPIC_ID): integrate STORY_ID"
```

**Step 2a: Merge succeeded** -- push and clean up:

```bash
git push origin epic/EPIC_ID
git branch -D story/STORY_ID
git push origin --delete story/STORY_ID
```

**Step 2b: Merge conflict** -- abort, stay on epic, spawn developer, retry:

Do NOT checkout main. Do NOT move to another priority item. Handle inline.

```bash
# 1. Abort the failed merge. Stay on the epic branch.
git merge --abort
# You are still on epic/EPIC_ID. Do NOT checkout main or any other branch.
```

```
# 2. Spawn developer for conflict resolution. Use this exact prompt:
CONFLICT RESOLUTION MODE. Story STORY_ID is accepted but cannot merge
into epic/EPIC_ID due to conflicts.

Your task: rebase story/STORY_ID onto the latest epic/EPIC_ID, resolving
all conflicts.

Steps:
1. git fetch origin
2. git checkout story/STORY_ID
3. git rebase origin/epic/EPIC_ID
4. Resolve conflicts in each file (keep functionality from both sides)
5. git rebase --continue after each resolution
6. Run tests to verify nothing is broken
7. git push --force-with-lease origin story/STORY_ID

Do NOT update nd -- the story is already accepted and closed.
Report: list of conflicting files, resolution decisions, test results.
```

```bash
# 3. After developer completes, retry the merge from the epic branch:
git fetch origin
git checkout epic/EPIC_ID
git pull origin epic/EPIC_ID
git merge --no-ff origin/story/STORY_ID -m "merge(epic/EPIC_ID): integrate STORY_ID"
```

```bash
# 4. If retry succeeds: push and clean up (same as Step 2a).
# 5. If retry STILL fails: escalate to user:
#    "Merge conflict persists for STORY_ID into epic/EPIC_ID after developer
#     rebase. Please resolve manually or provide guidance."
```

**Canonical branch names:** use `epic/<EPIC_ID>` and `story/<STORY_ID>` exactly.
Do not append descriptive suffixes.

**Merge order:** If multiple stories are waiting to merge, process them in
dependency order first, then priority order (P0 first) within each ready layer.

### Story Branch Cleanup (after merge)

After merging a developer's story branch, clean up in one step:

```bash
git branch -D story/<story-id>
git push origin --delete story/<story-id>
```

**Always use `-D` (not `-d`):** the branch is merged to the local epic branch
but not to `origin/main`, so `-d` will always fail with "not fully merged".

## spawn_agent Usage

Codex provides these primitives for multi-agent orchestration:

```python
# Spawn an agent with a specific skill
agent_id = spawn_agent(prompt="Use skill developer. story_id=PROJ-a1b2. ...")

# Wait for agent to complete
result = wait(agent_id)

# Send additional context to an active agent (e.g., user answers)
send_input(agent_id, message="User answers to your questions: ...")

# Re-open a previously closed agent only when needed
resume_agent(agent_id)

# Close an agent when done
close_agent(agent_id)
```

Current Codex behavior to account for:

- Repo-local `AGENTS.md` files are layered with global instructions.
- Subagents inherit the parent session's approval and sandbox policy.
- Branches/worktrees must be created explicitly when the workflow depends on them; do not assume Codex selected the right checkout for you.

## Concurrency Limits

All concurrency is WITHIN the current epic.

Detect stack from project files and enforce limits:

**Heavy stacks** (Rust, iOS/Swift, C#, CloudFlare Workers -- detected via `Cargo.toml`, `*.xcodeproj`, `*.csproj`, `wrangler.toml`, `wrangler.jsonc`):
- Maximum 2 developer agents simultaneously
- Maximum 1 PM-Acceptor agent simultaneously
- Total active agents must not exceed 3

**Light stacks** (Python, non-CF TypeScript/JavaScript -- detected via `pyproject.toml`, `package.json`):
- Maximum 4 developer agents simultaneously
- Maximum 2 PM-Acceptor agents simultaneously
- Total active agents must not exceed 6

When a project mixes stacks, use the most restrictive limit.

### Stack Detection

```bash
# Check for heavy stack indicators
ls Cargo.toml *.xcodeproj *.csproj wrangler.toml wrangler.jsonc 2>/dev/null

# Check for light stack indicators
ls pyproject.toml package.json 2>/dev/null
```

## D&F Orchestration (Greenfield)

### Full D&F: Sequential BLT with Questioning Rounds

```
1. Spawn BA with existing context (vault notes, codebase)
2. FIRST-TURN GATE: Check FIRST output for QUESTIONS_FOR_USER block
   - If present: relay to user, resume agent with answers
     - Check subsequent outputs:
       - If QUESTIONS_FOR_USER again: relay and resume (repeat)
       - If document produced: done, move to next agent
   - If ABSENT on first turn: PROTOCOL VIOLATION (agent skipped mandatory questioning)
     Re-spawn with correction prompt (max 2 retries):
       "You produced <DOCUMENT>.md without asking questions first. This violates
       your mandatory execution sequence. Your FIRST output MUST be a
       QUESTIONS_FOR_USER block. Re-read your instructions and start with
       questions. Do not produce the document until you have received answers."
     If agent still skips after 2 retries: escalate to user
3. Spawn Designer with BUSINESS.md content
4. Same first-turn gate + relay loop until DESIGN.md is produced
5. Spawn Architect with BUSINESS.md + DESIGN.md
6. Same first-turn gate + relay loop until ARCHITECTURE.md is produced
```

**Light D&F note:** The first-turn gate applies equally to light D&F. "Light" means
fewer questioning rounds (1-2 instead of 3-5), NOT "bypass questions". Every BLT agent
must ask at least one round of questions before producing a document.

#### Implementation

```python
def first_turn_gate(agent_id, role_name, doc_name, max_retries=2):
    """Structural enforcement: BLT agents MUST ask questions before producing documents."""
    result = wait(agent_id)

    # First-turn gate: first output MUST contain questions
    if "QUESTIONS_FOR_USER:" not in result:
        # Protocol violation -- agent skipped mandatory questioning
        for retry in range(max_retries):
            close_agent(agent_id)
            agent_id = spawn_agent(prompt=f"""Use skill {role_name}.
You produced {doc_name} without asking questions first. This violates
your mandatory execution sequence. Your FIRST output MUST be a
QUESTIONS_FOR_USER block. Re-read your instructions and start with
questions. Do not produce the document until you have received answers.""")
            result = wait(agent_id)
            if "QUESTIONS_FOR_USER:" in result:
                break
        else:
            # Max retries exhausted -- escalate to user
            user_choice = ask_user(
                f"The {role_name} agent is not asking questions despite being "
                f"instructed to. Answer questions manually or accept as-is?")
            if user_choice == "accept":
                return agent_id, result
            # else: user provides manual answers, resume below

    # Normal relay loop: relay questions until document is produced
    while "QUESTIONS_FOR_USER:" in result:
        user_answers = ask_user(extract_questions(result))
        send_input(agent_id, message=f"User answers: {user_answers}")
        result = wait(agent_id)

    close_agent(agent_id)
    return agent_id, result

# Phase 1: Business Analyst
ba_id = spawn_agent(prompt="""Use skill business_analyst.
problem_statement='<user's problem>'
Existing vault context: <vault search results>
Ask clarifying questions if needed.""")

first_turn_gate(ba_id, "business_analyst", "BUSINESS.md")

# Phase 2: Designer (sequential, needs BUSINESS.md)
business_md = read_file("docs/BUSINESS.md")
designer_id = spawn_agent(prompt=f"""Use skill designer.
product_context from BUSINESS.md:
{business_md}""")

first_turn_gate(designer_id, "designer", "DESIGN.md")

# Phase 3: Architect (sequential, needs BUSINESS.md + DESIGN.md)
design_md = read_file("docs/DESIGN.md")
arch_id = spawn_agent(prompt=f"""Use skill architect.
proposal from BUSINESS.md + DESIGN.md:
{business_md}
{design_md}""")

first_turn_gate(arch_id, "architect", "ARCHITECTURE.md")
```

### Specialist Review Loop (Optional, Setting-Gated)

After each BLT document is produced, check `dnf.specialist_review` in `.vault/knowledge/.settings.yaml`.
If enabled, spawn the matching challenger to adversarially review the document. On rejection,
re-spawn the creator with feedback. Loop up to `dnf.max_iterations` (default 3).

```python
# Challenger mapping: creator skill -> challenger skill, document name, upstream docs
CHALLENGER_MAP = {
    "business_analyst": ("ba_challenger", "BUSINESS.md", []),
    "designer": ("designer_challenger", "DESIGN.md", ["docs/BUSINESS.md"]),
    "architect": ("architect_challenger", "ARCHITECTURE.md", ["docs/BUSINESS.md", "docs/DESIGN.md"]),
}

def specialist_review_gate(creator_skill, user_context, max_iterations=None):
    """After a BLT agent produces its document, run the matching challenger if enabled."""
    settings = load_settings(".vault/knowledge/.settings.yaml")
    if not settings.get("dnf.specialist_review", False):
        return  # Setting disabled, skip review

    if max_iterations is None:
        max_iterations = settings.get("dnf.max_iterations", 3)

    challenger_skill, doc_name, upstream_paths = CHALLENGER_MAP[creator_skill]
    doc_content = read_file(f"docs/{doc_name}")
    upstream_docs = {p: read_file(p) for p in upstream_paths}

    for iteration in range(1, max_iterations + 1):
        # Spawn challenger
        upstream_context = "\n\n".join(f"{p}:\n{c}" for p, c in upstream_docs.items())
        challenger_id = spawn_agent(prompt=f"""Use skill {challenger_skill}.
Iteration: {iteration} of {max_iterations}.
User context: {user_context}
{doc_name}:
{doc_content}
{upstream_context}""")
        review_result = wait(challenger_id)
        close_agent(challenger_id)

        if "REVIEW_RESULT: APPROVED" in review_result:
            return  # Document passed review

        # Rejected -- extract feedback and re-spawn creator
        feedback = extract_between(review_result, "FEEDBACK_FOR_CREATOR:", None)
        creator_id = spawn_agent(prompt=f"""Use skill {creator_skill}.
Rework {doc_name} based on challenger feedback (iteration {iteration + 1}):
{feedback}
Original user context: {user_context}""")
        first_turn_gate(creator_id, creator_skill, doc_name)
        doc_content = read_file(f"docs/{doc_name}")  # Re-read updated document

    # Max iterations exhausted -- escalate to user
    ask_user(
        f"The {challenger_skill} rejected {doc_name} after {max_iterations} iterations. "
        f"Last feedback:\n{feedback}\n\nPlease review and decide how to proceed.")
```

Usage in the D&F flow (after each `first_turn_gate` call):

```python
first_turn_gate(ba_id, "business_analyst", "BUSINESS.md")
specialist_review_gate("business_analyst", user_context)

first_turn_gate(designer_id, "designer", "DESIGN.md")
specialist_review_gate("designer", user_context)

first_turn_gate(arch_id, "architect", "ARCHITECTURE.md")
specialist_review_gate("architect", user_context)
```

### BLT Convergence (MANDATORY after all three documents exist)

All three BLT members cross-review each other's work for consistency.
Can run in parallel (max 3 agents):

```python
# Read all three docs
business = read_file("docs/BUSINESS.md")
design = read_file("docs/DESIGN.md")
architecture = read_file("docs/ARCHITECTURE.md")
all_docs = f"BUSINESS.md:\n{business}\n\nDESIGN.md:\n{design}\n\nARCHITECTURE.md:\n{architecture}"

# Spawn cross-reviews in parallel
ba_review = spawn_agent(prompt=f"""Use skill business_analyst.
Cross-review: check DESIGN.md and ARCHITECTURE.md against BUSINESS.md.
{all_docs}
Output BLT_ALIGNED if consistent, or BLT_INCONSISTENCIES with specific issues.""")

designer_review = spawn_agent(prompt=f"""Use skill designer.
Cross-review: check BUSINESS.md and ARCHITECTURE.md against DESIGN.md.
{all_docs}
Output BLT_ALIGNED if consistent, or BLT_INCONSISTENCIES with specific issues.""")

arch_review = spawn_agent(prompt=f"""Use skill architect.
Cross-review: check BUSINESS.md and DESIGN.md against ARCHITECTURE.md.
{all_docs}
Output BLT_ALIGNED if consistent, or BLT_INCONSISTENCIES with specific issues.""")

# Wait for all three
ba_result = wait(ba_review)
designer_result = wait(designer_review)
arch_result = wait(arch_review)

# Check convergence (max 3 rounds)
for round in range(3):
    if all("BLT_ALIGNED" in r for r in [ba_result, designer_result, arch_result]):
        break  # Convergence complete
    # Collect inconsistencies, present to user, re-run owning agents
    # ...
```

### Post-D&F: Sr PM / Structural Gates / Anchor Pipeline

The post-D&F pipeline is three steps:

```
Sr PM generates backlog -> pvg rtm check + pvg lint -> Anchor reviews
```

The Sr PM and Anchor form a loop. The backlog is NOT ready until the Anchor returns APPROVED.
Between the Sr PM and the Anchor, two deterministic structural gates must pass. If either
gate fails, the Sr PM fixes the issues before the Anchor ever sees the backlog.

```python
for round in range(3):
    # Step 1: Spawn Sr PM
    srpm_id = spawn_agent(prompt=f"""Use skill sr_pm.
mode=greenfield_backlog.
Read docs/BUSINESS.md, docs/DESIGN.md, docs/ARCHITECTURE.md.
Create self-contained stories with all context embedded.
{f'Address Anchor gaps: {anchor_gaps}' if round > 0 else ''}""")
    srpm_result = wait(srpm_id)
    close_agent(srpm_id)

    # Step 2: Structural gates (deterministic -- must pass before Anchor)
    rtm_result = shell("pvg rtm check")
    lint_result = shell("pvg lint")
    if rtm_result.exit_code != 0 or lint_result.exit_code != 0:
        # Gates failed -- re-spawn Sr PM with gate failures (counts as same round)
        srpm_id = spawn_agent(prompt=f"""Use skill sr_pm.
mode=fix_anchor_gaps.
Structural gates failed. Fix these before Anchor review:
pvg rtm check output: {rtm_result.output}
pvg lint output: {lint_result.output}""")
        wait(srpm_id)
        close_agent(srpm_id)
        # Re-check gates
        rtm_result = shell("pvg rtm check")
        lint_result = shell("pvg lint")
        if rtm_result.exit_code != 0 or lint_result.exit_code != 0:
            escalate_to_user("Structural gates still failing after Sr PM fix attempt.")
            break

    # Step 3: Spawn Anchor
    anchor_id = spawn_agent(prompt=f"""Use skill anchor.
mode=backlog_review.
epic_id={epic_id}.
Review the backlog for gaps. Return APPROVED or REJECTED.""")
    anchor_result = wait(anchor_id)
    close_agent(anchor_id)

    if "APPROVED" in anchor_result:
        break  # Backlog is ready
    anchor_gaps = extract_gaps(anchor_result)

# If 3 rounds exhausted without APPROVED: escalate to user
```

## Setup

Initialize the loop before entering the iteration protocol:

```python
# Default: auto-select highest-priority epic with actionable work
shell("pvg loop setup")

# Target a specific epic
shell("pvg loop setup --epic EPIC_ID")

# Legacy: run across all epics without containment (not recommended)
shell("pvg loop setup --all")
```

Verify activation succeeded before continuing.

## Execution Loop (Post-Backlog Approval)

The loop drains one epic at a time. Each iteration, `pvg loop next --json` is the
SINGLE SOURCE OF TRUTH for what happens next. Do NOT query nd directly with
`pvg nd ready --json` or `pvg nd list --json` for choosing what to work on next.
Those queries are unscoped and will return stories from ALL epics, breaking containment.

You MAY use nd directly for:
- Reading story content before spawning a developer (`pvg nd show STORY_ID`)
- Checking story labels (`pvg nd show STORY_ID --json`)
- Bug triage routing (DISCOVERED_BUG blocks)
- Epic auto-close checks after PM acceptance

```python
while True:
    # 0. Bug triage: check if any prior agent output had DISCOVERED_BUG blocks
    if pending_bug_reports:
        srpm_id = spawn_agent(prompt=f"""Use skill sr_pm. mode=bug_triage.
Create properly structured bugs for these discovered issues:
{pending_bug_reports}""")
        wait(srpm_id)
        close_agent(srpm_id)
        pending_bug_reports = None
        continue  # Re-evaluate priorities after new bugs created

    step = shell("pvg loop next --json")

    if step.decision == "complete":
        break  # All epics drained
    if step.decision == "blocked":
        break  # All remaining work globally is blocked (--all mode)
    if step.decision == "wait":
        wait_for_existing_agents()  # Agents working in current epic
        continue
    if step.decision == "epic_complete":
        run_epic_completion_gate(step.epic_id)  # e2e + Anchor + merge to main
        continue
    if step.decision == "epic_blocked":
        escalate_to_user(f"All remaining work in epic {step.epic_id} is blocked.")
        break
    if step.decision == "rotate":
        # Epic done and gate passed. Update loop state to next epic.
        shell(f"pvg loop setup --epic {step.next_epic}")
        continue
    if step.decision != "act":
        escalate_to_user(step.reason)
        break

    story_id = step.next.story_id

    if step.next.role == "pm_acceptor":
        # NOTE: PM-Acceptor closes the story itself on acceptance via pvg story accept.
        pm_id = spawn_agent(prompt=f"Use skill pm_acceptor. story_id={story_id}.")
        pm_result = wait(pm_id)
        close_agent(pm_id)
        if "DISCOVERED_BUG:" in pm_result:
            pending_bug_reports = extract_bug_reports(pm_result)
        # IMMEDIATELY after acceptance: merge story branch to epic branch
        # Complete the merge before running pvg loop next --json again.
        merge_story_to_epic(story_id, step.epic_id)
        continue

    if step.next.hard_tdd and step.next.phase == "red":
        run_hard_tdd(story_id)
        continue

    prompt_suffix = ""
    if step.next.queue == "rejected":
        prompt_suffix = " Rework."

    dev_id = spawn_agent(prompt=f"Use skill developer. story_id={story_id}.{prompt_suffix}")
    dev_result = wait(dev_id)
    close_agent(dev_id)
    if "DISCOVERED_BUG:" in dev_result:
        pending_bug_reports = extract_bug_reports(dev_result)
```

## Epic Flow

The loop drains one epic at a time:

1. **Start**: `pvg loop setup` auto-selects the highest-priority epic with actionable work
2. **Execute**: all parallelization happens WITHIN the current epic
   (multiple developers on different stories, one PM reviewing)
3. **Complete**: when all stories are accepted and merged to the epic branch,
   `pvg loop next --json` returns `epic_complete`
4. **Gate**: run the epic completion gate (e2e tests + Anchor milestone review + merge to main)
5. **Rotate**: `pvg loop next --json` returns `rotate` with `next_epic` -- update state and continue

Epic completion is a GATE, not a passthrough. The full gate (e2e, Anchor, merge to main)
MUST finish before rotation. There is no cherry-picking across epics.

## Termination

The loop drains one epic at a time. Termination conditions:

| Condition | Action |
|-----------|--------|
| No actionable epics remain | Allow exit |
| Current epic blocked, no other epics | Allow exit |
| Max iterations reached | Allow exit |
| Too many consecutive waits (3) | Allow exit |
| Current epic has actionable work | Continue |
| Current epic complete, next epic exists | Rotate, continue |

### Live Demo (before session exit)

Every session must produce demonstrable progress. Before the loop exits:

1. Identify what was delivered (accepted stories, completed epics, merged to main)
2. If anything was merged to main: run the project's demo, smoke test, or e2e suite
   on main and report results to the user
3. If nothing reached main: explain what blocked progress and what the user should
   do next

A session that cannot show working software at the end should be treated as a
signal that something is wrong with the backlog, the infrastructure, or the
test suite -- not as normal.

## Context Loss Recovery

After context loss (compaction, new session, restart), run recovery as the FIRST
command before touching git, before spawning agents, before inspecting branches:

```python
# Recovery after context loss
shell("pvg loop recover")

# Then resume the execution loop -- pvg loop next --json picks up where we left off
step = shell("pvg loop next --json")
```

`pvg loop recover` automatically:
1. Removes stale agent worktrees and branches
2. Resets orphaned in-progress stories to `open` (delivered stories are preserved)
3. Outputs a recovery summary showing what is ready, delivered, and needs attention

**Before expected context loss**, note the current agent assignments in nd:
```python
shell("pvg nd update <story-id> --append-notes 'Agent state: developer active, commit <sha>'")
```

Recovery always works because nd state is persistent and authoritative.

## QUESTIONS_FOR_USER Relay

When an agent output contains `QUESTIONS_FOR_USER:`, the orchestrator:

1. Extracts the questions block
2. Presents them to the user
3. Resumes the agent with answers

```python
if "QUESTIONS_FOR_USER:" in agent_result:
    questions = extract_between(agent_result, "QUESTIONS_FOR_USER:", "END_QUESTIONS")
    user_answers = ask_user(questions)
    send_input(agent_id, message=f"User answers:\n{user_answers}")
    agent_result = wait(agent_id)
```

## Hard-TDD Orchestration

When a story has the `hard-tdd` label:

### Phase 1: RED (Test Author)

```python
test_author = spawn_agent(prompt=f"""Use skill developer. story_id={story_id}.
RED PHASE: Write tests ONLY. Do not implement production code.
Tests must prove the AC when they pass. Commit test files only.""")
wait(test_author)
close_agent(test_author)

# Record test commit
test_commit = shell("git rev-parse HEAD")

# PM reviews tests
pm_id = spawn_agent(prompt=f"""Use skill pm_acceptor. story_id={story_id}.
RED PHASE review: If these tests passed, would they prove the story is done?""")
pm_result = wait(pm_id)
close_agent(pm_id)
```

### Phase 2: GREEN (Implementer)

```python
implementer = spawn_agent(prompt=f"""Use skill developer. story_id={story_id}.
GREEN PHASE: Make the existing tests pass. Do NOT modify test files.
Test commit: {test_commit}""")
wait(implementer)
close_agent(implementer)

# Verify test files untouched
tampered = shell(f"git diff {test_commit} --name-only -- '*_test.go' '*.test.*' '*.spec.*'")
if tampered:
    # Reject, restore tests, re-spawn implementer
    shell(f"git checkout {test_commit} -- {tampered}")
```

## Decision Rules (What To Run Next)

These rules apply WITHIN the current epic. `pvg loop next --json` encodes them;
do not re-implement them in prompt logic.

| Decision | Condition | Action |
|----------|-----------|--------|
| `act` (pm_acceptor) | Delivered stories in current epic | Spawn `pm_acceptor` |
| `act` (developer) | Rejected stories in current epic | Spawn `developer` (rework) |
| `act` (developer) | Ready stories in current epic | Spawn `developer` (new) |
| `epic_complete` | All stories accepted and merged | Run epic completion gate |
| `epic_blocked` | All remaining work in epic is blocked | Escalate to user |
| `wait` | In-progress work in current epic | Wait for agent completions |
| `rotate` | Epic gate passed, next epic exists | Update loop state to next epic |
| `complete` | All epics drained | Allow exit |
| `blocked` | All remaining work globally blocked (--all mode) | Allow exit |

Pre-execution priorities (checked before `pvg loop next --json`):

| Priority | Condition | Next Skill |
|----------|-----------|------------|
| 0 | DISCOVERED_BUG blocks pending | `sr_pm` (bug_triage) |
| - | D&F incomplete (greenfield) | `business_analyst` -> `designer` -> `architect` |
| - | D&F complete, no backlog | `sr_pm` -> `anchor` loop |
| - | Milestone complete | `retro` |

Use `pvg story deliver|accept|reject` for state transitions. The orchestrator should not
replay label choreography itself after an agent already completed the transition.

## Required nd Operations

**Dispatch decisions come from `pvg loop next --json` ONLY.** Do NOT use the queries
below for choosing what to work on next -- they are unscoped and break epic containment.

```bash
pvg loop next --json   # SINGLE SOURCE OF TRUTH for dispatch decisions
pvg nd prime           # Full project context
pvg nd show <id>       # Full story context (allowed for reading before agent spawn)
pvg nd show <id> --json # Check labels (allowed for hard-tdd detection, etc.)
pvg nd stats           # Backlog statistics
```

The following are informational only -- never use them for dispatch:

```bash
pvg nd ready           # Unblocked work (UNSCOPED -- do not use for dispatch)
pvg nd ready --parent <epic-id> --json # Scoped but pvg loop next is authoritative
pvg nd list --status in_progress --label delivered --json  # Informational only
pvg nd list --status open --label rejected --json          # Informational only
```

**nd filter cheat sheet** (prevents wasted queries with wrong flags):
- Priority: `--priority 0` (not `--label P0` -- priority is not a label)
- Labels: `--label delivered`, `--label rejected`, `--label hard-tdd`
- Type: `--type bug`, `--type task`, `--type epic`
- Parent: `--parent <epic-id>`

As of nd v0.7.0, `nd ready` supports the same filter flags as `nd list`:
`--parent`, `--status`, `--label`, `--type`, `--assignee`, `--priority`,
`--no-parent`, `--sort`, `--reverse`, `--limit`, date range filters, `--json`.
Run `nd <command> --help` if unsure about available flags.

## Invocation

```bash
codex "Use skill orchestrator. Use Paivot to build <description>."
codex "Use skill orchestrator. epic_id=PROJ-a1b2. Drive this epic to completion."
codex "Use skill orchestrator. Pick the next ready story and advance it."
```
