#!/usr/bin/env zsh
# Test suite for mlr zsh completion
# Run with: ./test/run_tests.zsh

cd "$(dirname $0)/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

# Run a test file
run_test() {
    local test_file="$1"
    local test_name="${test_file:t:r}"

    if zsh "$test_file"; then
        echo "${GREEN}PASS${NC}: $test_name"
        ((PASS++))
    else
        echo "${RED}FAIL${NC}: $test_name"
        ((FAIL++))
    fi
}

echo "Running mlr completion tests..."
echo "================================"

# Run all test files
for test_file in test/test_*.zsh; do
    [[ -f "$test_file" ]] && run_test "$test_file"
done

echo "================================"
echo "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

[[ $FAIL -gt 0 ]] && exit 1
exit 0
