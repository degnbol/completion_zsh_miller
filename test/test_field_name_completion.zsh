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

if [[ ${#errors} -gt 0 ]]; then
    echo "Field name completion errors:" >&2
    printf '  - %s\n' "${errors[@]}" >&2
    exit 1
fi
