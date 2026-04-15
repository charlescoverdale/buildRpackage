# Numerical stability

Most R packages don't need to worry about floating-point arithmetic.
Statistical and mathematical packages do, because small numerical
errors compound into wrong-looking results that users report as bugs.

This file documents the most common traps and their fixes, with
examples drawn from real packages.

## 1. Overflow in exp()

**Problem**: `exp(x)` returns `Inf` for `x > 709` on double precision.

**Common in**:
- Softmax / logistic regression
- Kolm inequality index (`exp(alpha * (mu - x))` overflows when
  incomes are in thousands)
- Importance sampling weights
- Boltzmann distributions

**Fix**: the **log-sum-exp trick**. Instead of computing
`log(sum(w * exp(z)))`, compute:

```r
z_max <- max(z)
log_result <- z_max + log(sum(w * exp(z - z_max)))
```

This subtracts the max before exponentiating, so the largest term
becomes `exp(0) = 1` and no overflow occurs. The answer is
mathematically identical.

**Real example** (Kolm index for UK incomes):

Broken:
```r
value <- (1 / alpha) * log(sum(w * exp(alpha * (mu - x))))
# mu is ~49000, alpha = 1 → exp(49000) = Inf
```

Fixed:
```r
z <- alpha * (mu - x)
z_max <- max(z)
value <- (1 / alpha) * (z_max + log(sum(w * exp(z - z_max))))
```

## 2. Underflow in exp()

**Problem**: `exp(x)` returns `0` for `x < -745`. This silently
discards information.

**Common in**:
- Log-likelihoods at very small probabilities
- Gaussian tails far from the mean
- Product of many small probabilities

**Fix**: work in log space throughout. Instead of multiplying
probabilities, sum log-probabilities. Only exp at the end if needed.

## 3. log(0) and log(negative)

**Problem**: `log(0)` returns `-Inf`, `log(-1)` returns `NaN` with
a warning. Either can appear in chains of computations.

**Fix**: guard before the call.

```r
# Broken:
ll <- sum(log(p))  # if any p == 0, returns -Inf

# Fixed:
if (any(p <= 0)) {
  cli::cli_abort("All probabilities must be strictly positive.")
}
ll <- sum(log(p))
```

For cases where `x` can genuinely be 0 and `log(0) = -Inf` is the
right answer (e.g. entropy of a degenerate distribution), document
the behaviour.

## 4. Catastrophic cancellation

**Problem**: subtracting two nearly-equal large numbers loses most
of the significant digits.

```r
# These are equal in exact arithmetic:
(1e16 + 1) - 1e16  # returns 0, not 1 (all precision lost)
```

