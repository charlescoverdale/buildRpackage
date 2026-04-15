# URL 404 in DESCRIPTION

## The policy

CRAN's incoming feasibility check resolves every URL listed in the
DESCRIPTION file's `URL:` and `BugReports:` fields. If any returns a
404 or other error status, the submission fails.

## Symptoms

Reviewer email contains text like:
- "Found the following (possibly) invalid URLs"
- "URL: 404 Not Found"
- "BugReports: 404 Not Found"

## Common causes

1. **Pkgdown site URL included but no site exists yet**. Adding
   `https://username.github.io/pkg/` to URL before actually deploying
   the pkgdown site is the most frequent cause.

2. **Repo renamed on GitHub**. If you renamed the repository, old
   URLs in DESCRIPTION still point to the old path.

3. **BugReports pointing to a private repo**. Private GitHub repos
   return 404 to unauthenticated requests.

4. **API endpoint URLs in Description text**. Example API endpoints
   like `https://api.example.com/v1/data` may return 400 or 503 when
   hit without parameters. Sometimes this is a false positive that
   reviewers will forgive; sometimes it triggers the check.

## Fix

1. Remove any URL that does not currently serve a valid page.
2. If the pkgdown site isn't deployed, remove that line from
   DESCRIPTION.
3. If you want to include a placeholder for a future pkgdown site,
   deploy it first (a single commit to `gh-pages` with a minimal
   `index.html`) before adding the URL.
4. For API endpoints in Description text, wrap them in angle
   brackets, which tells CRAN's checker these are references, not URLs
   to fetch: `<https://api.example.com/>`.

## Prevention

Run `urlchecker::url_check()` before every submission. This catches
the problem locally before CRAN sees it.

```r
install.packages("urlchecker")
urlchecker::url_check()
```

Note: `urlchecker` requires pandoc to parse some documents. Set
`PATH="/Applications/quarto/bin/tools:$PATH"` on macOS if pandoc is
shipped with Quarto, or install `pandoc` separately.
