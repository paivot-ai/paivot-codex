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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ND_CMD="${SCRIPT_DIR}/paivot-nd.sh"
VAULT="$("${SCRIPT_DIR}/resolve-nd-vault.sh" --ensure)"
STORY_FILE="${VAULT}/issues/${STORY_ID}.md"

# Verify nd is available
if ! command -v nd >/dev/null 2>&1; then
    echo "[FAIL] nd is not installed or not in PATH"
    exit 2
fi

# Get story content
STORY_OUTPUT=$("${ND_CMD}" show "$STORY_ID" 2>&1) || {
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

# Check for delivered label from structured JSON, not a plain-text grep
if python3 - "$STORY_ID" "$ND_CMD" <<'PY'
import json
import subprocess
import sys

story_id = sys.argv[1]
nd_cmd = sys.argv[2]
out = subprocess.check_output([nd_cmd, "show", story_id, "--json"], text=True)
story = json.loads(out)
labels = set(story.get("labels") or [])
if "delivered" not in labels:
    print("[FAIL] label:delivered -- missing 'delivered' label")
    raise SystemExit(1)
print("[OK]   label:delivered")
PY
then
    PASS=$((PASS + 1))
else
    FAIL=$((FAIL + 1))
fi

# Check last nd_contract block directly from the file so we verify the
# authoritative EOF contract, not just a stale earlier block.
if python3 - "$STORY_FILE" <<'PY'
from pathlib import Path
import re
import sys

story_file = Path(sys.argv[1])
text = story_file.read_text()
matches = list(re.finditer(r"^## nd_contract\n(?P<body>.*?)(?=^## |\Z)", text, re.M | re.S))

if not matches:
    print("[FAIL] nd_contract:last_block -- no nd_contract block found")
    sys.exit(1)

last = matches[-1]
body = last.group("body")
status = re.search(r"^status:\s*(\w+)", body, re.M)
if not status or status.group(1) != "delivered":
    print("[FAIL] nd_contract:last_block -- authoritative contract is not delivered")
    sys.exit(1)

if text.rstrip() != text[: last.end()].rstrip():
    print("[FAIL] nd_contract:eof -- authoritative contract is not at EOF")
    sys.exit(1)

print("[OK]   nd_contract:last_block")
print("[OK]   nd_contract:eof")
PY
    PASS=$((PASS + 2))
else
    FAIL=$((FAIL + 2))
fi

# Check for implementation evidence section
check "notes:implementation_evidence" \
    "## Implementation Evidence" \
    "missing '## Implementation Evidence' heading"

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
