---
name: cran-package
description: End-to-end workflow for shipping an R package to CRAN. Covers ideation, naming, scoping, scaffolding, pre-flight checks, auditing, submission, and resubmission. Captures CRAN policies and common failure modes so you ship cleanly on the first try.
argument-hint: "[phase] [package-name] — phase is one of: ideate, name, plan, build, check, audit, submit, resubmit"
---

# /cran-package

Eight-phase workflow for getting an R package onto CRAN and keeping it there.

The skill is opinionated about **CRAN policies** (those are non-negotiable) and permissive about **conventions** (licence, prose style, HTTP library, etc. are user-configurable).

## Phases

| Phase | What it does | Outputs |
|---|---|---|
| `ideate` | Find a market gap worth filling | Ranked candidate list |
| `name` | Check name and prefix availability | Validated name + prefix |
| `plan` | Write a function-by-function scope document | `~/.claude/plans/<name>-scope.md` |
| `build` | Scaffold the package from templates | Full package skeleton |
| `check` | Mechanical pre-flight against CRAN policies | Pass/fail report with file:line |
| `audit` | Deep review (academic or code) | Scorecard with severity-ranked findings |
| `submit` | Push to GitHub and submit to CRAN | Confirmation email prompt |
| `resubmit` | Handle reviewer feedback | Fixed package, new version |

Invoke with `/cran-package <phase> [args]`. If no phase is given, ask the user which phase they want.

**`check` vs `audit`**: `check` is the mechanical CRAN compliance pass (URLs resolve, no `globalenv` manipulation, `\donttest` redirects cache to tempdir). `audit` is the deep review that goes beyond `R CMD check` to catch bugs, numerical instability, weak tests, and academic-credibility gaps. Run both before submission.

## First-time setup

Before the first real run, check whether `~/.claude/skills/cran-package/user-config.yml` exists.

If it does not exist, copy `user-config.example.yml` to `user-config.yml` and ask the user to fill in:
- Author name and email
- GitHub username
- Licence preference (MIT / GPL-2 / GPL-3 / Apache-2.0)
- Prose style (British / American) — affects README wording only
- HTTP client preference (httr2 / httr)
- Em dash preference (true / false)

All template placeholders read from this file. Without a config, the skill can still operate in "explain-only" mode but cannot generate files.

## Archetypes

The `build` phase supports three archetypes. Pick the one that matches the package:

| Archetype | Use for | Extra scaffolding |
|---|---|---|
| `compute` | Pure computation, no network (stats, algorithms, data processing) | None beyond base |
| `api` | REST API wrappers | `auth.R`, `cache.R`, request helpers |
| `data` | Bundled datasets with helpers | `data/`, `data-raw/`, inst data |

Invoke as `/cran-package build <name> --type=compute` (default is `compute`).

## CRAN policies (hard-coded, not configurable)

These are not preferences. They are CRAN policy. The skill refuses to proceed past the `check` phase if any of these fail:

1. **No home-filespace writes from examples.** Every `\donttest` example that writes to disk must redirect to `tempdir()`.
2. **No `globalenv()` / `.GlobalEnv` manipulation.** No `assign(..., envir = globalenv())` or `rm(..., envir = globalenv())` anywhere in R code.
3. **Network tests skip on CRAN.** Any test that hits the network must be wrapped in `skip_on_cran()` and `skip_if_offline()`.
4. **URLs in DESCRIPTION must resolve.** CRAN's incoming feasibility check fails the package otherwise.
5. **`\dontrun` only for examples that cannot run.** Network-dependent examples use `\donttest`. `\dontrun` is reserved for examples requiring credentials you cannot safely embed.
6. **Version bumps on every resubmission.** Even trivial fixes need a new version number.
7. **NEWS.md entry for every version.** No silent releases.

See `playbook/` for the fix pattern for each of these when they come up.

## Preferences (configurable via user-config.yml)

| Preference | Options | Default | Notes |
|---|---|---|---|
| Licence | MIT / GPL-2 / GPL-3 / Apache-2.0 | MIT | Affects LICENSE files |
| Language (DESCRIPTION) | en-GB / en-US | en-US | CRAN convention leans en-US even for British authors |
| Prose style | British / American | American | Affects README wording choices |
| Em dashes | true / false | false | Some CRAN reviewers flag em dashes |
| HTTP client | httr2 / httr | httr2 | httr is superseded but still accepted |
| JSON parser | jsonlite / RcppSimdJson | jsonlite | Matters for heavy JSON workloads |
| Prefix style | two-letter / three-letter / package-name | two-letter | Function name prefix convention |
| S3 print/plot methods | true / false | true | Whether to scaffold `print.<class>()` etc. |
| CRAN badges | true / false | true | Whether to include CRAN status badges in README |

