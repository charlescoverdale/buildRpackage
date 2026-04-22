# Pre-flight checklist

Run every item before calling `submit`. Items marked with (HARD STOP)
must pass; the skill will refuse to proceed to submission if any fail.
Items marked with (FIX) can be auto-fixed by the skill.

## Policy checks (HARD STOP)

- [ ] No `globalenv()` / `.GlobalEnv` / `assign(..., envir = globalenv())` / `rm(..., envir = globalenv())` anywhere in `R/`
      ```bash
      grep -rn "globalenv\|\.GlobalEnv\|assign.*envir\|rm.*envir" R/
      ```
- [ ] Every `\donttest{}` example that writes to disk redirects cache to `tempdir()`
- [ ] Every network-dependent test has `skip_on_cran()` and `skip_if_offline()`
- [ ] `tests/testthat/setup.R` sets the cache option to `tempfile(...)` if the package uses caching
- [ ] No bundled files over 5 MB in `inst/` or `data/`

- [ ] **No `\dontrun{}` in any roxygen example** unless the example genuinely cannot execute (credentials, interactive-only, irreversible system modification). CRAN reviewers will flag `\dontrun` wrapping slow-but-runnable or network code and demand `\donttest{}` instead. This is the recurring "Benjamin Altmann feedback" pattern.
      ```bash
      # Surface every \dontrun usage — inspect each one
      grep -rn '\\dontrun' R/ man/
      ```
      For each match, confirm one of the valid reasons applies:
      - Requires API key / OAuth token that cannot be embedded safely
      - Opens an interactive UI (Shiny app, browser window)
      - Makes irreversible changes (writes to `~`, modifies global config)
      If none apply, rewrite to `\donttest{}` (see
      `playbook/donttest-vs-dontrun.md`). `\donttest{}` is the default
      for "works but too slow / too network-y for inline examples".
      ivcheck 0.1.0 was rejected 2026-04-21 for `\dontrun{}` around a
      pure-R simulation that took > 5 s — exactly the anti-pattern.

- [ ] **Every `par()`, `options()`, and `setwd()` mutation inside `vignettes/`, `man/` examples, and `demo/` has a matching save-restore.** CRAN reviewers will reject otherwise; the user's session state must survive running your examples.
      ```bash
      # Find every mutation — each must have an adjacent save before and restore after
      grep -rn -E 'par\(|options\(|setwd\(' vignettes/ man/ demo/ R/ 2>/dev/null
      ```
      Valid patterns:
      ```r
      # par()
      oldpar <- par(no.readonly = TRUE)
      par(mfrow = c(1, 2))
      # ... plotting ...
      par(oldpar)

      # options()
      oldopt <- options(digits = 3)
      # ... code ...
      options(oldopt)

      # setwd() — avoid entirely in examples/vignettes if possible
      oldwd <- getwd()
      setwd(some_dir)
      # ... code ...
      setwd(oldwd)
      ```
      `par(new = TRUE)` and `par(mfrow = ...)` inside a function body
      that uses `on.exit(par(oldpar), add = TRUE)` also satisfy this.
      Reading `par()` (e.g. `par("mar")`) is safe; only mutations trigger
      the rule. ivcheck 0.1.0 was rejected 2026-04-21 for a
      `par(mfrow = c(1, 2))` in `vignettes/judge-designs.Rmd` with no
      restore.

## R CMD check

- [ ] `devtools::check(cran = TRUE)` returns 0 errors, 0 warnings
- [ ] Only acceptable NOTEs: "New submission" and "unable to verify current time"

## URL checks

- [ ] Every URL in `DESCRIPTION` (`URL:` and `BugReports:` fields) returns 200
      ```r
      urlchecker::url_check()
      ```
- [ ] No pkgdown URL in DESCRIPTION unless the pkgdown site is actually deployed
- [ ] **Every external URL in R code returns HTTP 200** (HARD GATE for
      data-access and API-wrapper packages)
      ```bash
      # Extract URLs from R files and verify each with curl
      grep -rhoE 'https?://[^"[:space:]]+' R/ | sort -u | \
        while read url; do
          code=$(curl -s -o /dev/null -w "%{http_code}" \
                 -H "User-Agent: Mozilla/5.0" "$url")
          echo "$code $url"
        done
      ```
      Any 404, 403, connection refused, or timeout means that function is
      broken for users. Fix before submission. See
      `reference/code-audit-checklist.md` Section 1a for details.

