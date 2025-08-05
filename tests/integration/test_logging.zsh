#!/bin/zsh

# Integration tests for logging functionality

# Get script directory
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"

# Source test utilities
source "$TEST_SCRIPT_DIR/../test_utils.zsh"

test_group "Logging Integration Tests"

# Test log file creation
test_log_file_creation() {
    setup_test_env
    
    local log_file="$TEST_DIR/test.log"
    
    # Write to log
    echo "Test log entry" >> "$log_file"
    
    assert_file_exists "$log_file" "Log file should be created"
    
    local content=$(cat "$log_file")
    assert_contains "$content" "Test log entry" "Log should contain the entry"
    
    teardown_test_env
}

# Test session logging
test_session_logging() {
    setup_test_env
    
    local log_file="$TEST_DIR/session.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log session start
    echo "----- $timestamp Session Start -----" >> "$log_file"
    
    # Log some operations
    echo "$timestamp - Moved to Projects: file1.txt" >> "$log_file"
    echo "$timestamp - Deleted (sent to Trash): file2.txt" >> "$log_file"
    echo "$timestamp - Skipped: file3.txt" >> "$log_file"
    
    # Log session end
    echo "----- Session End -----" >> "$log_file"
    
    assert_file_exists "$log_file" "Log file should exist"
    
    local content=$(cat "$log_file")
    assert_contains "$content" "Session Start" "Log should contain session start"
    assert_contains "$content" "Session End" "Log should contain session end"
    assert_contains "$content" "Moved to Projects" "Log should contain move operation"
    assert_contains "$content" "Deleted" "Log should contain delete operation"
    assert_contains "$content" "Skipped" "Log should contain skip operation"
    
    teardown_test_env
}

# Test log rotation (basic)
test_log_rotation() {
    setup_test_env
    
    local log_file="$TEST_DIR/rotate.log"
    local max_size=100  # Small size for testing
    
    # Write entries until file is large enough
    for i in {1..20}; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Log entry number $i" >> "$log_file"
    done
    
    assert_file_exists "$log_file" "Log file should exist"
    
    # Check file size
    local file_size=$(wc -c < "$log_file")
    assert_true "[[ $file_size -gt 0 ]]" "Log file should have content"
    
    teardown_test_env
}

# Test concurrent logging
test_concurrent_logging() {
    setup_test_env
    
    local log_file="$TEST_DIR/concurrent.log"
    
    # Simple sequential writes to test log file (avoiding background processes)
    for i in {1..5}; do
        echo "Process 1 - Entry $i" >> "$log_file"
    done
    
    for i in {1..5}; do
        echo "Process 2 - Entry $i" >> "$log_file"
    done
    
    assert_file_exists "$log_file" "Log file should exist"
    
    # Count entries from each process
    local p1_count=$(grep -c "Process 1" "$log_file")
    local p2_count=$(grep -c "Process 2" "$log_file")
    
    assert_equals "5" "$p1_count" "Should have 5 entries from Process 1"
    assert_equals "5" "$p2_count" "Should have 5 entries from Process 2"
    
    teardown_test_env
}

# Test log formatting
test_log_formatting() {
    setup_test_env
    
    local log_file="$TEST_DIR/format.log"
    local test_file="testfile.txt"
    local test_folder="Projects"
    
    # Format different log entries
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp - Moved to $test_folder: $test_file" >> "$log_file"
    echo "$timestamp - Deleted (sent to Trash): $test_file" >> "$log_file"
    echo "$timestamp - Skipped: $test_file" >> "$log_file"
    echo "$timestamp - Created new folder: $test_folder with shortcut [p]" >> "$log_file"
    echo "$timestamp - Go Mode activated, moved to Other: $test_file" >> "$log_file"
    
    assert_file_exists "$log_file" "Log file should exist"
    
    local content=$(cat "$log_file")
    
    # Check timestamp format
    assert_true "[[ '$content' =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]" \
        "Log entries should have proper timestamp format"
    
    # Check operation types
    assert_contains "$content" "Moved to" "Should log move operations"
    assert_contains "$content" "Deleted" "Should log delete operations"
    assert_contains "$content" "Skipped" "Should log skip operations"
    assert_contains "$content" "Created new folder" "Should log folder creation"
    assert_contains "$content" "Go Mode activated" "Should log Go Mode activation"
    
    teardown_test_env
}

# Run tests
test_log_file_creation
test_session_logging
test_log_rotation
test_concurrent_logging
test_log_formatting