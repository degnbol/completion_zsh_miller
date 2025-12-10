#!/usr/bin/env zsh
# Test that -s (option stacking) is not in _arguments_options
# Option stacking causes cursor jump issues

cd "$(dirname $0)/.."

# Should be (-S -C), not (-s -S -C)
if grep -q '_arguments_options=(-S -C)' _mlr; then
    exit 0
else
    echo "_arguments_options should be (-S -C), -s causes cursor jump" >&2
    exit 1
fi
