#!/bin/zsh

# CleanRush Test Runner
# Runs all tests and reports results

SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test results array
declare -a FAILED_TEST_NAMES

# Create temp file for test results
RESULTS_FILE=$(mktemp -t cleanrush_test_results_XXXXXX)
trap "rm -f $RESULTS_FILE" EXIT

# Function to run a test file
run_test_file() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .zsh)"
    
    echo -e "\n${BLUE}Running: ${test_name}${NC}"
    echo "----------------------------------------"
    
    # Run the test file with timeout and capture results
    timeout 10 zsh -c "
        # Export the results file path
        export TEST_RESULTS_FILE='$RESULTS_FILE'
        
        # Initialize test counters for this file
        export FILE_TOTAL=0
        export FILE_PASSED=0
        export FILE_FAILED=0
        export FILE_SKIPPED=0
        
        # Source test utilities
        source '$SCRIPT_DIR/test_utils.zsh'
        
        # Source and run the test file
        source '$test_file'
        
        # Write results to file
        echo \"\$FILE_TOTAL:\$FILE_PASSED:\$FILE_FAILED:\$FILE_SKIPPED\" >> '$RESULTS_FILE'
    " 2>/dev/null
    
    local exit_code=$?
    
    # Read the last line of results (for this test file)
    if [[ -f "$RESULTS_FILE" ]]; then
        local last_result=$(tail -n 1 "$RESULTS_FILE")
        if [[ -n "$last_result" ]]; then
            IFS=':' read -r file_total file_passed file_failed file_skipped <<< "$last_result"
            
            # Update global counters
            TOTAL_TESTS=$((TOTAL_TESTS + file_total))
            PASSED_TESTS=$((PASSED_TESTS + file_passed))
            FAILED_TESTS=$((FAILED_TESTS + file_failed))
            SKIPPED_TESTS=$((SKIPPED_TESTS + file_skipped))
            
            if [[ $file_failed -gt 0 ]]; then
                echo -e "${RED}✗ ${test_name}: $file_failed failed${NC}"
                FAILED_TEST_NAMES+=("$test_name")
            else
                echo -e "${GREEN}✓ ${test_name}: All tests passed${NC}"
            fi
        fi
    fi
    
    return $exit_code
}

# Main test execution
main() {
    echo -e "${BOLD}${CYAN}==================================${NC}"
    echo -e "${BOLD}${CYAN}    CleanRush Test Suite          ${NC}"
    echo -e "${BOLD}${CYAN}==================================${NC}"
    
    # Check if running in CI or local environment
    if [[ -n "$CI" ]]; then
        echo -e "${YELLOW}Running in CI environment${NC}"
    else
        echo -e "${YELLOW}Running in local environment${NC}"
    fi
    
    # Clear results file
    > "$RESULTS_FILE"
    
    # Run unit tests
    echo -e "\n${BOLD}Unit Tests${NC}"
    echo "=========="
    for test_file in "$SCRIPT_DIR"/unit/test_*.zsh; do
        if [[ -f "$test_file" ]]; then
            run_test_file "$test_file"
        fi
    done
    
    # Run integration tests
    echo -e "\n${BOLD}Integration Tests${NC}"
    echo "================"
    for test_file in "$SCRIPT_DIR"/integration/test_*.zsh; do
        if [[ -f "$test_file" ]]; then
            run_test_file "$test_file"
        fi
    done
    
    # Display summary
    echo -e "\n${BOLD}${CYAN}==================================${NC}"
    echo -e "${BOLD}${CYAN}         Test Summary             ${NC}"
    echo -e "${BOLD}${CYAN}==================================${NC}"
    
    echo -e "Total Tests:   ${BOLD}$TOTAL_TESTS${NC}"
    echo -e "Passed:        ${GREEN}${BOLD}$PASSED_TESTS${NC}"
    echo -e "Failed:        ${RED}${BOLD}$FAILED_TESTS${NC}"
    echo -e "Skipped:       ${YELLOW}${BOLD}$SKIPPED_TESTS${NC}"
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo -e "\n${RED}${BOLD}Failed Tests:${NC}"
        for failed_test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}• $failed_test${NC}"
        done
        exit 1
    elif [[ $TOTAL_TESTS -eq 0 ]]; then
        echo -e "\n${YELLOW}${BOLD}No tests were run!${NC}"
        exit 1
    else
        echo -e "\n${GREEN}${BOLD}All tests passed! 🎉${NC}"
        exit 0
    fi
}

# Run tests
main "$@"