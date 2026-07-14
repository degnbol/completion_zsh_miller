# Zsh completion for Miller (mlr)

## Features

- Verb, flag, and help-topic completion with descriptions.
- Verb chaining: completes correctly after `then` / `+`.
- Field names read from your actual input file:
  `mlr --from data.tsv cut -f <TAB>` offers the column names of `data.tsv`.
  Also works for comma-separated field lists, `join -l`/`--lk` (fields from
  the left file), and `rename` `old,new` pairs.
- Works with substring and case-insensitive matcher styles.

## Comparison to `mlr completion zsh`

Miller's built-in completion covers verb, flag, and help-topic names,
including `then`-chaining. On top of that, this repo adds descriptions,
field-name completion from the input file, and matching that follows your
zsh matcher styles.

## Dependencies

- zsh
- jq

## Install

Place or symlink `_mlr` in a folder of zsh's `$fpath`.
