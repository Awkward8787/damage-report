# Damage Report Format

Use this structure for both `latest.md` and archived reports.

```markdown
# Damage Report

## Target

- Repository:
- Mode: local | branch | pull-request
- PR:
- Base:
- Head:
- Branch:
- Generated (UTC):
- Reviewer: Cursor Agent using damage-report

## Executive Summary

- Headline: CLEAR | LIGHT | MODERATE | HEAVY | CRITICAL | BLOCKED
- Damage Score: 0-100
- Release Readiness: 0-100
- Confidence: high | medium | low
- Merge Recommendation: ready | not ready | blocked

One concise paragraph describing the change, current quality, and principal risk.

## Intended Change

What the change is supposed to accomplish and the evidence used to infer that intent.

## Change Map

| Subsystem | Files | What changed | Risk notes |
|---|---|---|---|

## Findings

| ID | Severity | Category | Location | Status | Summary |
|---|---|---|---|---|---|

### DR-001 — Finding title

- Severity:
- Category:
- Location:
- Status:
- Evidence:
- Impact:
- Recommended correction:
- Verification after correction:

Repeat for every finding. Write `No actionable findings` when appropriate.

## Verification

| Check | Command or source | Result | Evidence / blocker |
|---|---|---|---|

## Review and CI Intake

- Current-head review threads:
- Stale or carried-forward feedback:
- CI status:
- PR description quality:

## Scope and Drift

- Intended scope:
- Unexpected files or behavior:
- Unrelated pre-existing debt intentionally excluded:

## Priority Actions

1.
2.
3.

## Merge Decision

State `ready`, `not ready`, or `blocked`, followed by one sentence explaining why.

<!-- DAMAGE_REPORT_STATE
{"status":"actionable","headline":"MODERATE","damage_score":16,"release_readiness":84,"confidence":"medium","actionable_ids":["DR-001","DR-002"],"blocked_reasons":[],"head_sha":"abc123","base_ref":"origin/main"}
-->
```

## Writing requirements

- Use exact file paths and line numbers where stable.
- Quote only the minimum code or output needed to prove a finding.
- Separate command failure from product failure.
- Mark checks as `not run`, `passed`, `failed`, or `blocked`.
- Do not use green checkmarks for checks that were inferred rather than executed.
- Keep the executive summary concise; put technical detail under findings.
