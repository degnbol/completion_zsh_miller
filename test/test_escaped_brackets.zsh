#!/usr/bin/env zsh
# Test that square brackets inside option descriptions are escaped
# Unescaped nested brackets cause errors like:
# _arguments:comparguments:327: invalid option definition: -p[Produce percents [0..100]...]

cd "$(dirname $0)/.."

# Check fraction's -p option specifically (known to have [0..100] in description)
# The brackets must be escaped as \[0..100\] in the generated _mlr file
fraction_p=$(grep 'Produce percents' _mlr)

if [[ -z "$fraction_p" ]]; then
    echo "Could not find fraction -p option in _mlr" >&2
    exit 1
fi

# Fail if we find unescaped brackets [0..100] (without backslash)
# Use zsh pattern matching: *[0..100]* but NOT *\[0..100\]*
if [[ "$fraction_p" == *'[0..100]'* && "$fraction_p" != *'\[0..100\]'* ]]; then
    echo "Found unescaped [0..100] in fraction -p option:" >&2
    echo "$fraction_p" >&2
    exit 1
fi

# Verify the brackets ARE properly escaped (backslash before [ and ])
if [[ "$fraction_p" != *'\[0..100\]'* ]]; then
    echo "Missing properly escaped \\[0..100\\] in fraction -p option:" >&2
    echo "$fraction_p" >&2
    exit 1
fi
