#!/bin/zsh

SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
CONFIG_FILE="$SCRIPT_DIR/excludes.conf"
SOURCE_DIR="$HOME/Desktop"
BASE_DIR="$HOME/Desktop"
LOG_FILE="$SCRIPT_DIR/move_desktop_items.log"
STATS_FILE="$SCRIPT_DIR/stats.conf"
SCRIPT_PATH="$0"

# OS Detection
OS_TYPE="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Gamification variables
SESSION_START_TIME=$(date +%s)
SESSION_SORTS=0
SESSION_POINTS=0
TOTAL_SESSIONS=0
TOTAL_SORTS=0
TOTAL_POINTS=0
TOTAL_TIME=0
declare -A ACHIEVEMENTS

# Points system
POINTS_MOVE=10
POINTS_DELETE=5
POINTS_GO_MODE=1
POINTS_NEW_FOLDER=20

# Load stats
if [[ -f "$STATS_FILE" ]]; then
    while IFS=: read -r key value; do
        case "$key" in
            total_sessions) TOTAL_SESSIONS=$value ;;
            total_sorts) TOTAL_SORTS=$value ;;
            total_points) TOTAL_POINTS=$value ;;
            total_time) TOTAL_TIME=$value ;;
            achievement_*) ACHIEVEMENTS[${key#achievement_}]=$value ;;
        esac
    done < "$STATS_FILE"
fi

# First-time setup function
first_time_setup() {
    echo -e "\n${BOLD}${CYAN}🎮 WELCOME TO CLEANRUSH! 🎮${NC}"
    echo -e "\n${YELLOW}Let's set up your personalized folder structure.${NC}"
    echo -e "${GREEN}This is a one-time setup process.${NC}\n"
    
    echo -e "${CYAN}Would you like to:${NC}"
    echo "[1] Use suggested folders (Other, Projects, Archive, Temp)"
    echo "[2] Create your own custom folders"
    echo -n "Your choice (1 or 2): "
    
    read SETUP_CHOICE
    
    declare -A setup_folders
    
    if [[ "$SETUP_CHOICE" == "1" ]]; then
        # Default suggested folders
        setup_folders=(
            [o]="Other"
            [p]="Projects"
            [a]="Archive"
            [t]="Temp"
        )
        echo -e "\n${GREEN}Great! I'll set up these folders with shortcuts:${NC}"
        for key in ${(k)setup_folders}; do
            echo "  [$key] ${setup_folders[$key]}"
        done
    else
        # Custom folder setup
        echo -e "\n${CYAN}Let's create your custom folders!${NC}"
        echo -e "${YELLOW}Enter up to 6 folders. Press Enter with empty name when done.${NC}\n"
        
        local count=0
        local suggested_keys=(o p a d w t)
        
        while [[ $count -lt 6 ]]; do
            echo -n "Folder name (or press Enter to finish): "
            read folder_name
            
            if [[ -z "$folder_name" ]]; then
                if [[ $count -eq 0 ]]; then
                    echo -e "${RED}You need at least one folder!${NC}"
                    continue
                else
                    break
                fi
            fi
            
            echo -n "Shortcut key for '$folder_name' (suggested: ${suggested_keys[$((count+1))]}): "
            read shortcut_key
            
            if [[ -z "$shortcut_key" ]]; then
                shortcut_key=${suggested_keys[$((count+1))]}
            fi
            
            shortcut_key=$(echo "$shortcut_key" | tr '[:upper:]' '[:lower:]' | cut -c1)
            
            if [[ -n "${setup_folders[$shortcut_key]}" ]]; then
                echo -e "${RED}Key '$shortcut_key' already used for '${setup_folders[$shortcut_key]}'${NC}"
                continue
            fi
            
            setup_folders[$shortcut_key]="$folder_name"
            echo -e "${GREEN}✓ Added: [$shortcut_key] $folder_name${NC}"
            count=$((count + 1))
        done
    fi
    
    # Create folders and save configuration
    echo -e "\n${YELLOW}Creating folders and saving configuration...${NC}"
    
    for key in ${(k)setup_folders}; do
        local folder_path="$BASE_DIR/${setup_folders[$key]}"
        mkdir -p "$folder_path"
        echo "$key:${setup_folders[$key]}" >> "$CONFIG_FILE"
    done
    
    echo -e "\n${GREEN}✓ Setup complete! Your folders are ready.${NC}"
    echo -e "${CYAN}Starting the game in 3 seconds...${NC}\n"
    sleep 3
}

# Load shortcuts and exclusions from config
declare -A ASSIGNED_KEYS
EXCLUDES=(".DS_Store" ".localized")

if [[ -f "$CONFIG_FILE" ]]; then
    while IFS=: read -r key folder; do
        key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
        ASSIGNED_KEYS[$key]="$folder"
        EXCLUDES+=("$folder")
    done < "$CONFIG_FILE"
else
    # Run first-time setup
    first_time_setup
    
    # Reload configuration after setup
    while IFS=: read -r key folder; do
        key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
        ASSIGNED_KEYS[$key]="$folder"
        EXCLUDES+=("$folder")
    done < "$CONFIG_FILE"
fi

# Achievement functions
check_achievements() {
    local new_total=$((TOTAL_SORTS + SESSION_SORTS))
    local achievement_thresholds=(8 16 32 64 128 256 512 1024)
    
    for threshold in "${achievement_thresholds[@]}"; do
        if [[ $new_total -ge $threshold && $TOTAL_SORTS -lt $threshold ]]; then
            if [[ -z "${ACHIEVEMENTS[$threshold]}" ]]; then
                echo -e "\n${BOLD}${YELLOW}🏆 ACHIEVEMENT UNLOCKED! ${NC}${CYAN}Sorted $threshold items!${NC}"
                ACHIEVEMENTS[$threshold]=$(date +%s)
                sleep 1.5
            fi
        fi
    done
}

display_session_stats() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    local minutes=$((session_time / 60))
    local seconds=$((session_time % 60))
    
    echo -e "\n${BOLD}${CYAN}=== SESSION STATS ===${NC}"
    echo -e "${GREEN}⏱️  Time: ${minutes}m ${seconds}s${NC}"
    echo -e "${YELLOW}📦 Items sorted: $SESSION_SORTS${NC}"
    echo -e "${MAGENTA}⭐ Points earned: $SESSION_POINTS${NC}"
    
    if [[ $SESSION_SORTS -gt 0 ]]; then
        local avg_time=$((session_time / SESSION_SORTS))
        echo -e "${BLUE}⚡ Average: ${avg_time}s per item${NC}"
    fi
}

display_total_stats() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    local new_total_time=$((TOTAL_TIME + session_time))
    local total_hours=$((new_total_time / 3600))
    local total_minutes=$(((new_total_time % 3600) / 60))
    
    echo -e "\n${BOLD}${CYAN}=== LIFETIME STATS ===${NC}"
    echo -e "${GREEN}🎮 Total sessions: $((TOTAL_SESSIONS + 1))${NC}"
    echo -e "${YELLOW}📊 Total items sorted: $((TOTAL_SORTS + SESSION_SORTS))${NC}"
    echo -e "${MAGENTA}💎 Total points: $((TOTAL_POINTS + SESSION_POINTS))${NC}"
    echo -e "${BLUE}⏱️  Total time: ${total_hours}h ${total_minutes}m${NC}"
    
    # Display achievements
    if [[ ${#ACHIEVEMENTS[@]} -gt 0 ]]; then
        echo -e "\n${BOLD}${YELLOW}🏆 ACHIEVEMENTS:${NC}"
        for achievement in ${(k)ACHIEVEMENTS}; do
            echo -e "  ${CYAN}✓ Sorted $achievement items${NC}"
        done
    fi
}

save_stats() {
    local session_time=$(($(date +%s) - SESSION_START_TIME))
    {
        echo "total_sessions:$((TOTAL_SESSIONS + 1))"
        echo "total_sorts:$((TOTAL_SORTS + SESSION_SORTS))"
        echo "total_points:$((TOTAL_POINTS + SESSION_POINTS))"
        echo "total_time:$((TOTAL_TIME + session_time))"
        for key in ${(k)ACHIEVEMENTS}; do
            echo "achievement_$key:${ACHIEVEMENTS[$key]}"
        done
    } > "$STATS_FILE"
}

# Start log session
echo "----- $(date '+%Y-%m-%d %H:%M:%S') Session Start -----" >> "$LOG_FILE"

# Display welcome message with stats
echo -e "\n${BOLD}${CYAN}🎮 CLEANRUSH 🎮${NC}"
if [[ $TOTAL_SORTS -gt 0 ]]; then
    local total_hours=$((TOTAL_TIME / 3600))
    local total_minutes=$(((TOTAL_TIME % 3600) / 60))
    echo -e "${YELLOW}Welcome back! Total sorted: $TOTAL_SORTS items | Points: $TOTAL_POINTS | Time: ${total_hours}h ${total_minutes}m${NC}"
else
    echo -e "${GREEN}Welcome to your first session!${NC}"
fi
echo ""

GO_MODE=false

for ITEM in "$SOURCE_DIR"/*; do
    BASENAME=$(basename "$ITEM")
    if [[ " ${EXCLUDES[@]} " =~ " ${BASENAME} " ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipped (excluded): $BASENAME" >> "$LOG_FILE"
        continue
    fi

    if $GO_MODE; then
        mv "$ITEM" "$BASE_DIR/Other/"
        echo -e "${MAGENTA}[Go Mode]${NC} ${GREEN}Auto-moved $BASENAME to Other${NC} ${YELLOW}+${POINTS_GO_MODE} points!${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Auto-moved to Other (go mode): $BASENAME" >> "$LOG_FILE"
        SESSION_SORTS=$((SESSION_SORTS + 1))
        SESSION_POINTS=$((SESSION_POINTS + POINTS_GO_MODE))
        check_achievements
        continue
    fi

    echo ""
    echo -e "${YELLOW}Move $BASENAME to:${NC} ${CYAN}[Score: $SESSION_POINTS | Sorted: $SESSION_SORTS]${NC}"
    for key in ${(k)ASSIGNED_KEYS}; do
        echo "[$key] ${ASSIGNED_KEYS[$key]}"
    done
    echo "[d] Delete  [s] Skip  [g] Go Mode  [n] New"
    echo -n "Your choice: "

    stty -echo -icanon time 0 min 1
    ANSWER=$(dd bs=1 count=1 2>/dev/null)
    stty sane
    echo ""  # new line

    LOWER_ANSWER=$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]')

    if [[ $LOWER_ANSWER == "g" ]]; then
        GO_MODE=true
        mv "$ITEM" "$BASE_DIR/Other/"
        echo -e "${MAGENTA}Go Mode activated!${NC} ${GREEN}Moved $BASENAME to Other${NC} ${YELLOW}+${POINTS_GO_MODE} points!${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Go Mode activated, moved to Other: $BASENAME" >> "$LOG_FILE"
        SESSION_SORTS=$((SESSION_SORTS + 1))
        SESSION_POINTS=$((SESSION_POINTS + POINTS_GO_MODE))
        check_achievements
        continue
    fi

    if [[ $LOWER_ANSWER == "d" ]]; then
        if [[ "$OS_TYPE" == "macos" ]]; then
            osascript -e "tell application \"Finder\" to delete POSIX file \"${ITEM}\""
            echo -e "${RED}Deleted $BASENAME (sent to Trash)${NC} ${YELLOW}+${POINTS_DELETE} points!${NC}"
        elif [[ "$OS_TYPE" == "linux" ]]; then
            # Check for common Linux trash utilities
            if command -v gio &> /dev/null; then
                gio trash "$ITEM"
                echo -e "${RED}Deleted $BASENAME (sent to Trash)${NC} ${YELLOW}+${POINTS_DELETE} points!${NC}"
            elif command -v trash-put &> /dev/null; then
                trash-put "$ITEM"
                echo -e "${RED}Deleted $BASENAME (sent to Trash)${NC} ${YELLOW}+${POINTS_DELETE} points!${NC}"
            else
                # Fallback to creating a trash directory if no trash utility is available
                TRASH_DIR="$HOME/.local/share/Trash/files"
                mkdir -p "$TRASH_DIR"
                mv "$ITEM" "$TRASH_DIR/"
                echo -e "${RED}Deleted $BASENAME (moved to ~/.local/share/Trash)${NC} ${YELLOW}+${POINTS_DELETE} points!${NC}"
            fi
        else
            echo -e "${RED}Delete operation not supported on this OS${NC}"
            continue
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Deleted (sent to Trash): $BASENAME" >> "$LOG_FILE"
        SESSION_SORTS=$((SESSION_SORTS + 1))
        SESSION_POINTS=$((SESSION_POINTS + POINTS_DELETE))
        check_achievements
        continue
    fi

    if [[ $LOWER_ANSWER == "s" ]]; then
        echo -e "${BLUE}Skipped: $BASENAME${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipped: $BASENAME" >> "$LOG_FILE"
        continue
    fi

    if [[ $LOWER_ANSWER == "n" ]]; then
        echo -n "Enter name for new folder: "
        read NEW_FOLDER
        echo -n "Assign a shortcut key (single letter): "
        read NEW_KEY_RAW

        NEW_KEY=$(echo "$NEW_KEY_RAW" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

        if [[ -z "$NEW_KEY" || ${#NEW_KEY} -ne 1 ]]; then
            echo -e "${RED}Error: Invalid shortcut key entered. Please enter exactly one letter.${NC}"
            continue
        fi

        if [[ -n "${ASSIGNED_KEYS[$NEW_KEY]}" ]]; then
            echo -e "${RED}Error: Shortcut [$NEW_KEY] is already used for ${ASSIGNED_KEYS[$NEW_KEY]}.${NC}"
            continue
        fi

        NEW_FOLDER_PATH="$BASE_DIR/$NEW_FOLDER"
        mkdir -p "$NEW_FOLDER_PATH"
        echo "$NEW_KEY:$NEW_FOLDER" >> "$CONFIG_FILE"

        echo -e "${GREEN}Created new folder: $NEW_FOLDER with shortcut [$NEW_KEY]. ${YELLOW}+${POINTS_NEW_FOLDER} points!${NC} Restarting script..."
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Created new folder: $NEW_FOLDER with shortcut [$NEW_KEY]. Restarting script." >> "$LOG_FILE"
        
        SESSION_POINTS=$((SESSION_POINTS + POINTS_NEW_FOLDER))
        save_stats
        exec "$SCRIPT_PATH"
    fi

    if [[ -n "${ASSIGNED_KEYS[$LOWER_ANSWER]}" ]]; then
        TARGET_FOLDER="${ASSIGNED_KEYS[$LOWER_ANSWER]}"
        mv "$ITEM" "$BASE_DIR/$TARGET_FOLDER/"
        echo -e "${GREEN}Moved $BASENAME to $TARGET_FOLDER${NC} ${YELLOW}+${POINTS_MOVE} points!${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Moved to $TARGET_FOLDER: $BASENAME" >> "$LOG_FILE"
        SESSION_SORTS=$((SESSION_SORTS + 1))
        SESSION_POINTS=$((SESSION_POINTS + POINTS_MOVE))
        check_achievements
        continue
    fi

    echo -e "${BLUE}Skipped (default): $BASENAME${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipped (default): $BASENAME" >> "$LOG_FILE"
done

# Display final stats
display_session_stats
display_total_stats

# Save stats
save_stats

echo "----- Session End -----" >> "$LOG_FILE"
