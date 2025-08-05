#!/bin/zsh

# Configuration Management Module for CleanRush
# Handles loading/saving configuration files, stats, and exclusions

# Initialize configuration paths
init_config_paths() {
    export SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
    export CONFIG_FILE="$SCRIPT_DIR/excludes.conf"
    export STATS_FILE="$SCRIPT_DIR/stats.conf"
    export LOG_FILE="$SCRIPT_DIR/move_desktop_items.log"
    export SOURCE_DIR="$HOME/Desktop"
    export BASE_DIR="$HOME/Desktop"
}

# Load stats from stats.conf file
load_stats() {
    local -A stats
    
    # Initialize default values
    stats[total_sessions]=0
    stats[total_sorts]=0
    stats[total_points]=0
    stats[total_time]=0
    
    if [[ -f "$STATS_FILE" ]]; then
        while IFS=: read -r key value; do
            case "$key" in
                total_sessions|total_sorts|total_points|total_time)
                    stats[$key]=$value
                    ;;
                achievement_*)
                    # Handle achievements separately
                    stats[$key]=$value
                    ;;
            esac
        done < "$STATS_FILE"
    fi
    
    # Export stats as individual variables
    export TOTAL_SESSIONS=${stats[total_sessions]}
    export TOTAL_SORTS=${stats[total_sorts]}
    export TOTAL_POINTS=${stats[total_points]}
    export TOTAL_TIME=${stats[total_time]}
    
    # Load achievements into associative array
    declare -gA ACHIEVEMENTS
    for key in ${(k)stats}; do
        if [[ $key == achievement_* ]]; then
            ACHIEVEMENTS[${key#achievement_}]=${stats[$key]}
        fi
    done
}

# Save current stats to stats.conf file
save_stats() {
    local session_start_time=$1
    local session_sorts=$2
    local session_points=$3
    
    local session_time=$(($(date +%s) - session_start_time))
    {
        echo "total_sessions:$((TOTAL_SESSIONS + 1))"
        echo "total_sorts:$((TOTAL_SORTS + session_sorts))"
        echo "total_points:$((TOTAL_POINTS + session_points))"
        echo "total_time:$((TOTAL_TIME + session_time))"
        for key in ${(k)ACHIEVEMENTS}; do
            echo "achievement_$key:${ACHIEVEMENTS[$key]}"
        done
    } > "$STATS_FILE"
}

# Load shortcuts and exclusions from config file
load_shortcuts_and_exclusions() {
    declare -gA ASSIGNED_KEYS
    declare -ga EXCLUDES
    
    # Initialize default exclusions
    EXCLUDES=(".DS_Store" ".localized")
    
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS=: read -r key folder; do
            key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
            ASSIGNED_KEYS[$key]="$folder"
            EXCLUDES+=("$folder")
        done < "$CONFIG_FILE"
        return 0  # Config file exists
    else
        return 1  # Config file doesn't exist, need setup
    fi
}

# Reload configuration after setup
reload_configuration() {
    declare -gA ASSIGNED_KEYS
    declare -ga EXCLUDES
    
    # Reset arrays
    ASSIGNED_KEYS=()
    EXCLUDES=(".DS_Store" ".localized")
    
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS=: read -r key folder; do
            key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
            ASSIGNED_KEYS[$key]="$folder"
            EXCLUDES+=("$folder")
        done < "$CONFIG_FILE"
    fi
}

# Add new folder shortcut to config
add_folder_shortcut() {
    local key=$1
    local folder=$2
    
    echo "$key:$folder" >> "$CONFIG_FILE"
}

# Check if item should be excluded
is_excluded() {
    local basename=$1
    
    for exclude in "${EXCLUDES[@]}"; do
        if [[ "$basename" == "$exclude" ]]; then
            return 0  # Item is excluded
        fi
    done
    return 1  # Item is not excluded
}

# Initialize log session
start_log_session() {
    echo "----- $(date '+%Y-%m-%d %H:%M:%S') Session Start -----" >> "$LOG_FILE"
}

# End log session
end_log_session() {
    echo "----- Session End -----" >> "$LOG_FILE"
}

# Log action to file
log_action() {
    local action=$1
    local basename=$2
    local target=$3
    
    case "$action" in
        "moved")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Moved to $target: $basename" >> "$LOG_FILE"
            ;;
        "deleted")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Deleted (sent to Trash): $basename" >> "$LOG_FILE"
            ;;
        "skipped")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipped: $basename" >> "$LOG_FILE"
            ;;
        "excluded")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipped (excluded): $basename" >> "$LOG_FILE"
            ;;
        "go_mode")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Go Mode activated, moved to $target: $basename" >> "$LOG_FILE"
            ;;
        "go_mode_auto")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Auto-moved to $target (go mode): $basename" >> "$LOG_FILE"
            ;;
        "new_folder")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Created new folder: $target with shortcut [$basename]. Restarting script." >> "$LOG_FILE"
            ;;
        "default_skip")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipped (default): $basename" >> "$LOG_FILE"
            ;;
    esac
}