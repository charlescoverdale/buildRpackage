# Formula verification

For any package that implements named mathematical or statistical
methods, the gap between "the code runs" and "the code is right" is
where most academic-credibility problems live.

This file documents the common traps per domain. Use it alongside
`academic-audit-checklist.md` during a rigorous review.

## General principles

1. **One canonical source per formula.** Every non-trivial function
   should have a single cited paper (or textbook section) that
   defines the formula exactly as implemented. Avoid citing "the
   standard formula" or vague references.

2. **Continuous vs discrete discretisation.** Most published
   formulas are continuous. Your code implements them discretely.
   The discretisation choice matters:
   - Midpoint vs endpoint for CDF values
   - Linear interpolation vs step function for quantiles
   - Sample (divide by n-1) vs population (divide by n) variance
   Document which you use and why in `@details`.

3. **Limiting cases.** Many formulas have limits at boundary
   parameter values. L'Hôpital-type limits must be implemented
   explicitly (e.g. Atkinson at ε=1, Theil vs MLD in GE family).

4. **Normalisation.** Indices that are defined on a specific range
   (0-1, -1 to 1) must actually produce values in that range. Check
   with extreme inputs.

## Inequality measures

### Gini coefficient

Several equivalent formulas. The covariance formulation is numerically
stablest:

```
G = 2 * cov(x, F(x)) / mean(x)
```

where F(x) is the empirical CDF at x. For discrete weighted data:

```
G = (2/mu) * sum(w_i * x_i * (cumsum(w)_i - w_i/2)) - 1
```

Common errors:
- Using `cumsum(w)_i` instead of `cumsum(w)_i - w_i/2` (endpoint
  instead of midpoint)
- Dividing by `n-1` when the formula needs `n`
- Forgetting the `-1` at the end

Check against Gini of `c(0,0,0,0,10)` = 0.8 exactly.

### Theil / Generalised Entropy family

GE(0), the mean log deviation:
```
GE(0) = -mean(log(x/mu))
```

GE(1), Theil's T:
```
GE(1) = mean((x/mu) * log(x/mu))
```

General GE(α) for α ≠ 0, 1:
```
GE(α) = (1 / (α * (α-1))) * (mean((x/mu)^α) - 1)
```

Common errors:
- Swapping GE(0) and GE(1) (Theil T is GE(1), Theil L / MLD is GE(0))
- Not implementing the limits at α=0 and α=1 as special cases
  (direct formula evaluates to 0/0)
- Using weighted mean instead of `sum(w * x)` when weights don't
  sum to 1

GE(2) is half the squared coefficient of variation (using
POPULATION variance, not sample variance):
```
GE(2) = (1/2) * (pop_var(x) / mean(x)^2)
```

### Atkinson index

For ε ≠ 1:
```
A(ε) = 1 - (mean(x^(1-ε)))^(1/(1-ε)) / mean(x)
```

For ε = 1 (limit):
```
A(1) = 1 - exp(mean(log(x))) / mean(x)
```

i.e. use the geometric mean. Direct evaluation at ε=1 gives 0/0.

Common errors:
- Not branching on ε=1
- Allowing x=0 (breaks log in the ε=1 case)
- Returning a value > 1 for numerical reasons (clamp to [0, 1])

### Palma ratio

```
Palma = S(top 10%) / S(bottom 40%)
```

where S is the income share at that quantile. Use Lorenz
interpolation for the shares, not endpoint approximation.

Check: equal distribution → Palma = 0.10 / 0.40 = 0.25.

### Decomposition (Bourguignon 1979, Shorrocks 1980)

For the generalised entropy family, total GE decomposes exactly into
between-group and within-group components with no residual. The
between/within weights depend on α:

```
Between = GE(α) at group means (treating each observation as its
          group's mean)
Within  = sum over g of (n_g/n)^(1-α) * (mu_g/mu)^α * GE_g(α)
```

where GE_g is GE computed within group g.

Special cases simplify:
- α = 0: `Within = sum(n_g/n * GE_g)` (population-weighted)
- α = 1: `Within = sum(income_share_g * GE_g)` (income-weighted)

Common errors:
- Residual (should be exactly 0 for GE; only the Gini has a
  non-zero residual from overlap)
- Wrong weights for general α

### S-Gini (extended Gini)

Donaldson-Weymark (1980), Yitzhaki (1983):

```
S-Gini(δ) = 1 - (δ/μ) * sum(w_i * x_i * (1 - F_i)^(δ-1))
```

where F_i is the fractional rank (midpoint of the CDF step).

At δ=2 this reduces to the standard Gini. Verify.

### Kolm absolute index

Kolm (1976):

```
K(α) = (1/α) * log(sum(w_i * exp(α * (μ - x_i))))
```

This overflows for real-world incomes (μ ≈ 50000, α = 1 gives
exp(50000) = Inf). Always use the log-sum-exp trick:

```r
z <- alpha * (mu - x)
z_max <- max(z)
K <- (z_max + log(sum(w * exp(z - z_max)))) / alpha
```

