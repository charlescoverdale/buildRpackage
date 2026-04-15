# Unused @importFrom entries

## The policy

Not strictly a policy, but `R CMD check` raises a NOTE when
`@importFrom` declares a function that's never called in your code.
CRAN reviewers often flag these before accepting a new package.

## Symptoms

Check output contains:

```
* checking dependencies in R code ... NOTE
Namespace in Imports field not imported from: 'pkg'
  All declared Imports should be used.
```

Or:

```
@importFrom Excluding unknown export from stats: 'pmin'.
```

The second case catches `@importFrom` entries for functions that
don't exist in the target namespace — usually because you imported a
base operator (`pmin` is a base generic, not a stats export).

## Fix

1. For truly unused imports: remove them from the roxygen
   `@importFrom` block and re-run `devtools::document()`.

2. For imports of things that don't exist in the listed namespace:
   move to the correct namespace, or remove if they're in `base`
   (which doesn't need `@importFrom`).

## Detection

The check phase of this skill runs this automatically:

```bash
for fn in $(grep -h "@importFrom" R/*.R | sed 's/.*@importFrom [^ ]* //' | tr ' ' '\n' | sort -u); do
  count=$(grep -rn "\b${fn}\b" R/ --include="*.R" | grep -v "@importFrom" | wc -l)
  if [ "$count" -eq "0" ]; then
    echo "UNUSED: $fn"
  fi
done
```

## Prevention

- Write imports incrementally as you use them, not in bulk up front.
- When removing a function, check whether its imports are still needed.
- Base R operators (`pmin`, `pmax`, `abs`, `sum`, etc.) don't need
  `@importFrom`; they're always available.
