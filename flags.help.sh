#!/usr/bin/env zsh
mlr help flags | grep '^-' | sed 's/ or -/|-/g' | sed -E 's/ +/\t/' | sed -E 's/ +/ /g' |
    ./table_unjag.sh 1 $'\t' '|' | sed 's/\[/\\[/g' | sed 's/\]/\\]/g' |
    sed -E 's/\t(.*)/[\1]/' | sed '/[.}]]$/!s/]$/…]/' > flags.help
# add format conversion table
mlr help flags | grep '^|' | grep -o -- '--[^ ]*' >> flags.help
# add help shorthands
mlr help topics | grep 'mlr -' | sed 's/ *mlr //' | sed 's/ = mlr /[/' | sed 's/$/]/' >> flags.help
# make --from complete filenames using state-based completion for proper substring matching
# https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org
sed -i '' '/^--from/s/$/: :->from_file/' flags.help
