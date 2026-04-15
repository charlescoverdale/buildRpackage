# Academic audit checklist

Use this when the user asks "does this package stand up to academic
scrutiny?" or runs `/cran-package audit academic`. The goal is to
establish whether the package's methods are correct, well-cited, and
defensible against a referee.

## 1. Literature coverage

For every exported function that implements a named method:

- [ ] The original source paper is cited in roxygen `@references`
- [ ] The citation uses CRAN-compatible format:
  - Book: `Author (Year). \emph{Title}. Publisher.`
  - Paper: `Author (Year). "Title." \emph{Journal}, vol(issue), pages.`
  - DOI: `<doi:10.xxxx/yyyy>` (angle brackets, no space after `doi:`)
  - arXiv: `<arXiv:1234.5678>`
- [ ] Subsequent refinements are cited where relevant
  (e.g. if the package computes Gini, cite both Gini 1912 and
  Yitzhaki 1979 for the covariance formulation; for FGT poverty,
  cite both Foster-Greer-Thorbecke 1984 and the SST refinement if
  using Sen)
- [ ] Textbook references are included for pedagogical context
  (e.g. Cowell 2011 for inequality, Haughton-Khandker 2009 for
  poverty, Cameron-Trivedi 2005 for microeconometrics)

Red flags:
- Function documents a method by name but cites no paper
- Paper cited but uses a different formula than the package implements
- Only textbook citations, no primary source

## 2. Formula verification

For each non-trivial function, verify:

- [ ] The implemented formula matches the published formula
- [ ] Special cases (limits, degeneracies) are handled correctly
  - Log-based measures at equal distribution
  - Ratios when denominator is zero
  - Parameters at boundary values
- [ ] Discretisation choices are explicit and documented
  - Midpoint vs endpoint CDF for rank-based measures
  - Population vs sample variance/covariance
  - Weighted vs unweighted quantile interpolation
- [ ] Normalisation constants are correct
  - Probability distributions integrate to 1
  - Indices scale to their documented range (0-1, -1 to 1, etc.)

Cross-check each formula against:
- The original paper (verify line-by-line)
- At least one textbook
- At least one reference implementation in R or Python
- Known analytical values (e.g. Gini of equal distribution = 0)

See `reference/formula-verification.md` for common traps per domain.

## 3. Reference implementation comparison

For methods with established implementations elsewhere:

- [ ] Identify the canonical implementation (R, Python, or Stata)
- [ ] Run both on the same input, check agreement to reasonable
  numerical tolerance (1e-6 typically; 1e-10 for purely analytical
  identities)
- [ ] Document any deliberate differences in roxygen (e.g. "uses
  midpoint CDF, unlike ineq::Gini which uses endpoint")
- [ ] If your result differs systematically, either fix it or justify

Common reference implementations:

| Domain | R reference | Python reference |
|---|---|---|
| Inequality | ineq, convey | inequalipy, pysal.inequality |
| Causal inference (DiD) | did, fixest | linearmodels, pyfixest |
| Time series | forecast, fable | statsmodels, sktime |
| Survival | survival | lifelines |
| Bayesian | rstanarm, brms | PyMC, numpyro |
| Optimisation | CVXR, nloptr | cvxpy, scipy.optimize |
| NLP / sentiment | quanteda, tidytext | spaCy, nltk |
| Network analysis | igraph | networkx |
| Spatial | sf, spdep | geopandas, pysal |

## 4. Comparison to incumbent packages

If replacing or competing with an existing CRAN package:

- [ ] Document what's new or better (in the README "Why this
  package?" section)
- [ ] List what the incumbent does that your package does NOT
  (don't pretend to be a superset if you're not)
- [ ] If a related package exists, consider citing it in the
  Description and linking in the README "Related packages" section
- [ ] If the incumbent is archived or unmaintained, say so plainly

## 5. Python / other-language comparison

Often the method exists first in Python or Stata. Before claiming
a novel R implementation:

- [ ] Search PyPI for the method name
- [ ] Search Stata's SSC for equivalent commands
- [ ] Note in README whether your R implementation is a port, a
  reimplementation, or novel

## 6. Methodological transparency

For every function with a non-obvious implementation choice:

- [ ] A `@details` section in roxygen explaining the formula,
  discretisation, and any assumptions
- [ ] Edge cases documented in the roxygen (what happens at
  extremes, what the default parameter means)
- [ ] Units of output documented (percentage vs proportion,
  ratio vs index)

## 7. Limitations disclosure

Create a `## Limitations` section in the README (or a vignette):

- [ ] What the package does NOT do (scope boundary)
- [ ] Known numerical issues (e.g. "unstable for n < 30")
- [ ] Assumptions users must satisfy (e.g. "assumes equally
  spaced time points")
- [ ] When to prefer a different package

Users trust packages more, not less, when limitations are stated up
front.

## 8. Test adequacy (analytical)

See `reference/test-adequacy.md` for the full test-design heuristic.
At minimum for academic credibility:

- [ ] Known-value tests against hand-computed cases
- [ ] Analytical invariants (e.g. between + within = total for GE
  decomposition, triangle inequality for distance measures,
  monotonicity in parameters)
- [ ] Cross-validation against reference implementations
- [ ] Boundary tests (parameter at 0, 1, ∞)

## 9. Reproducibility

- [ ] `set.seed()` called before any random operation in tests
  and examples
- [ ] Same input produces byte-identical output across R versions
  (no dependency on random seed state from elsewhere)
- [ ] Floating-point comparisons use `tolerance =` explicitly
  (testthat default is strict)

## 10. Citation hygiene

- [ ] If the package implements a method from an unpublished
  working paper, is the citation stable? (SSRN, NBER, arXiv are OK;
  personal websites are not)
- [ ] If a paper is behind a paywall, is there a preprint URL too?
- [ ] `citation("yourpackage")` in R should produce a sensible
  citation (add a `inst/CITATION` file for non-trivial packages)

## Output format

Produce a scorecard with categories:

```
## Academic audit: <package>

### 1. Literature coverage          [✗] Missing Yitzhaki (1979) for iq_gini
### 2. Formula verification         [✓]
### 3. Reference implementations    [!] Gini differs from ineq::Gini by 0.002; investigate
### 4. Incumbent comparison         [✓]
### 5. Python comparison            [✗] inequalipy exists; document differentiation
### 6. Methodological transparency  [!] iq_decompose missing @details on alpha weighting
### 7. Limitations                  [✗] No Limitations section in README
### 8. Test adequacy                [!] No boundary tests at epsilon=0
### 9. Reproducibility              [✓]
### 10. Citation hygiene             [✓]

### Overall: 6/10 pass, 3 warnings, 1 blocker
### Blocker: reference implementation disagreement needs resolution before release.
```

Severity levels:
- `[✓]` pass
- `[!]` warning (should fix but not blocking)
- `[✗]` blocker (must fix before claiming academic credibility)
