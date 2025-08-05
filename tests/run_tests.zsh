#!/bin/zsh

# Simple test runner for CleanRush

SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Overall counters
TOTAL=0
PASSED=0
FAILED=0

echo -e "${BOLD}${CYAN}==================================${NC}"
echo -e "${BOLD}${CYAN}    CleanRush Test Suite          ${NC}"
echo -e "${BOLD}${CYAN}==================================${NC}"

# Unit Tests
echo -e "\n${BOLD}Unit Tests${NC}"
echo "=========="

for test in "$SCRIPT_DIR"/unit/test_*.zsh; do
    if [[ -f "$test" ]]; then
        name=$(basename "$test" .zsh)
        echo -e "\n${BLUE}Running: $name${NC}"
        
        # Run test and count results
        output=$("$test" 2>&1)
        test_passed=$(echo "$output" | grep -c "✓")
        test_failed=$(echo "$output" | grep -c "✗")
        
        echo "$output"
        
        TOTAL=$((TOTAL + test_passed + test_failed))
        PASSED=$((PASSED + test_passed))
        FAILED=$((FAILED + test_failed))
        
        if [[ $test_failed -eq 0 ]]; then
            echo -e "${GREEN}✓ $name completed${NC}"
        else
            echo -e "${RED}✗ $name: $test_failed failures${NC}"
        fi
    fi
done

# Integration Tests
echo -e "\n${BOLD}Integration Tests${NC}"
echo "================"

for test in "$SCRIPT_DIR"/integration/test_*.zsh; do
    if [[ -f "$test" ]]; then
        name=$(basename "$test" .zsh)
        echo -e "\n${BLUE}Running: $name${NC}"
        
        # Run test and count results
        output=$("$test" 2>&1)
        test_passed=$(echo "$output" | grep -c "✓")
        test_failed=$(echo "$output" | grep -c "✗")
        
        echo "$output"
        
        TOTAL=$((TOTAL + test_passed + test_failed))
        PASSED=$((PASSED + test_passed))
        FAILED=$((FAILED + test_failed))
        
        if [[ $test_failed -eq 0 ]]; then
            echo -e "${GREEN}✓ $name completed${NC}"
        else
            echo -e "${RED}✗ $name: $test_failed failures${NC}"
        fi
    fi
done

# Summary
echo -e "\n${BOLD}${CYAN}==================================${NC}"
echo -e "${BOLD}${CYAN}         Test Summary             ${NC}"
echo -e "${BOLD}${CYAN}==================================${NC}"

echo -e "Total Tests:   ${BOLD}$TOTAL${NC}"
echo -e "Passed:        ${GREEN}${BOLD}$PASSED${NC}"
echo -e "Failed:        ${RED}${BOLD}$FAILED${NC}"

if [[ $FAILED -gt 0 ]]; then
    echo -e "\n${RED}${BOLD}Tests failed!${NC}"
    exit 1
else
    echo -e "\n${GREEN}${BOLD}All tests passed! 🎉${NC}"
    exit 0
fi