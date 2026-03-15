#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/merge-story.sh <story-id> [--base main]
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit 2
fi

story_id="$1"
shift
base_branch="main"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            base_branch="${2:-}"
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

python3 - "$story_id" "$nd_cmd" <<'PY'
import json
import subprocess
import sys

story_id = sys.argv[1]
nd_cmd = sys.argv[2]
out = subprocess.check_output([nd_cmd, "show", story_id, "--json"], text=True)
story = json.loads(out)
labels = set(story.get("labels") or [])
status = story.get("status")
if status != "closed" or "accepted" not in labels:
    raise SystemExit(
        f"ERROR: {story_id} is not merge-ready (status={status}, labels={sorted(labels)})"
    )
PY

story_branch="story/${story_id}"

git fetch origin
git checkout "${base_branch}"
git pull origin "${base_branch}"

if git show-ref --verify --quiet "refs/remotes/origin/${story_branch}"; then
    merge_target="origin/${story_branch}"
elif git show-ref --verify --quiet "refs/heads/${story_branch}"; then
    merge_target="${story_branch}"
else
    echo "ERROR: could not find local or remote branch ${story_branch}" >&2
    exit 1
fi

git merge --no-ff "${merge_target}" -m "merge(${story_branch}): integrate ${story_id}"
git push origin "${base_branch}"

if git show-ref --verify --quiet "refs/remotes/origin/${story_branch}"; then
    git push origin --delete "${story_branch}"
fi

if git show-ref --verify --quiet "refs/heads/${story_branch}"; then
    git branch -D "${story_branch}"
fi

printf 'OK: merged %s into %s and retired branch %s\n' "${story_id}" "${base_branch}" "${story_branch}"
