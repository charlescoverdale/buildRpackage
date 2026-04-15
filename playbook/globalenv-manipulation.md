# globalenv manipulation

## The policy

CRAN policy prohibits packages from writing to, or removing from, the
user's global environment. Neither library code nor examples nor tests
may modify `.GlobalEnv`.

This includes:
- `assign(x, value, envir = globalenv())`
- `assign(x, value, envir = .GlobalEnv)`
- `rm(x, envir = globalenv())`
- `rm(x, envir = .GlobalEnv)`
- Any `<<-` assignment that would persist to the global environment

## Symptoms

Reviewer email contains text like:
- "modifies the global environment"
- "writes to `.GlobalEnv`"
- "packages should not modify the user's workspace"

## Fix

Use a package-level environment instead:

```r
# In utils.R or a similar internal file:
mypkg_env <- new.env(parent = emptyenv())

# Write to it:
mypkg_env$api_key <- key

# Read from it:
key <- mypkg_env$api_key
```

Package environments are created at load time, are private to the
package, and do not leak into the user's workspace.

For the specific case of `set.seed()` save/restore inside a function
that draws random numbers: just call `set.seed()` directly without
saving and restoring. Modern CRAN guidance is that sample-data
functions setting their own seed is acceptable even if it affects the
user's RNG state, because the function is deterministic and the user
called it intentionally.

## Prevention

During pre-flight check, grep for the prohibited patterns:

```bash
grep -rn "globalenv\|\.GlobalEnv\|assign.*envir\|rm.*envir" R/
```

The check phase of this skill runs this automatically and refuses to
proceed if any match is found.
