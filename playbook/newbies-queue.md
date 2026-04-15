# The CRAN newbies queue

## What it is

First-time CRAN submissions go to the "newbies" queue, which is
processed by human reviewers (most notably Prof Brian Ripley and
Konstanze Lauseker). The queue is slower than regular updates: expect
2-10 business days for a first review.

Archived packages being resubmitted also go through the newbies queue,
even if the same author had other packages accepted before.

## Timeline expectations

- **Day 1**: Automated pretest runs. You'll receive an email within
  minutes confirming receipt and the pretest result.
- **Day 2-10**: Human review. No news is usually good news at this
  stage.
- **If accepted**: Email from CRAN Team, package appears on CRAN
  within hours.
- **If feedback**: Email from a named reviewer with specific issues.
  You have a window (typically 2 weeks) to respond before the package
  is auto-archived.

## What happens during review

Reviewers check things automated tests don't:
- DESCRIPTION Title and Description match the actual package
- Examples make sense
- No obvious policy violations
- The package does what it claims to do
- The name doesn't conflict with existing infrastructure

## If you hear nothing

After 10 business days with no response, it's acceptable to email
CRAN-submissions at r-project.org with a polite chase. Reference your
submission email and ask for an update.

## Don't

- Don't resubmit while the previous submission is still in the queue.
  This creates duplicates and annoys reviewers.
- Don't email multiple CRAN team members about the same submission.
- Don't argue with reviewer feedback unless they've made a factual
  error. If they ask you to change something, change it.
- Don't wait too long to respond to feedback — packages get
  auto-archived if the window expires.

## What to do after acceptance

1. Click the "confirm submission" link in your email within a few
   hours of receiving it.
2. Wait for the "package is on CRAN" email.
3. Tag the release in git: `git tag v0.1.0 && git push --tags`.
4. Update any install instructions in READMEs from
   `devtools::install_github(...)` to show `install.packages(...)` as
   the primary option.
5. Add your package to any aggregation or portfolio lists you keep.
