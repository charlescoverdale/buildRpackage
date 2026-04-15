# Cross-platform gotchas

CRAN runs `R CMD check` on Linux (Debian), Windows, and sometimes
macOS. Many R authors only test on one platform and are surprised
when CRAN's Windows check fails. This file documents the most common
cross-platform traps.

## File paths

### Use `file.path()` always

```r
# Broken on Windows:
path <- paste0(dir, "/", filename)

# Portable:
path <- file.path(dir, filename)
```

`file.path()` uses the correct separator for the platform.

### Use `tempfile()` and `tempdir()`, not hardcoded paths

```r
# Broken on Windows and Unix:
log_file <- "/tmp/mypackage.log"

# Portable:
log_file <- tempfile("mypackage_", fileext = ".log")
# Or:
log_file <- file.path(tempdir(), "mypackage.log")
```

### Never hardcode your home directory

```r
# Broken for everyone else:
data <- read.csv("/Users/charles/data.csv")
```

## Line endings

Windows uses `\r\n`, Unix uses `\n`. If your tests assume one or the
other:

```r
# Broken on Windows:
expect_equal(readLines(file), c("line 1", "line 2"))
# Reads correctly on Unix; fails on Windows due to trailing \r
```

`readLines()` strips line endings, so this is usually fine. Problems
arise when:
- You read raw bytes with `readBin()`
- You compare file sizes
- You count bytes/characters in a file

## Character encoding

### Specify encoding on read

```r
# Broken on Windows (Windows default is locale-specific, not UTF-8):
read.csv("data.csv")

# Portable:
read.csv("data.csv", fileEncoding = "UTF-8")
```

### Unicode in file paths

Windows handles Unicode filenames differently from Unix. If your
package reads files with non-ASCII names, test on both.

### Unicode in string constants

Write non-ASCII characters using Unicode escapes, not raw bytes:

```r
# Broken (depends on source file encoding):
greeting <- "Bon jour"  # with accent

# Portable:
greeting <- "Bon\u200cjour"  # explicit Unicode escape
```

Better: write the package source in UTF-8 (declare in DESCRIPTION:
`Encoding: UTF-8`) and let R handle it.

## Locale

### String sorting

```r
# Result depends on locale:
sort(c("a", "b", "A", "B"))
# Could be: "A", "B", "a", "b" (C locale)
# Or:       "a", "A", "b", "B" (en_US.UTF-8)
```

If order matters, use `sort(..., method = "radix")` which is
locale-independent:

```r
sort(x, method = "radix")
```

### Case conversion

```r
# Turkish locale: uppercase "i" is "İ", not "I"
toupper("i")  # returns "I" or "İ" depending on locale
```

For stable case conversion, use `toupper(x, type = "ASCII")` (not
actually an option in base R; use `tools::toTitleCase()` or
stringr's `str_to_upper(..., locale = "en")`).

### Number formatting

```r
# In some locales:
as.numeric("1,5")  # returns 1.5 (comma as decimal)
# In others:
as.numeric("1,5")  # returns NA
```

When parsing external data, use `readr` with explicit locale, or
`read.csv` with explicit `dec` argument.

## Timezone

```r
Sys.time()  # returns a POSIXct in the current timezone
```

### Tests that use `Sys.time()` break across timezones

```r
# Broken: test fails if run in Tokyo at a different hour:
test_that("log has today's date", {
  log <- create_log()
  expect_equal(format(log$time, "%Y-%m-%d"), format(Sys.Date(), "%Y-%m-%d"))
})
```

Fix: set the timezone explicitly in the test:

```r
test_that("log has today's date", {
  withr::with_envvar(c(TZ = "UTC"), {
    log <- create_log()
    expect_equal(format(log$time, "%Y-%m-%d"), format(Sys.Date(tz = "UTC"), "%Y-%m-%d"))
  })
})
```

### Don't capture `Sys.time()` in default arguments

```r
# Broken: default is evaluated at package load time:
my_func <- function(now = Sys.time()) { ... }
```

Use lazy evaluation:

```r
my_func <- function(now = NULL) {
  if (is.null(now)) now <- Sys.time()
  ...
}
```

## Numeric precision

Most R arithmetic is IEEE 754 double and consistent across
platforms. Exceptions:

- `long double` is platform-dependent. Avoid in C/C++ extensions.
- `sprintf("%a", x)` output differs slightly across platforms.
- Floating-point rounding in the last bit can differ for some
  transcendental functions.

Use tolerances in tests:

```r
expect_equal(x, y, tolerance = 1e-8)  # good default
```

## Random number generation

RNG is platform-independent **if you set the RNG kind explicitly**:

```r
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(42)
# Now rnorm(10) is identical on Linux, Windows, macOS
```

R's default RNG has changed between R versions (the `sample.kind`
changed in R 3.6.0). For maximum portability:

```r
set.seed(42, kind = "Mersenne-Twister", normal.kind = "Inversion",
         sample.kind = "Rejection")
```

## Case sensitivity in file names

- Unix (Linux): case-sensitive (`Data.csv` != `data.csv`)
- Windows: case-insensitive by default
- macOS: case-insensitive by default (but case-preserving)

This bites when you develop on macOS, have `DESCRIPTION` but write
tests that reference `description`, and they pass on macOS but fail
on Linux.

Always use the exact case of the filename.

## Symlinks

Windows treats symlinks differently from Unix. Avoid relying on
symlink behaviour. `normalizePath()` resolves symlinks if you need
consistent paths.

## Line length in source files

Some Windows editors add a BOM (byte-order mark) to UTF-8 files.
This breaks `source()` on Unix. Ensure your source files are saved
without BOM.

## R CMD check flavours

CRAN's `R CMD check` runs on multiple flavours:
- `r-devel-linux-x86_64-debian-gcc` (most strict)
- `r-devel-windows-x86_64`
- `r-devel-linux-x86_64-debian-clang` (valgrind)
- `r-patched-linux-x86_64`
- `r-release-linux-x86_64`
- `r-release-windows-x86_64`
- `r-oldrel-windows-x86_64`

Test on at least Linux and Windows before submission. GitHub Actions
with `actions/setup-r@v2` runs all three platforms for free.

## Pre-submission checklist

- [ ] All file paths use `file.path()`
- [ ] All temp files use `tempfile()` / `tempdir()`
- [ ] No hardcoded `/` or `\\` separators
- [ ] No hardcoded paths to `/tmp`, `/Users/...`, `C:\Users\...`
- [ ] Encoding specified for every `read.csv` / `readLines` /
  `readBin` on user-supplied files
- [ ] Tests don't compare `Sys.time()` across timezones
- [ ] Tests set RNG kind explicitly if using `set.seed`
- [ ] `DESCRIPTION` has `Encoding: UTF-8`
- [ ] Source files saved as UTF-8 without BOM
- [ ] If package has CI, it runs on Linux + Windows (macOS is bonus)

## CI setup (GitHub Actions)

Minimal `.github/workflows/R-CMD-check.yaml`:

```yaml
on: [push, pull_request]

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.config.os }}
    strategy:
      matrix:
        config:
          - {os: ubuntu-latest, r: 'release'}
          - {os: windows-latest, r: 'release'}
          - {os: macos-latest, r: 'release'}
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
      - uses: r-lib/actions/setup-r-dependencies@v2
      - uses: r-lib/actions/check-r-package@v2
```

This catches ~80% of cross-platform issues before CRAN does.
