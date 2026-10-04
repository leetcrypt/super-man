# Super Man Enhancement Proposal

## 🎯 Goal
Transform super-man into an intelligent CLI assistant that can:
- Accept natural language questions
- Return relevant bash commands with examples
- Explain flags in context
- Remain fast and local
- Work offline

## 🏗️ Multi-Tiered Architecture

### Tier 1: Fast Keyword Matching (Instant - <10ms)
**Use Case:** Simple, common tasks

```bash
super-man "list files by size"
# Returns: ls -lhS

super-man "find large files"
# Returns: find . -type f -size +100M -exec ls -lh {} \;

super-man "search in files"
# Returns: grep -r "pattern" .
```

**Implementation:**
- JSON database of common tasks → commands
- Simple keyword matching
- Pre-indexed for speed

### Tier 2: Pattern Database (Fast - <100ms)
**Use Case:** More complex tasks with variations

```bash
super-man "compress all logs older than 30 days"
# Returns: find /var/log -name "*.log" -mtime +30 -exec gzip {} \;
# Explanation: Finds logs older than 30 days and compresses them

super-man "monitor cpu usage every 2 seconds"
# Returns: watch -n 2 'top -b -n 1 | head -20'
```

**Implementation:**
- Template-based matching
- Parameter extraction
- Context-aware suggestions

### Tier 3: Local LLM (Optional - ~1-5s)
**Use Case:** Complex, unique queries

```bash
super-man --ai "extract all email addresses from files and save to csv"
# Uses local Ollama/llama.cpp for understanding
# Generates: grep -roh '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b' . | sort -u > emails.csv
```

**Implementation:**
- Optional Ollama integration
- Cached responses
- Fallback to pattern matching

## 📊 Proposed Features

### 1. Natural Language Query Mode

```bash
# Ask a question
super-man ask "how do I find files modified today"

# Get command + explanation
super-man explain "what does find . -name '*.log' do"

# Get examples for a task
super-man examples "working with archives"
```

### 2. Task-Based Categories

```bash
# Browse by category
super-man category files      # File operations
super-man category network    # Network commands
super-man category system     # System monitoring
super-man category text       # Text processing
```

### 3. Interactive Examples

```bash
super-man demo "find and replace in files"
# Shows:
# 1. Basic: sed -i 's/old/new/g' file.txt
# 2. Recursive: find . -type f -exec sed -i 's/old/new/g' {} +
# 3. With backup: find . -type f -exec sed -i.bak 's/old/new/g' {} +
```

### 4. Command Builder

```bash
super-man build
# Interactive wizard:
# What do you want to do?
# > Find files
# What type of files?
# > Text files (*.txt)
# Any conditions?
# > Larger than 1MB
#
# Generated: find . -name "*.txt" -size +1M
```

## 🗄️ Data Structure

### commands.json
```json
{
  "tasks": [
    {
      "id": "list-files-by-size",
      "keywords": ["list", "files", "size", "largest", "biggest"],
      "category": "files",
      "command": "ls -lhS",
      "description": "List files sorted by size (largest first)",
      "examples": [
        {
          "desc": "List all files by size",
          "cmd": "ls -lhS"
        },
        {
          "desc": "List only in current dir (no subdirs)",
          "cmd": "ls -lhS | grep -v '^d'"
        },
        {
          "desc": "Show top 10 largest",
          "cmd": "ls -lhS | head -11"
        }
      ],
      "related": ["find-large-files", "disk-usage"],
      "flags_explained": {
        "-l": "Long format (detailed info)",
        "-h": "Human readable sizes (KB, MB, GB)",
        "-S": "Sort by size (largest first)"
      }
    },
    {
      "id": "find-large-files",
      "keywords": ["find", "large", "big", "files", "disk", "space"],
      "category": "files",
      "command": "find . -type f -size +100M -exec ls -lh {} \\;",
      "description": "Find files larger than 100MB",
      "templates": [
        {
          "pattern": "find {files} larger than {size}",
          "cmd": "find . -type f -size +{size} -exec ls -lh {} \\;"
        }
      ],
      "examples": [
        {
          "desc": "Find files larger than 100MB",
          "cmd": "find . -type f -size +100M -exec ls -lh {} \\;"
        },
        {
          "desc": "Find and sort by size",
          "cmd": "find . -type f -size +100M -exec ls -lh {} \\; | sort -k5 -hr"
        }
      ]
    }
  ],
  "categories": {
    "files": ["File Operations", "list-files-by-size", "find-large-files"],
    "text": ["Text Processing", "search-in-files", "find-and-replace"],
    "network": ["Network Operations", "check-ports", "download-file"],
    "system": ["System Monitoring", "cpu-usage", "memory-usage"]
  }
}
```

## 🚀 Implementation Phases

### Phase 1: Enhanced Command Database (Week 1)
- Create comprehensive JSON database
- 100+ common tasks with examples
- Keyword-based search
- Category browsing

**Files to create:**
- `commands-db.json` - Task database
- `super-man-search.sh` - Search functionality
- `super-man-ask.sh` - Natural language queries

### Phase 2: Pattern Matching (Week 2)
- Template-based command generation
- Parameter extraction from queries
- Context-aware suggestions

**Features:**
- "find files modified in last {N} days"
- "compress all {extension} files"
- "search for {pattern} in {location}"

### Phase 3: LLM Integration (Optional)
- Ollama integration for complex queries
- Caching layer for speed
- Graceful fallback

**Integration points:**
- `super-man --ai "complex query"`
- Local llama3 or codellama
- Response caching in ~/.cache/super-man/

