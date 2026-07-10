#!/usr/bin/env zsh
# Fail if the committed completion data is stale vs the installed mlr.
cd "$(dirname $0)/.."
./check-drift.zsh
