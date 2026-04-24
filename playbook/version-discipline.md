# Version discipline

## Rules

1. **First submission MUST be 0.1.0**. CRAN reviewers expect new
   packages to start here. Submitting a first version as 0.2.0,
   1.0.0, or 2.3.4 is technically allowed but:
   - Raises suspicion with reviewers
   - Looks like an abandoned v0.1.0 nobody else uses
   - Usually triggers a request to renumber
   - Wastes at least one submission cycle (2-10 days)

   If you have been developing the package on GitHub with
   incremental versions (0.1.0, 0.2.0, etc.), for the CRAN
   submission specifically, collapse all pre-CRAN versions into a
   single 0.1.0 entry in NEWS.md and bump DESCRIPTION to 0.1.0.
   Keep your GitHub tags intact; they don't need to match CRAN
   version numbers.

   **The `submit` phase of this skill hard-gates on this rule.** If
   the DESCRIPTION version is anything other than 0.1.0 and the
   package is not already on CRAN, the submit phase will refuse to
   run and instruct the user to renumber first.

2. **Bump the patch version on every resubmission of an
   already-accepted package**, including trivial fixes. Never
   resubmit the same version number once a version has shipped to
   CRAN.

   **CRITICAL exception — pre-acceptance resubmissions keep the
   same version.** If the package failed CRAN's automatic incoming
   checks (pretest NOTE from win-builder / Debian), the tarball was
   rejected at the gate and nothing was released. Keep the version
   number the same. For a first submission this means 0.1.0 stays
   0.1.0 through every pretest cycle until CRAN actually accepts
   it. Bumping 0.1.0 → 0.1.1 after a pretest failure is wrong: no
   0.1.0 was ever released, so a 0.1.1 entry in NEWS.md refers to
   an imaginary prior release. Update `cran-comments.md` to say
   "Resubmission (same version)" and enumerate the fixes there.

   **How to tell which regime you're in:**
   - Pretest failure email contains "does not pass the incoming
     checks automatically" and the package is NOT visible at
     `cran.r-project.org/package=<name>` → keep version.
   - Reviewer feedback email from a human CRAN maintainer, or the
     package has ever been on CRAN (including archived) → bump
     version.

3. **Every version needs a NEWS.md entry**. Even if the change is one
   line, the entry exists so downstream users know what changed.

4. **cran-comments.md must reference the current version**. If you're
   submitting 0.2.1, the file must say 0.2.1 and explain what changed
   since 0.2.0 (or the previous CRAN version).

5. **Use semantic versioning loosely**. Patch for fixes, minor for new
   exports, major for breaking changes. Nobody checks this strictly on
   CRAN but downstream users appreciate it.

## Common mistakes

- **Bumping 0.1.0 → 0.1.1 after a pretest-stage rejection of a
  first submission.** Pretest rejections do not publish anything;
  keep 0.1.0 until CRAN actually accepts the upload. The NEWS.md
  must not grow a 0.1.1 entry for a version that never shipped.
  This has happened multiple times — the rule is: bump only after
  a real release. Last incident: cer 0.1.0, 2026-04-24. See rule 2
  above for the trigger-phrase test.

- Submitting 0.2.1 after 0.2.0 was accepted, then getting reviewer
  feedback and resubmitting as 0.2.1 again. CRAN will not process
  duplicates once a version is on the system. Bump to 0.2.2.

- Forgetting to update NEWS.md when bumping. `R CMD check` does not
  catch this; CRAN reviewers sometimes do.

- Rolling a major version (1.0.0) for a first submission because you
  feel the package is "production ready". CRAN doesn't care. 0.1.0 is
  fine.

## What to put in NEWS.md for a resubmission

```markdown
# mypackage 0.2.1

* Fix: address CRAN reviewer feedback (2026-04-13).
  Examples no longer write to the user's home filespace.
```

That's it. One line per change. Grouped under a heading that matches
the version.

## What to put in cran-comments.md

Include:
- Version number being submitted
- Note that it's a resubmission (if applicable)
- Who flagged the previous issue and when
- Specific fixes applied since last version
- Current `R CMD check` results (0/0/0 or known NOTEs)

See `templates/cran-comments-resubmit.md.tmpl` for the structure.
