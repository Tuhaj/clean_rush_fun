#!/bin/zsh

# Integration tests for file operations

# Get script directory
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"

# Source test utilities
source "$TEST_SCRIPT_DIR/../test_utils.zsh"

test_group "File Operations Integration Tests"

# Test file moving operation
test_file_moving() {
    setup_test_env
    
    # Create test folders
    mkdir -p "$TEST_DESKTOP/Projects"
    mkdir -p "$TEST_DESKTOP/Archive"
    
    # Create test files
    create_test_file "document.txt" "Test document" "$TEST_DESKTOP"
    create_test_file "script.sh" "Test script" "$TEST_DESKTOP"
    
    assert_file_exists "$TEST_DESKTOP/document.txt" "Document should exist before move"
    assert_file_exists "$TEST_DESKTOP/script.sh" "Script should exist before move"
    
    # Move files
    mv "$TEST_DESKTOP/document.txt" "$TEST_DESKTOP/Projects/"
    mv "$TEST_DESKTOP/script.sh" "$TEST_DESKTOP/Archive/"
    
    assert_file_not_exists "$TEST_DESKTOP/document.txt" "Document should not exist in original location"
    assert_file_not_exists "$TEST_DESKTOP/script.sh" "Script should not exist in original location"
    
    assert_file_exists "$TEST_DESKTOP/Projects/document.txt" "Document should exist in Projects"
    assert_file_exists "$TEST_DESKTOP/Archive/script.sh" "Script should exist in Archive"
    
    teardown_test_env
}

# Test folder creation
test_folder_creation() {
    setup_test_env
    
    local new_folder="$TEST_DESKTOP/NewFolder"
    
    assert_false "[[ -d '$new_folder' ]]" "Folder should not exist initially"
    
    mkdir -p "$new_folder"
    
    assert_dir_exists "$new_folder" "New folder should be created"
    
    teardown_test_env
}

# Test file deletion to trash (Linux)
test_file_deletion_linux() {
    setup_test_env
    
    # Create test file
    create_test_file "to_delete.txt" "File to delete" "$TEST_DESKTOP"
    assert_file_exists "$TEST_DESKTOP/to_delete.txt" "File should exist before deletion"
    
    # Create trash directory (simulating Linux trash)
    local trash_dir="$TEST_DIR/.local/share/Trash/files"
    mkdir -p "$trash_dir"
    
    # Move to trash
    mv "$TEST_DESKTOP/to_delete.txt" "$trash_dir/"
    
    assert_file_not_exists "$TEST_DESKTOP/to_delete.txt" "File should not exist after deletion"
    assert_file_exists "$trash_dir/to_delete.txt" "File should exist in trash"
    
    teardown_test_env
}

# Test handling files with spaces
test_files_with_spaces() {
    setup_test_env
    
    mkdir -p "$TEST_DESKTOP/My Documents"
    
    # Create file with spaces in name
    create_test_file "my important file.txt" "Content" "$TEST_DESKTOP"
    
    assert_file_exists "$TEST_DESKTOP/my important file.txt" "File with spaces should exist"
    
    # Move file with spaces
    mv "$TEST_DESKTOP/my important file.txt" "$TEST_DESKTOP/My Documents/"
    
    assert_file_not_exists "$TEST_DESKTOP/my important file.txt" "File should be moved from desktop"
    assert_file_exists "$TEST_DESKTOP/My Documents/my important file.txt" "File should exist in destination"
    
    teardown_test_env
}

# Test handling special characters
test_special_characters() {
    setup_test_env
    
    mkdir -p "$TEST_DESKTOP/Special"
    
    # Create files with special characters
    create_test_file "file-with-dash.txt" "Content" "$TEST_DESKTOP"
    create_test_file "file_with_underscore.txt" "Content" "$TEST_DESKTOP"
    create_test_file "file.with.dots.txt" "Content" "$TEST_DESKTOP"
    
    assert_file_exists "$TEST_DESKTOP/file-with-dash.txt" "File with dash should exist"
    assert_file_exists "$TEST_DESKTOP/file_with_underscore.txt" "File with underscore should exist"
    assert_file_exists "$TEST_DESKTOP/file.with.dots.txt" "File with dots should exist"
    
    # Move all special character files
    mv "$TEST_DESKTOP"/file*.txt "$TEST_DESKTOP/Special/"
    
    assert_file_exists "$TEST_DESKTOP/Special/file-with-dash.txt" "Dash file should be moved"
    assert_file_exists "$TEST_DESKTOP/Special/file_with_underscore.txt" "Underscore file should be moved"
    assert_file_exists "$TEST_DESKTOP/Special/file.with.dots.txt" "Dots file should be moved"
    
    teardown_test_env
}

# Test exclusion handling
test_exclusion_handling() {
    setup_test_env
    
    # Create files that should be excluded
    create_test_file ".DS_Store" "System file" "$TEST_DESKTOP"
    create_test_file ".localized" "System file" "$TEST_DESKTOP"
    create_test_file "regular.txt" "Regular file" "$TEST_DESKTOP"
    
    # Define exclusions
    local excludes=(".DS_Store" ".localized")
    
    # Check each file
    for file in "$TEST_DESKTOP"/*; do
        local basename=$(basename "$file")
        local should_exclude="false"
        
        for exclude in "${excludes[@]}"; do
            if [[ "$basename" == "$exclude" ]]; then
                should_exclude="true"
                break
            fi
        done
        
        if [[ "$basename" == ".DS_Store" || "$basename" == ".localized" ]]; then
            assert_equals "true" "$should_exclude" "$basename should be excluded"
        else
            assert_equals "false" "$should_exclude" "$basename should not be excluded"
        fi
    done
    
    teardown_test_env
}

# Run tests
test_file_moving
test_folder_creation
test_file_deletion_linux
test_files_with_spaces
test_special_characters
test_exclusion_handling