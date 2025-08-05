#!/bin/zsh

# Unit tests for configuration management

# Get script and project directories
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_SCRIPT_DIR")")"

# Source test utilities
source "$TEST_SCRIPT_DIR/../test_utils.zsh"

# Source the config module
SCRIPT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/lib/config.zsh"

test_group "Configuration Management Tests"

# Test config file parsing with new modular functions
test_config_file_parsing() {
    setup_test_env
    
    # Set up test config paths
    export CONFIG_FILE="$TEST_DIR/test_excludes.conf"
    
    # Create a test config file
    cat > "$CONFIG_FILE" << EOF
o:Other
p:Projects
a:Archive
t:Temp
EOF
    
    # Use the new modular function to load shortcuts
    load_shortcuts_and_exclusions
    
    assert_equals "Other" "${ASSIGNED_KEYS[o]}" "Should parse 'o' key for Other folder"
    assert_equals "Projects" "${ASSIGNED_KEYS[p]}" "Should parse 'p' key for Projects folder"
    assert_equals "Archive" "${ASSIGNED_KEYS[a]}" "Should parse 'a' key for Archive folder"
    assert_equals "Temp" "${ASSIGNED_KEYS[t]}" "Should parse 't' key for Temp folder"
    
    teardown_test_env
}

# Test stats file parsing with new modular functions
test_stats_file_parsing() {
    setup_test_env
    
    # Set up test stats file path
    export STATS_FILE="$TEST_DIR/test_stats.conf"
    
    # Create a test stats file
    cat > "$STATS_FILE" << EOF
total_sessions:5
total_sorts:42
total_points:500
total_time:3600
achievement_8:1234567890
achievement_16:1234567900
EOF
    
    # Use the new modular function to load stats
    load_stats
    
    assert_equals "5" "$TOTAL_SESSIONS" "Should parse total sessions"
    assert_equals "42" "$TOTAL_SORTS" "Should parse total sorts"
    assert_equals "500" "$TOTAL_POINTS" "Should parse total points"
    assert_equals "3600" "$TOTAL_TIME" "Should parse total time"
    assert_equals "1234567890" "${ACHIEVEMENTS[8]}" "Should parse achievement 8"
    assert_equals "1234567900" "${ACHIEVEMENTS[16]}" "Should parse achievement 16"
    
    teardown_test_env
}

# Test config file creation with new modular functions
test_config_file_creation() {
    setup_test_env
    
    export CONFIG_FILE="$TEST_DIR/new_config.conf"
    local test_key="x"
    local test_folder="TestFolder"
    
    # Use the new modular function to add folder shortcut
    add_folder_shortcut "$test_key" "$test_folder"
    
    assert_file_exists "$CONFIG_FILE" "Config file should be created"
    
    # Read back the content
    local content=$(cat "$CONFIG_FILE")
    assert_contains "$content" "x:TestFolder" "Config should contain the new entry"
    
    teardown_test_env
}

# Test stats file saving with new modular functions
test_stats_file_saving() {
    setup_test_env
    
    export STATS_FILE="$TEST_DIR/save_stats.conf"
    
    # Set test values in global variables (as the new function expects)
    TOTAL_SESSIONS=2  # Will be incremented by 1 in save_stats
    TOTAL_SORTS=20
    TOTAL_POINTS=250
    TOTAL_TIME=1500
    
    # Mock session values
    local session_start_time=$(($(date +%s) - 300))  # 5 minutes ago
    local session_sorts=5
    local session_points=50
    
    # Use the new modular function to save stats
    save_stats "$session_start_time" "$session_sorts" "$session_points"
    
    assert_file_exists "$STATS_FILE" "Stats file should be created"
    
    # Verify content
    local content=$(cat "$STATS_FILE")
    assert_contains "$content" "total_sessions:3" "Should save total sessions (incremented)"
    assert_contains "$content" "total_sorts:25" "Should save total sorts (original + session)"
    assert_contains "$content" "total_points:300" "Should save total points (original + session)"
    assert_contains "$content" "total_time:" "Should save total time entry"
    
    teardown_test_env
}

# Test exclusion checking
test_exclusion_checking() {
    setup_test_env
    
    # Set up excludes
    EXCLUDES=(".DS_Store" ".localized" "TestFolder")
    
    # Test excluded items
    is_excluded ".DS_Store"
    assert_equals "0" "$?" "Should exclude .DS_Store"
    
    is_excluded "TestFolder"
    assert_equals "0" "$?" "Should exclude TestFolder"
    
    # Test non-excluded items
    is_excluded "regularfile.txt"
    assert_equals "1" "$?" "Should not exclude regular file"
    
    teardown_test_env
}

# Run tests
test_config_file_parsing
test_stats_file_parsing
test_config_file_creation
test_stats_file_saving
test_exclusion_checking