# CRAN policies summary

Complete reference: https://cran.r-project.org/web/packages/policies.html

This file summarises the policies most relevant to submission. Check
the full policies document if in doubt.

## Mandatory (violations cause rejection)

### Filespace

> Packages should not write to the user's file space (or anywhere
> else on the file system apart from the R session's temporary
> directory or its children). Installing into the system's R
> installation (e.g., scripts to its `bin` directory) is not allowed.

### Internet access

> Packages which use Internet resources should fail gracefully with
> an informative message if the resource is not available or has
> changed (and not give a check warning nor error).

Practical translation: wrap network calls in `tryCatch()` and return
a meaningful `cli::cli_abort()` with guidance, not a raw error.

### Global state

> Packages must not modify the user's global environment. Likewise
> for `options()`, `par()`, `Sys.setenv()` and similar — these may be
> modified temporarily if `on.exit()` is used to restore them before
> returning.

### Licence

> Every package must have a licence file, which must be one of the
> standard licences (or the `file LICENSE` / `file LICENCE` pattern).

### Reverse dependencies

> Authors of reverse-dependent packages must be notified before a
> package is updated in a way that may break them.

Relevant only if your package has reverse dependencies already.

## Strongly recommended

### Documentation

> All exported functions must have working `\examples{}` (preferably
> without `\dontrun{}`).

### Testing

> Packages should include tests. The CRAN maintainers will check that
> the tests pass.

### Startup

> Packages should not produce messages when loaded except in
> exceptional circumstances.

Use `packageStartupMessage()` if you truly must say something at
load, never bare `message()` or `cat()`.

## Checks that fail on unexpected output

`R CMD check --as-cran` fails on:
- Any ERROR
- Most WARNINGs
- Specific NOTEs (missing documentation, invalid URLs, etc.)

Acceptable NOTEs on first submission:
- "New submission" (informational)
- "Possibly misspelled words in DESCRIPTION" (check but usually false
  positive)
- "unable to verify current time" (local network / NTP issue)

All other NOTEs should be fixed before submission.

## Hidden requirements (not written down but enforced)

Based on community experience with reviewers:

- First version should be 0.1.0 (not a firm rule; some reviewers
  accept 1.0.0 for first submission if justified)
- Title should be in Title Case, not sentence case
- Description should not start with "This package..."
- Description should not include the package name (it's redundant)
- Don't include `\dontrun{}` wrappers for network examples; use
  `\donttest{}` instead
- Reference papers in Description using `<doi:10.xxxx/yyyy>` angle
  brackets, not bare text

## See also

- `donttest-vs-dontrun.md` — when to use each directive
- `cache-policy.md` — the most common example-related rejection
- `globalenv-manipulation.md` — how to avoid writing to the user's
  workspace
- `url-404-in-description.md` — URL validation
