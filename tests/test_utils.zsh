#!/bin/zsh

# Test utilities and helper functions

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize counters if not already set
[[ -z "$FILE_TOTAL" ]] && FILE_TOTAL=0
[[ -z "$FILE_PASSED" ]] && FILE_PASSED=0
[[ -z "$FILE_FAILED" ]] && FILE_FAILED=0
[[ -z "$FILE_SKIPPED" ]] && FILE_SKIPPED=0

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${GREEN}✓${NC} $message"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Expected: '$expected'"
        echo -e "    Actual:   '$actual'"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if [[ "$not_expected" != "$actual" ]]; then
        echo -e "  ${GREEN}✓${NC} $message"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Should not be: '$not_expected'"
        echo -e "    Actual:        '$actual'"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if eval "$condition"; then
        echo -e "  ${GREEN}✓${NC} $message"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Condition: '$condition' is false"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if ! eval "$condition"; then
        echo -e "  ${GREEN}✓${NC} $message"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Condition: '$condition' is true"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $message: $file"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message: $file"
        echo -e "    File does not exist"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if [[ -d "$dir" ]]; then
        echo -e "  ${GREEN}✓${NC} $message: $dir"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message: $dir"
        echo -e "    Directory does not exist"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if [[ ! -f "$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $message: $file"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message: $file"
        echo -e "    File exists but shouldn't"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    FILE_TOTAL=$((FILE_TOTAL + 1))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "  ${GREEN}✓${NC} $message"
        FILE_PASSED=$((FILE_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    String: '$haystack'"
        echo -e "    Should contain: '$needle'"
        FILE_FAILED=$((FILE_FAILED + 1))
        return 1
    fi
}

# Test setup and teardown
setup_test_env() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d -t cleanrush_test_XXXXXX)
    export TEST_DIR
    
    # Create test desktop directory
    TEST_DESKTOP="$TEST_DIR/Desktop"
    mkdir -p "$TEST_DESKTOP"
    
    # Save original HOME and set test HOME
    ORIGINAL_HOME="$HOME"
    export ORIGINAL_HOME
    export HOME="$TEST_DIR"
    
    echo -e "${CYAN}Test environment created: $TEST_DIR${NC}"
}

teardown_test_env() {
    # Restore original HOME
    if [[ -n "$ORIGINAL_HOME" ]]; then
        export HOME="$ORIGINAL_HOME"
    fi
    
    # Clean up test directory
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
        echo -e "${CYAN}Test environment cleaned up${NC}"
    fi
}

# Create test files and directories
create_test_file() {
    local filename="$1"
    local content="${2:-Test content}"
    local dir="${3:-$TEST_DESKTOP}"
    
    echo "$content" > "$dir/$filename"
}

create_test_files() {
    local count="${1:-5}"
    local prefix="${2:-testfile}"
    local dir="${3:-$TEST_DESKTOP}"
    
    for i in $(seq 1 $count); do
        create_test_file "${prefix}_${i}.txt" "Content of file $i" "$dir"
    done
}

# Skip test function
skip_test() {
    local reason="${1:-No reason provided}"
    echo -e "  ${YELLOW}⊘ SKIPPED:${NC} $reason"
    FILE_SKIPPED=$((FILE_SKIPPED + 1))
    FILE_TOTAL=$((FILE_TOTAL + 1))
}

# Mock functions for testing
mock_user_input() {
    local inputs=("$@")
    MOCK_INPUT_INDEX=0
    
    get_mock_input() {
        if [[ $MOCK_INPUT_INDEX -lt ${#inputs[@]} ]]; then
            echo "${inputs[$MOCK_INPUT_INDEX]}"
            MOCK_INPUT_INDEX=$((MOCK_INPUT_INDEX + 1))
        else
            echo ""
        fi
    }
}

# Run a test group
test_group() {
    local group_name="$1"
    echo -e "\n${CYAN}$group_name${NC}"
}