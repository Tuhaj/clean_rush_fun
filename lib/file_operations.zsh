#!/bin/zsh

# File Operations Module for CleanRush
# Handles OS detection, file movement, deletion, and trash operations

# OS Detection
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        export OS_TYPE="linux"
    else
        export OS_TYPE="unknown"
    fi
}

# Move file to target folder
move_file() {
    local source_item=$1
    local target_folder=$2
    local basename=$(basename "$source_item")
    
    # Ensure target directory exists
    mkdir -p "$BASE_DIR/$target_folder"
    
    # Move the file
    if mv "$source_item" "$BASE_DIR/$target_folder/"; then
        return 0  # Success
    else
        return 1  # Failed
    fi
}

# Delete file (send to trash)
delete_file() {
    local item=$1
    local basename=$(basename "$item")
    
    case "$OS_TYPE" in
        "macos")
            if osascript -e "tell application \"Finder\" to delete POSIX file \"${item}\"" 2>/dev/null; then
                return 0  # Success
            else
                return 1  # Failed
            fi
            ;;
        "linux")
            # Check for common Linux trash utilities
            if command -v gio &> /dev/null; then
                if gio trash "$item" 2>/dev/null; then
                    return 0  # Success
                else
                    return 1  # Failed
                fi
            elif command -v trash-put &> /dev/null; then
                if trash-put "$item" 2>/dev/null; then
                    return 0  # Success
                else
                    return 1  # Failed
                fi
            else
                # Fallback to creating a trash directory if no trash utility is available
                local trash_dir="$HOME/.local/share/Trash/files"
                mkdir -p "$trash_dir"
                if mv "$item" "$trash_dir/" 2>/dev/null; then
                    return 0  # Success
                else
                    return 1  # Failed
                fi
            fi
            ;;
        *)
            return 2  # Unsupported OS
            ;;
    esac
}

# Create new folder
create_folder() {
    local folder_name=$1
    local folder_path="$BASE_DIR/$folder_name"
    
    if mkdir -p "$folder_path"; then
        return 0  # Success
    else
        return 1  # Failed
    fi
}

# Get all items in source directory
get_source_items() {
    local items=()
    
    # Check if source directory exists and is readable
    if [[ -d "$SOURCE_DIR" && -r "$SOURCE_DIR" ]]; then
        for item in "$SOURCE_DIR"/*; do
            # Check if glob found actual files (not literal asterisk)
            if [[ -e "$item" ]]; then
                items+=("$item")
            fi
        done
    fi
    
    # Return array of items
    printf '%s\n' "${items[@]}"
}

# Check if file/folder exists
item_exists() {
    local item_path=$1
    
    if [[ -e "$item_path" ]]; then
        return 0  # Exists
    else
        return 1  # Doesn't exist
    fi
}

# Check if path is a directory
is_directory() {
    local item_path=$1
    
    if [[ -d "$item_path" ]]; then
        return 0  # Is directory
    else
        return 1  # Not directory
    fi
}

# Check if path is a file
is_file() {
    local item_path=$1
    
    if [[ -f "$item_path" ]]; then
        return 0  # Is file
    else
        return 1  # Not file
    fi
}

# Get file/folder permissions
get_permissions() {
    local item_path=$1
    
    if [[ -e "$item_path" ]]; then
        ls -ld "$item_path" | cut -d' ' -f1
    else
        echo "not_found"
    fi
}

# Check if we have write permission to base directory
check_base_dir_permissions() {
    if [[ -w "$BASE_DIR" ]]; then
        return 0  # Writable
    else
        return 1  # Not writable
    fi
}

# Get file size in human readable format
get_file_size() {
    local item_path=$1
    
    if [[ -e "$item_path" ]]; then
        if command -v du &> /dev/null; then
            du -h "$item_path" | cut -f1
        else
            echo "unknown"
        fi
    else
        echo "not_found"
    fi
}

# Get file modification time
get_modification_time() {
    local item_path=$1
    
    if [[ -e "$item_path" ]]; then
        if [[ "$OS_TYPE" == "macos" ]]; then
            stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$item_path"
        elif [[ "$OS_TYPE" == "linux" ]]; then
            stat -c "%y" "$item_path" | cut -d'.' -f1
        else
            echo "unknown"
        fi
    else
        echo "not_found"
    fi
}

# Validate folder name for creation
validate_folder_name() {
    local folder_name=$1
    
    # Check if name is empty
    if [[ -z "$folder_name" ]]; then
        return 1  # Invalid: empty name
    fi
    
    # Check for invalid characters (basic validation)
    if [[ "$folder_name" =~ [/\\:*?\"\<\>\|] ]]; then
        return 2  # Invalid: contains illegal characters
    fi
    
    # Check if folder already exists
    if [[ -e "$BASE_DIR/$folder_name" ]]; then
        return 3  # Invalid: already exists
    fi
    
    return 0  # Valid
}

# Validate shortcut key
validate_shortcut_key() {
    local key=$1
    local assigned_keys_var_name=$2
    
    # Clean and validate key
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    
    # Check if key is single character
    if [[ -z "$key" || ${#key} -ne 1 ]]; then
        return 1  # Invalid: not single character
    fi
    
    # Check if key is already assigned
    local existing_value
    existing_value=$(eval "echo \${${assigned_keys_var_name}[$key]}" 2>/dev/null)
    if [[ -n "$existing_value" ]]; then
        return 2  # Invalid: already assigned
    fi
    
    # Check if key is reserved
    local reserved_keys=("d" "s" "g" "n")
    for reserved in "${reserved_keys[@]}"; do
        if [[ "$key" == "$reserved" ]]; then
            return 3  # Invalid: reserved key
        fi
    done
    
    return 0  # Valid
}

# Get disk space information
get_disk_space() {
    local path=${1:-"$BASE_DIR"}
    
    if command -v df &> /dev/null; then
        df -h "$path" | tail -1
    else
        echo "unknown"
    fi
}