## 🎨 Enhanced CLI Interface

```bash
# Current
super-man ls size              # Show ls flags with 'size'

# Enhanced
super-man ask "show largest files"
super-man task "compress old logs"
super-man explain "tar -czf archive.tar.gz folder/"
super-man category files
super-man search "find duplicate"
super-man build                # Interactive builder
super-man recent              # Recently used commands
super-man bookmark "useful-find-command"
super-man --ai "complex natural language query"
```

## 📦 Database Content Areas

### File Operations (30+ tasks)
- List, find, search, copy, move, delete
- Permissions, ownership
- Archives (tar, zip, gzip)
- Disk usage, large files

### Text Processing (25+ tasks)
- grep, sed, awk patterns
- Find and replace
- Text manipulation
- Format conversion

### Network (20+ tasks)
- Download files (wget, curl)
- Check connections (ping, netstat)
- Port scanning (nc, nmap)
- SSH operations

### System Monitoring (20+ tasks)
- CPU, memory, disk usage
- Process management
- Logs analysis
- System info

### Git Operations (15+ tasks)
- Common workflows
- Branch management
- Undoing changes
- Collaboration

## 🔧 Technical Architecture

```
super-man (main script)
    │
    ├─> Mode Detection
    │   ├─> --help, --list (existing)
    │   ├─> COMMAND [FILTER] (existing)
    │   ├─> ask "query"
    │   ├─> task "description"
    │   ├─> explain "command"
    │   └─> category NAME
    │
    ├─> Fast Keyword Search
    │   └─> commands-db.json lookup
    │       └─> Return top 3 matches
    │
    ├─> Pattern Matching
    │   └─> Template expansion
    │       └─> Parameter substitution
    │
    └─> Optional LLM (--ai flag)
        └─> Ollama API call
            └─> Cache response
```

## 💾 Storage & Performance

### Fast Lookup Strategy
```bash
# Pre-indexed keyword→command mapping
KEYWORD_INDEX=~/.local/share/super-man/keywords.idx

# On first run: build index
# Subsequent runs: instant lookup

# Expected performance:
# - Keyword search: <10ms
# - Pattern match: <100ms
# - LLM query: 1-5s (cached: <10ms)
```

### Caching
```bash
~/.cache/super-man/
    ├── ai-responses/       # Cached LLM responses
    ├── recent-commands     # History
    └── bookmarks.json      # User bookmarks
```

## 🎯 Example Usage Scenarios

### Scenario 1: New User Learning
```bash
$ super-man ask "how to find text in files"

📖 Task: Search for text in files

Command:
  grep -r "pattern" directory/

Explanation:
  -r  : Recursive search
  "pattern" : Text to find
  directory/ : Where to search

Examples:
  1. Search in current directory:
     grep -r "error" .

  2. Case-insensitive search:
     grep -ri "error" .

  3. Show line numbers:
     grep -rn "error" .

Related tasks:
  • find-and-replace
  • search-specific-files
  • count-occurrences
```

### Scenario 2: Quick Lookup
```bash
$ super-man task "compress folder"

💡 Quick answer:

  tar -czf archive.tar.gz folder/

Flags explained:
  -c : Create archive
  -z : Compress with gzip
  -f : File name follows

Try also:
  super-man explain "tar -czf archive.tar.gz folder/"
  super-man category files
```

### Scenario 3: Complex Query (with AI)
```bash
$ super-man --ai "find all python files modified in last week, exclude virtual environments, and count lines of code"

🤖 AI Assistant (using local LLM)

Generated command:
  find . -name "*.py" -not -path "*/venv/*" -not -path "*/.env/*" \
    -mtime -7 -exec wc -l {} + | awk '{sum+=$1} END {print sum}'

Breakdown:
  1. find . -name "*.py"           # Find Python files
  2. -not -path "*/venv/*"         # Exclude venv directories
  3. -mtime -7                     # Modified in last 7 days
  4. -exec wc -l {} +              # Count lines
  5. awk '{sum+=$1} END {print sum}' # Sum total

Cached for future use.
```

## 🔌 Ollama Integration (Optional)

### Setup
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a code-focused model
ollama pull codellama:7b

# Configure super-man
super-man config set llm.enable true
super-man config set llm.model codellama:7b
```

### Usage
```bash
# First time (generates command)
super-man --ai "complex query"  # ~3s

# Second time (cached)
super-man --ai "complex query"  # <10ms

# Clear cache
super-man cache clear
```

## 📈 Success Metrics

After implementation, users should be able to:
- ✅ Ask questions in natural language
- ✅ Get relevant commands instantly (<100ms)
- ✅ See examples for any task
- ✅ Understand what commands do
- ✅ Build complex commands interactively
- ✅ Work completely offline
- ✅ Learn bash progressively

## 🎓 Educational Value

The enhanced tool becomes a learning platform:
1. **Discovery**: Browse categories to learn what's possible
2. **Examples**: See real-world usage patterns
3. **Explanation**: Understand each flag's purpose
4. **Practice**: Build commands interactively
5. **History**: Review and reuse previous solutions

## 🚀 Next Steps

Ready to implement? Here's the order:

1. **Create command database** (commands-db.json)
   - Start with 20-30 common tasks
   - Expand over time

2. **Add search functionality**
   - Keyword matching
   - Category browsing

3. **Implement query modes**
   - ask, task, explain, category

4. **Optional: Add LLM integration**
   - Ollama setup
   - Caching layer

5. **Test and iterate**
   - Real-world usage
   - Expand database

Would you like me to start implementing this? We can begin with Phase 1!
