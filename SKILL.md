---
name: damage-report
description: >
  Performs an evidence-based review of local code changes or a GitHub pull request and produces a persistent
  engineering status report. Use when Cursor is coding, before opening or merging a PR, after a large edit,
  when the user asks what changed, what is broken, what remains, whether the branch is ready, or requests a
  Greptile-style PR assessment without requiring Greptile.
license: MIT
compatibility: Designed for Cursor Agent. Requires git. GitHub PR enrichment requires the authenticated GitHub CLI (gh). Project checks may require the repository's normal package manager and toolchain.
metadata:
  author: Awkward8787
  version: "1.0.0"
  skill-family: damage-report
allowed-tools: Bash(git:*) Bash(gh:*) Read Grep Glob
---

# Damage Report

Create a high-signal, evidence-backed status report for the current worktree, branch, commit range, or GitHub pull request. This skill is **review-first**: do not edit production code, resolve threads, commit, or push. Use `damage-report-loop` when the user wants findings fixed iteratively.

## Inputs

Accept any combination of:

- A GitHub PR number or URL.
- A base ref such as `main`, `develop`, or a commit SHA.
- `--quick`: inspect the diff, existing checks, and highest-risk paths; run only targeted checks.
- `--full`: run the complete available verification suite. This is the default when scope is reasonable.
- `--no-write`: return the report in chat without creating report files.
- A named scope such as security, API contracts, database changes, UI, performance, or tests.

If no target is provided, inspect the current branch and working tree.

## Non-negotiable rules

1. Report only issues supported by code, diff, command output, repository conventions, or review evidence.
2. Distinguish facts, inferences, and unverified risks.
3. Focus on regressions or risks introduced by the target change. Do not turn unrelated legacy debt into blockers.
4. Never expose secrets, tokens, private keys, credential values, or sensitive environment content.
5. Never run destructive commands, production migrations, deploys, billing operations, or commands that modify remote state.
6. Never claim a test passed unless the command completed successfully during this run or a current CI result proves it.
7. Preserve the user's worktree exactly. This skill is read-only except for report artifacts under `.cursor/damage-reports/`.

## Procedure

### 1. Establish the review target

Confirm this is a git worktree:

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git rev-parse HEAD
```

Capture the initial dirty state so report artifacts are not confused with product changes.

Determine the target in this order:

1. Explicit PR number or URL.
2. PR associated with the current branch:
   ```bash
   gh pr view --json number,url,title,body,state,isDraft,baseRefName,headRefName,headRefOid 2>/dev/null
   ```
3. Explicit base ref.
4. Remote default branch:
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null
   ```
5. `origin/main`, `origin/master`, `main`, or `master`, whichever exists.
6. If no base can be resolved, review staged and unstaged changes only and state the limitation.

For a PR, use the PR base and head SHA. For a branch review, use the merge base:

```bash
git merge-base <BASE_REF> HEAD
```

Include staged, unstaged, and untracked source files in local mode. Never silently omit working-tree changes.

### 2. Collect change evidence

Collect a compact change map before reading individual files:

```bash
git diff --stat <BASE>...HEAD
git diff --name-status <BASE>...HEAD
git log --oneline --decorate <BASE>..HEAD
git diff --stat
git diff --name-status
git diff --cached --stat
git diff --cached --name-status
git ls-files --others --exclude-standard
```

Then inspect the actual patches. Review generated files, lockfiles, schemas, migrations, configuration, and CI files separately from handwritten application code.

For GitHub PRs, also collect:

```bash
gh pr view <PR> --json number,url,title,body,state,isDraft,author,baseRefName,headRefName,headRefOid,mergeable,reviewDecision,statusCheckRollup,files,commits
gh pr checks <PR>
gh api --paginate "repos/{owner}/{repo}/issues/<PR>/comments?per_page=100"
gh api --paginate "repos/{owner}/{repo}/pulls/<PR>/reviews?per_page=100"
gh api --paginate "repos/{owner}/{repo}/pulls/<PR>/comments?per_page=100"
```

Use timestamps and head SHA to separate current feedback from stale feedback. A comment on an older revision may still be valid, but label it as carried forward rather than current-head evidence.

### 3. Reconstruct intent

Determine what the change is supposed to accomplish from:

- The user's current request.
- PR title and description.
- Linked issue or acceptance criteria, when available.
- Commit messages.
- Existing tests, types, schemas, API contracts, and nearby canonical implementations.

Write a one-paragraph **Intended Change**. If intent remains ambiguous, state the ambiguity and avoid inventing requirements.

### 4. Build the change map

Group changed files by subsystem and identify boundaries crossed:

