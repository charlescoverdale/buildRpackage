# Resubmission checklist

Follow this sequence when responding to CRAN reviewer feedback.

## 1. Parse the feedback

Read the reviewer email carefully. Identify each specific issue. For
each issue:

- [ ] Quote the exact text from the reviewer
- [ ] Locate the corresponding code (file:line)
- [ ] Classify against `playbook/` entries:
  - Filespace write → `playbook/cache-policy.md`
  - URL 404 → `playbook/url-404-in-description.md`
  - globalenv manipulation → `playbook/globalenv-manipulation.md`
  - Unused imports → `playbook/unused-importfrom.md`
  - `\dontrun` vs `\donttest` → `playbook/donttest-vs-dontrun.md`
  - `par()` / `options()` / `setwd()` not restored → `playbook/save-restore-user-state.md`
  - Other → document in cran-comments.md

## 2. Apply the fixes

- [ ] Fix each issue with the pattern from `playbook/`
- [ ] Re-document: `devtools::document()`
- [ ] Re-check: `devtools::check(cran = TRUE)`
- [ ] Verify 0/0/0 (or only acceptable NOTEs)

## 3. Update version

**First determine the regime** — this gate is non-negotiable, see
`playbook/version-discipline.md`:

- **Pretest failure** (email says "does not pass the incoming
  checks automatically", package never reached CRAN):
  - [ ] Keep the same version (first submissions stay at 0.1.0)
  - [ ] Do NOT add a new NEWS.md entry; update the existing
        version entry if the fix is worth recording, or leave
        NEWS alone
  - [ ] cran-comments.md header: "Resubmission (same version)"
- **Post-acceptance reviewer feedback** (human reviewer, package
  was on CRAN):
  - [ ] Bump patch version in DESCRIPTION (e.g. 0.2.0 → 0.2.1)
  - [ ] Add entry to NEWS.md for the new version
  - [ ] Summarise the fixes in one or two lines per issue

## 4. Update cran-comments.md

Use the `templates/cran-comments-resubmit.md.tmpl` template. Include:

- [ ] Version being submitted
- [ ] "This is a resubmission" statement
- [ ] Reviewer name and feedback date
- [ ] Bulleted list of what changed since the previous version
- [ ] Current check results

## 5. Verify and commit

- [ ] Full pre-flight checklist passes (`checklists/preflight.md`)
- [ ] Working tree is clean
- [ ] All changes committed
- [ ] Pushed to origin (required BEFORE submitting)

## 6. Submit

```r
assignInNamespace("yesno", function(...) FALSE, "devtools")
devtools::submit_cran()
```

- [ ] Click confirmation link in email within a few hours

## Things to watch for

- **Version rule depends on regime.** Pretest-stage rejection
  keeps the same version; post-acceptance rejection bumps. If in
  doubt, check `cran.r-project.org/package=<name>` — if the
  package is not listed, no version was ever released, so keep the
  number.

- **Don't argue with reviewers unless they're factually wrong**. If a
  reviewer asks for a change that's purely stylistic, make it. It's
  faster than disputing.

- **Respond to the submission email, not to the reviewer's personal
  address**, unless the reviewer explicitly asks you to reply to them.

- **Don't submit new changes while a submission is in the queue**.
  Wait for a response (accept or feedback) before resubmitting.

- **If you get multiple rounds of feedback from different reviewers**,
  address all issues in a single resubmission. Don't cherry-pick.
