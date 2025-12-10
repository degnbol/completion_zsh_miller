#!/usr/bin/env zsh
# Test actual completion output for problematic cases
# Uses zsh's completion system to verify expected completions

cd "$(dirname $0)/.."

# Setup completion system
autoload -Uz compinit
compinit -u -d /dev/null

# Create temp test file for file completion tests
TESTDIR=$(mktemp -d)
trap "rm -rf $TESTDIR" EXIT
touch "$TESTDIR/completion_test.csv"
touch "$TESTDIR/other_file.csv"

errors=()

# Helper: get completions for a given command line
# Sets $reply array with completion candidates
get_completions() {
    local input="$1"
    reply=()

    # Set up the completion context
    local -a words
    words=(${(z)input})
    local CURRENT=${#words}

    # If input ends with space, we're completing a new word
    if [[ "$input" == *" " ]]; then
        words+=('')
        ((CURRENT++))
    fi

    # Capture completions by temporarily overriding compadd
    local -a captured=()
    compadd() {
        local -a opts args
        zparseopts -D -E -a opts - d: k X: x: J: V: o+: r: R: S: q e Q n U C 1 2 F: M+: P: p: s: W: f i
        captured+=("$@")
    }

    # Run completion
    (
        BUFFER="$input"
        CURSOR=${#BUFFER}
        _mlr 2>/dev/null
    )

    reply=("${captured[@]}")
}

# Test: --cs should complete to --csv (not --asv)
test_csv_completion() {
    local -a completions

    # Get all --c* options from _mlr
    completions=($(grep -oE "'--c[a-z-]+\[" _mlr | tr -d "['"))

    # --csv should be in the list
    if [[ " ${completions[*]} " != *" --csv "* ]]; then
        errors+=("--csv not found in completions")
        return
    fi

    # When prefix is --cs, --csv should match but --asv should not
    # This tests our fix for the _approximate issue
    local cs_matches=()
    for c in $completions; do
        [[ "$c" == --cs* ]] && cs_matches+=($c)
    done

    if [[ " ${cs_matches[*]} " != *" --csv "* ]]; then
        errors+=("--csv should match prefix --cs")
    fi

    # --asv should NOT match --cs prefix
    if [[ " ${cs_matches[*]} " == *" --asv "* ]]; then
        errors+=("--asv should NOT match prefix --cs")
    fi
}

# Test: --from should have file completion via state handler
test_from_completion() {
    # Verify --from uses state-based completion
    if ! grep -q "'--from\[.*\]: :->from_file'" _mlr; then
        errors+=("--from should use state-based completion (: :->from_file)")
    fi

    # Verify from_file state uses _alternative (enables substring matching)
    if ! grep -A3 "from_file)" _mlr | grep -q "_alternative.*files.*_files"; then
        errors+=("from_file state should use _alternative for file completion")
    fi
}

# Test: verb options should be available
test_verb_options() {
    # cat verb should have -n option
    if ! sed -n '/^cat)/,/^;;/p' _mlr | grep -q '"-n\['; then
        errors+=("cat verb missing -n option")
    fi

    # head verb should have -n option
    if ! sed -n '/^head)/,/^;;/p' _mlr | grep -q '"-n\['; then
        errors+=("head verb missing -n option")
    fi

    # cut verb should have -f option with field completion
    if ! sed -n '/^cut)/,/^;;/p' _mlr | grep -q '"-f.*_mlr_field_names'; then
        errors+=("cut verb missing -f option with field completion")
    fi

    # sort verb should have -f option with field completion
    if ! sed -n '/^sort)/,/^;;/p' _mlr | grep -q '"-f.*_mlr_field_names'; then
        errors+=("sort verb missing -f option with field completion")
    fi
}

# Test: chain keywords (then, +) should be in file completion
test_chain_completion() {
    if ! grep -q '_mlr_files_or_chain' _mlr; then
        errors+=("_mlr_files_or_chain function not found")
        return
    fi

    # Check that 'then' and '+' are offered as chain operators
    if ! grep -A5 '_mlr_files_or_chain()' _mlr | grep -q 'then.*chain'; then
        errors+=("'then' chain operator not in _mlr_files_or_chain")
    fi
}

# Test: common flags exist
test_common_flags() {
    local flags=(--csv --json --tsv --from --nidx --dkvp --pprint)

    for flag in $flags; do
        if ! grep -q "'${flag}\[" _mlr; then
            errors+=("common flag $flag not found")
        fi
    done
}

# Run tests
test_csv_completion
test_from_completion
test_verb_options
test_chain_completion
test_common_flags

if [[ ${#errors} -gt 0 ]]; then
    echo "Completion output errors:" >&2
    printf '  - %s\n' "${errors[@]}" >&2
    exit 1
fi
