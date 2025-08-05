# Contributing to CleanRush

Thank you for your interest in contributing to CleanRush! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

### Our Pledge
We are committed to providing a friendly, safe, and welcoming environment for all contributors, regardless of experience level, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, nationality, or other similar characteristics.

### Expected Behavior
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:
1. **Clear title and description**
2. **Steps to reproduce the issue**
3. **Expected behavior**
4. **Actual behavior**
5. **System information** (macOS version, ZSH version)
6. **Relevant log entries** from `move_desktop_items.log`

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:
1. **Use case** - Why is this enhancement needed?
2. **Proposed solution** - How should it work?
3. **Alternatives considered** - What other solutions did you think about?
4. **Additional context** - Mockups, examples, etc.

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** (see below)
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Write clear commit messages**
6. **Submit a pull request** with a comprehensive description

## Development Setup

### Prerequisites
- macOS (for testing Finder integration)
- ZSH shell
- Git

### Local Development

1. Fork and clone the repository:
```bash
git clone https://github.com/yourusername/clean_rush_fun.git
cd clean_rush_fun
```

2. Create a feature branch:
```bash
git checkout -b feature/your-feature-name
```

3. Make your changes to the appropriate module(s) in `lib/` or main script

4. Test your changes:
```bash
# Create a test directory with sample files
mkdir -p ~/Desktop/test_cleanup
touch ~/Desktop/test_cleanup/file{1..5}.txt

# Run the script
./clean_rush_fun.zsh
```

5. Commit your changes:
```bash
git add .
git commit -m "Add: brief description of your change"
```

## Project Architecture

CleanRush uses a **modular architecture** to make development and maintenance easier. Understanding this structure will help you contribute more effectively.

### Module Overview

```
clean_rush_fun/
├── clean_rush_fun.zsh      # Main entry point (lightweight orchestrator)
├── lib/                    # Modular components
│   ├── config.zsh         # Configuration & persistence
│   ├── gamification.zsh   # Points & achievements
│   ├── file_operations.zsh # File handling & OS operations
│   ├── ui.zsh            # Display & user interface
│   └── setup.zsh         # First-time setup wizard
└── tests/                 # Test suite (updated for modules)
```

### When to Edit Which Module

- **Configuration changes** (new config options, stats formats) → `lib/config.zsh`
- **Points/achievements features** (new point values, achievement types) → `lib/gamification.zsh`
- **File operations** (new platforms, file handling) → `lib/file_operations.zsh`
- **UI improvements** (colors, messages, display formats) → `lib/ui.zsh`
- **Setup wizard changes** (folder creation, validation) → `lib/setup.zsh`
- **Main flow changes** (game loop, orchestration) → `clean_rush_fun.zsh`

### Module Dependencies

- All modules can use functions from `config.zsh` (logging, configuration)
- `setup.zsh` imports `ui.zsh`, `config.zsh`, and `file_operations.zsh`
- `gamification.zsh` uses `ui.zsh` for achievement display
- Main script imports all modules in the correct order

### Adding New Features

1. **Identify the right module** for your feature
2. **Add your function** to the appropriate module
3. **Export any new global variables** that other modules need
4. **Update tests** in the corresponding test file
5. **Update main script** if you need to call your function from the game loop

## Coding Standards

### Shell Script Guidelines

1. **Use meaningful variable names**
```bash
# Good
POINTS_FOR_MOVE=10

# Bad
P_M=10
```

2. **Add comments for complex logic**
```bash
# Check if achievement threshold is reached and not already unlocked
if [[ $new_total -ge $threshold && $TOTAL_SORTS -lt $threshold ]]; then
```

3. **Use consistent indentation** (4 spaces)

4. **Quote variables to prevent word splitting**
```bash
# Good
mv "$ITEM" "$BASE_DIR/$TARGET_FOLDER/"

# Bad
mv $ITEM $BASE_DIR/$TARGET_FOLDER/
```

5. **Check return values for critical operations**
```bash
if ! mkdir -p "$NEW_FOLDER_PATH"; then
    echo "Error: Failed to create folder"
    exit 1
fi
```

### Color Code Usage
Use existing color variables for consistency:
- `GREEN` - Success messages
- `RED` - Errors or deletions
- `YELLOW` - Warnings or points
- `CYAN` - Information or stats
- `MAGENTA` - Special modes
- `BLUE` - Skip or neutral actions

## Testing Guidelines

### Manual Testing Checklist

Before submitting a PR, test:

- [ ] First-time setup flow
- [ ] File moving to each folder type
- [ ] File deletion (Trash integration)
- [ ] Skip functionality
- [ ] Go Mode activation and processing
- [ ] New folder creation
- [ ] Points calculation
- [ ] Achievement unlocking
- [ ] Stats persistence across sessions
- [ ] Config file updates
- [ ] Log file entries

### Edge Cases to Test

1. **Empty Desktop** - Script should exit gracefully
2. **Folders only** - Should skip all folders
3. **Special characters** in filenames
4. **Very long filenames**
5. **Files with spaces** in names
6. **Interrupted sessions** (Ctrl+C handling)

## Feature Ideas

Here are some features we'd love to see:

### High Priority
- [ ] Undo last action
- [ ] Dry run mode
- [ ] Configuration backup/restore
- [ ] Custom achievement names

### Medium Priority
- [ ] Multiple source directories
- [ ] File type filtering
- [ ] Scheduled runs
- [ ] Statistics visualization

### Nice to Have
- [ ] Sound effects
- [ ] Leaderboards
- [ ] Export statistics
- [ ] Theme customization

## Documentation

### When to Update Documentation

Update documentation when you:
- Add new features
- Change existing behavior
- Add new configuration options
- Fix bugs that users should know about

### Documentation Files
- `README.md` - User-facing documentation
- `CONTRIBUTING.md` - This file
- `CLAUDE.md` - AI assistant guidance
- Code comments - Inline explanations

## Release Process

1. **Version Numbering** - We use semantic versioning (MAJOR.MINOR.PATCH)
2. **Changelog** - Update CHANGELOG.md with your changes
3. **Testing** - Ensure all tests pass
4. **Documentation** - Update all relevant docs
5. **Tag Release** - Create a git tag for the version

## Getting Help

### Resources
- Check existing issues and discussions
- Review the README and documentation
- Look at previous pull requests

### Contact
- Open an issue for bugs or features
- Start a discussion for questions
- Tag maintainers for urgent issues

## Recognition

Contributors will be recognized in:
- The README.md contributors section
- Release notes
- The project's Contributors page on GitHub

## License

By contributing to CleanRush, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make CleanRush better! 🎮✨