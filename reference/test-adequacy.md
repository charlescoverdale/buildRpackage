# Test adequacy

Most test suites under-test the things that matter and over-test the
things that don't. This file is a heuristic for asking: do these
tests actually verify the package works correctly, or do they just
verify that the code runs?

## The four levels of test quality

### Level 0: It runs

```r
test_that("iq_gini works", {
  g <- iq_gini(c(1, 2, 3))
  expect_s3_class(g, "iq_gini")
})
```

This only proves the function doesn't error. It doesn't verify
correctness. Common but nearly useless.

### Level 1: Structure

```r
test_that("iq_gini returns correct structure", {
  g <- iq_gini(c(1, 2, 3))
  expect_s3_class(g, "iq_gini")
  expect_named(g, c("gini", "n", "se", "ci_lower", "ci_upper",
                    "level", "method"))
  expect_type(g$gini, "double")
})
```

Confirms the return value has the documented shape. Useful. Not
enough.

### Level 2: Known values

```r
test_that("Gini of equal incomes is 0", {
  expect_equal(iq_gini(rep(100, 50))$gini, 0, tolerance = 1e-10)
})

test_that("Gini of maximum inequality is 1 - 1/n", {
  expect_equal(iq_gini(c(0, 0, 0, 0, 10))$gini, 0.8,
               tolerance = 1e-10)
})
```

Verifies against analytically known values. This is the minimum for
claiming mathematical correctness. Every formula-implementing
function needs at least one Level 2 test.

### Level 3: Invariants

```r
test_that("GE decomposition is exact", {
  d <- iq_sample_data("grouped")
  dec <- iq_decompose(d$income, d$group, index = "T")
  expect_equal(dec$between + dec$within, dec$total,
               tolerance = 1e-10)
})

test_that("S-Gini at delta=2 equals standard Gini", {
  x <- c(1, 2, 3, 4, 5)
  expect_equal(iq_sgini(x, delta = 2)$value,
               iq_gini(x)$gini,
               tolerance = 1e-10)
})
```

Verifies that mathematical properties that MUST hold actually do.
These catch subtle bugs (wrong discretisation, off-by-one) better
than known-value tests.

### Level 4: Cross-implementation

```r
test_that("Gini matches ineq::Gini to 6 decimal places", {
  skip_if_not_installed("ineq")
  x <- rlnorm(1000)
  expect_equal(iq_gini(x)$gini, ineq::Gini(x),
               tolerance = 1e-6)
})
```

Verifies against an independent implementation. The gold standard.

## What your test suite should include

For a formula-implementing package, every exported function needs:

- **1-2 Level 2 tests** (known analytical values)
- **1 Level 3 test** (an invariant that must hold)
- **1 Level 4 test** (cross-check against another package or
  published worked example), wrapped in `skip_if_not_installed()`
- **5-10 Level 1 tests** for structure, argument validation, and
  print methods

For an API-wrapper package:
- Structure tests for parsed responses
- Tests for argument validation
- A small number of live integration tests wrapped in
  `skip_on_cran()` + `skip_if_offline()` + optional
  `skip_if_not(nzchar(Sys.getenv("KEY")))`
- Mock-response tests for error paths (malformed JSON, 429, 503,
  401)

For a data package:
- Structure tests for each bundled dataset
- Checksum tests (content is what it should be)
- Provenance tests (source and date are documented)

## Parameter-space coverage

For functions with numeric parameters, test the parameter space:

- At the documented minimum
- At the documented maximum
- At the boundary between formula regimes (e.g. α=0 vs α=1 for GE)
- At a typical value
- With a typical input

For functions with categorical parameters (e.g. `type = c("A", "B")`),
test every category.

For functions with logical parameters, test both TRUE and FALSE.

## Common under-testing patterns

### Only testing one case

```r
test_that("iq_gini works", {
  g <- iq_gini(c(1, 2, 3))
  # ... checks about g ...
})
```

Three integers? That's one point in the parameter space. Test with:
- Weighted input
- Input containing duplicates
- Extreme values
- Large N

### Testing only the happy path

Real user inputs include typos, NAs, and wrong types. Test the
error paths too.

### Testing that tests don't error

```r
test_that("no error on extreme input", {
  expect_no_error(iq_gini(rep(1e10, 100)))
})
```

`expect_no_error` only catches errors. Combine with a sanity check
on the value:

```r
test_that("large values produce finite result", {
  g <- iq_gini(rep(1e10, 100))
  expect_true(is.finite(g$gini))
  expect_equal(g$gini, 0, tolerance = 1e-10)
})
```

### Only testing one platform

If your tests use filesystem paths, they'll break on Windows.
Run the suite on Linux, macOS, and (if possible) Windows before
CRAN submission. GitHub Actions with `actions/setup-r@v2` makes
this easy.

## Common over-testing patterns

### Testing base R

```r
test_that("mean works", {
  expect_equal(mean(c(1, 2, 3)), 2)
})
```

Don't test functions from other packages. Test your own package's
behaviour.

### Testing print output format

```r
test_that("print output matches", {
  expect_output(print(g), "Gini: 0.3")
})
```

Print output is cosmetic. If you change the format, you'll break
tests for no good reason. Test with `expect_no_error(print(g))`
and verify the structure, not the exact formatting.

### Testing S3 class names exhaustively

Two tests for S3 class is enough:

```r
expect_s3_class(g, "iq_gini")
expect_type(g, "list")
```

You don't need to test that every element exists and is of the
right type on every single test.

## Test-to-code ratio

Rough guideline:
- **Pure-computation packages**: 1.5-3x test lines per code line
  (formula packages need more tests than data wrappers)
- **API wrappers**: 0.5-1.5x test lines per code line (mostly mocks
  and structural checks)
- **Data packages**: 0.3-0.8x test lines per code line (just
  content verification)

Far below these ratios suggests under-testing. Far above suggests
testing the wrong things.

## What `covr` tells you

```r
covr::package_coverage()
```

Line coverage above 80% is a reasonable target. Below 60% is a
warning sign. But line coverage is a weak metric: you can hit 100%
coverage with Level-0 tests and still have a broken package.

Prefer tests that verify behaviour, not tests that hit lines.

## Test adequacy audit checklist

For each exported function:

- [ ] At least one Level 2 (known value) test
- [ ] At least one Level 3 (invariant) test if the function has
  analytical properties
- [ ] At least one Level 4 (cross-implementation) test if an
  independent implementation exists
- [ ] Structural tests for the return value
- [ ] Argument validation tests (invalid types, out-of-range values)
- [ ] Edge-case tests (see `edge-cases.md`)
- [ ] Print method test (if there is one)

For the package as a whole:

- [ ] Coverage above 80%
- [ ] No `\dontrun` in tests (use `skip_on_cran` instead)
- [ ] Tests don't depend on network by default
- [ ] Tests don't write outside `tempdir()`
- [ ] Tests are deterministic (set seeds, fix tolerances)
- [ ] Tests run in < 30 seconds on a modest machine

## Output for the audit

```
## Test adequacy: <package>

| Function | L1 struct | L2 known | L3 invariant | L4 cross |
|---|---|---|---|---|
| iq_gini    | ✓ | ✓ | ✓ | ✗ (missing) |
| iq_theil   | ✓ | ✓ | ✓ | ✓ |
| iq_palma   | ✓ | ✓ | ✗ | ✗ |
| iq_decompose | ✓ | ✓ | ✓ | ✗ |

Coverage: 91%
Total tests: 134
Blocking gaps: iq_palma needs an invariant test (e.g. bounds check)
Recommended additions: cross-implementation tests against ineq and convey
```
