#!/usr/bin/env zsh
# Emit the main mlr flags (one per line) for completion, to stdout.
cd ${0:A:h}
{
    mlr help flags | grep '^-' | sed 's/ or -/|-/g' | sed -E 's/ +/\t/' | sed -E 's/ +/ /g' |
        ./table_unjag.sh 1 $'\t' '|' | sed 's/\[/\\[/g' | sed 's/\]/\\]/g' |
        sed -E 's/\t(.*)/[\1]/' | sed '/[.}]]$/!s/]$/…]/'
    # add format conversion table
    mlr help flags | grep '^|' | grep -o -- '--[^ ]*'
    # add help shorthands
    mlr help topics | grep 'mlr -' | sed 's/ *mlr //' | sed 's/ = mlr /[/' | sed 's/$/]/'
# make --from complete filenames using state-based completion for proper substring matching
# https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org
} | sed '/^--from/s/$/: :->from_file/'
