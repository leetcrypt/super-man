# Using the `super-man` Alias

## Alias Configuration

Your bash alias has been updated to use the new Super Man script:

```bash
alias super-man='/home/dell/coding/gitea-projects/super-man/super-man.sh'
```

**Location:** `~/.bashrc`

## Activating the Alias

To use the updated alias in your current terminal session:

```bash
source ~/.bashrc
```

Or simply open a new terminal - the alias will be available automatically.

## Quick Start

Now you can use `super-man` as a shortcut for all Super Man features:

### Natural Language Queries

```bash
super-man ask "find large files"
super-man task "compress a folder"
super-man ask "search text in files"
```

### Browse by Category

```bash
super-man category files
super-man category network
super-man category system
super-man category text
```

### Explain Commands

```bash
super-man explain "tar -czf archive.tar.gz folder/"
super-man explain "find . -name '*.txt'"
```

### Original Modes (Still Work)

```bash
super-man ls size              # Direct flag lookup
super-man                      # Interactive fzf mode
super-man --help               # Show help with ASCII banner
super-man --list               # List all commands
```

## Examples

### 1. Quick Command Lookup

```bash
$ super-man ask "disk usage"

Searching for: "disk usage"

Found 5 matches:

1. Show disk usage of directories
   du -sh */

2. Find files larger than 100MB
   find . -type f -size +100M -exec ls -lh {} \;
...
```

### 2. Learn New Commands

```bash
$ super-man category files

Category: File Operations

1. List files sorted by size (largest first)
   ls -lhS

2. Find files larger than 100MB
   find . -type f -size +100M -exec ls -lh {} \;
...
```

### 3. Understand Command Flags

```bash
$ super-man explain "tar -czf archive.tar.gz folder/"

Command: tar -czf archive.tar.gz folder/

Description: Compress a folder into tar.gz archive

Flag explanations:
  -c : Create archive
  -z : Compress with gzip
  -f : File name follows
```

## Features

- **Fast**: All queries return in <100ms
- **Local**: No internet required
- **Smart**: Understands natural language
- **Helpful**: Shows examples and explanations
- **Professional**: ASCII banner and color-coded output

## Help System

View complete help anytime:

```bash
super-man --help
```

Shows:
- ASCII banner
- Quick start guide
- All available modes
- Examples for each feature
- Requirements and dependencies

## Tips

1. **Use quotes for multi-word queries:**
   ```bash
   super-man ask "find large files"  # ✓ Correct
   super-man ask find large files    # ✗ Will only search "find"
   ```

2. **Browse categories to discover commands:**
   ```bash
   super-man category files    # See all file operations
   ```

3. **Explain any command you're curious about:**
   ```bash
   super-man explain "any bash command here"
   ```

4. **Original direct lookup still works:**
   ```bash
   super-man ls size    # Quick flag reference
   ```

## Version

**Super Man v2.0.0** - Phase 1 Complete

With natural language queries, 20-task database, and intelligent search!

## Repository

All code is version-controlled and pushed to Gitea:

**URL:** http://localhost:3030/trill-technician/super-man

**Latest commits:**
- `13cb602` - docs: Add Phase 1 live demo with examples and benchmarks
- `7f00dfe` - feat: Phase 1 - Add intelligent natural language query system with ASCII banner
- `effbd8e` - feat: Add CLI parameter support for direct command lookup

## Enjoy!

You now have a powerful, intelligent CLI assistant at your fingertips with just one command: **`super-man`**

Try it now:
```bash
source ~/.bashrc
super-man ask "compress folder"
```

🚀 Happy scripting!
