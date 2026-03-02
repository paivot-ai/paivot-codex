#!/usr/bin/env python3
"""
Minimal verifier for the Paivot Codex delivery contract.

Goal: reduce churn where PM rejects due to missing evidence/proof.

This is intentionally lightweight and text-based; it does not validate code correctness.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def _run_bd_show(story_id: str) -> dict:
    p = subprocess.run(
        ["bd", "show", story_id, "--json"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if p.returncode != 0:
        raise RuntimeError(
            "bd show failed (exit %s): %s" % (p.returncode, (p.stderr or p.stdout).strip())
        )
    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError as e:
        raise RuntimeError("bd show did not return valid JSON: %s" % e) from e


def _last_bd_contract_status(notes: str) -> str | None:
    # We treat the last contract block as authoritative (append-only notes).
    matches = list(
        re.finditer(r"(?ms)^## bd_contract\\s*$.*?^status:\\s*(\\S+)\\s*$", notes)
    )
    if not matches:
        return None
    return matches[-1].group(1).strip()


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Verify a delivered story has minimal evidence/proof.")
    ap.add_argument("story_id", help="Story ID (e.g. bd-a1b2)")
    args = ap.parse_args(argv)

    try:
        story = _run_bd_show(args.story_id)
    except Exception as e:
        print(f"[FAIL] {e}")
        return 2

    labels = set(story.get("labels") or [])
    notes = story.get("notes") or ""

    checks: list[Check] = []

    checks.append(
        Check(
            "label:delivered",
            "delivered" in labels,
            f"labels={sorted(labels)}",
        )
    )

    checks.append(
        Check(
            "notes:implementation_evidence",
            "## Implementation Evidence (DELIVERED)" in notes,
            "missing '## Implementation Evidence (DELIVERED)' heading",
        )
    )

    last_status = _last_bd_contract_status(notes)
    checks.append(
        Check(
            "bd_contract:last_status=delivered",
            last_status == "delivered",
            f"last_status={last_status!r}",
        )
    )

    # Minimal proof shape.
    checks.append(
        Check(
            "notes:ci_test_results",
            "### CI/Test Results" in notes,
            "missing '### CI/Test Results' section",
        )
    )
    checks.append(
        Check(
            "notes:commands_run",
            "Commands run:" in notes,
            "missing 'Commands run:' list",
        )
    )
    checks.append(
        Check(
            "notes:summary",
            "Summary:" in notes,
            "missing 'Summary:' line",
        )
    )
    checks.append(
        Check(
            "notes:commit_sha",
            bool(re.search(r"(?m)^-\\s*SHA:\\s*[0-9a-fA-F]{7,40}\\s*$", notes)),
            "missing '- SHA: <sha>' line",
        )
    )

    # AC verification can be a table or checklist; require at least one explicit AC line.
    checks.append(
        Check(
            "proof:ac_items_present",
            bool(re.search(r"(?m)^- \\[[xX]\\]\\s*AC\\s*#?\\d+:", notes))
            or ("### AC Verification" in notes),
            "missing AC verification (checklist or '### AC Verification' section)",
        )
    )

    ok = all(c.ok for c in checks)
    for c in checks:
        status = "OK" if c.ok else "FAIL"
        detail = f" - {c.detail}" if (c.detail and not c.ok) else ""
        print(f"[{status}] {c.name}{detail}")

    if ok:
        print("[PASS] Delivery proof looks complete enough for PM review.")
        return 0
    print("[FAIL] Delivery proof is incomplete; expect PM rejection until fixed.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

