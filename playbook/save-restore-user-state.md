# Save-restore `par()`, `options()`, `setwd()` in examples and vignettes

## The rule

CRAN policy: your examples, vignettes, and demos must not leave the
user's session state modified. If you change `par()`, `options()`, or
the working directory, you must restore the original value before the
example / vignette finishes.

Reviewer wording you will see:

> Please always make sure to reset to user's options(), working
> directory or par() after you changed it in examples and vignettes
> and demos.

Rejection path: the package goes straight back to you with this request
regardless of how clean the rest of the check is. It is non-negotiable.

## Why it matters

A user loads your package, runs your example, then runs their own code.
If your example called `par(mfrow = c(1, 2))` without restoring, every
subsequent plot they make has two panels. If your example called
`options(digits = 3)` without restoring, every numeric they print for
the rest of their session is rounded. These are real bug reports CRAN
has seen and is now ruthless about preventing.

## Fix patterns

### `par()`

Was:
```r
par(mfrow = c(1, 2))
plot(x, y)
plot(a, b)
```

Fix:
```r
oldpar <- par(no.readonly = TRUE)
par(mfrow = c(1, 2))
plot(x, y)
plot(a, b)
par(oldpar)
```

`no.readonly = TRUE` is essential: `par()` with no arguments returns a
list that includes read-only parameters (`"cin"`, `"cra"`, etc.), and
passing those back into `par()` triggers warnings on CRAN checks.

Inside a function body, prefer `on.exit()` so `par` is restored even if
the function errors:

```r
myplot <- function(x, y) {
  oldpar <- par(no.readonly = TRUE)
  on.exit(par(oldpar), add = TRUE)
  par(mfrow = c(1, 2))
  plot(x, y)
  plot(y, x)
}
```

### `options()`

Was:
```r
options(digits = 3)
print(result)
```

Fix:
```r
oldopt <- options(digits = 3)   # options() returns the *old* values
print(result)
options(oldopt)
```

Note the useful behaviour: `options(digits = 3)` both sets the new
value and returns the list of previous values, so you only need one
save call.

Inside a function:
```r
myfunc <- function() {
  oldopt <- options(digits = 3)
  on.exit(options(oldopt), add = TRUE)
  # ...
}
```

### `setwd()`

Avoid `setwd()` in examples and vignettes entirely if you can. It is
almost always a code smell: use absolute paths, `file.path()`, or
`withr::with_dir()`. If you genuinely need it:

Was:
```r
setwd(some_dir)
do_work()
```

Fix:
```r
oldwd <- getwd()
setwd(some_dir)
do_work()
setwd(oldwd)
```

Or, cleaner:
```r
withr::with_dir(some_dir, do_work())
```

## What the preflight check looks for

Grep for mutations inside vignettes, man/ examples, and demo/:

```bash
grep -rn -E 'par\(|options\(|setwd\(' vignettes/ man/ demo/ R/
```

For each match, check an adjacent save appears before it and an
adjacent restore appears after it (or inside an `on.exit` in the same
function scope).

Safe patterns that do NOT trigger the rule:

- `par("mar")` — reading, not mutating
- `getOption("foo")` — reading
- `getwd()` — reading
- Package-internal options that the package itself owns (e.g.
  `options(mypkg.cache_dir = tempdir())` inside the package, where
  the package never promises to preserve user state for its own
  options)

Even for package-owned options, still save-restore if the option
affects *how your functions behave later in the session*. User-facing
options live forever in the session and should be treated as user
state.

## Incidents

- **ivcheck 0.1.0 (2026-04-21, Benjamin Altmann)**: `par(mfrow = c(1, 2))`
  in `vignettes/judge-designs.Rmd` without restore. Fixed with
  `oldpar <- par(no.readonly = TRUE) ... par(oldpar)` in v0.1.1.
