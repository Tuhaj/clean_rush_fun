# CleanRush 🎮

A gamified desktop file organizer for macOS and Linux that makes cleaning your desktop fun and rewarding!

🌐 **Website**: [https://www.cleanrush.fun/](https://www.cleanrush.fun/)

## Features

### 🎯 Interactive File Sorting
- **Quick keyboard shortcuts** - Sort files with single keystrokes
- **Custom folders** - Create your own organizational structure
- **Smart exclusions** - Automatically skips system files and configured folders
- **Go Mode** - Batch process remaining files quickly

### 🏆 Gamification System
- **Points rewards** for every action:
  - Move file: 10 points
  - Delete file: 5 points
  - Create folder: 20 points
  - Go Mode: 1 point per file
- **Achievement system** - Unlock achievements at milestone thresholds (8, 16, 32, 64... items sorted)
- **Session tracking** - Monitor your progress per session
- **Lifetime statistics** - Track your total cleaning accomplishments

### 📊 Statistics & Progress
- Session time tracking
- Items sorted counter
- Average time per item
- Total points earned
- Achievement gallery

## Installation

### Prerequisites
- **Operating System**: macOS or Linux
- **Shell**: ZSH (default on modern macOS, installable on Linux via `apt install zsh` or `yum install zsh`)
- **Linux Trash Support** (optional): 
  - `gio` (GNOME/GTK environments)
  - `trash-cli` (install via `apt install trash-cli` or `pip install trash-cli`)
  - Falls back to XDG trash directory if neither is available

### Setup

1. Clone the repository:
```bash
git clone git@github.com:Tuhaj/clean_rush_fun.git
cd clean_rush_fun
```

2. Make the script executable:
```bash
chmod +x clean_rush_fun.zsh
```

3. Run CleanRush:
```bash
./clean_rush_fun.zsh
```

## Usage

### First Time Setup
On your first run, CleanRush will guide you through setting up your folder structure:

1. Choose between suggested folders or create custom ones
2. Assign single-letter shortcuts to each folder
3. Folders are automatically created on your Desktop

### Sorting Files
When you run CleanRush, it will:

1. Scan your Desktop for unsorted files
2. Present each file with sorting options:
   - **[letter]** - Move to assigned folder
   - **[d]** - Delete (send to Trash)
   - **[s]** - Skip this file
   - **[g]** - Activate Go Mode (auto-sort remaining to "Other")
   - **[n]** - Create new folder with shortcut

### Configuration Files

CleanRush creates several files in its directory:

- `excludes.conf` - Stores folder shortcuts and exclusions
- `stats.conf` - Saves your gamification progress
- `move_desktop_items.log` - Logs all file operations

### Tips for Maximum Points

1. **Be decisive** - Quick decisions earn more points per minute
2. **Use Go Mode** - When you have many similar files
3. **Create folders** - Earn 20 points and better organization
4. **Regular sessions** - Build streaks and unlock achievements

## Platform-Specific Features

### macOS
- Uses native Finder integration for trash operations via `osascript`
- Handles macOS-specific files (`.DS_Store`, `.localized`)
- Full Trash/Bin integration with recovery options

### Linux
- Supports multiple trash implementations:
  - **GNOME/GTK**: Uses `gio trash` for native trash integration
  - **trash-cli**: Python-based trash utility with full XDG compliance
  - **Fallback**: Creates XDG-compliant trash in `~/.local/share/Trash/files`
- Works with all major desktop environments (GNOME, KDE, XFCE, etc.)

## Customization

### Adding Default Exclusions
Edit the script to add files/folders to always skip:
```zsh
EXCLUDES=(".DS_Store" ".localized" "your_folder_name")
```

### Modifying Point Values
Adjust the point system in the script:
```zsh
POINTS_MOVE=10
POINTS_DELETE=5
POINTS_GO_MODE=1
POINTS_NEW_FOLDER=20
```

### Changing Source Directory
By default, CleanRush organizes files on your Desktop. To change this:
```zsh
SOURCE_DIR="$HOME/Desktop"  # Change to your preferred directory
BASE_DIR="$HOME/Desktop"    # Where organized folders are created
```

## Testing

CleanRush includes a comprehensive test suite to ensure reliability across platforms.

### Running Tests

Run all tests:
```bash
./tests/run_tests.zsh
```

Run specific test categories:
```bash
# Unit tests only
for test in tests/unit/test_*.zsh; do $test; done

# Integration tests only
for test in tests/integration/test_*.zsh; do $test; done
```

### Test Coverage

The test suite includes:
- **Unit Tests**:
  - OS detection (macOS/Linux)
  - Points and achievements system
  - Configuration file management
- **Integration Tests**:
  - File operations (move, delete, create)
  - Logging functionality
  - Special character handling

### Writing Tests

Tests use the included test utilities (`tests/test_utils.zsh`) which provide:
- Assertion functions (`assert_equals`, `assert_file_exists`, etc.)
- Test environment setup/teardown
- Mock input capabilities

Example test:
```zsh
source "$(dirname "$0")/../test_utils.zsh"

test_my_feature() {
    setup_test_env
    
    # Your test code here
    assert_equals "expected" "$actual" "Description"
    
    teardown_test_env
}
```

## Troubleshooting

### Script Won't Run
- Ensure you have execution permissions: `chmod +x clean_rush_fun.zsh`
- Check you're using ZSH: `echo $SHELL` should show `/bin/zsh` or `/usr/bin/zsh`
- **Linux users**: Install ZSH if not present: `sudo apt install zsh` (Debian/Ubuntu) or `sudo yum install zsh` (RHEL/CentOS)

### Files Not Moving
- Check folder permissions
- Ensure target folders exist
- Review the log file for errors

### Stats Not Saving
- Verify write permissions in the script directory
- Check if `stats.conf` exists and is writable

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created with ❤️ for everyone who struggles with desktop clutter

---

*Turn chaos into order, one point at a time!* 🚀