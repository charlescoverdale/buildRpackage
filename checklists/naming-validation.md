# Naming validation checklist

Run all of these before committing to a package name.

## CRAN rules (HARD)

- [ ] Name contains only letters, numbers, and full stops (`.`)
- [ ] Name starts with a letter
- [ ] Name is at least 2 characters long
- [ ] Name does not contain underscores, hyphens, or spaces
- [ ] Name is case-sensitive but not conventionally uppercase

## Availability (HARD)

- [ ] Not taken on CRAN
      ```bash
      curl -s -o /dev/null -w "%{http_code}" "https://cran.r-project.org/package=<name>"
      ```
      404 = available, 200 = taken

- [ ] Not on CRAN archive (archived packages cannot be reclaimed by
      different authors in most cases)
      ```bash
      curl -s "https://cran-archive.r-project.org/web/checks/2026/2026-03-30_check_results_<name>.html"
      ```

- [ ] Not taken on GitHub for your username
      ```bash
      curl -s -o /dev/null -w "%{http_code}" "https://github.com/<user>/<name>"
      ```

- [ ] Not a base R package: `base`, `utils`, `stats`, `graphics`,
      `grDevices`, `methods`, `datasets`, `tools`, `parallel`,
      `compiler`, `splines`, `grid`, `tcltk`, `stats4`
- [ ] Not a recommended R package: `boot`, `class`, `cluster`,
      `codetools`, `foreign`, `KernSmooth`, `lattice`, `MASS`,
      `Matrix`, `mgcv`, `nlme`, `nnet`, `rpart`, `spatial`, `survival`

## Style (SOFT)

- [ ] Name is short (ideally < 10 characters)
- [ ] Name is pronounceable
- [ ] Name is memorable and searchable (not a generic English word)
- [ ] Name doesn't collide with well-known software (Python packages,
      JavaScript libraries, etc.) in a confusing way
- [ ] Name doesn't use emoji or unicode symbols

## Prefix selection

Choose a function prefix (e.g. `mypkg_`, `mp_`, `pkg_`) that:

- [ ] Does not clash with any base R function of the same name
- [ ] Does not clash with common tidyverse function names (`filter`,
      `select`, `arrange`, `mutate`, `summarise`, `group_by`,
      `map`, `reduce`, etc.)
- [ ] Is consistent across all your exported functions
- [ ] Makes functions visibly tied to your package when called

## Style variants

Depending on `conventions.prefix_style` in user-config:

- **two-letter**: `xy_function()` — compact, fewer keystrokes
- **three-letter**: `xyz_function()` — less ambiguous
- **package-name**: `mypackage_function()` — self-documenting but verbose
- **no prefix**: `function()` — only viable if function names are
  unique enough (e.g. domain-specific jargon)

## Validation output format

Report one of:

```
✓ Name "mypackage" is available
  - CRAN: available
  - CRAN archive: not archived
  - GitHub: repo available
  - Base R: no clash
  - Prefix "mp_": suggested, no clash
```

or

```
✗ Name "stats" is not available
  - Base R: clash with base package "stats"
  - Suggest: pick a different name
```
