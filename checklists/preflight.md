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

## R CMD check

- [ ] `devtools::check(cran = TRUE)` returns 0 errors, 0 warnings
- [ ] Only acceptable NOTEs: "New submission" and "unable to verify current time"

## URL checks

- [ ] Every URL in `DESCRIPTION` (`URL:` and `BugReports:` fields) returns 200
      ```r
      urlchecker::url_check()
      ```
- [ ] No pkgdown URL in DESCRIPTION unless the pkgdown site is actually deployed

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
