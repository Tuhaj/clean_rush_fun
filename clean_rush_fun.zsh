#!/bin/zsh

# CleanRush - Gamified Desktop File Organizer
# Main entry point script

# Get script directory and set up paths
SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
export SCRIPT_PATH="$0"

# Load all modules
source "$SCRIPT_DIR/lib/config.zsh"
source "$SCRIPT_DIR/lib/ui.zsh"
source "$SCRIPT_DIR/lib/gamification.zsh"
source "$SCRIPT_DIR/lib/file_operations.zsh"
source "$SCRIPT_DIR/lib/setup.zsh"

# Initialize the application
main() {
    # Initialize configuration and detect OS
    init_config_paths
    detect_os
    
    # Load stats and initialize gamification
    load_stats
    init_gamification
    
    # Check if first-time setup is needed
    if ! load_shortcuts_and_exclusions; then
        first_time_setup
        reload_configuration
    fi
    
    # Start logging and display welcome
    start_log_session
    display_welcome "$TOTAL_SORTS" "$TOTAL_POINTS" "$TOTAL_TIME"
    
    # Run the main game loop
    run_game_loop
    
    # Display final stats and save
    display_session_stats "$SESSION_START_TIME" "$SESSION_SORTS" "$SESSION_POINTS"
    display_total_stats "$SESSION_START_TIME" "$TOTAL_SESSIONS" "$TOTAL_SORTS" "$SESSION_SORTS" "$TOTAL_POINTS" "$SESSION_POINTS" "$TOTAL_TIME" ACHIEVEMENTS
    save_stats "$SESSION_START_TIME" "$SESSION_SORTS" "$SESSION_POINTS"
    end_log_session
}

# Main game loop
run_game_loop() {
    local go_mode=false
    
    # Get all items in source directory
    local items=()
    while IFS= read -r item; do
        [[ -n "$item" ]] && items+=("$item")
    done < <(get_source_items)
    
    for item in "${items[@]}"; do
        local basename=$(basename "$item")
        
        # Skip excluded items
        if is_excluded "$basename"; then
            log_action "excluded" "$basename" ""
            continue
        fi

        # Handle Go Mode auto-sorting
        if $go_mode; then
            if move_file "$item" "Other"; then
                award_points "go_mode"
                track_sort
                display_action_result "go_mode_auto" "$basename" "Other" "$LAST_POINTS_AWARDED"
                log_action "go_mode_auto" "$basename" "Other"
                check_achievements
            fi
            continue
        fi

        # Display file options and get user input
        display_file_options "$basename" "$SESSION_POINTS" "$SESSION_SORTS" ASSIGNED_KEYS
        local answer=$(get_single_char_input)
        local lower_answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

        # Handle Go Mode activation
        if [[ $lower_answer == "g" ]]; then
            go_mode=true
            if move_file "$item" "Other"; then
                award_points "go_mode"
                track_sort
                display_action_result "go_mode" "$basename" "Other" "$LAST_POINTS_AWARDED"
                log_action "go_mode" "$basename" "Other"
                check_achievements
            fi
            continue
        fi

        # Handle delete action
        if [[ $lower_answer == "d" ]]; then
            delete_file "$item"
            local delete_result=$?
            case $delete_result in
                0)
                    award_points "delete"
                    track_sort
                    display_action_result "deleted" "$basename" "" "$LAST_POINTS_AWARDED"
                    log_action "deleted" "$basename" ""
                    check_achievements
                    ;;
                2)
                    display_action_result "error" "Delete operation not supported on this OS" "" ""
                    ;;
                *)
                    display_action_result "error" "Failed to delete $basename" "" ""
                    ;;
            esac
            continue
        fi

        # Handle skip action
        if [[ $lower_answer == "s" ]]; then
            display_action_result "skipped" "$basename" "" ""
            log_action "skipped" "$basename" ""
            continue
        fi

        # Handle new folder creation
        if [[ $lower_answer == "n" ]]; then
            local new_folder_result=$(add_new_folder_interactive ASSIGNED_KEYS)
            if [[ $? -eq 0 ]]; then
                award_points "new_folder"
                local new_key=$(echo "$new_folder_result" | cut -d: -f1)
                local new_folder=$(echo "$new_folder_result" | cut -d: -f2)
                display_action_result "new_folder" "$new_key" "$new_folder" "$LAST_POINTS_AWARDED"
                log_action "new_folder" "$new_key" "$new_folder"
                save_stats "$SESSION_START_TIME" "$SESSION_SORTS" "$SESSION_POINTS"
                exec "$SCRIPT_PATH"
            fi
            continue
        fi

        # Handle folder shortcuts
        local target_folder
        target_folder=$(eval "echo \${ASSIGNED_KEYS[$lower_answer]}" 2>/dev/null)
        if [[ -n "$target_folder" ]]; then
            if move_file "$item" "$target_folder"; then
                award_points "move"
                track_sort
                display_action_result "moved" "$basename" "$target_folder" "$LAST_POINTS_AWARDED"
                log_action "moved" "$basename" "$target_folder"
                check_achievements
            fi
            continue
        fi

        # Default action (skip)
        display_action_result "skipped" "$basename" "" ""
        log_action "default_skip" "$basename" ""
    done
}

# Entry point
main
