#!/usr/bin/env zsh
# Emit all mlr verbs (chain verbs + aux commands), one per line, to stdout.
mlr -l
mlr aux-list | grep '^ ' | sed 's/^ *//' | sed 's/^mlr //'
