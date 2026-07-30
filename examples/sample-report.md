# Damage Report

## Target

- Repository: example/app
- Mode: pull-request
- PR: #42
- Base: main
- Head: 8f34c2a
- Branch: feature/session-refresh
- Generated (UTC): 2026-07-30T13:00:00Z
- Reviewer: Cursor Agent using damage-report

## Executive Summary

- Headline: MODERATE
- Damage Score: 16
- Release Readiness: 84
- Confidence: high
- Merge Recommendation: not ready

The PR adds automatic session refresh and is structurally sound, but two reachable retry-path defects can create duplicate refresh requests and log users out after a transient network failure.

## Intended Change

Refresh access tokens before expiration without interrupting active sessions.

## Change Map

| Subsystem | Files | What changed | Risk notes |
|---|---|---|---|
| Client auth | `src/auth/session.ts` | Added refresh scheduling | Timing and duplicate execution |
| API client | `src/api/client.ts` | Retries after 401 | Error classification |
| Tests | `src/auth/session.test.ts` | Added happy-path coverage | Missing concurrency case |

## Findings

| ID | Severity | Category | Location | Status | Summary |
|---|---|---|---|---|---|
| DR-001 | P2 | Concurrency | `src/auth/session.ts:88` | actionable | Multiple callers can start refresh simultaneously |
| DR-002 | P2 | Reliability | `src/api/client.ts:141` | actionable | Network errors are treated as invalid refresh tokens |

## Verification

| Check | Command or source | Result | Evidence / blocker |
|---|---|---|---|
| Unit tests | `npm test -- session.test.ts` | passed | 12 tests |
| Typecheck | `npm run typecheck` | passed | Exit 0 |
| Full test suite | `npm test` | passed | 438 tests |

## Priority Actions

1. Add a shared in-flight refresh promise.
2. Separate transient transport errors from rejected refresh credentials.
3. Add concurrent-call and network-failure tests.

## Merge Decision

Not ready until DR-001 and DR-002 are fixed and the targeted tests prove both paths.

<!-- DAMAGE_REPORT_STATE
{"status":"actionable","headline":"MODERATE","damage_score":16,"release_readiness":84,"confidence":"high","actionable_ids":["DR-001","DR-002"],"blocked_reasons":[],"head_sha":"8f34c2a","base_ref":"main"}
-->
