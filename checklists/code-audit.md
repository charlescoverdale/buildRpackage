# Code audit checklist

Run through every item. Classify each as pass `[✓]`, warning `[!]`,
or blocker `[✗]`. Report the full scorecard at the end.

Full heuristic: `reference/code-audit-checklist.md`.
Edge case catalogue: `reference/edge-cases.md`.
Numerical stability: `reference/numerical-stability.md`.
Cross-platform traps: `reference/cross-platform-gotchas.md`.
rOpenSci standards: `reference/ropensci-standards.md`.

## 1. CRAN policy

Delegated to `checklists/preflight.md`:

- [ ] No `globalenv()` / `.GlobalEnv` / `assign(envir = globalenv())`
- [ ] No writes to user's home filespace in examples or tests
- [ ] Network tests wrapped in `skip_on_cran()` + `skip_if_offline()`
- [ ] Every URL in DESCRIPTION resolves
- [ ] `\dontrun` only for examples that genuinely cannot run
- [ ] Every exported function has `@return` and runnable `@examples`
- [ ] `R CMD check --as-cran` returns 0/0/0
- [ ] **Version is `0.1.0` if this is a first submission** (check by
  looking up the package name on CRAN; 404 means first submission)

If any fails, **blocker**. Fix before continuing.

## 2. Edge cases

For each exported function, verify handling of:

- [ ] Empty input (vector, data frame, list of length 0)
- [ ] Length-1 input
- [ ] Input with `NA` (respects `na.rm` argument)
- [ ] Input that is all `NA`
- [ ] Duplicates
- [ ] Unsorted input (when function assumes sorted)
- [ ] Parameter at boundary values (0, 1, ∞)
- [ ] Integer overflow
- [ ] Very large / very small floats

## 3. Numerical stability

- [ ] No `exp(large)` without log-sum-exp protection
- [ ] No `log(0)` without guard
- [ ] No catastrophic cancellation in variance / cross-products
- [ ] No `==` comparisons of floats
- [ ] No division by potentially-zero denominators without guard
- [ ] Normalisation re-applied after filtering (weights drift)

## 4. Error handling

- [ ] Every network call wrapped in `tryCatch`
- [ ] HTTP 4xx handled distinctly from 5xx
- [ ] 429 triggers retry-with-backoff, not error
- [ ] 401/403 gives clear "check credentials" message
- [ ] Timeout handled explicitly
- [ ] Malformed response doesn't crash
- [ ] Empty response doesn't crash
- [ ] User input validation uses `cli::cli_abort()` with `.arg`
  markup

## 5. Style and idioms

- [ ] `lintr::lint_package()` produces no high-severity warnings
- [ ] `vapply` used where return type is fixed (not `sapply`)
- [ ] `seq_along` / `seq_len` used (not `1:length(x)` / `1:n`)
- [ ] `inherits(x, "class")` used (not `class(x) == "class"`)
- [ ] No `library()` or `require()` in package functions
- [ ] `styler::style_pkg(dry = "on")` shows minimal diff

## 6. Documentation quality

- [ ] `@return` is specific, not "a list"
- [ ] `@examples` demonstrate realistic use
- [ ] Error conditions documented
- [ ] `@seealso` links to related functions
- [ ] `@family` groups related functions
- [ ] S3 class structure documented

## 7. Dependencies

- [ ] Every package in `Imports` is used
- [ ] Version floors justified
- [ ] `Suggests` items guarded with `requireNamespace()`
- [ ] No unnecessary tidyverse dependencies
- [ ] No `@importFrom` for base R operators

## 8. Cross-platform

- [ ] All paths use `file.path()`
- [ ] All temp files use `tempfile()` / `tempdir()`
- [ ] `read.csv` etc. specify `fileEncoding = "UTF-8"` on
  user-supplied files
- [ ] No `Sys.time()` comparisons across timezones in tests
- [ ] No `1:n` / `1:length()` patterns
- [ ] `DESCRIPTION` declares `Encoding: UTF-8`

## 9. Reproducibility

- [ ] `set.seed()` before every random call in tests and examples
- [ ] No captured `Sys.time()` in default arguments
- [ ] No paths hardcoded to the author's home
- [ ] No API keys in source

## 10. Hidden gotchas

- [ ] `NULL` vs missing argument handled consistently
- [ ] `stringsAsFactors = FALSE` explicit in `data.frame()` calls
- [ ] Integer literals (`1L`) used where integer is required
- [ ] Partial matching disabled with
  `options(warnPartialMatchDollar = TRUE)` during development
- [ ] Lazy evaluation in default args is intentional

## 11. Security (if the package handles untrusted input)

- [ ] User input URL-encoded before inclusion in URLs
- [ ] User input escaped/parameterised in SQL/SPARQL
- [ ] API keys never in error messages or URLs
- [ ] File paths from user input validated (no `..` traversal)

## 12. Performance

- [ ] No accidental O(n²) where O(n) is possible
- [ ] No `rbind()` in a loop (use `do.call(rbind, list)`)
- [ ] No reading a whole file when streaming would work
- [ ] No repeated network calls in a loop when batch exists

## Output

```
## Code audit: <package>

1. CRAN policy                      [✓|!|✗]
2. Edge cases                       [✓|!|✗]
3. Numerical stability              [✓|!|✗]
4. Error handling                   [✓|!|✗]
5. Style and idioms                 [✓|!|✗]
6. Documentation quality            [✓|!|✗]
7. Dependencies                     [✓|!|✗]
8. Cross-platform                   [✓|!|✗]
9. Reproducibility                  [✓|!|✗]
10. Hidden gotchas                  [✓|!|✗]
11. Security                        [✓|!|✗|n/a]
12. Performance                     [✓|!|✗]

## Summary
Blockers: N   Warnings: N   Passes: N

## Priority actions
1. [blocker] R/gini.R:47 — iq_gini crashes on empty vector (fix: add length check at start)
2. [blocker] R/api.R:102 — 429 response not retried (fix: add req_retry)
3. [warning] R/theil.R:34 — 1:length(x) should be seq_along(x)
...
```

After the scorecard, propose a concrete pre-submission plan: which
blockers to fix now, which warnings can wait for a v0.1.1 patch.