## Poverty measures

### FGT (Foster-Greer-Thorbecke, 1984)

```
FGT(α) = sum(w_i * ((z - x_i)/z)^α) for x_i < z
```

where z is the poverty line.

- α = 0: headcount ratio
- α = 1: poverty gap
- α = 2: poverty severity (squared gap)

Common errors:
- Not restricting the sum to x_i < z
- Using `max(z - x, 0)` but not normalising by z

### Sen index

The original Sen (1976) formula has a discontinuity issue at the
poverty line. The Sen-Shorrocks-Thon (SST) refinement is the
standard modern implementation:

```
SST = H * (G_poor * (1 - avg_gap_poor) + avg_gap_poor)
```

Prefer SST over original Sen unless matching a specific paper.

### Watts index

```
W = mean(log(z / x_i)) for x_i < z
```

(Watts 1968). Distribution-sensitive, unlike the headcount.

## Causal inference

### Difference-in-differences

Simple 2x2 case:
```
DiD = (Y_T_after - Y_T_before) - (Y_C_after - Y_C_before)
```

But this is rarely what users want. Modern implementations should
use:
- **Callaway-Sant'Anna (2021)** for staggered treatment timing
- **Sun-Abraham (2021)** for event studies with variation in
  treatment timing
- **de Chaisemartin-D'Haultfoeuille (2020)** for heterogeneous
  treatment effects

Implementing a naïve TWFE DiD as the only option is a red flag for
a reviewer.

### Synthetic control

Original Abadie-Diamond-Hainmueller (2010): weight pre-treatment
donor units to minimise pre-treatment outcome distance, subject to
weights summing to 1 and being non-negative.

Modern variants:
- **Synthetic DiD** (Arkhangelsky et al. 2021)
- **Augmented synthetic control** (Ben-Michael et al. 2021)

### IV / 2SLS

Standard 2SLS is fine but should use robust standard errors by
default. Weak-instrument tests (Stock-Yogo, Olea-Pflueger) should
be provided.

## Time series

### Stationarity

Differencing (naïve): `diff(x)` discards the first observation.
Document whether your function does this.

### Autocorrelation

`acf()` in base R handles NAs poorly. For production code, check
for NAs first.

### Moving averages

Centred vs trailing: most users expect trailing (right-aligned).
Document which.

### HP filter (Hodrick-Prescott)

Standard λ values:
- 100 for annual data
- 1600 for quarterly
- 129600 for monthly

The HP filter has known endpoint issues. Document or use a modern
alternative (Hamilton 2018 suggests replacing HP with a regression-
based filter).

## Probability and distributions

### Empirical CDF

`ecdf(x)(y)` gives the proportion of x ≤ y. Note the ≤ vs <
distinction: with ties, the choice matters.

### Quantile

R has 9 `type` options in `quantile()`. Type 7 is the default.
For weighted quantiles, there's no base R function; implement
carefully:

```r
weighted_quantile <- function(x, w, p) {
  ord <- order(x)
  x <- x[ord]; w <- w[ord]
  cum_w <- cumsum(w) / sum(w)
  approx(cum_w, x, xout = p, method = "linear", rule = 2)$y
}
```

Document which interpolation method you use. Different choices give
slightly different answers at the same quantile.

### Monte Carlo

Always call `set.seed()` at the start of any simulation. Document the
expected variance of the estimate for given N.

## Regression

### Robust standard errors

`lm()` gives OLS SEs. For heteroscedasticity, use `sandwich::vcovHC()`.
For clustering, use `sandwich::vcovCL()`.

If your package returns coefficient SEs, document which estimator.

### Model selection (AIC, BIC)

```
AIC = -2 * log_lik + 2 * k
BIC = -2 * log_lik + log(n) * k
```

Common errors:
- Using log-likelihood from a different specification
- Using k = predictors, not k = parameters (k includes intercept
  and sigma for OLS)
- Using n = rows, not effective sample size

## Signal processing

### FFT

R's `fft()` returns unnormalised results. Divide by N for a proper
DFT.

### Filtering

Linear filters with `filter()` in base R are causal. For zero-phase
filters, apply forward then backward.

## How to verify a formula

1. **Trace the paper.** Print the formula exactly as published.
   Check your code against it term by term.

2. **Compute a worked example.** Pick inputs where you can compute
   the answer by hand (5 observations, integer weights, simple
   distribution). Verify your code produces the same answer.

3. **Check limiting cases.** What does the formula predict for
   equal distribution? All-zeros-except-one? Infinite sample size?
   Your code should match.

4. **Cross-check against a reference implementation.** If another
   package computes the same thing, run both on the same data and
   check they agree to 6+ decimal places (or document why they
   don't).

5. **Test at parameter boundaries.** Pass the parameter at 0, 1,
   the documented min, the documented max. Verify no errors and
   reasonable output.

6. **Sensitivity analysis.** Nudge the input by 1e-10 and check the
   output changes by roughly 1e-10 * derivative. Large jumps
   indicate instability.
