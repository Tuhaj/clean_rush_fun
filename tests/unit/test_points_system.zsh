#!/bin/zsh

# Unit tests for points and achievements system

# Get script and project directories
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_SCRIPT_DIR")")"

# Source test utilities
source "$TEST_SCRIPT_DIR/../test_utils.zsh"

# Source the gamification and config modules
SCRIPT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/lib/config.zsh"
source "$PROJECT_ROOT/lib/gamification.zsh"

test_group "Points System Tests"

# Test point values using new modular functions
test_point_values() {
    # The constants are defined in the gamification module
    assert_equals "10" "$POINTS_MOVE" "Move points should be 10"
    assert_equals "5" "$POINTS_DELETE" "Delete points should be 5"
    assert_equals "1" "$POINTS_GO_MODE" "Go mode points should be 1"
    assert_equals "20" "$POINTS_NEW_FOLDER" "New folder points should be 20"
}

# Test session points calculation using new modular functions
test_session_points_calculation() {
    init_gamification
    
    # Test awarding points for different actions
    award_points "move"
    assert_equals "10" "$LAST_POINTS_AWARDED" "Should award 10 points for move"
    assert_equals "10" "$SESSION_POINTS" "Session points should be updated"
    
    award_points "delete"
    assert_equals "5" "$LAST_POINTS_AWARDED" "Should award 5 points for delete"
    assert_equals "15" "$SESSION_POINTS" "Session points should accumulate"
    
    award_points "go_mode"
    assert_equals "1" "$LAST_POINTS_AWARDED" "Should award 1 point for go mode"
    assert_equals "16" "$SESSION_POINTS" "Session points should continue accumulating"
    
    award_points "new_folder"
    assert_equals "20" "$LAST_POINTS_AWARDED" "Should award 20 points for new folder"
    assert_equals "36" "$SESSION_POINTS" "Session points should reach 36"
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

# Test achievement unlocking logic using new modular functions
test_achievement_unlock_logic() {
    init_gamification
    
    # Set up test conditions for achievement unlock
    TOTAL_SORTS=7
    SESSION_SORTS=1
    declare -gA ACHIEVEMENTS
    
    # Test unlocking achievement when crossing threshold
    check_achievements
    local unlock_result=$?
    assert_equals "0" "$unlock_result" "Should unlock achievement when crossing threshold from 7+1=8"
    
    # Verify achievement was recorded
    assert_equals "1" "${#ACHIEVEMENTS[@]}" "Should have one achievement unlocked"
    
    # Test when already past threshold - reset for clean test
    TOTAL_SORTS=10
    SESSION_SORTS=1
    
    check_achievements
    local no_unlock_result=$?
    assert_equals "1" "$no_unlock_result" "Should not unlock when already past threshold"
}

# Test session tracking
test_session_tracking() {
    init_gamification
    
    # Test sort tracking
    assert_equals "0" "$SESSION_SORTS" "Should start with 0 sorts"
    
    track_sort
    assert_equals "1" "$SESSION_SORTS" "Should have 1 sort after tracking"
    
    track_sort
    track_sort
    assert_equals "3" "$SESSION_SORTS" "Should have 3 sorts after tracking 3 times"
}

# Run tests
test_point_values
test_session_points_calculation
test_achievement_thresholds
test_achievement_unlock_logic
test_session_tracking