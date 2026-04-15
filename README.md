# buildRpackage

A [Claude Code](https://claude.com/claude-code) skill for shipping R packages to CRAN. Seven-phase workflow from market-gap ideation through acceptance: `ideate`, `name`, `plan`, `build`, `check`, `submit`, `resubmit`.

Captures CRAN policies and common failure modes as playbook entries, so you ship cleanly on the first try.


## Background

If you are new to R packaging, here is what this skill is about.

### What is an R package?

R packages are the standard way to share R code. When you type `install.packages("dplyr")` and then `library(dplyr)`, you are using someone else's package: a bundle of functions, documentation, datasets, and tests. Writing one is how you move from "R scripts I run locally" to "a tool other people (or your future self) can install, use, and cite."

A package is a folder with a specific structure: a `DESCRIPTION` file (metadata), an `R/` folder (your code), a `man/` folder (documentation generated from roxygen comments), an optional `tests/` folder, and an optional `data/` folder. There are ~21,000 R packages on CRAN as of early 2026, with more on GitHub, Bioconductor, and r-universe.

### What is CRAN?

CRAN is the **Comprehensive R Archive Network**. It is the default package repository that R installs from when a user runs `install.packages()`. Getting a package on CRAN means:

1. **Discoverability**: the package shows up in R's default search, in CRAN's task views, and in cran.r-project.org listings.
2. **Trust**: CRAN enforces quality standards, so users can install packages without worrying about breakage.
3. **Reach**: CRAN mirrors are installed everywhere (universities, research institutes, corporations). A CRAN package is accessible from the most locked-down corporate network.
4. **Citability**: you get a stable DOI-like URL (`https://CRAN.R-project.org/package=yourpackage`) and a reproducible version history.

The alternative is hosting your package on GitHub only. That works, but users need `devtools` or `remotes` installed, and many institutional computers disallow GitHub installs. CRAN is the higher bar but the wider audience.

### How CRAN reviews packages

This is the part that surprises newcomers. **CRAN packages undergo manual human review**, not just automated checks.

When you submit a package, two things happen:

1. **Automated pretest** (within minutes): CRAN's servers run `R CMD check --as-cran` on your package across multiple platforms (Linux, Windows, sometimes macOS). The result is emailed to you. This catches obvious problems (missing documentation, test failures, broken examples).

2. **Human review** (2-10 business days): a CRAN team member, often Prof Brian Ripley, Uwe Ligges, or Konstanze Lauseker, actually reads your submission. They check that the package does what it claims, that the DESCRIPTION is accurate, that examples are sensible, and that no CRAN policies are violated.

First-time submissions (and resubmissions of previously-archived packages) go to the **newbies queue**, which is human-reviewed in full. If anything is off, you get an email listing the issues. You fix them, bump the version, and resubmit.

This review process is why CRAN packages are trustworthy and why getting one accepted feels like an achievement. It also means there is a long tail of ways to get rejected that are not obvious from reading the policies document.

### Why this skill exists

CRAN has many gotchas that you only learn by hitting them:

- Prof Ripley's rule that examples must not write to the user's home directory, even via `tools::R_user_dir()` caching
- The difference between `\donttest` and `\dontrun` in documentation (they behave very differently on CRAN's test systems)
- The `globalenv()` manipulation trap (using `assign(x, y, envir = globalenv())` gets packages rejected even though it "works" locally)
- URL 404s in DESCRIPTION failing incoming feasibility when a pkgdown site isn't deployed yet
- Version number discipline (you cannot resubmit the same version number, so every round of feedback costs a patch bump)

Hitting any of these sends your package back to the newbies queue for another 2-10 day wait. Most first-time submitters hit at least one.

This skill encodes the full workflow plus the fix pattern for each common rejection reason. It takes a package from an empty directory through submission to CRAN, with the policy landmines documented and pre-checked, so you spend time on the package and not on the submission process.


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
