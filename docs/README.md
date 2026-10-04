# Super Man

🚀 CLI assistant for impromptu bash scripting help

## Description

Interactive bash command helper that uses `fzf` to browse common bash commands and their options. Perfect for when you need a quick reminder of command flags and usage without digging through man pages.

## Features

- 🔍 **Interactive Search** - Browse commands with fzf fuzzy finder
- 📖 **Command Descriptions** - Clear explanations for each command
- 🎯 **Flag Filtering** - Search for specific command options
- 🎨 **Color-Coded Output** - Easy-to-read terminal output
- 📚 **Smart Help** - Works with both built-in and external commands
- ⚡ **Quick Access** - Fast command reference at your fingertips

## Dependencies

```bash
# fzf - Fuzzy finder (required)
sudo apt install fzf      # Ubuntu/Debian
brew install fzf          # macOS
sudo pacman -S fzf        # Arch
```

## Installation

```bash
# Clone the repository
git clone http://localhost:3030/trill-technician/super-man.git
cd super-man

# Make executable
chmod +x super-man.sh

# Optional: Install system-wide
sudo cp super-man.sh /usr/local/bin/super-man

# Or add to your PATH
echo 'export PATH="$HOME/super-man:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

```bash
./super-man.sh
```

### Workflow

1. **Launch** - Run the script
2. **Browse** - Use arrow keys to navigate commands
3. **Select** - Press Enter to choose a command
4. **Filter** - Optionally enter a keyword to filter flags
5. **View** - See all available flags for the command

### Example Session

```
$ ./super-man.sh

> ls:List directory contents
  cd:Change the current directory
  pwd:Print the name of the current working directory
  cp:Copy files and directories
  mv:Move or rename files and directories
  ...

Command: ls
Description: List directory contents
Filter flags (optional): size

    Flags for ls:
       -s, --size
              print the allocated size of each file, in blocks
       -S     sort by file size, largest first
       --block-size=SIZE
              with -l, scale sizes by SIZE when printing them
```

## Included Commands

The script includes help for these common bash commands:

| Command | Description |
|---------|-------------|
| `ls` | List directory contents |
| `cd` | Change the current directory |
| `pwd` | Print working directory |
| `cp` | Copy files and directories |
| `mv` | Move or rename files |
| `rm` | Remove files or directories |
| `mkdir` | Create directories |
| `rmdir` | Remove empty directories |
| `grep` | Search text patterns |
| `find` | Search for files |
| `echo` | Display text |

## Customization

### Adding More Commands

Edit the `COMMANDS` array in `super-man.sh`:

```bash
COMMANDS=(
  "command-name:Description of what it does"
  "wget:Download files from the web"
  "curl:Transfer data with URLs"
  "tar:Archive files"
  # Add your own...
)
```

### Changing Colors

Modify the color variables at the top of the `show_flags()` function:

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color
```

## How It Works

1. **Command List** - Defines an array of common bash commands with descriptions
2. **FZF Selection** - Presents commands in an interactive fuzzy finder
3. **Help Extraction** - Retrieves flag information from:
   - Built-in commands using `help`
   - External commands using `man` pages
4. **Filtered Output** - Optionally filters flags based on your search term

## Tips

- Use partial matching in fzf (type any part of command name)
- Filter flags to find specific options quickly
- Add your most-used commands to the array
- Combine with aliases for even faster access

```bash
# Add to ~/.bashrc
alias bh='super-man.sh'
```

## Contributing

Feel free to:
- Add more commands to the default list
- Improve flag extraction logic
- Enhance the user interface
- Fix bugs or improve documentation

## License

MIT License - feel free to modify and distribute

## Author

Created as a quick reference tool for bash command-line work

---

**Pro Tip**: Bookmark common flag patterns you discover, or add them as comments in the script for quick reference!
