#!/usr/bin/env bash
# verify-delivery.sh -- Preflight check for Paivot delivery proof in nd
#
# Checks that a story has the minimum evidence/proof structure required
# for PM-Acceptor review. Does NOT validate code correctness.
#
# Usage: scripts/verify-delivery.sh <story-id>

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <story-id>"
    echo "Example: $0 PROJ-a1b2"
    exit 2
fi

STORY_ID="$1"

# Verify nd is available
if ! command -v nd >/dev/null 2>&1; then
    echo "[FAIL] nd is not installed or not in PATH"
    exit 2
fi

# Get story content
STORY_OUTPUT=$(nd show "$STORY_ID" 2>&1) || {
    echo "[FAIL] nd show $STORY_ID failed: $STORY_OUTPUT"
    exit 2
}

PASS=0
FAIL=0

check() {
    local name="$1"
    local pattern="$2"
    local fail_msg="$3"

    if echo "$STORY_OUTPUT" | grep -qE "$pattern"; then
        echo "[OK]   $name"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $name -- $fail_msg"
        FAIL=$((FAIL + 1))
    fi
}

echo "Verifying delivery proof for $STORY_ID"
echo "---"

# Check for delivered label
if nd show "$STORY_ID" 2>/dev/null | grep -q "delivered"; then
    echo "[OK]   label:delivered"
    PASS=$((PASS + 1))
else
    echo "[FAIL] label:delivered -- missing 'delivered' label"
    FAIL=$((FAIL + 1))
fi

# Check for implementation evidence section
check "notes:implementation_evidence" \
    "## Implementation Evidence" \
    "missing '## Implementation Evidence' heading"

# Check for nd_contract with delivered status
check "nd_contract:status_delivered" \
    "status: delivered" \
    "missing 'status: delivered' in nd_contract"

# Check for CI/test results
check "notes:ci_test_results" \
    "### CI/Test Results|### Test Results" \
    "missing CI/Test Results section"

# Check for commands run
check "notes:commands_run" \
    "Commands run:|commands run:" \
    "missing 'Commands run:' list"

# Check for summary
check "notes:summary" \
    "Summary:" \
    "missing 'Summary:' line"

# Check for commit SHA
check "notes:commit_sha" \
    "SHA: [0-9a-fA-F]{7,40}" \
    "missing commit SHA"

# Check for AC verification
check "proof:ac_items" \
    "\[x\] AC|### AC Verification" \
    "missing AC verification (checklist or table)"

echo "---"
echo "Passed: $PASS, Failed: $FAIL"

if [ "$FAIL" -eq 0 ]; then
    echo "[PASS] Delivery proof looks complete enough for PM review."
    exit 0
else
    echo "[FAIL] Delivery proof is incomplete; expect PM rejection until fixed."
    exit 1
fi
