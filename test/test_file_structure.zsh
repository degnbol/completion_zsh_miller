#!/usr/bin/env zsh
# Test that _mlr has the expected file structure

cd "$(dirname $0)/.."
errors=()

# Check for #compdef
grep -q '#compdef mlr' _mlr || errors+=("missing #compdef mlr")

# Check for main function
grep -q '^_mlr()' _mlr || errors+=("missing _mlr() function definition")

# Check for final call
grep -q '^_mlr "\$@"' _mlr || errors+=("missing _mlr \"\$@\" call at end")

# Check for case statement
grep -q 'case \$state in' _mlr || errors+=("missing state case statement")

# Check for mlr-tui state
grep -q 'mlr-tui)' _mlr || errors+=("missing mlr-tui state handler")

if [[ ${#errors} -gt 0 ]]; then
    echo "Structure errors: ${errors[*]}" >&2
    exit 1
fi
