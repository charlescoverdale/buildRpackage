# `\donttest` vs `\dontrun`

## The distinction

Both directives prevent an example from running under
`example(fn)` and during `R CMD check` by default. The difference:

| Directive | Skipped on CRAN | Runs locally during testing | Runs with `--run-donttest` |
|---|---|---|---|
| `\donttest{}` | Yes | **Yes** | **Yes** |
| `\dontrun{}` | Yes | **No** | **No** |

Prof Ripley runs CRAN tests with `--run-donttest`, so `\donttest`
examples DO get executed on CRAN. `\dontrun` is truly "never run".

## When to use which

**Use `\donttest` for**:
- Network-dependent examples (API calls, downloads)
- Slow examples (> 5 seconds)
- Examples that open graphics devices

**Use `\dontrun` for**:
- Examples that require credentials you cannot safely embed
  (API keys, tokens, login details)
- Examples that would irreversibly modify the user's system
- Examples that only work in interactive mode

## Common CRAN feedback

"Examples in \dontrun{} should be in \donttest{} or executable."

This means: you used `\dontrun` for something that CRAN expects to
actually run. Typically this applies to:
- Network examples that should succeed most of the time
- Examples where the credentials check is wrapped safely

## Fix patterns

### Pattern 1: Network example with cache

Was:
```r
#' @examples
#' \dontrun{
#' result <- myfunc("query")
#' }
```

Fix:
```r
#' @examples
#' \donttest{
#' op <- options(mypkg.cache_dir = tempdir())
#' result <- myfunc("query")
#' options(op)
#' }
```

### Pattern 2: Credential-dependent example

Was (wrong — CRAN will try to execute):
```r
#' @examples
#' \donttest{
#' myfunc_with_key("query")  # needs env var MYPKG_API_KEY
#' }
```

Fix (correct — stays skipped):
```r
#' @examples
#' \dontrun{
#' # Requires MYPKG_API_KEY environment variable to be set
#' myfunc_with_key("query")
#' }
```

### Pattern 3: Interactive-only example

Was:
```r
#' @examples
#' \donttest{
#' launch_shiny_app()
#' }
```

Fix:
```r
#' @examples
#' \dontrun{
#' launch_shiny_app()  # opens a browser window
#' }
```
