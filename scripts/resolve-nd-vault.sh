#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${ND_VAULT_DIR:-}" ]]; then
    printf '%s\n' "$ND_VAULT_DIR"
    exit 0
fi

if [[ -n "${PAIVOT_ND_VAULT:-}" ]]; then
    printf '%s\n' "$PAIVOT_ND_VAULT"
    exit 0
fi

common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || {
    echo "ERROR: not inside a git repository; cannot resolve shared nd vault" >&2
    exit 1
}

if [[ "${common_dir}" != /* ]]; then
    common_dir="$(cd "${common_dir}" && pwd)"
fi

vault="${common_dir}/paivot/nd-vault"

if [[ "${1:-}" == "--ensure" ]]; then
    mkdir -p "${vault}"
    if [[ ! -f "${vault}/.nd.yaml" ]]; then
        nd init --vault "${vault}" >/dev/null
    fi
fi

printf '%s\n' "${vault}"
