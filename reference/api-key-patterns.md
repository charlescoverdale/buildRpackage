# API key patterns

For packages that wrap authenticated APIs, use this pattern to manage
credentials.

## Storage

Credentials go in a package-level environment, with env var fallback:

```r
# In utils.R or similar:
mypkg_env <- new.env(parent = emptyenv())

# Setter (exported):
mypkg_set_key <- function(key) {
  if (!is.character(key) || length(key) != 1L || !nzchar(key)) {
    cli::cli_abort("{.arg key} must be a non-empty character string.")
  }
  mypkg_env$api_key <- key
  invisible(NULL)
}

# Getter (internal):
mypkg_get_key <- function() {
  key <- mypkg_env$api_key %||% Sys.getenv("MYPKG_API_KEY", unset = "")
  if (!nzchar(key)) {
    cli::cli_abort(c(
      "No API key found.",
      "i" = "Set one with {.fn mypkg_set_key} or the {.envvar MYPKG_API_KEY} env var.",
      "i" = "Register at {.url https://api.provider.example/register}."
    ))
  }
  key
}
```

## Benefits

- **Package env** is private (not visible in user's workspace)
- **Env var fallback** lets users set keys in `.Renviron` once
- **Clear error message** with registration URL if no key is set
- **No globalenv manipulation** (CRAN-compliant)

## What to call the env var

Convention: `<PACKAGE>_API_KEY` in all caps. For multi-credential
APIs (username + key), use both: `<PACKAGE>_USER`, `<PACKAGE>_KEY`.

## HTTP Basic Auth

For APIs that use Basic Auth (e.g. MHCLG EPC), store both parts:

```r
mypkg_set_key <- function(user, key) {
  # ... validation ...
  mypkg_env$user <- user
  mypkg_env$api_key <- key
}

.mypkg_auth <- function() {
  user <- mypkg_env$user %||% Sys.getenv("MYPKG_USER", unset = "")
  key  <- mypkg_env$api_key %||% Sys.getenv("MYPKG_API_KEY", unset = "")
  if (!nzchar(user) || !nzchar(key)) {
    cli::cli_abort(...)
  }
  list(user = user, password = key)
}
```

Then in request code:

```r
req <- httr2::request(url)
req <- httr2::req_auth_basic(req, auth$user, auth$password)
```

## Examples with API keys

Use `\dontrun{}`, not `\donttest{}`, because CRAN runs `\donttest`
with `--run-donttest`. Without a key, the example would error on
CRAN's test system.

```r
#' @examples
#' \dontrun{
#' mypkg_set_key("your_key_here")
#' result <- mypkg_search("query")
#' }
```

## Tests with API keys

Guard live tests with env var checks:

```r
test_that("live API search works", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not(
    nzchar(Sys.getenv("MYPKG_API_KEY")),
    "Set MYPKG_API_KEY to run live tests."
  )
  result <- mypkg_search("query")
  expect_s3_class(result, "data.frame")
})
```

## Never

- Never bundle real keys in the package.
- Never commit `.Renviron` to git.
- Never log or print the key in error messages (use only the first
  few characters if absolutely needed for debugging).
- Never write the key to disk automatically.
