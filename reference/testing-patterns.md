# Testing patterns

## testthat version

Use testthat 3+ (declare `Config/testthat/edition: 3` in DESCRIPTION).
Edition 3 is stricter about test isolation and has better error
reporting.

## Test file organisation

One test file per R file in the package source:

```
R/gini.R           → tests/testthat/test-gini.R
R/theil.R          → tests/testthat/test-theil.R
R/utils.R          → tests/testthat/test-utils.R
```

This makes it easy to find tests for any function and keeps test file
size manageable.

## Test naming

Each test should have a descriptive `test_that()` string that
describes the behaviour being tested, not the function:

```r
test_that("Gini of equal incomes is 0", { ... })    # Good
test_that("iq_gini works", { ... })                  # Bad
```

## Skip patterns for CRAN

Four common skip patterns:

### Network-dependent tests

```r
test_that("live API fetch works", {
  skip_on_cran()
  skip_if_offline()
  result <- fetch_from_api()
  expect_s3_class(result, "data.frame")
})
```

### Credential-dependent tests

```r
test_that("authenticated query works", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not(
    nzchar(Sys.getenv("MYPKG_API_KEY")),
    "Set MYPKG_API_KEY to run live tests."
  )
  # ...
})
```

### Slow tests

```r
test_that("bulk download and parse works", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not(
    nzchar(Sys.getenv("MYPKG_LIVE_TESTS")),
    "Set MYPKG_LIVE_TESTS to run slow bulk tests."
  )
  # ... 100MB+ download ...
})
```

### Platform-specific tests

```r
test_that("Windows-specific path handling", {
  skip_on_os("mac")
  skip_on_os("linux")
  # ...
})
```

## setup.R

Use `tests/testthat/setup.R` for anything that should happen once
before tests run. Most commonly:

```r
# Redirect cache to avoid writing to home filespace
options(mypkg.cache_dir = tempfile("mypkg_test_cache_"))
```

## What to test

For a typical CRAN package, aim for:

- **Pure computation**: 100% branch coverage, including edge cases
  (empty inputs, NAs, zero-length, single-element)
- **API wrappers**: offline validation of argument parsing and
  response parsing (using mocked responses), plus a small number of
  live integration tests skipped on CRAN
- **Data parsers**: test with a small bundled sample of real-world
  data

## Known-value tests

Where possible, verify against analytically known results:

```r
test_that("Gini of maximum inequality is correct", {
  # c(0, 0, 0, 0, 10): Gini = 1 - 1/n = 0.8
  g <- iq_gini(c(0, 0, 0, 0, 10))
  expect_equal(g$gini, 0.8, tolerance = 1e-10)
})
```

These catch regressions even when the function "works" but has a
subtly wrong constant.

## Expect functions

Use `expect_equal()` with explicit `tolerance` for floating point.
Prefer `expect_identical()` for exact equality (integer counts, class
checks).

For print methods (which use `cli`, writing to stderr not stdout),
use `expect_no_error()` not `expect_output()`:

```r
test_that("print method works", {
  expect_no_error(print(my_object))
})
```
