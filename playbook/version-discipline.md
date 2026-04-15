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

2. **Bump the patch version on every resubmission**, including
   trivial fixes. Never resubmit the same version number.

3. **Every version needs a NEWS.md entry**. Even if the change is one
   line, the entry exists so downstream users know what changed.

4. **cran-comments.md must reference the current version**. If you're
   submitting 0.2.1, the file must say 0.2.1 and explain what changed
   since 0.2.0 (or the previous CRAN version).

5. **Use semantic versioning loosely**. Patch for fixes, minor for new
   exports, major for breaking changes. Nobody checks this strictly on
   CRAN but downstream users appreciate it.

## Common mistakes

- Submitting 0.1.0, getting feedback, fixing, and resubmitting 0.1.0.
  CRAN will not process the new tarball. Bump to 0.1.1.

- Forgetting to update NEWS.md when bumping. `R CMD check` does not
  catch this; CRAN reviewers sometimes do.

- Rolling a major version (1.0.0) for a first submission because you
  feel the package is "production ready". CRAN doesn't care. 0.1.0 is
  fine.

## What to put in NEWS.md for a resubmission

```markdown
# mypackage 0.2.1

* Fix: address CRAN feedback from Prof Ripley (2026-04-13).
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