**Common in**:
- Sample variance computed as `mean(x^2) - mean(x)^2`
  (Welford's algorithm is numerically stable)
- Cross-product differences
- Logistic function at extreme arguments

**Fix**: rearrange the computation. For variance:

```r
# Broken (two-pass but cancellation-prone):
var_bad <- mean(x^2) - mean(x)^2

# Better (Welford's online algorithm):
var_welford <- function(x) {
  n <- length(x)
  mu <- 0; M2 <- 0
  for (i in seq_along(x)) {
    delta <- x[i] - mu
    mu <- mu + delta / i
    M2 <- M2 + delta * (x[i] - mu)
  }
  M2 / (n - 1)
}

# In practice, use base R's var() which handles this correctly
```

## 5. Comparing floats with ==

**Problem**: `0.1 + 0.2 != 0.3` in IEEE 754 arithmetic. `==` will
return FALSE.

**Fix**: use a tolerance.

```r
# Broken:
if (a == b) ...

# Fixed:
if (abs(a - b) < 1e-10) ...

# Or in tests:
expect_equal(a, b, tolerance = 1e-10)
```

The default `tolerance` in `expect_equal` is
`sqrt(.Machine$double.eps)` ≈ 1.49e-8, which is correct for most
purposes.

## 6. Division by zero

**Problem**: `x / 0` returns `Inf` (if x > 0), `-Inf` (if x < 0), or
`NaN` (if x = 0). None of these propagate cleanly through
subsequent computations.

**Fix**: guard divisions.

```r
# Broken:
ratio <- top10_share / bottom40_share

# Fixed:
if (bottom40_share == 0) {
  cli::cli_abort("Bottom 40% share is zero; ratio undefined.")
}
ratio <- top10_share / bottom40_share
```

For ratios where 0/0 has a well-defined limit (e.g. `x/x -> 1` as
both approach zero), handle that case explicitly.

## 7. Integer overflow

**Problem**: R integers are 32-bit. `.Machine$integer.max` is
~2.1e9. Sums or products can overflow silently.

```r
x <- rep(1L, 3e9)  # error: too large
x <- rep(1L, 1e9)
sum(x)  # returns NA_integer_ silently in some older R versions
```

**Fix**: coerce to double before summing large integer vectors.

```r
sum(as.double(x))
```

Or use `sum()` which already coerces in recent R versions. Verify
on your target R version.

## 8. Kahan summation for long sums

**Problem**: summing N small floating-point numbers accumulates
rounding error of O(N) in the worst case.

**Fix**: for most packages, `sum()` is fine. For scientific
computation where every bit matters, use Kahan compensated
summation:

```r
kahan_sum <- function(x) {
  s <- 0; c <- 0
  for (v in x) {
    y <- v - c
    t <- s + y
    c <- (t - s) - y
    s <- t
  }
  s
}
```

Usually overkill. Mention in docs if your sums are known to suffer.

## 9. Square root of tiny negatives

**Problem**: numerical error can make a theoretically-non-negative
quantity (a variance, a sum of squares) tiny-negative. `sqrt()` of
that returns `NaN` with a warning.

**Fix**: clamp before `sqrt`.

```r
# Broken:
sd <- sqrt(variance)  # NaN if variance is -1e-17

# Fixed:
sd <- sqrt(max(variance, 0))
```

Only safe if you're confident the true value is non-negative.

## 10. Rank statistics with ties

**Problem**: `rank()` handles ties with averaging by default, but
some statistical formulas assume integer ranks or specific tiebreak
behaviour.

**Fix**: be explicit.

```r
rank(x, ties.method = "average")  # default
rank(x, ties.method = "min")      # competition ranking
rank(x, ties.method = "first")    # ties broken by position
rank(x, ties.method = "random")   # random tiebreak (set.seed!)
```

Document in roxygen which tiebreak behaviour your function uses.

## 11. Normalisation drift

**Problem**: probabilities or weights that should sum to 1
accumulate floating-point error as you multiply or filter them.
Over many iterations, the sum drifts to 0.9999... or 1.0001...

**Fix**: re-normalise explicitly at key points.

```r
w <- w / sum(w)  # re-normalise after any subsetting
```

## 12. Gradients and derivatives

**Problem**: numerical differentiation with step size `h`:
- Too small: subtraction cancels, gets garbage
- Too large: truncation error

**Fix**:
- Use `h = sqrt(.Machine$double.eps) * max(abs(x), 1)` for forward
  difference
- Or use complex-step differentiation: `Im(f(x + 1i*1e-20)) / 1e-20`
  (no cancellation, works for analytic functions)
- Or use the `numDeriv` package, which does the right thing

## How to check for numerical issues

During the code audit:

```r
# Try extreme inputs:
f(x = rep(1e10, 1000))
f(x = rep(1e-10, 1000))
f(x = c(1, 1 + .Machine$double.eps))
f(x = c(rep(1, 999), 1e10))

# Check sensitivity:
f(x = x) - f(x = x + 1e-10)  # should be ~ 1e-10 * derivative
```

Any result that is `Inf`, `NaN`, `NA_real_` without a warning is a
bug. Any result that changes drastically for a tiny input
perturbation indicates instability.
