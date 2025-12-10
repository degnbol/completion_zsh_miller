#!/usr/bin/env zsh
# Test that early return exists for option completion
# Without this, mlr-tui state handler causes cursor jump when completing main flags

cd "$(dirname $0)/.."

if grep -q '\[\[ -z "\$line" && "\$state" == "mlr-tui" \]\] && return' _mlr; then
    exit 0
else
    echo "Missing early return for option completion (prevents cursor jump)" >&2
    exit 1
fi
