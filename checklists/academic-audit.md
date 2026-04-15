# Academic audit checklist

Run through every item. Classify each as pass `[✓]`, warning `[!]`,
or blocker `[✗]`. Report the full scorecard at the end.

Full heuristic: `reference/academic-audit-checklist.md`.
Formula traps by domain: `reference/formula-verification.md`.
Test design guidance: `reference/test-adequacy.md`.

## 1. Literature coverage

- [ ] Every exported method has a primary source citation in
  `@references`
- [ ] Citations use CRAN format: `<doi:10.xxxx/yyyy>` (angle
  brackets, no space)
- [ ] Subsequent refinements are cited where they change the
  recommended formula
- [ ] Textbook references included for pedagogical context
- [ ] Description field in DESCRIPTION cites foundational papers
  for methods the package implements

## 2. Formula verification

For each function implementing a named method:

- [ ] Formula matches the published formula line-by-line
- [ ] Discretisation choice (e.g. midpoint vs endpoint CDF)
  documented in `@details`
- [ ] Limiting cases implemented as special branches (e.g.
  ε=1 for Atkinson, α=0/1 for GE)
- [ ] Normalisation correct (index in documented range)
- [ ] Log-based measures guard against `log(0)` and `log(x)` for
  x < 0

## 3. Reference implementation agreement

- [ ] Identified the canonical reference implementation (R or
  Python) for each major function
- [ ] Cross-checked numerically (tolerance ≤ 1e-6) on realistic
  inputs
- [ ] Any deliberate differences documented

## 4. Incumbent comparison

- [ ] If replacing an existing package, differentiation stated in
  README
- [ ] Not claiming features the incumbent has that you lack
- [ ] Related packages listed in README
- [ ] Incumbent's archival status noted (if archived)

## 5. Python comparison

- [ ] Checked PyPI for equivalent packages
- [ ] Noted whether this is a port, a reimplementation, or novel

## 6. Methodological transparency

- [ ] Each non-trivial function has `@details` explaining the
  algorithm
- [ ] Defaults for parameters are justified
- [ ] Units of output documented

## 7. Limitations disclosure

- [ ] README has a `## Limitations` section (or equivalent)
- [ ] Known numerical issues documented
- [ ] Scope boundaries explicit

## 8. Test adequacy

See `reference/test-adequacy.md` for the four levels of test quality.

- [ ] Every formula function has at least one known-value test
  (Level 2)
- [ ] Each has at least one invariant test (Level 3) where
  applicable
- [ ] Cross-implementation tests (Level 4) exist for at least the
  headline functions
- [ ] Parameter-space coverage: tests at min, max, and boundary
  values
- [ ] Edge cases (`edge-cases.md`) covered

## 9. Reproducibility

- [ ] `set.seed()` called before every random operation in tests
  and examples
- [ ] RNG kind set explicitly if reproducibility matters
- [ ] No `Sys.time()` in default arguments
- [ ] No dependency on the user's RNG state

## 10. Citation hygiene

- [ ] `inst/CITATION` file exists for non-trivial packages
- [ ] `citation("pkg")` produces sensible output
- [ ] Working papers cited have stable URLs (SSRN, NBER, arXiv,
  not personal sites)

## Output

```
## Academic audit: <package>

1. Literature coverage              [✓|!|✗]
2. Formula verification             [✓|!|✗]
3. Reference implementation         [✓|!|✗]
4. Incumbent comparison             [✓|!|✗]
5. Python comparison                [✓|!|✗]
6. Methodological transparency      [✓|!|✗]
7. Limitations disclosure           [✓|!|✗]
8. Test adequacy                    [✓|!|✗]
9. Reproducibility                  [✓|!|✗]
10. Citation hygiene                [✓|!|✗]

## Summary
Blockers: N   Warnings: N   Passes: N

## Priority actions
1. [blocker] <specific action with file:line>
2. [warning] <specific action>
...
```

After presenting the scorecard, propose a concrete plan to address
blockers and high-priority warnings before release.