- [ ] **Every DOI referenced in the package resolves via CrossRef**
      (HARD GATE for packages that cite papers, bundle research data,
      or depend on academic replication archives). DOIs appear in three
      places the URL grep above misses:
      - `<doi:10.xxxx/yyyy>` in DESCRIPTION's Description field
      - `\doi{10.xxxx/yyyy}` in roxygen R files and generated .Rd
      - DOI strings stored in bundled metadata tables
      CrossRef is the authoritative DOI registry. Do NOT verify via
      `https://doi.org/<doi>` — publishers (AEA, Wiley, OUP, Elsevier)
      routinely block bot traffic with 403s that are not real failures.
      CrossRef's API never bot-blocks and distinguishes "real 404 (DOI
      does not exist)" from "publisher blocked your UA".
      ```bash
      # Extract and verify every DOI in the package
      {
        grep -rhoE '<doi:[^>]+>' DESCRIPTION 2>/dev/null | \
          sed -E 's/<doi:(.*)>/\1/'
        grep -rhoE '\\doi\{[^}]+\}' R/ man/ 2>/dev/null | \
          sed -E 's/\\doi\{(.*)\}/\1/'
        grep -rhoE '10\.[0-9]{4,}/[A-Za-z0-9._/:-]+' R/ | \
          grep -oE '10\.[0-9]{4,}/[A-Za-z0-9._/:-]+'
      } | sort -u | while read doi; do
        code=$(curl -s -o /dev/null -w "%{http_code}" \
               -H "User-Agent: preflight-check" \
               --max-time 10 \
               "https://api.crossref.org/works/$doi")
        echo "$code $doi"
      done
      ```
      Any 404 from CrossRef means the DOI does not exist: either a
      typo, stale pre-publication DOI, or paper was republished under
      a new DOI. Fix before submission. Common causes:
      - Pre-print DOI used instead of published-version DOI
      - Journal ID (?id=...) captured instead of DOI
      - Single-digit typo in volume/issue portion
      - Manuscript number confused with article DOI
      Consider adding a `test-urls.R` with `skip_on_cran()` and
      `skip_if_offline()` that verifies every DOI in the package's
      metadata table at local test time. This catches regressions that
      R CMD check will not.

## Documentation

- [ ] Every exported function has `@return`
- [ ] Every exported function has working `@examples`
- [ ] `@examples` use `\donttest{}` for slow/network; `\dontrun{}` only for credential-required
- [ ] All `@importFrom` entries reference functions that exist and are used (FIX)
- [ ] No em dashes in R/ or man/ if `em_dashes_allowed: false` in user-config (FIX)
- [ ] Title in DESCRIPTION is in Title Case
- [ ] Description in DESCRIPTION does not start with "This package..."
- [ ] Description does not contain the package name
- [ ] Software and API names quoted in single quotes in Description

## Files

- [ ] `NEWS.md` has entry for the current version
- [ ] `cran-comments.md` exists and references the current version
- [ ] `LICENSE` file exists and matches the licence field in DESCRIPTION
- [ ] `LICENSE.md` exists (excluded from build via `.Rbuildignore`)
- [ ] `.Rbuildignore` includes `^cran-comments\.md$`
- [ ] No `Rplots.pdf` in the package root (FIX: remove it)
- [ ] No `.Rproj.user/` directory committed

## Version (HARD GATE)

- [ ] **First submission: version MUST be `0.1.0`**. If it is
  anything else, STOP. Bump DESCRIPTION, consolidate NEWS.md into
  a single 0.1.0 entry, and update cran-comments.md before
  proceeding. Submitting 0.2.0 or higher as a first submission
  triggers reviewer suspicion and often leads to a re-do.
- [ ] **Resubmission (not currently on CRAN, e.g. archived):**
  bump at least the patch version from the previously-submitted
  version. Not 0.1.0.
- [ ] **Update to live CRAN package:** version must be strictly
  greater than the current CRAN version.

To check whether a package is on CRAN:
```r
# 200 = currently on CRAN; 404 = never on CRAN or archived
# (archived packages redirect to /src/contrib/Archive/<pkg>/)
httr2::req_perform(httr2::request(
  paste0("https://cran.r-project.org/package=", pkg_name)
))
```

Alternatively search https://cran.r-project.org/ directly.

## Git state

- [ ] Working tree is clean (`git status` shows no changes)
- [ ] Current branch is `main` or equivalent
- [ ] Latest commit is pushed to origin

## Final build test

- [ ] `R CMD build <pkg>` produces a tarball
- [ ] `R CMD check --as-cran <pkg>_<version>.tar.gz` returns 0/0/0 (or only acceptable NOTEs)

## If all pass

Proceed to the `submit` phase.
