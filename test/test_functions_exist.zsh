#!/usr/bin/env zsh
# Test that all required functions are defined in _mlr

cd "$(dirname $0)/.."
source ./_mlr

errors=()

# Check _mlr function
(( $+functions[_mlr] )) || errors+=("_mlr")

# Check helper functions
(( $+functions[_mlr_commands] )) || errors+=("_mlr_commands")
(( $+functions[_mlr_files_or_chain] )) || errors+=("_mlr_files_or_chain")
(( $+functions[_mlr_field_names] )) || errors+=("_mlr_field_names")

if [[ ${#errors} -gt 0 ]]; then
    echo "Missing functions: ${errors[*]}" >&2
    exit 1
fi
