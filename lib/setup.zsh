#!/bin/zsh

# Setup Module for CleanRush
# Handles first-time setup and configuration wizard

# Load dependencies
source "$SCRIPT_DIR/lib/ui.zsh"
source "$SCRIPT_DIR/lib/config.zsh"
source "$SCRIPT_DIR/lib/file_operations.zsh"

# Main first-time setup function
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
        setup_suggested_folders setup_folders
    else
        setup_custom_folders setup_folders
    fi
    
    # Create folders and save configuration
    finalize_setup setup_folders
}

# Setup with suggested default folders
setup_suggested_folders() {
    local folders_var_name=$1
    
    # Default suggested folders - use eval to assign to the named variable
    eval "${folders_var_name}[o]='Other'" >/dev/null 2>&1
    eval "${folders_var_name}[p]='Projects'" >/dev/null 2>&1
    eval "${folders_var_name}[a]='Archive'" >/dev/null 2>&1
    eval "${folders_var_name}[t]='Temp'" >/dev/null 2>&1
    
    echo -e "\n${GREEN}Great! I'll set up these folders with shortcuts:${NC}"
    echo "  [o] Other"
    echo "  [p] Projects"
    echo "  [a] Archive"
    echo "  [t] Temp"
}

# Setup with custom user-defined folders
setup_custom_folders() {
    local folders_var_name=$1
    
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
        
        # Validate folder name
        validate_folder_name "$folder_name"
        local validation_result=$?
        
        case $validation_result in
            1)
                echo -e "${RED}Error: Folder name cannot be empty!${NC}"
                continue
                ;;
            2)
                echo -e "${RED}Error: Folder name contains invalid characters!${NC}"
                continue
                ;;
            3)
                echo -e "${RED}Error: Folder '$folder_name' already exists!${NC}"
                continue
                ;;
        esac
        
        echo -n "Shortcut key for '$folder_name' (suggested: ${suggested_keys[$((count+1))]}): "
        read shortcut_key
        
        if [[ -z "$shortcut_key" ]]; then
            shortcut_key=${suggested_keys[$((count+1))]}
        fi
        
        shortcut_key=$(echo "$shortcut_key" | tr '[:upper:]' '[:lower:]' | cut -c1)
        
        # Validate shortcut key
        validate_shortcut_key "$shortcut_key" "$folders_var_name"
        local key_validation=$?
        
        case $key_validation in
            1)
                echo -e "${RED}Error: Invalid shortcut key. Please enter exactly one letter.${NC}"
                continue
                ;;
            2)
                # Get the existing value for this key
                local existing_value
                existing_value=$(eval "echo \${${folders_var_name}[$shortcut_key]}" 2>/dev/null)
                echo -e "${RED}Error: Key '$shortcut_key' already used for '$existing_value'${NC}"
                continue
                ;;
            3)
                echo -e "${RED}Error: Key '$shortcut_key' is reserved for system functions.${NC}"
                continue
                ;;
        esac
        
        eval "${folders_var_name}[$shortcut_key]='$folder_name'" >/dev/null 2>&1
        echo -e "${GREEN}✓ Added: [$shortcut_key] $folder_name${NC}"
        count=$((count + 1))
    done
}

# Create folders and save configuration
finalize_setup() {
    local folders_var_name=$1
    
    echo -e "\n${YELLOW}Creating folders and saving configuration...${NC}"
    
    local created_count=0
    local failed_count=0
    
    # Get all keys from the associative array
    local all_keys
    eval "all_keys=(\${(k)${folders_var_name}})" >/dev/null 2>&1
    
    for key in ${all_keys}; do
        local folder_name
        folder_name=$(eval "echo \${${folders_var_name}[$key]}" 2>/dev/null)
        
        if create_folder "$folder_name"; then
            add_folder_shortcut "$key" "$folder_name"
            echo -e "${GREEN}✓ Created: $folder_name${NC}"
            created_count=$((created_count + 1))
        else
            echo -e "${RED}✗ Failed to create: $folder_name${NC}"
            failed_count=$((failed_count + 1))
        fi
    done
    
    echo -e "\n${GREEN}✓ Setup complete!${NC}"
    echo -e "${CYAN}Created $created_count folders successfully${NC}"
    
    if [[ $failed_count -gt 0 ]]; then
        echo -e "${YELLOW}Warning: $failed_count folders failed to create${NC}"
    fi
    
    echo -e "${CYAN}Starting the game in 3 seconds...${NC}\n"
    sleep 3
}

