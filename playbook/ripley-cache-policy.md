# CRAN cache policy (the "Ripley rule")

## The policy

CRAN policy forbids packages from writing to the user's home filespace
outside of a session-temporary location. This includes any automatic
cache directory created by `tools::R_user_dir(pkg, "cache")` or
`rappdirs::user_cache_dir(pkg)`.

The policy is enforced primarily during example checks. Prof Ripley
runs `R CMD check --run-donttest` on CRAN's test systems. If any
`\donttest` example creates directories under `~/.cache/` or
equivalent, the package gets flagged.

## Symptoms

Reviewer email contains text like:
- "writes to the user's home filespace"
- "Please redirect to `tempdir()` in examples"
- "Packages must not write to the user's home filespace by default"

Common triggering pattern:

```r
#' @examples
#' \donttest{
#' result <- myfunc()  # internally calls tools::R_user_dir() and
#'                      # downloads data, which creates a permanent
#'                      # cache directory for the user
#' }
```

## Fix

Redirect the cache to `tempdir()` within every `\donttest` block that
could trigger a cache write:

```r
#' @examples
#' \donttest{
#' op <- options(mypackage.cache_dir = tempdir())
#' result <- myfunc()
#' options(op)
#' }
```

This requires the package's cache helper to read from `options()`
before falling back to `tools::R_user_dir()`:

```r
mypackage_cache_dir <- function() {
  d <- getOption("mypackage.cache_dir",
                 default = tools::R_user_dir("mypackage", "cache"))
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  d
}
```

## Prevention

1. Use the `cache.R.tmpl` template from this skill, which includes the
   `options()`-aware cache helper.
2. Ensure every `\donttest` example in your roxygen that calls any
   function which might write to disk wraps the call with
   `options(<pkg>.cache_dir = tempdir())`.
3. Also protect the test suite: `tests/testthat/setup.R` should set
   the same option globally so tests don't write to the real cache
   during `R CMD check`.

## Common mistake

Do not use `replace_all` when fixing this across a file. The cache
helper function itself uses `tools::R_user_dir()` as the default; if
you blindly replace that string, you'll cause infinite recursion.
Only wrap the **examples** and **tests**, not the helper definition.
