# Code audit checklist

Use this when the user asks for a pre-CRAN-submission code review, or
runs `/cran-package audit code`. Goes beyond `R CMD check` to catch
bugs, style issues, and CRAN-reviewer concerns that automated checks
miss.

## 1. CRAN policy (hard blockers)

Delegated to `checklists/preflight.md`:

- [ ] No `globalenv()` / `.GlobalEnv` / `assign(envir = globalenv())` / `rm(envir = globalenv())`
- [ ] No writes to user's home filespace in examples or tests
- [ ] Network tests wrapped in `skip_on_cran()` + `skip_if_offline()`
- [ ] Every URL in DESCRIPTION resolves
- [ ] `\dontrun` only for examples that genuinely cannot run
- [ ] Every exported function has `@return`
- [ ] Every exported function has working `@examples`
- [ ] 0 errors, 0 warnings on `R CMD check --as-cran`

If any of these fail, stop. Fix before continuing with the rest of
this audit.

## 2. Edge cases

See `reference/edge-cases.md` for the full catalogue. At minimum, for
every exported function check behaviour on:

- [ ] Empty input (`c()`, `character(0)`, `data.frame()`)
- [ ] Length-1 input
- [ ] Input containing `NA`
- [ ] Input that is all `NA`
- [ ] Input containing duplicates
- [ ] Unsorted input (when the function assumes sorted)
- [ ] Input at parameter boundaries (0, 1, ∞, -∞)
- [ ] Integer overflow (sums of large vectors, factorials, choose)
- [ ] Floating-point weirdness (`1/3 * 3 != 1`, `0.1 + 0.2 != 0.3`)

Missing edge-case handling is the #1 source of post-CRAN bug reports.

## 3. Numerical stability

See `reference/numerical-stability.md` for the full list. Common traps:

- [ ] `exp(large)` without log-sum-exp trick → `Inf`
- [ ] `log(0)` without handling → `-Inf`
- [ ] `log(x)` where `x` could be negative → `NaN` with no warning
- [ ] Subtracting nearly-equal numbers (catastrophic cancellation)
- [ ] Dividing by a quantity that could be zero without guard
- [ ] Accumulating a sum of N small numbers without Kahan summation
- [ ] Using `==` to compare floats (should be `abs(a - b) < tol`)

## 4. Error handling

- [ ] Every network call wrapped in `tryCatch()` with a `cli::cli_abort()`
  giving the user actionable guidance
