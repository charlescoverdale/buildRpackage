# buildRpackage

A [Claude Code](https://claude.com/claude-code) skill for shipping R packages to CRAN. Seven-phase workflow from market-gap ideation through acceptance: `ideate`, `name`, `plan`, `build`, `check`, `submit`, `resubmit`.

Captures CRAN policies and common failure modes as playbook entries, so you ship cleanly on the first try.


## Why this exists

CRAN submissions have a long tail of gotchas that aren't obvious from the policies page: Prof Ripley's cache-write rule, the difference between `\donttest` and `\dontrun`, the globalenv manipulation trap, when URL 404s fail incoming feasibility. Hitting any of these sends your package back to the newbies queue for another 2-10 days.

This skill encodes the full workflow plus the fix pattern for each common rejection reason, so you spend time building the package and not fighting the submission process.


## Install

Clone into your Claude Code skills directory:

```bash
git clone https://github.com/charlescoverdale/buildRpackage ~/.claude/skills/cran-package
```

Then copy the config example to your real config:

```bash
cp ~/.claude/skills/cran-package/user-config.example.yml \
   ~/.claude/skills/cran-package/user-config.yml
```

Edit `user-config.yml` with your name, email, GitHub username, and preferred conventions (licence, prose style, HTTP client, prefix style).


## Usage

In Claude Code:

```
/cran-package ideate
/cran-package name <proposed-name>
/cran-package plan <name>
/cran-package build <name>
/cran-package check
/cran-package submit
/cran-package resubmit
```

If you invoke `/cran-package` with no arguments, the skill asks which phase you want.


## What the skill contains

```
cran-package/
  SKILL.md                   # Claude reads this first; phase routing lives here
  user-config.example.yml    # copy to user-config.yml and edit

  templates/                 # all substitutable via {{PLACEHOLDERS}}
    DESCRIPTION.tmpl
    LICENSE.tmpl  LICENSE.md.tmpl
    .Rbuildignore
    .gitignore
    package.R.tmpl
    utils.R.tmpl
    cache.R.tmpl             # for the api and data archetypes
    auth.R.tmpl              # for the api archetype
    request.R.tmpl           # for the api archetype
    README.md.tmpl
    NEWS.md.tmpl
    cran-comments.md.tmpl
    cran-comments-resubmit.md.tmpl
    tests_testthat.R
    setup.R

  playbook/                  # fix patterns for common rejections
    ripley-cache-policy.md
    globalenv-manipulation.md
    url-404-in-description.md
    unused-importfrom.md
    donttest-vs-dontrun.md
    version-discipline.md
    newbies-queue.md

  reference/                 # background reading
    cran-policies-summary.md
    caching-patterns.md
    api-key-patterns.md
    testing-patterns.md
    common-first-notes.md

  checklists/
    preflight.md             # run every item before submit
    postflight.md            # what to do after a successful submission
    resubmission.md          # how to handle reviewer feedback
    naming-validation.md     # CRAN + GitHub + base R name availability
```


## Archetypes

Three package archetypes are supported. Pick one at build time:

| Archetype | Use for | Extra scaffolding |
|---|---|---|
| `compute` | Pure computation, no network (stats, algorithms) | None beyond base |
| `api` | REST API wrappers | `auth.R`, `cache.R`, `request.R` |
| `data` | Bundled datasets with helpers | `data/`, `data-raw/`, inst data |

Invoke with `/cran-package build <name> --type=api` (default is `compute`).


## Opinionated vs configurable

The skill enforces **CRAN policies** (not negotiable) and respects **user preferences** (configurable via `user-config.yml`).

Hard-coded because they are CRAN policies:

- No home-filespace writes from examples
- No `globalenv()` / `.GlobalEnv` manipulation
- Network tests wrapped in `skip_on_cran()` + `skip_if_offline()`
- Every URL in DESCRIPTION must resolve
- `\dontrun` only for genuinely-unrunnable examples
- Version bump on every resubmission
- NEWS.md entry for every version

Configurable in `user-config.yml`:

- Author details (name, email, GitHub username, ORCID)
- Licence (MIT, GPL-2, GPL-3, Apache-2.0)
- DESCRIPTION language (en-GB, en-US)
- Prose style (British, American)
- Em dash preference
- HTTP client (httr2, httr)
- JSON parser (jsonlite, RcppSimdJson)
- Prefix style (two-letter, three-letter, package-name)
- S3 print/plot method scaffolding
- CRAN / lifecycle / licence badges


## Contributing

Additions to the playbook and reference sections are welcome. If a CRAN reviewer flags an issue that isn't covered here, open a PR with the fix pattern.


## Licence

MIT. See `LICENSE` in this repository.
