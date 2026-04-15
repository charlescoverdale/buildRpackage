# buildRpackage

A [Claude Code](https://claude.com/claude-code) skill for shipping R packages to CRAN.

## Why this exists

Hadley Wickham's [*R Packages*](https://r-pkgs.org) is the canonical book on how to structure an R package: `DESCRIPTION`, `R/`, roxygen, tests, the whole shape of it. Read it. But the book gets you to a working package, not a CRAN-accepted one.

CRAN itself has accumulated a thick layer of policy over two decades. Prof Ripley's rule that examples cannot write to the user's home directory, even via `tools::R_user_dir()`. The `globalenv()` prohibition that rejects packages even though they "work" locally. `\donttest` vs `\dontrun` behaving completely differently on CRAN's test systems. Version discipline: you cannot resubmit the same version number, so every round of reviewer feedback costs a patch bump. URL 404s in `DESCRIPTION` failing incoming feasibility when a pkgdown site is not yet deployed. Mozilla UA quirks for EU servers. Cross-platform path and encoding traps. The newbies queue for first submissions and the 2-10 business day wait that comes with it.

Each of these is a single line in the [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html), and each one can bounce a first submission back for another review round. Most first-time submitters hit at least one. Reading through every policy, then auditing every function in your package for compliance, is exactly the kind of grinding checklist work that an AI agent is good at and a human is tired of.

This skill encodes the full workflow plus the fix pattern for each common rejection reason. Seven phases from market-gap ideation through acceptance (`ideate`, `name`, `plan`, `build`, `check`, `submit`, `resubmit`), plus a 12-category code audit and an optional academic-methods audit. It runs the policy scans, verifies every external URL, runs `R CMD check --as-cran`, and cross-checks your functions against the audit checklists before you hit submit.

Built from shipping 17 R packages to CRAN. Every gotcha in the playbook is one that sent a previous package back to the newbies queue.


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
/cran-package audit academic <name>    # deep methods + literature review
/cran-package audit code <name>        # deep code + test quality review
/cran-package submit
/cran-package resubmit
```

If you invoke `/cran-package` with no arguments, the skill asks which phase you want.

**`check` vs `audit`**: `check` is the mechanical CRAN compliance pass. `audit` is the deep review that catches edge-case bugs, numerical instability, weak tests, and academic-credibility gaps. Run both before submitting.


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
    academic-audit-checklist.md    # for /audit academic
    formula-verification.md        # domain-specific formula traps
    test-adequacy.md               # four-level test quality model
    code-audit-checklist.md        # for /audit code
    edge-cases.md                  # empty, length-1, NA, duplicates, boundaries
    numerical-stability.md         # overflow, underflow, log-sum-exp
    cross-platform-gotchas.md      # paths, encoding, timezones
    ropensci-standards.md          # aspirational ceiling

  checklists/
    preflight.md             # run every item before submit
    postflight.md            # what to do after a successful submission
    resubmission.md          # how to handle reviewer feedback
    naming-validation.md     # CRAN + GitHub + base R name availability
    academic-audit.md        # 10-category academic scorecard
    code-audit.md            # 12-category code/CRAN scorecard
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
