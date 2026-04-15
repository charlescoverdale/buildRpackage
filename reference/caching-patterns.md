# Caching patterns

For packages that download data from APIs or other remote sources,
local caching is almost always desirable. This file documents the
standard patterns.

## Where to cache

Use `tools::R_user_dir(package, "cache")` as the default. This gives a
platform-appropriate user-specific cache directory:
- macOS: `~/Library/Caches/R/<package>`
- Linux: `~/.cache/R/<package>`
- Windows: `%LOCALAPPDATA%\R\cache\R\<package>`

Allow overriding via `options()` so tests and examples can redirect
to `tempdir()`:

```r
mypkg_cache_dir <- function() {
  d <- getOption("mypkg.cache_dir",
                 default = tools::R_user_dir("mypkg", "cache"))
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  d
}
```

This pattern satisfies CRAN's filespace policy (examples redirect to
tempdir) without the user having to manage cache location manually.

## What to cache

Cache at the level that makes semantic sense. For API packages, that
usually means:
- One file per distinct query (keyed by parameters)
- Bulk downloads (yearly files, ZIP archives) kept as-is
- Metadata files (lists of valid codes, etc.) refreshed on a known
  cadence

Avoid caching:
- Very small responses (not worth the filesystem overhead)
- Query results that change frequently (unless you add expiration)

## Cache keys

Build cache keys from all parameters that affect the response. A
typical pattern:

```r
cache_key <- paste0(
  "hpi_", region_slug,
  if (!is.null(from)) paste0("_from_", from) else "",
  if (!is.null(to)) paste0("_to_", to) else "",
  ".csv"
)
cache_path <- file.path(mypkg_cache_dir(), cache_key)
```

Avoid characters that aren't portable across filesystems: keep keys
to `[a-zA-Z0-9_-]` and use extensions (`.csv`, `.json`, `.zip`) that
match the payload.

## Refresh control

Every cached function should accept `refresh = FALSE` as the last
argument. When `TRUE`, bypass the cache and re-download:

```r
if (!file.exists(cache_path) || refresh) {
  download_fresh(cache_path)
} else {
  cli::cli_inform(c("i" = "Loading from cache. Use {.code refresh = TRUE} to re-download."))
}
```

## Cache inspection

Expose `mypkg_cache_info()` and `mypkg_clear_cache()` so users can
manage the cache manually. See `templates/cache.R.tmpl` for the
standard implementation.

## Testing with cache

In `tests/testthat/setup.R`:

```r
options(mypkg.cache_dir = tempfile("mypkg_test_cache_"))
```

This makes every test write to a unique temp directory that gets
cleaned up when the session ends.

## Examples with cache

Every `\donttest{}` example that triggers a cache write:

```r
#' \donttest{
#' op <- options(mypkg.cache_dir = tempdir())
#' result <- my_fetching_function()
#' options(op)
#' }
```

Restore the option with `options(op)` to avoid affecting the user's
subsequent session.
