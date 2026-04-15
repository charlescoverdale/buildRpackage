# Edge cases

Edge-case bugs are the #1 source of post-CRAN bug reports. Users pass
inputs you didn't consider: empty vectors, single observations, all
NAs, all duplicates. A function that returns wrong results on these
inputs gets reported as a bug; a function that errors cleanly with a
helpful message does not.

Every exported function should handle, or explicitly reject, each of
the cases below.

## The essential quartet

For any function that takes a vector input:

### Empty input
```r
f(numeric(0))
f(character(0))
f(data.frame())
```

Expected behaviour:
- Mathematical functions: error with a clear message ("need at
  least N observations")
- Data-munging functions: return an empty result of the correct
  shape (empty data frame with correct column names)
- Summary functions: return NA or error (not 0, which implies a
  computed result)

### Length-1 input
```r
f(5)
f("single")
```

Expected behaviour:
- Often the same code path as general input, but with no cross-
  observation computation to do
- Variance, SD, Gini, etc. are typically undefined or zero for
  n = 1; document which
- Avoid computing "the empty case plus 1" (e.g. `1:length(x)` in an
  empty-safe way is `seq_along(x)`)

### Input containing NA
```r
f(c(1, 2, NA, 4))
```

Expected behaviour:
- Error by default, with a message suggesting `na.rm = TRUE`
- Or accept a `na.rm` argument and respect it
- NEVER silently drop NAs (users will get wrong answers they can't
  debug)

### Input that is all NA
```r
f(c(NA, NA, NA))
```

Expected behaviour:
- Error or return NA of the expected type (`NA_real_`,
  `NA_character_`)
- Don't return 0 or an empty result (implies a computed answer)

## Further cases by function type

### Numeric functions

- [ ] Input at 0, -0, positive infinity, negative infinity, NaN
- [ ] Input that's all the same value (variance = 0, Gini = 0,
  etc. — check that your function doesn't divide by a zero
  standard deviation)
- [ ] Integer vs double input (`1L` vs `1.0` — usually identical
  but not always in modular arithmetic or bit operations)
- [ ] Negative input where positivity is assumed (log, sqrt,
  probabilities)
- [ ] Very large input (risk of overflow; see numerical-stability.md)
- [ ] Very small input (risk of underflow)
- [ ] Input with duplicates (`c(1, 1, 1, 2)`)
- [ ] Unsorted input (when the function assumes sorted)

### String functions

- [ ] Empty string `""`
- [ ] String with only whitespace `"   "`
- [ ] Unicode / non-ASCII (`"naïve"`, `"北京"`)
- [ ] Very long string (>1 MB)
- [ ] String with regex metacharacters (`"a.b*c"`) when used as
  literal pattern
- [ ] Leading/trailing whitespace
- [ ] Mixed case
- [ ] NULL byte (rare but possible)

### Date/time functions

- [ ] Date before 1970 (Unix epoch start; some code breaks)
- [ ] Date in the far future (2100+)
- [ ] 29 February in a leap year
- [ ] Daylight savings transition days (23-hour or 25-hour days)
- [ ] Timezone-aware vs naive
- [ ] POSIXct vs POSIXlt vs Date coercion
- [ ] Input as character string in various formats ("2020-01-01",
  "2020/01/01", "01-Jan-2020", "2020-01")

### Data frame functions

- [ ] Data frame with 0 rows
- [ ] Data frame with 0 columns
- [ ] Column with all NAs
- [ ] Column with mixed types (shouldn't happen but users do it)
- [ ] Duplicate column names
- [ ] Column names with spaces, dots, or special characters
- [ ] Factor columns where strings are expected
- [ ] List columns (modern tibbles support these; old code breaks)
- [ ] Grouped tibble where you want ungrouped
- [ ] Data with row.names that are factors vs characters

### List / vector of lists

- [ ] Empty list `list()`
- [ ] List with NULL elements `list(NULL, 1, 2)`
- [ ] Ragged list (different-length elements)
- [ ] Nested lists
- [ ] Named vs unnamed

### API / network functions

- [ ] Invalid URL format
- [ ] URL that 404s
- [ ] URL that redirects (301, 302)
- [ ] URL that times out
- [ ] Response with 200 but empty body
- [ ] Response with 200 but invalid JSON
- [ ] Response with 200 but error payload (some APIs return error
  in the body with 200 status)
- [ ] Rate limit (429) response
- [ ] Server error (500, 503)
- [ ] Very large response (>100 MB)
- [ ] Slow response (>30s)
- [ ] Authentication failure (401, 403)
- [ ] Offline (connection refused)

### File functions

- [ ] File doesn't exist
- [ ] File exists but is empty (0 bytes)
- [ ] File is readable but malformed
- [ ] File is very large (won't fit in memory)
- [ ] Path contains spaces or special characters
- [ ] Path contains non-ASCII characters
- [ ] Symlinks (follow or not?)
- [ ] Read-only filesystem
- [ ] Disk full (can't write cache)

## How to test edge cases

Add a `test-<fn>-edge-cases.R` test file per function family:

```r
test_that("iq_gini handles edge cases", {
  # Empty
  expect_error(iq_gini(numeric(0)))

  # Length 1
  expect_equal(iq_gini(5)$gini, 0)  # or expect_error, whichever
                                      # you chose

  # All NA
  expect_error(iq_gini(c(NA, NA, NA)))
  expect_equal(iq_gini(c(NA, NA, NA), na.rm = TRUE)$gini,
               expected_value_or_error)

  # All same value
  expect_equal(iq_gini(rep(50, 100))$gini, 0)

  # With NA, na.rm = TRUE
  expect_equal(iq_gini(c(1, 2, 3, NA), na.rm = TRUE)$gini,
               iq_gini(c(1, 2, 3))$gini)

  # With NA, na.rm = FALSE (default)
  expect_error(iq_gini(c(1, 2, 3, NA)))

  # Negative values (if unsupported)
  expect_error(iq_gini(c(-1, 2, 3)), "non-negative")

  # Large values (test for overflow)
  expect_no_error(iq_gini(rep(1e15, 100)))
})
```

## Checklist per function

Before marking a function "done", confirm:

- [ ] Empty input is handled (error or empty result, documented)
- [ ] Length-1 input is handled
- [ ] `na.rm` argument exists and works, or NA input errors
  clearly
- [ ] All-NA input handled
- [ ] Duplicates handled (explicit or trivially)
- [ ] Boundary values of any numeric parameters handled (e.g.
  `epsilon = 0`, `alpha = 1`, `delta -> ∞`)
- [ ] Error messages name the problem argument using `cli`'s
  `{.arg arg_name}` markup
- [ ] Edge-case tests exist in `tests/testthat/test-<fn>-edge.R`

## Common mistakes

- Checking `length(x) > 0` but not `!all(is.na(x))`
- Using `1:length(x)` (fails when length is 0) instead of
  `seq_along(x)`
- Calling `quantile(x, ...)` without checking for NAs first
- Assuming sorted input without documenting or enforcing
- Coercing character to factor silently
- Computing stats with integer input that overflows
