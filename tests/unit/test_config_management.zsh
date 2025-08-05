#!/bin/zsh

# Unit tests for configuration management

# Get script directory
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"

# Source test utilities
source "$TEST_SCRIPT_DIR/../test_utils.zsh"

test_group "Configuration Management Tests"

# Test config file parsing
test_config_file_parsing() {
    setup_test_env
    
    # Create a test config file
    local config_file="$TEST_DIR/test_excludes.conf"
    cat > "$config_file" << EOF
o:Other
p:Projects
a:Archive
t:Temp
EOF
    
    # Parse config file
    declare -A ASSIGNED_KEYS
    while IFS=: read -r key folder; do
        key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
        ASSIGNED_KEYS[$key]="$folder"
    done < "$config_file"
    
    assert_equals "Other" "${ASSIGNED_KEYS[o]}" "Should parse 'o' key for Other folder"
    assert_equals "Projects" "${ASSIGNED_KEYS[p]}" "Should parse 'p' key for Projects folder"
    assert_equals "Archive" "${ASSIGNED_KEYS[a]}" "Should parse 'a' key for Archive folder"
    assert_equals "Temp" "${ASSIGNED_KEYS[t]}" "Should parse 't' key for Temp folder"
    
    teardown_test_env
}

# Test stats file parsing
test_stats_file_parsing() {
    setup_test_env
    
    # Create a test stats file
    local stats_file="$TEST_DIR/test_stats.conf"
    cat > "$stats_file" << EOF
total_sessions:5
total_sorts:42
total_points:500
total_time:3600
achievement_8:1234567890
achievement_16:1234567900
EOF
    
    # Parse stats file
    TOTAL_SESSIONS=0
    TOTAL_SORTS=0
    TOTAL_POINTS=0
    TOTAL_TIME=0
    declare -A ACHIEVEMENTS
    
    while IFS=: read -r key value; do
        case "$key" in
            total_sessions) TOTAL_SESSIONS=$value ;;
            total_sorts) TOTAL_SORTS=$value ;;
            total_points) TOTAL_POINTS=$value ;;
            total_time) TOTAL_TIME=$value ;;
            achievement_*) ACHIEVEMENTS[${key#achievement_}]=$value ;;
        esac
    done < "$stats_file"
    
    assert_equals "5" "$TOTAL_SESSIONS" "Should parse total sessions"
    assert_equals "42" "$TOTAL_SORTS" "Should parse total sorts"
    assert_equals "500" "$TOTAL_POINTS" "Should parse total points"
    assert_equals "3600" "$TOTAL_TIME" "Should parse total time"
    assert_equals "1234567890" "${ACHIEVEMENTS[8]}" "Should parse achievement 8"
    assert_equals "1234567900" "${ACHIEVEMENTS[16]}" "Should parse achievement 16"
    
    teardown_test_env
}

# Test config file creation
test_config_file_creation() {
    setup_test_env
    
    local config_file="$TEST_DIR/new_config.conf"
    local test_key="x"
    local test_folder="TestFolder"
    
    # Write to config file
    echo "$test_key:$test_folder" >> "$config_file"
    
    assert_file_exists "$config_file" "Config file should be created"
    
    # Read back the content
    local content=$(cat "$config_file")
    assert_contains "$content" "x:TestFolder" "Config should contain the new entry"
    
    teardown_test_env
}

# Test stats file saving
test_stats_file_saving() {
    setup_test_env
    
    local stats_file="$TEST_DIR/save_stats.conf"
    
    # Set test values
    local test_sessions=3
    local test_sorts=25
    local test_points=300
    local test_time=1800
    
    # Save stats
    {
        echo "total_sessions:$test_sessions"
        echo "total_sorts:$test_sorts"
        echo "total_points:$test_points"
        echo "total_time:$test_time"
    } > "$stats_file"
    
    assert_file_exists "$stats_file" "Stats file should be created"
    
    # Verify content
    local content=$(cat "$stats_file")
    assert_contains "$content" "total_sessions:3" "Should save total sessions"
    assert_contains "$content" "total_sorts:25" "Should save total sorts"
    assert_contains "$content" "total_points:300" "Should save total points"
    assert_contains "$content" "total_time:1800" "Should save total time"
    
    teardown_test_env
}

# Run tests
test_config_file_parsing
test_stats_file_parsing
test_config_file_creation
test_stats_file_saving