# Interactive folder addition during runtime
add_new_folder_interactive() {
    local assigned_keys_var_name=$1
    
    echo -n "Enter name for new folder: "
    read new_folder
    
    # Validate folder name
    validate_folder_name "$new_folder"
    local validation_result=$?
    
    case $validation_result in
        1)
            echo -e "${RED}Error: Folder name cannot be empty.${NC}"
            return 1
            ;;
        2)
            echo -e "${RED}Error: Folder name contains invalid characters.${NC}"
            return 1
            ;;
        3)
            echo -e "${RED}Error: Folder '$new_folder' already exists.${NC}"
            return 1
            ;;
    esac
    
    echo -n "Assign a shortcut key (single letter): "
    read new_key_raw
    
    new_key=$(echo "$new_key_raw" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    
    # Validate shortcut key
    validate_shortcut_key "$new_key" "$assigned_keys_var_name"
    local key_validation=$?
    
    case $key_validation in
        1)
            echo -e "${RED}Error: Invalid shortcut key entered. Please enter exactly one letter.${NC}"
            return 1
            ;;
        2)
            # Get the existing value for this key
            local existing_value
            existing_value=$(eval "echo \${${assigned_keys_var_name}[$new_key]}" 2>/dev/null)
            echo -e "${RED}Error: Shortcut [$new_key] is already used for $existing_value.${NC}"
            return 1
            ;;
        3)
            echo -e "${RED}Error: Shortcut [$new_key] is reserved for system functions.${NC}"
            return 1
            ;;
    esac
    
    # Create folder and add to config
    if create_folder "$new_folder"; then
        add_folder_shortcut "$new_key" "$new_folder"
        echo "$new_key:$new_folder"  # Return the key:folder pair for logging
        return 0
    else
        echo -e "${RED}Error: Failed to create folder '$new_folder'.${NC}"
        return 1
    fi
}

# Verify setup integrity
verify_setup() {
    local verification_passed=true
    
    echo -e "${CYAN}Verifying setup...${NC}"
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}✗ Configuration file missing${NC}"
        verification_passed=false
    else
        echo -e "${GREEN}✓ Configuration file found${NC}"
    fi
    
    # Check if base directory is writable
    if ! check_base_dir_permissions; then
        echo -e "${RED}✗ No write permission to base directory${NC}"
        verification_passed=false
    else
        echo -e "${GREEN}✓ Base directory writable${NC}"
    fi
    
    # Verify created folders exist
    local folder_count=0
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS=: read -r key folder; do
            if [[ -d "$BASE_DIR/$folder" ]]; then
                folder_count=$((folder_count + 1))
            else
                echo -e "${YELLOW}⚠ Folder '$folder' not found, will be created if needed${NC}"
            fi
        done < "$CONFIG_FILE"
        echo -e "${GREEN}✓ Found $folder_count configured folders${NC}"
    fi
    
    if $verification_passed; then
        echo -e "${GREEN}✓ Setup verification passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Setup verification failed${NC}"
        return 1
    fi
}

# Reset configuration (for testing or re-setup)
reset_configuration() {
    echo -e "${YELLOW}Warning: This will reset all configuration!${NC}"
    echo -n "Are you sure? (y/N): "
    read confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            rm "$CONFIG_FILE"
            echo -e "${GREEN}✓ Configuration reset${NC}"
        else
            echo -e "${YELLOW}No configuration file found${NC}"
        fi
        return 0
    else
        echo -e "${BLUE}Reset cancelled${NC}"
        return 1
    fi
}