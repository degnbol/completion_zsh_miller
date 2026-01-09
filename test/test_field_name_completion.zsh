#!/usr/bin/env zsh
# Test that field name completion extracts columns from input files
# e.g. mlr --csv --from file.csv uniq -f <TAB> should complete column names

cd "$(dirname $0)/.."

errors=()

# Check _mlr_field_names function exists
if ! grep -q '_mlr_field_names()' _mlr; then
    errors+=("_mlr_field_names function not found")
fi

# Check it parses --from argument
if ! grep -A30 '_mlr_field_names()' _mlr | grep -q '"--from"'; then
    errors+=("_mlr_field_names should look for --from argument")
fi

# Check it uses mlr to extract column names
if ! grep -A50 '_mlr_field_names()' _mlr | grep -q 'mlr.*head'; then
    errors+=("_mlr_field_names should use mlr head to get columns")
fi

# Check it uses jq to extract keys
if ! grep -A50 '_mlr_field_names()' _mlr | grep -q "jq"; then
    errors+=("_mlr_field_names should use jq to extract keys")
fi

# Check verbs with field options use _mlr_field_names
field_verbs=(cut sort uniq stats1 head tail)
for verb in $field_verbs; do
    if ! sed -n "/^${verb})/,/^;;/p" _mlr | grep -q '_mlr_field_names'; then
        errors+=("$verb should use _mlr_field_names for field completion")
    fi
done

# Integration test: create a test CSV and verify column extraction works
TESTDIR=$(mktemp -d)
trap "rm -rf $TESTDIR" EXIT

echo "name,age,city" > "$TESTDIR/test.csv"
echo "Alice,30,NYC" >> "$TESTDIR/test.csv"

# Test that mlr can extract the columns (this is what _mlr_field_names does)
cols=$(mlr --csv --ojsonl head -n 1 "$TESTDIR/test.csv" 2>/dev/null | jq -r 'keys[]' 2>/dev/null)
expected_cols="age
city
name"

if [[ "$cols" != "$expected_cols" ]]; then
    errors+=("Column extraction failed: expected '$expected_cols', got '$cols'")
fi

# Check comma-separated field support (compset -P '*,')
if ! grep -A60 '_mlr_field_names()' _mlr | grep -q "compset -P '\*,'"; then
    errors+=("_mlr_field_names should support comma-separated fields with compset -P '*,'")
fi

# Check no suffix is added (user types comma themselves if needed)
if grep -A70 '_mlr_field_names()' _mlr | grep -q "\-S ','"; then
    errors+=("_mlr_field_names should not add comma suffix (causes issues with trailing commas)")
fi

# Check that field name functions use LBUFFER (not BUFFER) to handle trailing pipes
# e.g. mlr --from file.tsv cut -f | sed ... should still complete field names
# Pattern: match BUFFER} but not LBUFFER}
if grep -A60 '_mlr_field_names()' _mlr | grep 'BUFFER}' | grep -qv 'LBUFFER}'; then
    errors+=("_mlr_field_names should use LBUFFER, not BUFFER (to handle trailing pipes)")
fi

if grep -A60 '_mlr_join_left_field_names()' _mlr | grep 'BUFFER}' | grep -qv 'LBUFFER}'; then
    errors+=("_mlr_join_left_field_names should use LBUFFER, not BUFFER (to handle trailing pipes)")
fi

# Check that mlr-tui state handler uses LBUFFER for verb extraction and trailing space check
# This ensures completion works when there's text after cursor (e.g., pipes, chain operators)
if sed -n '/mlr-tui)/,/^[[:space:]]*;;/p' _mlr | grep 'buf_words=.*BUFFER}' | grep -qv 'LBUFFER}'; then
    errors+=("mlr-tui handler should use LBUFFER for buf_words (to handle trailing pipes)")
fi

if sed -n '/mlr-tui)/,/^[[:space:]]*;;/p' _mlr | grep -q '"\$BUFFER" == \*" "'; then
    errors+=("mlr-tui handler should check LBUFFER for trailing space, not BUFFER")
fi

# Check chain detection searches buf_words (from LBUFFER), not line
# This prevents text after cursor (like "+ count") from being detected as chain delimiters
if sed -n '/mlr-tui)/,/^[[:space:]]*;;/p' _mlr | grep -q 'line\[idx\].*==.*then'; then
    errors+=("mlr-tui chain detection should search buf_words, not line (to ignore text after cursor)")
fi

# Check _mlr_rename_field_names function exists and handles odd/even positions
if ! grep -q '_mlr_rename_field_names()' _mlr; then
    errors+=("_mlr_rename_field_names function not found")
fi

# Check rename verb uses _mlr_rename_field_names for positional arg
if ! sed -n '/^rename)/,/^;;/p' _mlr | grep -q '_mlr_rename_field_names'; then
    errors+=("rename verb should use _mlr_rename_field_names for field completion")
fi

# Check rename function counts commas to determine position
if ! grep -A60 '_mlr_rename_field_names()' _mlr | grep -q '#commas.*%'; then
    errors+=("_mlr_rename_field_names should count commas to determine old/new position")
fi

if [[ ${#errors} -gt 0 ]]; then
    echo "Field name completion errors:" >&2
    printf '  - %s\n' "${errors[@]}" >&2
    exit 1
fi
