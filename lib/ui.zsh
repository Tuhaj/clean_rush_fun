#!/bin/zsh

# UI and Display Module for CleanRush
# Contains color definitions, display functions, and user interface utilities

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Display welcome message with stats
display_welcome() {
    local total_sorts=$1
    local total_points=$2
    local total_time=$3
    
    echo -e "\n${BOLD}${CYAN}🎮 CLEANRUSH 🎮${NC}"
    if [[ $total_sorts -gt 0 ]]; then
        local total_hours=$((total_time / 3600))
        local total_minutes=$(((total_time % 3600) / 60))
        echo -e "${YELLOW}Welcome back! Total sorted: $total_sorts items | Points: $total_points | Time: ${total_hours}h ${total_minutes}m${NC}"
    else
        echo -e "${GREEN}Welcome to your first session!${NC}"
    fi
    echo ""
}

# Display session statistics
display_session_stats() {
    local session_start_time=$1
    local session_sorts=$2
    local session_points=$3
    
    local session_time=$(($(date +%s) - session_start_time))
    local minutes=$((session_time / 60))
    local seconds=$((session_time % 60))
    
    echo -e "\n${BOLD}${CYAN}=== SESSION STATS ===${NC}"
    echo -e "${GREEN}⏱️  Time: ${minutes}m ${seconds}s${NC}"
    echo -e "${YELLOW}📦 Items sorted: $session_sorts${NC}"
    echo -e "${MAGENTA}⭐ Points earned: $session_points${NC}"
    
    if [[ $session_sorts -gt 0 ]]; then
        local avg_time=$((session_time / session_sorts))
        echo -e "${BLUE}⚡ Average: ${avg_time}s per item${NC}"
    fi
}

# Display lifetime statistics
display_total_stats() {
    local session_start_time=$1
    local total_sessions=$2
    local total_sorts=$3
    local session_sorts=$4
    local total_points=$5
    local session_points=$6
    local total_time=$7
    local achievements_var_name=$8
    
    local session_time=$(($(date +%s) - session_start_time))
    local new_total_time=$((total_time + session_time))
    local total_hours=$((new_total_time / 3600))
    local total_minutes=$(((new_total_time % 3600) / 60))
    
    echo -e "\n${BOLD}${CYAN}=== LIFETIME STATS ===${NC}"
    echo -e "${GREEN}🎮 Total sessions: $((total_sessions + 1))${NC}"
    echo -e "${YELLOW}📊 Total items sorted: $((total_sorts + session_sorts))${NC}"
    echo -e "${MAGENTA}💎 Total points: $((total_points + session_points))${NC}"
    echo -e "${BLUE}⏱️  Total time: ${total_hours}h ${total_minutes}m${NC}"
    
    # Display achievements - get the size of the achievements array
    local achievements_size
    achievements_size=$(eval "echo \${#${achievements_var_name}[@]}" 2>/dev/null)
    
    if [[ $achievements_size -gt 0 ]]; then
        echo -e "\n${BOLD}${YELLOW}🏆 ACHIEVEMENTS:${NC}"
        
        # Get all keys from the achievements array
        local all_achievement_keys
        eval "all_achievement_keys=(\${(k)${achievements_var_name}})" >/dev/null 2>&1
        
        for achievement in ${all_achievement_keys}; do
            echo -e "  ${CYAN}✓ Sorted $achievement items${NC}"
        done
    fi
}

# Display file sorting options
display_file_options() {
    local basename=$1
    local session_points=$2
    local session_sorts=$3
    local assigned_keys_var_name=$4
    
    echo ""
    echo -e "${YELLOW}Move $basename to:${NC} ${CYAN}[Score: $session_points | Sorted: $session_sorts]${NC}"
    
    # Get all keys from the associative array
    local all_keys
    eval "all_keys=(\${(k)${assigned_keys_var_name}})" >/dev/null 2>&1
    
    for key in ${all_keys}; do
        local folder_name
        folder_name=$(eval "echo \${${assigned_keys_var_name}[$key]}" 2>/dev/null)
        echo "[$key] $folder_name"
    done
    echo "[d] Delete  [s] Skip  [g] Go Mode  [n] New"
    echo -n "Your choice: "
}

# Get single character input without pressing Enter
get_single_char_input() {
    local answer
    # Simple and reliable approach - just use regular read
    read answer
    # Take only the first character
    answer=$(echo "$answer" | cut -c1)
    echo "$answer"
}

# Display action result messages
display_action_result() {
    local action=$1
    local basename=$2
    local target=$3
    local points=$4
    
    case "$action" in
        "moved")
            echo -e "${GREEN}Moved $basename to $target${NC} ${YELLOW}+${points} points!${NC}"
            ;;
        "deleted")
            echo -e "${RED}Deleted $basename (sent to Trash)${NC} ${YELLOW}+${points} points!${NC}"
            ;;
        "skipped")
            echo -e "${BLUE}Skipped: $basename${NC}"
            ;;
        "go_mode")
            echo -e "${MAGENTA}Go Mode activated!${NC} ${GREEN}Moved $basename to $target${NC} ${YELLOW}+${points} points!${NC}"
            ;;
        "go_mode_auto")
            echo -e "${MAGENTA}[Go Mode]${NC} ${GREEN}Auto-moved $basename to $target${NC} ${YELLOW}+${points} points!${NC}"
            ;;
        "new_folder")
            echo -e "${GREEN}Created new folder: $target with shortcut [$basename]. ${YELLOW}+${points} points!${NC} Restarting script..."
            ;;
        "error")
            echo -e "${RED}$basename${NC}"
            ;;
    esac
}

# Display achievement notification
display_achievement() {
    local threshold=$1
    echo -e "\n${BOLD}${YELLOW}🏆 ACHIEVEMENT UNLOCKED! ${NC}${CYAN}Sorted $threshold items!${NC}"
}