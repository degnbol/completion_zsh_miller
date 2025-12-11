#!/usr/bin/env zsh
# Test that verbs with positional arguments have them defined

cd "$(dirname $0)/.."

errors=()

# sub/gsub/ssub require old and new positional args
for verb in sub gsub ssub; do
    grep -q "^${verb})" _mlr || { errors+=("$verb case missing"); continue; }

    # Extract the verb's case block and check for positional args
    verb_block=$(sed -n "/^${verb})/,/^;;/p" _mlr)
    echo "$verb_block" | grep -q '"1:old:"' || errors+=("$verb missing 1:old:")
    echo "$verb_block" | grep -q '"2:new:"' || errors+=("$verb missing 2:new:")
done

if [[ ${#errors} -gt 0 ]]; then
    echo "Positional arg errors: ${errors[*]}" >&2
    exit 1
fi
