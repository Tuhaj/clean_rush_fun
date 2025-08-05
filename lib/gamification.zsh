#!/bin/zsh

# Gamification Module for CleanRush
# Handles points system, achievements, and progress tracking

# Points system constants
export POINTS_MOVE=10
export POINTS_DELETE=5
export POINTS_GO_MODE=1
export POINTS_NEW_FOLDER=20

# Initialize gamification variables
init_gamification() {
    export SESSION_START_TIME=$(date +%s)
    export SESSION_SORTS=0
    export SESSION_POINTS=0
    
    # ACHIEVEMENTS array is initialized in config.zsh load_stats()
    if [[ -z "${ACHIEVEMENTS}" ]]; then
        declare -gA ACHIEVEMENTS
    fi
}

# Award points for an action
award_points() {
    local action=$1
    local points=0
    
    case "$action" in
        "move")
            points=$POINTS_MOVE
            ;;
        "delete")
            points=$POINTS_DELETE
            ;;
        "go_mode")
            points=$POINTS_GO_MODE
            ;;
        "new_folder")
            points=$POINTS_NEW_FOLDER
            ;;
    esac
    
    # Update global SESSION_POINTS
    export SESSION_POINTS=$((SESSION_POINTS + points))
    export LAST_POINTS_AWARDED=$points
    return 0
}

# Track a sorted item
track_sort() {
    export SESSION_SORTS=$((SESSION_SORTS + 1))
}

# Check and unlock achievements
check_achievements() {
    local new_total=$((TOTAL_SORTS + SESSION_SORTS))
    local achievement_thresholds=(8 16 32 64 128 256 512 1024)
    
    for threshold in "${achievement_thresholds[@]}"; do
        if [[ $new_total -ge $threshold && $TOTAL_SORTS -lt $threshold ]]; then
            if [[ -z "${ACHIEVEMENTS[$threshold]}" ]]; then
                # Source UI module to use display function
                source "$SCRIPT_DIR/lib/ui.zsh"
                display_achievement "$threshold"
                ACHIEVEMENTS[$threshold]=$(date +%s)
                sleep 1.5
                return 0  # Achievement unlocked
            fi
        fi
    done
    return 1  # No achievement unlocked
}

# Get current session statistics
get_session_stats() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    local minutes=$((session_time / 60))
    local seconds=$((session_time % 60))
    
    echo "time:$session_time minutes:$minutes seconds:$seconds sorts:$SESSION_SORTS points:$SESSION_POINTS"
}

# Get total statistics
get_total_stats() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    local new_total_time=$((TOTAL_TIME + session_time))
    local total_hours=$((new_total_time / 3600))
    local total_minutes=$(((new_total_time % 3600) / 60))
    local new_total_sessions=$((TOTAL_SESSIONS + 1))
    local new_total_sorts=$((TOTAL_SORTS + SESSION_SORTS))
    local new_total_points=$((TOTAL_POINTS + SESSION_POINTS))
    
    echo "sessions:$new_total_sessions sorts:$new_total_sorts points:$new_total_points time:$new_total_time hours:$total_hours minutes:$total_minutes"
}

# Calculate average time per item for current session
get_session_average() {
    if [[ $SESSION_SORTS -gt 0 ]]; then
        local session_time=$(($(date +%s) - SESSION_START_TIME))
        local avg_time=$((session_time / SESSION_SORTS))
        echo $avg_time
    else
        echo 0
    fi
}

# Get formatted session duration
get_session_duration() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    local minutes=$((session_time / 60))
    local seconds=$((session_time % 60))
    echo "${minutes}m ${seconds}s"
}

# Get formatted total time
get_formatted_total_time() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    local new_total_time=$((TOTAL_TIME + session_time))
    local total_hours=$((new_total_time / 3600))
    local total_minutes=$(((new_total_time % 3600) / 60))
    echo "${total_hours}h ${total_minutes}m"
}

# Check if this is the first session
is_first_session() {
    if [[ $TOTAL_SORTS -eq 0 ]]; then
        return 0  # First session
    else
        return 1  # Not first session
    fi
}

# Get achievement count
get_achievement_count() {
    echo ${#ACHIEVEMENTS[@]}
}

# Get all achievements as formatted string
get_achievements_list() {
    local achievements_list=""
    for achievement in ${(k)ACHIEVEMENTS}; do
        if [[ -z "$achievements_list" ]]; then
            achievements_list="$achievement"
        else
            achievements_list="$achievements_list,$achievement"
        fi
    done
    echo "$achievements_list"
}

# Calculate points per minute for current session
get_points_per_minute() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    if [[ $session_time -gt 0 ]]; then
        local minutes=$((session_time / 60))
        if [[ $minutes -gt 0 ]]; then
            local ppm=$((SESSION_POINTS / minutes))
            echo $ppm
        else
            echo $SESSION_POINTS
        fi
    else
        echo 0
    fi
}