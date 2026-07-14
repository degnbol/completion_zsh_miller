# Design decisions

## No native backend, not even for dispatch

Native completion is backed at runtime by
`mlr completion complete <idx> <words…>` (0-based word index). Probed
against mlr 6.20.2:

- Candidates are bare names — no description text, `compadd` without `-d`.
- Field-flag contexts return the `files` directive: `cut -f <TAB>`,
  `join -l`, `rename` never see column names.
- Filtering is exact-prefix and case-sensitive: `within` does not match
  `sort-within-records`; `CO` matches nothing — defeating matcher-list
  styles (substring, case-insensitive).

Descriptions and field-taking-flag markers exist only in `mlr <verb>
--help` text, so the scrape pipeline (`RUNME.zsh`) cannot be replaced by
native. A hybrid — native for context dispatch, scraped data decorating
its candidates — was also rejected: the wrapper would still need
chain-aware verb re-derivation to decorate, and the prefix filtering
forces blanking the current word before delegating, leaving native almost
nothing to own while adding a subprocess per TAB.

## `_arguments_options=(-S -C)`, no `-s`

- `-S`: don't complete options after `--`.
- `-C`: modify curcontext for state actions.
- `-s` (option stacking) caused cursor-jump issues and was removed.

## State-based file completion for `--from`

```zsh
'--from[...]: :->from_file'    # not: '--from[...]:filename:_files'
```

with `_alternative 'files:filename:_files'` in the state handler. Direct
`_files` inside `_arguments` doesn't respect the global matcher-list, so
substring matching (`tion.zsh` → `completion.zsh`) fails.

## Early return when completing main flags

```zsh
[[ -z "$line" && "$state" == "mlr-tui" ]] && return ret
```

When completing main flags (before any verb), `$line` is empty. Without
this, the `mlr-tui` handler manipulates `words`/`CURRENT` and causes cursor
jumps. The condition names the state so other states (`from_file`) still
run.

## Chain detection parses `LBUFFER`, not `line`

`line` from `_arguments` includes text after the cursor, so a `then`/`+`
typed after the cursor would be treated as a chain delimiter. `LBUFFER`
contains only text before the cursor. The same applies to finding input
files and detecting trailing space.

## Field completion adds no suffix

A trailing comma silently breaks mlr (`-f name,` gives wrong results), so
completion inserts the bare field name; users type commas themselves.
`compset -P '*,'` supports continuing a comma-separated list. Exception:
`rename` adds `-S ','` because its `old,new` pairs are always comma-joined,
and only "old" positions (even comma count in `IPREFIX`) are completed.

## Known zsh limitation: empty PREFIX with non-empty SUFFIX

`mlr uniq -f <TAB>,other` shows no completions — zsh matching doesn't
handle an empty PREFIX with a non-empty SUFFIX. Workaround: type at least
one character before TAB.

## Host completion styles this was tuned against

Case-insensitive, separator-partial, and substring matcher-list, with
completer chain `_expand _complete _match` — `_approximate` excluded
because typo-tolerance made `--cs` match `--asv`. (Defined in the author's
dotfiles: `zsh/completion.zsh`.)
