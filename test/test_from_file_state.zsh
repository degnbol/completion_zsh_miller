#!/usr/bin/env zsh
# Test that --from uses state-based completion with _alternative
# This enables proper substring matching for file completion

cd "$(dirname $0)/.."
errors=()

# --from should use state-based completion
grep -q '\-\-from.*:->from_file' _mlr || errors+=("--from should use : :->from_file")

# from_file state handler should exist
grep -q 'from_file)' _mlr || errors+=("from_file state handler missing")

# from_file should use _alternative for proper matching
grep -A2 'from_file)' _mlr | grep -q '_alternative' || errors+=("from_file should use _alternative")

# flags.help should have the state completion
grep -q '^--from.*:->from_file' flags.help || errors+=("flags.help missing state completion for --from")

if [[ ${#errors} -gt 0 ]]; then
    echo "Errors: ${errors[*]}" >&2
    exit 1
fi