## Phase-by-phase instructions

### Phase 1: `ideate`

Given a domain (e.g. "economics", "genomics", "hydrology") and optional keywords, produce a ranked candidate table.

Search strategy:
1. Check CRAN Task Views for the domain. List packages marked unmaintained.
2. Query cranlogs for top-N packages in the space by monthly downloads.
3. Check each for last-update date. Flag anything unchanged for 3+ years with 1000+ DLs/month as a replacement opportunity.
4. Search the CRAN archive (archived packages page) for recently-removed packages in the domain.
5. List public APIs in the domain that have no CRAN client (requires web search).

Output format: single ranked table with columns `candidate`, `opportunity_type`, `incumbent` (if any), `incumbent_downloads`, `incumbent_last_update`, `estimated_build_effort`, `notes`. One sentence per row in `notes`.

### Phase 2: `name`

Validate the proposed package name against:
- CRAN: HTTP HEAD to `https://cran.r-project.org/package=<name>` — 200 means taken, 404 means available.
- CRAN archive: `https://cran.r-project.org/web/packages/<name>/index.html` may redirect to archive page.
- GitHub: check `https://github.com/<user>/<name>` — 404 means available.
- R base packages: name must not clash with anything in `base`, `utils`, `stats`, `graphics`, `grDevices`, `methods`, `datasets`.
- CRAN naming rules: letters, numbers, full stops. Must start with a letter. Must not contain underscores or hyphens.

Output: ✓ available or ✗ with reason.

### Phase 3: `plan`

Produce a scope document in `~/.claude/plans/<name>-scope.md` with these sections:
1. **Context**: what gap this fills, who uses it, realistic monthly DL estimate
2. **Package metadata**: name, prefix, version (0.1.0 for first submission), licence, language, depends, imports, suggests
3. **Archetype**: compute / api / data
4. **Function spec**: one table per function family. Each row: function name, signature, what it does, data source endpoint (for API archetype), cache key (if cached), notes
5. **File structure**: tree of R/, tests/, data-raw/, inst/
6. **Implementation order**: which families to build first
7. **Verification**: what "done" looks like (test count target, known-value tests)

Refer user to the plan file when done. Do not start building.

### Phase 4: `build`

Scaffold from templates. For each file in `templates/`, substitute placeholders:
- `{{PACKAGE_NAME}}` → chosen name
- `{{PACKAGE_TITLE}}` → one-line Title: value
- `{{PACKAGE_DESCRIPTION}}` → DESCRIPTION text (from plan doc)
- `{{AUTHOR_NAME}}` → from user-config
- `{{AUTHOR_EMAIL}}` → from user-config
- `{{GITHUB_USERNAME}}` → from user-config
- `{{LICENCE}}` → from user-config
- `{{LANGUAGE}}` → from user-config
- `{{PREFIX}}` → chosen prefix (without trailing underscore)
- `{{YEAR}}` → current year
- `{{HTTP_CLIENT}}` → from user-config
- `{{JSON_PARSER}}` → from user-config (if archetype is api or data)

Archetype selection determines which optional templates get used:
- `compute`: package.R, utils.R, tests setup
- `api`: above + auth.R, cache.R, request helpers
- `data`: above + data-raw/ script template

After scaffolding, run `devtools::document()` then `devtools::check()` and report the result.

### Phase 5: `check`

Run the full pre-flight checklist from `checklists/preflight.md`. Report every failure with file:line. Auto-fix the items listed as "auto-fixable":
- Em dashes in R/ and man/ (if user-config `em_dashes: false`)
- Trailing whitespace
- Unused `@importFrom` entries
- Missing `skip_on_cran()` in network tests (prompt before changing)

Hard-stop items (must be fixed before proceeding):
- R CMD check is not 0/0/0 (2 benign NOTEs allowed: "New submission" and "unable to verify current time")
- Any CRAN policy violation from the `playbook/`

Do not proceed to `submit` if any hard-stop fails.

### Phase 6: `audit`

Deep review beyond `R CMD check`. Two sub-modes:

#### `audit academic <pkg>`

For packages that implement named statistical, mathematical, or
scientific methods. Verifies that the package stands up to academic
scrutiny. Uses:

