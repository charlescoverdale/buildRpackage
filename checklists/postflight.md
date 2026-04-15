# Post-submission checklist

After `devtools::submit_cran()` returns success, complete these
items while waiting for CRAN's response.

## Immediately

- [ ] Check email for the CRAN confirmation link and click it within
      a few hours. The package is NOT in the queue until you confirm.
- [ ] Record the submission:
      - Package name
      - Version submitted
      - Submission date
      - First-submission or resubmission

If the skill is configured with a queue file
(`paths.queue_file` in user-config), this is done automatically.

## Within 24 hours

- [ ] Check for the automated pretest email from
      `CRAN-submissions@R-project.org`. It will tell you:
      - Pretest result (usually 1 NOTE for new submissions)
      - Whether any issues were flagged in `last released version's
        additional issues` section
- [ ] If pretest passes, no action needed. Wait for human review.
- [ ] If pretest fails, fix the issue immediately and resubmit.

## Within 2-10 business days

- [ ] Watch for reviewer email (typically from a named person, not
      the `CRAN-submissions` bot)
- [ ] If no email after 10 business days, send a polite chase to
      `CRAN-submissions@R-project.org` referencing your submission date

## On acceptance

- [ ] Wait for "package is on CRAN" email
- [ ] Tag the release: `git tag v<version> && git push --tags`
- [ ] Update install instructions in README:
      ```r
      install.packages("<pkg>")

      # Or install the development version from GitHub
      # install.packages("devtools")
      devtools::install_github("<user>/<pkg>")
      ```
- [ ] Add CRAN badges to README if `cran_badge: true` in user-config:
      ```markdown
      [![CRAN status](https://www.r-pkg.org/badges/version/pkg)](https://CRAN.R-project.org/package=pkg)
      [![CRAN downloads](https://cranlogs.r-pkg.org/badges/pkg)](https://CRAN.R-project.org/package=pkg)
      ```
- [ ] Add to any aggregation lists you maintain (profile README,
      portfolio site, etc.)
- [ ] Announce on relevant channels (social, blog, mailing list) if
      desired

## On rejection or request for changes

- [ ] Do NOT panic. Most first submissions require at least one
      round of feedback.
- [ ] Read the reviewer's email carefully. Note every specific issue.
- [ ] Use the `resubmit` phase of this skill to classify and fix each
      issue. Most common issues are already in `playbook/`.
- [ ] Bump the patch version.
- [ ] Update NEWS.md and cran-comments.md.
- [ ] Re-run the full pre-flight checklist.
- [ ] Resubmit.
