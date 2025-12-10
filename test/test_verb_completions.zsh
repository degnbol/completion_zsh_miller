#!/usr/bin/env zsh
# Test that common verb completions exist

cd "$(dirname $0)/.."

verbs=(cat head tail cut sort filter put join stats1 stats2 uniq count top sample)
missing=()

for verb in $verbs; do
    grep -q "^${verb})" _mlr || missing+=($verb)
done

if [[ ${#missing} -gt 0 ]]; then
    echo "Missing verb completions: ${missing[*]}" >&2
    exit 1
fi
