# Common CRAN feedback on first submissions

Things reviewers frequently flag on first submission, with guidance
on whether each is fatal, fixable, or informational.

## "New submission" NOTE

```
* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Your Name <you@example.com>'
  New submission
```

**Status**: Informational. Always appears on first submission.
**Action**: None.

## "Possibly misspelled words in DESCRIPTION"

```
Possibly misspelled words in DESCRIPTION:
  API (5:12)
  GeoJSON (8:34)
```

**Status**: Often false positives. Technical terms, proper nouns, and
acronyms trigger this.

**Action**: Review each flagged word:
- If it's a real typo: fix it
- If it's a proper noun or acronym: ignore, reviewers usually accept
- If it's a technical term and reviewers complain, quote it in
  single quotes in the Description: `'GeoJSON' endpoints`

## "Checking URLs"

```
Found the following (possibly) invalid URLs:
  URL: https://example.com/deprecated-page
    From: inst/doc/vignette.html
    Status: 404
    Message: Not Found
```

**Status**: Fatal if the URL is in DESCRIPTION. Often ignored if in
vignettes or README and reviewers understand why (e.g. API example
URLs return 400 when hit without parameters).

**Action**: Remove dead URLs. For API examples, wrap the URL in
angle brackets: `<https://api.example.com/>`.

## "Examples with CPU (user + system) or elapsed time > 5s"

```
Examples with CPU (user + system) or elapsed time > 5s
         user system elapsed
mypkg_fn 0.02   0.01    7.23
```

**Status**: Can be fatal depending on how far over the limit.

**Action**: Wrap slow examples in `\donttest{}`. CRAN still runs
`\donttest` examples but doesn't enforce the 5-second limit on them.

## "Please ensure that your functions do not write by default or in
your examples/vignettes/tests in the user's home filespace"

**Status**: Fatal.
**Action**: See `playbook/ripley-cache-policy.md`.

## "Please add \value tags to your function documentation"

```
Undocumented return values:
  myfunc
```

**Status**: Fatal.

**Action**: Every exported function needs `@return` describing what
it returns. For functions that return `invisible(NULL)`:

```r
#' @return Invisibly returns `NULL`.
```

## "Please replace \dontrun with \donttest"

**Status**: Fatal if reviewer insists.

**Action**: See `playbook/donttest-vs-dontrun.md`. If the example
genuinely requires credentials, explain in cran-comments.md why
`\dontrun` is appropriate.

## "Please provide small toy examples"

**Status**: Fatal.

**Action**: Every exported function needs runnable examples, not
just placeholders. If the function requires data, include sample data
with the package or use generated data in the example.

## "Please write your Title in Title Case"

**Status**: Fatal.

**Action**: `Title: Access UK Housing Data` (good) not
`Title: Access uk housing data` (bad).

## "Please write package names, software names and API names in
single quotes"

**Status**: Fatal.

**Action**: In DESCRIPTION:
- `'HM Land Registry'` not `HM Land Registry`
- `'FRED'` not `FRED`
- `'Python'` not `Python`

## "Please add references describing the methods"

```
If there are references describing the methods in your package,
please add these in the description field of your DESCRIPTION file...
```

**Status**: Fatal if the package implements academic methods.

**Action**: Add references using the CRAN format:

```
Bourguignon (1979) <doi:10.2307/1914138>
```

Note the angle brackets around the DOI link and no space between
`doi:` and the identifier.
