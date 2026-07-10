#!/usr/bin/env zsh
# Detect when the generated completion data is stale relative to the installed
# mlr. Cheap: re-runs only the list generators, not the full per-verb regen.
# Exit 0 if current, 1 if drift found (fix by re-running ./RUNME.zsh).
set -uo pipefail
cd ${0:A:h}

drift=0

recorded_version=$([[ -f VERSION ]] && cat VERSION || echo "(none)")
installed_version=$(mlr --version)
if [[ "$recorded_version" != "$installed_version" ]]; then
    echo "version: recorded '$recorded_version', installed '$installed_version'"
    drift=1
fi

verb_diff=$(diff verbs.list =(./verbs.list.sh) || true)
if [[ -n "$verb_diff" ]]; then
    echo "verbs (< recorded, > installed):"
    echo "$verb_diff"
    drift=1
fi

flag_diff=$(diff flags.help =(./flags.help.sh) || true)
if [[ -n "$flag_diff" ]]; then
    echo "flags (< recorded, > installed):"
    echo "$flag_diff"
    drift=1
fi

(( drift )) && echo "stale — regenerate with ./RUNME.zsh"
exit $drift
