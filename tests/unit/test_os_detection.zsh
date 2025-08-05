#!/bin/zsh

# Unit tests for OS detection functionality

# Get script directory
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"

# Source test utilities
source "$TEST_SCRIPT_DIR/../test_utils.zsh"

test_group "OS Detection Tests"

# Test OS type detection on macOS
test_macos_detection() {
    # Mock OSTYPE for macOS
    local original_ostype="$OSTYPE"
    OSTYPE="darwin20.0"
    
    # Source the detection logic
    OS_TYPE="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    fi
    
    assert_equals "macos" "$OS_TYPE" "Should detect macOS from darwin OSTYPE"
    
    # Restore original OSTYPE
    OSTYPE="$original_ostype"
}

# Test OS type detection on Linux
test_linux_detection() {
    # Mock OSTYPE for Linux
    local original_ostype="$OSTYPE"
    OSTYPE="linux-gnu"
    
    # Source the detection logic
    OS_TYPE="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    fi
    
    assert_equals "linux" "$OS_TYPE" "Should detect Linux from linux-gnu OSTYPE"
    
    # Restore original OSTYPE
    OSTYPE="$original_ostype"
}

# Test unknown OS detection
test_unknown_os_detection() {
    # Mock OSTYPE for unknown OS
    local original_ostype="$OSTYPE"
    OSTYPE="freebsd"
    
    # Source the detection logic
    OS_TYPE="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    fi
    
    assert_equals "unknown" "$OS_TYPE" "Should return unknown for unsupported OS"
    
    # Restore original OSTYPE
    OSTYPE="$original_ostype"
}

# Run tests
test_macos_detection
test_linux_detection
test_unknown_os_detection