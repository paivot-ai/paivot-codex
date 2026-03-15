#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/story-transition.sh deliver <story-id>
  scripts/story-transition.sh accept <story-id> [--reason <text>] [--next <story-id>]
  scripts/story-transition.sh reject <story-id> [--feedback <text>]
EOF
}

if [[ $# -lt 2 ]]; then
    usage
    exit 2
fi

action="$1"
story_id="$2"
shift 2

reason=""
feedback=""
next_story=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reason)
            reason="${2:-}"
            shift 2
            ;;
        --feedback)
            feedback="${2:-}"
            shift 2
            ;;
        --next)
            next_story="${2:-}"
            shift 2
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            usage
            exit 2
            ;;
    esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nd_cmd="${script_dir}/paivot-nd.sh"
vault="$("${script_dir}/resolve-nd-vault.sh" --ensure)"

"${nd_cmd}" show "${story_id}" >/dev/null 2>&1 || {
    echo "ERROR: story not found: ${story_id}" >&2
    exit 1
}

append_contract() {
    local status="$1"
    local evidence="$2"
    local proof="$3"
    local block

    block=$(cat <<EOF

## nd_contract
status: ${status}

### evidence
- ${evidence}

### proof
- ${proof}
EOF
)
    "${nd_cmd}" update "${story_id}" --append-notes "${block}" >/dev/null
}

case "${action}" in
    deliver)
        "${nd_cmd}" update "${story_id}" --status=in_progress >/dev/null
        "${nd_cmd}" labels rm "${story_id}" rejected >/dev/null 2>&1 || true
        "${nd_cmd}" labels rm "${story_id}" accepted >/dev/null 2>&1 || true
        "${nd_cmd}" labels add "${story_id}" delivered >/dev/null
        append_contract \
            "delivered" \
            "Transitioned via story-transition deliver on $(date +%Y-%m-%d)." \
            "[ ] Developer evidence block must remain authoritative above this contract."
        ;;
    accept)
        "${nd_cmd}" labels rm "${story_id}" delivered >/dev/null 2>&1 || true
        "${nd_cmd}" labels rm "${story_id}" rejected >/dev/null 2>&1 || true
        "${nd_cmd}" labels add "${story_id}" accepted >/dev/null
        close_args=(close "${story_id}" "--reason=${reason:-Accepted via story-transition}")
        if [[ -n "${next_story}" ]]; then
            close_args+=("--start=${next_story}")
        fi
        "${nd_cmd}" "${close_args[@]}" >/dev/null
        append_contract \
            "accepted" \
            "PM closeout applied via story-transition accept on $(date +%Y-%m-%d)." \
            "[x] Story closed after accepted label was applied."
        ;;
    reject)
        "${nd_cmd}" update "${story_id}" --status=open >/dev/null
        "${nd_cmd}" labels rm "${story_id}" delivered >/dev/null 2>&1 || true
        "${nd_cmd}" labels rm "${story_id}" accepted >/dev/null 2>&1 || true
        "${nd_cmd}" labels add "${story_id}" rejected >/dev/null
        if [[ -n "${feedback}" ]]; then
            "${nd_cmd}" comments add "${story_id}" "${feedback}" >/dev/null
        fi
        append_contract \
            "rejected" \
            "PM rejection applied via story-transition reject on $(date +%Y-%m-%d)." \
            "[ ] Story requires another developer delivery before it can be accepted."
        ;;
    *)
        echo "ERROR: unknown action: ${action}" >&2
        usage
        exit 2
        ;;
esac

"${nd_cmd}" doctor --fix >/dev/null
printf 'OK: %s %s using shared nd vault %s\n' "${action}" "${story_id}" "${vault}"
