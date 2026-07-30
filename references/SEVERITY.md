# Damage Report Severity Model

Use impact and reachability together. Choose the lowest severity that accurately represents the evidence.

## P0 — Critical

A reachable issue likely to cause catastrophic harm or make release unsafe:

- Authentication or authorization bypass.
- Exposure of credentials, private data, or destructive administrative capability.
- Irrecoverable data loss or corruption.
- Remote code execution or equivalent critical compromise.
- A change that reliably takes a critical production path offline with no safe fallback.

P0 requires concrete evidence of a reachable path. Do not assign P0 to a speculative concern.

## P1 — High

A probable production defect with major user, business, security, or operational impact:

- Core feature is broken for a meaningful user segment.
- Incorrect billing, permissions, data writes, or externally visible results.
- Migration or deployment can fail or leave the system inconsistent.
- Significant regression with no practical workaround.
- Required CI/build/test failure that demonstrates the branch cannot ship.

## P2 — Medium

A real defect or material risk that should be fixed before merge when within scope:

- Important edge case fails.
- Error path is unsafe, misleading, or insufficiently recoverable.
- API contract or validation is incomplete but limited in impact.
- Missing test coverage for changed high-risk behavior.
- Performance or reliability regression likely under realistic load.
- Accessibility or responsive behavior prevents use in a supported scenario.

## P3 — Low

A limited, non-blocking problem:

- Small maintainability issue with a concrete future cost.
- Minor user-facing inconsistency.
- Low-risk test, documentation, logging, or observability gap.
- Defensive improvement where current behavior remains correct.

## Non-findings

Do not create findings for:

- Personal style preferences.
- Unchanged legacy debt unless the change makes it worse.
- Purely hypothetical concerns with no plausible execution path.
- Formatter output or generated-file noise with no behavioral impact.
- A missing optimization without evidence of a performance requirement.

## Status rules

- `actionable`: a change is required in the reviewed branch.
- `informational`: useful context, but no branch change is required.
- `already-addressed`: evidence shows a later change resolved it.
- `blocked`: the issue cannot be evaluated or corrected with current access.
- `needs-confirmation`: product intent or environment evidence is required before classifying it as a defect.
