#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vault="$("${script_dir}/resolve-nd-vault.sh" --ensure)"

exec nd --vault "${vault}" "$@"