- UI or client.
- API or service layer.
- Authentication and authorization.
- Database, migrations, queues, caches, or storage.
- Shared types, schemas, and public contracts.
- Infrastructure, deployment, CI, and environment configuration.
- Tests, fixtures, generated code, and dependencies.

Call out cross-layer changes because they carry higher regression risk.

### 5. Discover and run verification

Prefer repository-defined commands over generic guesses. Inspect, as applicable:

- `package.json` scripts and workspace configuration.
- `Makefile`, `justfile`, `Taskfile.yml`.
- `pyproject.toml`, `tox.ini`, `pytest.ini`.
- `go.mod`, `Cargo.toml`, `pom.xml`, Gradle files.
- CI workflows under `.github/workflows/`.
- Project documentation and `.cursor/rules/`.

Run the narrowest relevant checks first, then broader checks when practical:

1. Tests directly covering changed behavior.
2. Type checking or compilation.
3. Linting or static analysis.
4. Full unit/integration suite.
5. Build.
6. Security or dependency checks already configured by the repository.

Do not install new global tools or change dependency versions merely to complete the audit. If a command cannot run, record the exact blocker.

### 6. Review the code

Inspect the complete changed behavior, not only changed lines. Trace callers, callees, schemas, tests, and error paths where needed.

Evaluate applicable categories:

- Correctness and acceptance criteria.
- Security, authentication, authorization, input validation, and secret handling.
- Data integrity, migrations, transactions, idempotency, and rollback behavior.
- API and schema compatibility.
- State management, concurrency, race conditions, retries, and duplicate execution.
- Error handling, observability, operational recovery, and failure modes.
- Performance, query patterns, memory, network, and unnecessary work.
- Test quality, missing cases, brittle mocks, and false-positive tests.
- UI behavior, responsiveness, accessibility, loading, empty, and error states.
- Maintainability, duplication, confusing abstractions, and repository convention drift.
- Deployment, configuration, environment, and CI impact.

Do not report style preferences already enforced by formatters unless they create a real maintenance or correctness risk.

### 7. Classify findings

Use the severity model in [references/SEVERITY.md](references/SEVERITY.md).

Each finding must contain:

- Stable ID: `DR-001`, `DR-002`, and so on.
- Severity: `P0`, `P1`, `P2`, or `P3`.
- Category.
- Exact file and line, symbol, command, check, or review thread.
- Evidence.
- User or system impact.
- Recommended correction.
- Status: `actionable`, `informational`, `already-addressed`, `blocked`, or `needs-confirmation`.

Do not inflate severity. A theoretical possibility without a reachable path is not a confirmed defect.

### 8. Calculate status

Calculate the **Damage Score**:

- Each P0: +40
- Each P1: +20
- Each P2: +8
- Each P3: +2
- Each failing required check not already represented by a finding: +15
- Each unresolved actionable current-head review thread not already represented: +5
- Cap at 100

Set **Release Readiness** to `100 - Damage Score`.

Assign the headline state:

- `CLEAR`: no actionable P0/P1/P2 findings, required checks pass, and no unresolved actionable current-head review threads.
- `LIGHT`: only P3 findings or non-blocking verification gaps.
- `MODERATE`: one or more P2 findings, but no P0/P1.
- `HEAVY`: one or more P1 findings.
- `CRITICAL`: one or more P0 findings.
- `BLOCKED`: evidence collection or verification is materially incomplete.

Set confidence to `high`, `medium`, or `low` based on diff coverage, test coverage, runtime evidence, and access to PR/CI context. Confidence is not a quality score.

### 9. Write the report

Unless `--no-write` was requested, create:

- `.cursor/damage-reports/latest.md`
- `.cursor/damage-reports/<UTC_TIMESTAMP>-<SAFE_TARGET>.md`

Do not stage or commit these files unless the user explicitly requests it. Use the format in [references/REPORT_FORMAT.md](references/REPORT_FORMAT.md).

The report must include a machine-readable footer:

```html
<!-- DAMAGE_REPORT_STATE
{"status":"clear","headline":"CLEAR","damage_score":0,"release_readiness":100,"confidence":"high","actionable_ids":[],"blocked_reasons":[],"head_sha":"<sha>","base_ref":"<ref>"}
-->
```

Use lowercase `status` values: `clear`, `actionable`, or `blocked`.

### 10. Return the chat summary

Return:

1. Target reviewed and current head SHA.
2. Headline state, Damage Score, Release Readiness, and confidence.
3. Count of findings by severity.
4. Failing or unavailable checks.
5. The three highest-priority actions.
6. Report file path, when written.
7. A direct merge recommendation: `ready`, `not ready`, or `blocked`.

Never hide findings only because the overall score is good.