- [ ] HTTP status codes 4xx handled distinctly from 5xx
- [ ] 429 (rate limit) triggers retry-with-backoff, not error
- [ ] 401/403 (auth) gives a clear "check your key" message
- [ ] Timeout handled explicitly (don't rely on default behaviour)
- [ ] Malformed response (200 with invalid JSON) doesn't crash
- [ ] Empty response (200 with empty body) doesn't crash
- [ ] Validation errors (bad user input) use `cli::cli_abort()` with
  `.arg` markup pointing at the problem argument

## 5. Style and idioms

Run `lintr::lint_package()` and fix the high-severity issues. Manual
review for:

- [ ] `vapply()` used instead of `sapply()` where the return type is
  fixed (sapply's variable return type is a common bug source)
- [ ] `seq_along(x)` and `seq_len(n)` instead of `1:length(x)` and
  `1:n` (the latter fails when length is 0)
- [ ] `integer(0)` / `numeric(0)` / `character(0)` instead of `NULL`
  for typed empty vectors
- [ ] `inherits(x, "class")` instead of `class(x) == "class"`
  (the latter breaks for objects with multiple classes)
- [ ] `is.null(x)` check before `length(x)` check (length of NULL is 0,
  which is usually not what you meant)
- [ ] No `library()` or `require()` inside package functions (use
  `loadNamespace()` or `requireNamespace()` for optional deps)

## 6. Documentation quality

Beyond "has roxygen":

- [ ] `@return` is specific (not just "a list" but "a list with
  elements `x`, `y`, `z` where `x` is...")
- [ ] `@examples` actually demonstrate use, not just call the function
  with default args
- [ ] Error conditions documented (what arguments trigger errors)
- [ ] `@seealso` links to related functions in the package
- [ ] `@family` groups related functions into families
- [ ] For S3 classes, `@return` documents the class structure

## 7. Dependencies

- [ ] Every package in `Imports` is actually used
- [ ] Version floors (`>= x.y.z`) are justified (don't add floors
  for versions that are ancient; do add them for versions that
  introduced the specific function you use)
- [ ] `Suggests` for truly optional dependencies (must be guarded
  with `requireNamespace()` in code)
- [ ] Base R operators (`pmin`, `pmax`, `abs`) don't need
  `@importFrom`
- [ ] No tidyverse dependencies unless you need them (tidyverse adds
  significant load time and breakage surface)

## 8. Cross-platform concerns

See `reference/cross-platform-gotchas.md`. Quick checks:

- [ ] All file paths use `file.path()`, not hardcoded separators
- [ ] Temp files use `tempfile()`, not `/tmp/...`
- [ ] No assumption about line endings (`\n` vs `\r\n`)
- [ ] Unicode strings tested (non-ASCII names, paths)
- [ ] Encoding specified when reading files
  (`read.csv(..., fileEncoding = "UTF-8")`)
- [ ] `Sys.time()` and `Sys.Date()` not compared literally in tests
  (they differ across timezones; use fixed values)

## 9. Reproducibility

- [ ] `set.seed()` before any random operation in tests and examples
- [ ] No `Sys.time()` in default arguments (captured at load time,
  not call time)
- [ ] No paths hardcoded to the author's home directory
- [ ] No API keys committed (even in tests; use env vars with
  `skip_if_not(nzchar(Sys.getenv("KEY")))`)

## 10. Hidden gotchas

A few things that catch even experienced authors:

- [ ] `NULL` vs missing argument: use `missing(x)` or `is.null(x)`
  consistently
- [ ] Factors in data frames: specify `stringsAsFactors = FALSE`
  in `data.frame()` (R 4.0+ default changed, but old code may still
  set options that break this)
- [ ] Integer vs double: `1L` vs `1` matters when passing to C code
  or when doing modular arithmetic
- [ ] Partial matching: R allows `df$nam` to match `df$name`, which
  silently breaks if you add a column called `nam_more`. Turn off
  with `options(warnPartialMatchDollar = TRUE)` during development
- [ ] Lazy argument evaluation: default arguments that reference
  other arguments (`f(x = 1, y = x + 1)`) work but are fragile
- [ ] `NextMethod()` behaviour changes with `UseMethod()` signature

## 11. Security

See `reference/security-considerations.md` if the package handles
untrusted input. Most packages don't, but API wrappers should check:

- [ ] User input in URLs is URL-encoded
- [ ] User input in SQL/SPARQL is escaped or parameterised
- [ ] API keys never appear in error messages, URLs (query strings
  are logged), or user-visible output
- [ ] File paths from user input are validated (no `..` traversal)

## 12. Performance

Most CRAN packages don't need to be fast. But check:

- [ ] No accidental O(n²) when O(n) is possible (common with
  `rbind()` in a loop — use `do.call(rbind, list_of_dfs)` instead)
- [ ] No reading a whole file into memory when streaming would work
- [ ] No repeated network calls in a loop when a batch endpoint
  exists
- [ ] `Rprof()` the slow paths if performance matters

## 13. rOpenSci standards

If you want a package that's better than median CRAN quality, apply
rOpenSci review standards as a stretch goal. See
`reference/ropensci-standards.md`.

## Output format

```
## Code audit: <package>

### 1. CRAN policy                  [✓]
### 2. Edge cases                   [✗] iq_gini crashes on empty vector
### 3. Numerical stability          [!] Kolm can overflow at large alpha
### 4. Error handling               [✗] 429 retries not implemented
### 5. Style and idioms             [!] 3 uses of 1:length() in R/theil.R
### 6. Documentation quality        [!] @return in iq_decompose not specific enough
### 7. Dependencies                 [✓]
### 8. Cross-platform               [!] Hardcoded / in file path on R/cache.R:34
### 9. Reproducibility              [✓]
### 10. Hidden gotchas              [✓]
### 11. Security                    [n/a] No untrusted input
### 12. Performance                 [!] rbind-in-loop in iq_ppd_years

### Summary: 2 blockers, 5 warnings, 5 passes
### Recommended action: fix blockers (2,4) before submission; address
### warnings in a v0.1.1 patch.
```

Severity:
- `[✓]` pass
- `[!]` warning (should fix but not blocking)
- `[✗]` blocker (must fix before CRAN submission)
- `[n/a]` not applicable to this package
