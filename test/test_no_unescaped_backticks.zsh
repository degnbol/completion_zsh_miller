#!/usr/bin/env zsh
# Test that backticks are escaped in _mlr to prevent command substitution
# Unescaped backticks in double-quoted strings cause errors like:
# _mlr_commands:1: command not found: sub

cd "$(dirname $0)/.."

# Find unescaped backticks in double-quoted strings
# Pattern: lines starting with " that contain ` not preceded by \
if grep -E '^".*[^\\]`' _mlr | grep -v '\\`' | head -1 | grep -q .; then
    echo "Found unescaped backticks in double-quoted strings:" >&2
    grep -E '^".*[^\\]`' _mlr | grep -v '\\`' | head -3 >&2
    exit 1
fi
