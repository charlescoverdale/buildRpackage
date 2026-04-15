# rOpenSci review standards

rOpenSci runs a voluntary peer-review process for R packages in the
scientific-computing and data-access space. Their review standards
are stricter than CRAN's but produce packages of noticeably higher
quality. Writing a package that would pass rOpenSci review is a
strong signal of craft.

Full standards: https://devguide.ropensci.org/
Book: https://books.ropensci.org/dev_guide/

This file summarises the parts most worth adopting even if you don't
submit to rOpenSci.

## What rOpenSci reviews

Review happens on GitHub, openly, by two reviewers plus an editor.
They check:

1. **Fit**: does the package fit rOpenSci scope? (reproducible
   research, data access, spatial, statistics, etc.)
2. **Overlap**: is there a similar package already in rOpenSci or
   on CRAN? Why yours is different.
3. **Functionality**: does it work as documented?
4. **Documentation**: is it complete, clear, with working examples?
5. **Code quality**: style, structure, error handling, testing.
6. **Community**: README, CONTRIBUTING, code of conduct.

## Standards worth adopting

### README

rOpenSci expects:
- Badges: lifecycle, CRAN status, R-CMD-check, codecov
- One-line description
- Installation instructions (CRAN + GitHub)
- Usage examples with output (not just code)
- Links to vignettes
- Citation instructions
- Code of conduct link
- Contributing guidelines link

A minimal rOpenSci-compatible README has ~150-300 lines.

### Function documentation

Every exported function needs:

- **Title**: one line, Title Case, no trailing period
- **Description**: 1-3 sentences explaining what the function does
  AND why you'd use it
- **`@param`**: every argument, with type, default, and meaning
- **`@return`**: specific structure of the return value, including
  class, fields, and types
- **`@examples`**: runnable, demonstrating typical use (not trivial
  calls with defaults)
- **`@details`**: explanation of the algorithm, assumptions, or
  non-obvious behaviour
- **`@references`**: citations for any method implemented
- **`@seealso`**: related functions in the package or other packages
- **`@family`**: group related functions into families

### Vignettes

Every package should have at least one vignette:
- `vignettes/getting-started.Rmd` (or similar)
- Rendered via `knitr` or `quarto`
- Executable (not just code blocks)
- ~200-500 lines of mixed prose and code

For packages with multiple use cases, add vignettes per use case.

### Testing

rOpenSci expects:
- testthat 3+ edition
- Coverage >80% (check with `covr`)
- Tests named clearly
- Tests don't depend on network by default
- Tests cover edge cases
- CI runs tests on Linux, Windows, macOS

### Code style

- 80-character line width (soft limit)
- 2-space indentation
- Snake_case for function and variable names
- Tidyverse style guide (https://style.tidyverse.org/) is the
  de facto standard
- Run `styler::style_pkg()` to auto-format
- Run `lintr::lint_package()` and address warnings

### Error handling

- Use `cli::cli_abort()` for errors (not `stop()`)
- Use `cli::cli_warn()` for warnings (not `warning()`)
- Use `cli::cli_inform()` for informational messages (not `message()`)
- Error messages should include the function name and offending
  argument
- Error messages should suggest how to fix the problem

### Dependencies

- Minimise Imports: every dependency is a point of future breakage
- Avoid the tidyverse meta-package: depend on specific packages
  (`dplyr`, `purrr`) if needed
- Prefer base R over small utility packages (e.g. don't add `stringr`
  for a single `str_trim()` — use `trimws()`)
- Justify version floors in NEWS or DESCRIPTION comments

### Licencing

rOpenSci prefers permissive licences: MIT or Apache-2.0. Copyleft
licences (GPL-2, GPL-3) are accepted but discouraged for libraries.

### Contribution infrastructure

- `CONTRIBUTING.md` explaining how to propose changes
- `CODE_OF_CONDUCT.md` (rOpenSci uses the Contributor Covenant)
- Issue templates for bug reports and feature requests
- Pull request template
- CHANGELOG via NEWS.md

### Citation

- `inst/CITATION` file with the recommended citation
- `citation("yourpackage")` should return something sensible
- DOI for each release (via Zenodo / GitHub release integration)

## Things rOpenSci does NOT require

- S4 classes (S3 is fine)
- Extensive vignettes for simple packages
- CI on all three platforms (Linux + macOS is usually enough)
- 100% test coverage
- A pkgdown site (nice to have, not required)

## How this compares to CRAN

| Standard | CRAN | rOpenSci |
|---|---|---|
| `R CMD check` 0/0/0 | Required | Required |
| Tests | "Should have" | Required, 80%+ coverage |
| Vignettes | Optional | Recommended |
| Error handling style | "Should use standard idioms" | cli or equivalent |
| README structure | Optional | Required structure |
| `CONTRIBUTING.md` | Optional | Required |
| Code of conduct | Optional | Required |
| Style conformance | Informal | styler + lintr |
| DOI / citation | Optional | Required |

## Using this as a stretch goal

You don't need to submit to rOpenSci to benefit. Use their standards
as a checklist for the version of your package that would pass peer
review:

1. After CRAN acceptance, file GitHub issues for each rOpenSci
   standard your package doesn't meet yet.
2. Address them over the next release cycle.
3. If the package is in-scope for rOpenSci (and many data/stats
   packages are), consider submitting. Review is free and the
   feedback is genuinely useful.

Packages that have been through rOpenSci review: https://ropensci.org/packages/

## What CRAN reviewers secretly want that rOpenSci makes explicit

CRAN reviewers don't require these but appreciate them:

- Descriptions don't start with "This package..."
- Titles don't include the package name
- Functions with non-obvious behaviour have `@details`
- Error messages suggest fixes
- Examples are meaningful, not placeholder
- References are cited correctly
- Dependencies are minimal and justified

Meeting rOpenSci standards by default means CRAN review is usually
uneventful.
