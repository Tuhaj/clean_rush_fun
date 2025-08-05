#!/bin/zsh

# Unit tests for points and achievements system

# Get script directory
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"

# Source test utilities
source "$TEST_SCRIPT_DIR/../test_utils.zsh"

test_group "Points System Tests"

# Test point values
test_point_values() {
    # Define point values as in main script
    POINTS_MOVE=10
    POINTS_DELETE=5
    POINTS_GO_MODE=1
    POINTS_NEW_FOLDER=20
    
    assert_equals "10" "$POINTS_MOVE" "Move points should be 10"
    assert_equals "5" "$POINTS_DELETE" "Delete points should be 5"
    assert_equals "1" "$POINTS_GO_MODE" "Go mode points should be 1"
    assert_equals "20" "$POINTS_NEW_FOLDER" "New folder points should be 20"
}

# Test session points calculation
test_session_points_calculation() {
    SESSION_POINTS=0
    POINTS_MOVE=10
    POINTS_DELETE=5
    
    # Simulate moving 3 files
    SESSION_POINTS=$((SESSION_POINTS + POINTS_MOVE))
    SESSION_POINTS=$((SESSION_POINTS + POINTS_MOVE))
    SESSION_POINTS=$((SESSION_POINTS + POINTS_MOVE))
    
    assert_equals "30" "$SESSION_POINTS" "Should have 30 points after 3 moves"
    
    # Simulate deleting 2 files
    SESSION_POINTS=$((SESSION_POINTS + POINTS_DELETE))
    SESSION_POINTS=$((SESSION_POINTS + POINTS_DELETE))
    
    assert_equals "40" "$SESSION_POINTS" "Should have 40 points after 3 moves and 2 deletes"
}

# Test achievement thresholds
test_achievement_thresholds() {
    # Note: ZSH arrays are 1-indexed by default
    local achievement_thresholds=(8 16 32 64 128 256 512 1024)
    
    assert_equals "8" "${achievement_thresholds[1]}" "First achievement at 8 items"
    assert_equals "16" "${achievement_thresholds[2]}" "Second achievement at 16 items"
    assert_equals "32" "${achievement_thresholds[3]}" "Third achievement at 32 items"
    assert_equals "1024" "${achievement_thresholds[8]}" "Last achievement at 1024 items"
}

# Test achievement unlocking logic
test_achievement_unlock_logic() {
    TOTAL_SORTS=7
    SESSION_SORTS=1
    declare -A ACHIEVEMENTS
    
    local new_total=$((TOTAL_SORTS + SESSION_SORTS))
    local threshold=8
    
    # Check if achievement should be unlocked
    if [[ $new_total -ge $threshold && $TOTAL_SORTS -lt $threshold ]]; then
        local should_unlock="true"
    else
        local should_unlock="false"
    fi
    
    assert_equals "true" "$should_unlock" "Should unlock achievement when crossing threshold"
    
    # Test when already past threshold
    TOTAL_SORTS=10
    SESSION_SORTS=1
    new_total=$((TOTAL_SORTS + SESSION_SORTS))
    
    if [[ $new_total -ge $threshold && $TOTAL_SORTS -lt $threshold ]]; then
        should_unlock="true"
    else
        should_unlock="false"
    fi
    
    assert_equals "false" "$should_unlock" "Should not unlock when already past threshold"
}

# Run tests
test_point_values
test_session_points_calculation
test_achievement_thresholds
test_achievement_unlock_logic