- `checklists/academic-audit.md` as the driving checklist
- `reference/academic-audit-checklist.md` for the detailed heuristic
- `reference/formula-verification.md` for domain-specific formula
  traps (inequality, causal inference, time series, etc.)
- `reference/test-adequacy.md` for the four-level test quality model

Output: a scorecard with pass/warning/blocker for each category,
plus a concrete plan to address blockers before release.

Ten categories audited:
1. Literature coverage (citations, DOIs, primary sources)
2. Formula verification (matches published formula)
3. Reference implementation agreement (cross-checks)
4. Incumbent comparison (what's different vs existing packages)
5. Python comparison (porting from or competing with)
6. Methodological transparency (`@details` for non-obvious code)
7. Limitations disclosure (README section)
8. Test adequacy (Level 2+ tests per function)
9. Reproducibility (seeds, RNG kind)
10. Citation hygiene (CITATION file, stable references)

#### `audit code <pkg>`

For any package before CRAN submission. Goes beyond `R CMD check`
to catch edge-case bugs, numerical instability, weak error
handling, cross-platform issues, and style problems. Uses:

- `checklists/code-audit.md` as the driving checklist
- `reference/code-audit-checklist.md` for the detailed heuristic
- `reference/edge-cases.md` for the empty/length-1/NA/duplicates
  quartet and domain-specific cases
- `reference/numerical-stability.md` for overflow, underflow,
  log-sum-exp, catastrophic cancellation
- `reference/cross-platform-gotchas.md` for paths, encoding,
  timezone traps
- `reference/ropensci-standards.md` as an aspirational ceiling

Output: a scorecard across 12 categories with severity-ranked
findings and specific file:line references.

Twelve categories audited:
1. CRAN policy (hard blockers, delegated to preflight)
2. Edge cases (empty, length-1, NA, duplicates, boundaries)
3. Numerical stability (overflow, underflow, cancellation)
4. Error handling (network, timeouts, malformed responses)
5. Style and idioms (lintr, vapply, seq_along)
6. Documentation quality (specific @return, meaningful @examples)
7. Dependencies (justified imports, version floors)
8. Cross-platform (paths, encoding, timezone)
9. Reproducibility (seeds, no Sys.time defaults)
10. Hidden gotchas (NULL vs missing, partial matching)
11. Security (URL encoding, injection, key leakage) — n/a for
    most packages
12. Performance (accidental O(n²), rbind in loops)

After the scorecard, propose a concrete pre-submission plan:
which blockers to fix now, which warnings can wait for a v0.1.1
patch.

### Phase 7: `submit`

1. Verify working tree is clean. If not, prompt user to commit.
2. Verify current branch is pushed to `origin`. If not, push.
3. Verify `cran-comments.md` exists and mentions the current version.
4. Verify `NEWS.md` has an entry for the current version.
5. Run: `assignInNamespace("yesno", function(...) FALSE, "devtools"); devtools::submit_cran()` — this bypasses the interactive prompt.
6. On success, tell user: "check your email for the CRAN confirmation link — must click within a few hours."
7. Record submission in `state/queue.jsonl` (optional, if state tracking enabled).

### Phase 8: `resubmit`

Input: reviewer email content (user pastes it).

1. Parse the email for the specific issues flagged.
2. Match each issue against `playbook/` entries. Common classifications:
   - Ripley cache policy → `playbook/ripley-cache-policy.md`
   - URL 404 → `playbook/url-404-in-description.md`
   - globalenv manipulation → `playbook/globalenv-manipulation.md`
   - Missing/extra imports → `playbook/unused-importfrom.md`
   - "Possibly misspelled words" → usually informational, not fatal
   - "Examples wrapped in `\dontrun{}` should be executable" → `playbook/donttest-vs-dontrun.md`
3. Apply the fix. Bump patch version in DESCRIPTION. Update NEWS.md and cran-comments.md.
4. Re-run `check` then `submit`.

## State tracking (optional)

If the user wants a submission queue, maintain `~/.claude/skills/cran-package/state/queue.jsonl` with one line per submission:

```json
{"pkg": "mypackage", "version": "0.1.0", "submitted_at": "2026-04-15T18:30:00Z", "status": "pending"}
```

On each `/cran-package` invocation, check the queue and flag any package pending for >7 days so the user can chase.

## Distribution

To share this skill:
- The `SKILL.md`, templates, playbook, reference, and checklists are all generic.
- The user's `user-config.yml` stays local and is not committed.
- Include `user-config.example.yml` in the distribution.
- Add a `.gitignore` entry for `user-config.yml` if publishing to a repo.
