#!/bin/bash

# Get script directory for commands-db.json location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_FILE="$SCRIPT_DIR/commands-db.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ─── Theme engine: coherent random color schemes (HSL harmony → truecolor) ───
# Coherence rule: pick one base hue + a harmony scheme (analogous/triadic/
# complementary/split-complement) with constrained saturation & lightness so
# the derived role colors relate to each other and never clash.
SM_SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
SM_THEME_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/super-man"
SM_THEME_FILE="$SM_THEME_DIR/theme"

_sm_truecolor() { case "$COLORTERM" in *truecolor*|*24bit*) return 0;; esac; return 1; }

# HSL (H 0-359, S/L 0-100) -> "R G B"
_sm_hsl_rgb() {
  awk -v h="$1" -v s="$2" -v l="$3" 'BEGIN{
    s/=100; l/=100;
    a=(2*l-1); if(a<0)a=-a; c=(1-a)*s;
    hp=h/60.0; m2=hp%2; d=m2-1; if(d<0)d=-d; x=c*(1-d);
    if(hp<1){r=c;g=x;b=0}else if(hp<2){r=x;g=c;b=0}
    else if(hp<3){r=0;g=c;b=x}else if(hp<4){r=0;g=x;b=c}
    else if(hp<5){r=x;g=0;b=c}else{r=c;g=0;b=x}
    m=l-c/2;
    printf "%d %d %d",int((r+m)*255+0.5),int((g+m)*255+0.5),int((b+m)*255+0.5)
  }'
}
_sm_fg() { local p=($1); printf '\033[38;2;%d;%d;%dm' "${p[0]}" "${p[1]}" "${p[2]}"; }

# sm_gen_theme [seed] — derive a coherent palette and remap the legacy color vars.
# Sets: SM_THEME_SEED, SM_HUE, SM_SCHEME, SM_SAT, SM_LIGHT and CYAN/BLUE/MAGENTA/YELLOW/GREEN.
sm_gen_theme() {
  local seed="${1:-$RANDOM$RANDOM}"
  # Deterministic MINSTD LCG (mawk's srand() ignores its seed, so we roll our own).
  read -r SM_HUE SM_SCHEME_ID SM_SAT SM_LIGHT <<<"$(awk -v seed="$seed" '
    function rnd(){s=(s*48271)%2147483647; return s/2147483647}
    BEGIN{
      s=seed%2147483646; if(s<1)s+=2147483646;
      print int(rnd()*360), int(rnd()*4), 62+int(rnd()*23), 58+int(rnd()*12)
    }')"
  local o1 o2 o3 o4
  case "$SM_SCHEME_ID" in
    0) o1=30;  o2=-30; o3=60;  o4=-60; SM_SCHEME="analogous" ;;
    1) o1=120; o2=240; o3=60;  o4=300; SM_SCHEME="triadic" ;;
    2) o1=180; o2=30;  o3=210; o4=150; SM_SCHEME="complementary" ;;
    3) o1=150; o2=210; o3=30;  o4=330; SM_SCHEME="split-complement" ;;
  esac
  local yl=$((SM_LIGHT+6)); [ $yl -gt 80 ] && yl=80
  local dl=$((SM_LIGHT-18))
  CYAN=$(_sm_fg    "$(_sm_hsl_rgb "$SM_HUE" "$SM_SAT" "$SM_LIGHT")")              # primary
  BLUE=$(_sm_fg    "$(_sm_hsl_rgb "$(((SM_HUE+o1+360)%360))" "$SM_SAT" "$dl")")  # header/separator
  MAGENTA=$(_sm_fg "$(_sm_hsl_rgb "$(((SM_HUE+o2+360)%360))" "$SM_SAT" "$SM_LIGHT")") # accent/args
  YELLOW=$(_sm_fg  "$(_sm_hsl_rgb "$(((SM_HUE+o3+360)%360))" "$SM_SAT" "$yl")")  # flags
  GREEN=$(_sm_fg   "$(_sm_hsl_rgb "$(((SM_HUE+o4+360)%360))" "$SM_SAT" "$SM_LIGHT")") # values/ok
  SM_THEME_SEED="$seed"
}

# Load a previously-saved theme (opt-in: no file ⇒ keep default colors, nothing breaks).
if [ -z "$NO_COLOR" ] && _sm_truecolor && [ -f "$SM_THEME_FILE" ]; then
  sm_gen_theme "$(cat "$SM_THEME_FILE" 2>/dev/null)"
fi

# Raw (real-ESC-byte) versions of the themeable colors, for use inside sed/awk
# replacements where a literal "\033" would be misread (sed treats \0 as the match).
# printf %b yields a real ESC regardless of whether the source is themed or default.
sm_refresh_raw_colors() {
  C_PRIMARY=$(printf '%b' "$CYAN"); C_FLAG=$(printf '%b' "$YELLOW")
  C_ARG=$(printf '%b' "$MAGENTA"); C_OPT=$(printf '%b' "$GREEN")
  C_HDR=$(printf '%b' "$BLUE");    C_BOLD=$(printf '%b' "$BOLD")
  C_DIM=$(printf '%b' "$DIM");     C_RESET=$(printf '%b' "$NC")
  C_FLAGB="${C_BOLD}${C_FLAG}"     # bold + flag color, for flag listings
}
sm_refresh_raw_colors

# ASCII Banner
show_banner() {
  echo -en "${CYAN}"
  cat <<'BANNER'
 ____                          __  __
/ ___| _   _ _ __   ___ _ __  |  \/  | __ _ _ __
\___ \| | | | '_ \ / _ \ '__| | |\/| |/ _` | '_ \
 ___) | |_| | |_) |  __/ |    | |  | | (_| | | | |
|____/ \__,_| .__/ \___|_|    |_|  |_|\__,_|_| |_|
            |_|
BANNER
  echo -e "${NC}${YELLOW}        Your Intelligent CLI Assistant for Bash${NC}"
  echo ""
}

show_help() {
  show_banner
  echo -e "${BOLD}${YELLOW}QUICK START${NC}"
  echo -e "  ${GREEN}super-man ask \"find large files\"${NC}     # Ask a question"
  echo -e "  ${GREEN}super-man category files${NC}             # Browse by category"
  echo -e "  ${GREEN}super-man explain \"tar -czf\"${NC}         # Explain a command"
  echo ""
  echo -e "${BOLD}${YELLOW}MODES${NC}"
  echo -e "  ${CYAN}Natural Language Queries:${NC}"
  echo -e "    ${GREEN}ask${NC} \"query\"           Ask in natural language (database)"
  echo -e "    ${GREEN}task${NC} \"description\"    Describe what you want to do (database)"
  echo -e "    ${GREEN}ai${NC} \"complex query\"    Text-to-bash one-liner, fully local (advanced) 🤖"
  echo ""
  echo -e "  ${CYAN}Browse & Explore:${NC}"
  echo -e "    ${GREEN}category${NC} NAME          Browse by category (files/text/network/system)"
  echo -e "    ${GREEN}explain${NC} \"command\"      Explain what a command does"
  echo -e "    ${GREEN}theme${NC} [seed|show|off]  Roll a coherent color theme (truecolor; Ctrl-T in fzf)"
  echo ""
  echo -e "  ${CYAN}Direct Lookup:${NC}"
  echo -e "    ${GREEN}COMMAND [FILTER]${NC}       Show flags for command (e.g., ls size)"
  echo -e "    ${GREEN}-i${NC}, ${GREEN}--interactive${NC}      Interactive fzf mode"
  echo -e "    ${GREEN}-l${NC}, ${GREEN}--list${NC}             List all commands"
  echo ""
  echo -e "${BOLD}${YELLOW}CATEGORIES${NC} (20+ tasks)"
  echo -e "  ${CYAN}files${NC}    File operations (compress, find, permissions, symlinks)"
  echo -e "  ${CYAN}text${NC}     Text processing (search, replace, compare, count)"
  echo -e "  ${CYAN}network${NC}  Network ops (download, ports, ping)"
  echo -e "  ${CYAN}system${NC}   System monitoring (cpu, memory, processes)"
  echo ""
  echo -e "${BOLD}${YELLOW}EXAMPLES${NC}"
  echo -e "  ${DIM}# Natural language${NC}"
  echo "  super-man ask \"compress folder\""
  echo "  super-man ask \"search text in files\""
  echo "  super-man task \"monitor cpu usage\""
  echo ""
  echo -e "  ${DIM}# Browse and learn${NC}"
  echo "  super-man category network"
  echo "  super-man explain \"find . -name '*.txt'\""
  echo ""
  echo -e "  ${DIM}# Original modes (still work)${NC}"
  echo "  super-man ls size          # Direct flag lookup"
  echo "  super-man                  # Interactive fzf mode"
  echo ""
  echo -e "${BOLD}${YELLOW}REQUIREMENTS${NC}"
  echo -e "  ${GREEN}✓${NC} jq (for natural language queries)"
  echo -e "  ${GREEN}✓${NC} fzf (for interactive mode only)"
  echo ""
  echo -e "${BOLD}${YELLOW}AI MODE${NC} 🤖 (text-to-bash, fully local via ollama)"
  echo -e "    ${GREEN}super-man ai \"find python files modified last week\"${NC}"
  echo -e "    ${GREEN}super-man ai -q \"count lines in all js files\"${NC}      # print ONLY the command"
  echo -e "    ${GREEN}super-man ai --compare \"list the 5 largest files\"${NC}  # A/B models"
  echo ""
  echo -e "  ${DIM}-q/--raw prints just the command — pipeable:${NC}"
  echo -e "    ${GREEN}\$(super-man ai -q \"...\")${NC}   or   ${GREEN}super-man ai -q \"...\" | tee cmd.sh${NC}"
  echo ""
  echo -e "  Default model: ${CYAN}${SUPERMAN_AI_MODEL}${NC}"
  echo "  Configure via env vars:"
  echo "    SUPERMAN_AI_MODEL           default model (e.g. qwen2.5-coder:1.5b for speed)"
  echo "    SUPERMAN_AI_COMPARE_MODELS  space-separated list for --compare"
  echo ""
  echo -e "${YELLOW}Database:${NC} $DB_FILE"
  echo -e "${YELLOW}Version:${NC} 2.3.0 (250+ commands, local text-to-bash AI)"
  echo ""
}

# Check if jq is available
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo "jq is required for database search features."
    echo "Install it with:"
    echo "  Debian/Ubuntu: sudo apt install jq"
    echo "  macOS:         brew install jq"
    echo "  Fedora/RHEL:   sudo dnf install jq"
    echo "  Arch:          sudo pacman -S jq"
    echo ""
    echo "You can still use the original modes:"
    echo "  super-man COMMAND [FILTER]"
    echo "  super-man --interactive"
    return 1
  fi
  return 0
}

# Check if database exists
check_database() {
  if [ ! -f "$DB_FILE" ]; then
    echo -e "${RED}Error: Database file not found${NC}"
    echo "Expected location: $DB_FILE"
    echo ""
    echo "You can still use the original modes for direct command lookup."
    return 1
  fi
  return 0
}

# Search database by keywords
search_by_keywords() {
  local query="$1"
  local max_results="${2:-3}"

  if ! check_jq || ! check_database; then
    return 1
  fi

  # Convert query to lowercase for matching
  local query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

  # Search and score tasks based on keyword matches
  jq -r --arg query "$query_lower" --argjson max "$max_results" '
    .tasks[] |
    # Calculate score based on keyword matches
    . as $task |
    ($query | split(" ") | map(select(length > 2))) as $query_words |
    (
      [
        $query_words[] as $word |
        (
          (.keywords | map(select(. | ascii_downcase | contains($word))) | length) * 2 +
          (if (.description | ascii_downcase | contains($word)) then 1 else 0 end) +
          (if (.command | ascii_downcase | contains($word)) then 1 else 0 end)
        )
      ] | add // 0
    ) as $score |
    select($score > 0) |
    {score: $score, task: .}
  ' "$DB_FILE" | jq -s --argjson max "$max_results" 'sort_by(-.score) | .[0:$max] | .[] | .task'
}

# Display a task with full details
show_task() {
  local task_json="$1"

  local id=$(echo "$task_json" | jq -r '.id')
  local desc=$(echo "$task_json" | jq -r '.description')
  local cmd=$(echo "$task_json" | jq -r '.command')
  local category=$(echo "$task_json" | jq -r '.category')

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}Task:${NC} $desc"
  echo -e "${CYAN}Category:${NC} $category"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${YELLOW}Command:${NC}"
  echo -e "  ${MAGENTA}$cmd${NC}"
  echo ""

  # Show flags explanation if available
  local flags=$(echo "$task_json" | jq -r '.flags_explained // empty')
  if [ -n "$flags" ]; then
    echo -e "${YELLOW}Flags explained:${NC}"
    echo "$task_json" | jq -r '.flags_explained | to_entries[] | "  \(.key) : \(.value)"'
    echo ""
  fi

  # Show examples
  local examples=$(echo "$task_json" | jq -r '.examples // empty')
  if [ -n "$examples" ]; then
    echo -e "${YELLOW}Examples:${NC}"
    echo "$task_json" | jq -r '.examples[] | "  \(.desc)\n    → \(.cmd)\n"'
  fi

  # Show related tasks
  local related=$(echo "$task_json" | jq -r '.related // empty')
  if [ -n "$related" ] && [ "$related" != "null" ]; then
    echo -e "${YELLOW}Related tasks:${NC}"
    echo "$task_json" | jq -r '.related[]' | while read -r rel_id; do
      local rel_desc=$(jq -r --arg id "$rel_id" '.tasks[] | select(.id == $id) | .description' "$DB_FILE")
      if [ -n "$rel_desc" ] && [ "$rel_desc" != "null" ]; then
        echo "  • $rel_desc (id: $rel_id)"
      fi
    done
    echo ""
  fi

  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Show compact task result (for multiple results)
show_task_compact() {
  local task_json="$1"
  local number="$2"

  local desc=$(echo "$task_json" | jq -r '.description')
  local cmd=$(echo "$task_json" | jq -r '.command')

  echo -e "${CYAN}${number}.${NC} ${GREEN}$desc${NC}"
  echo -e "   ${MAGENTA}$cmd${NC}"
  echo ""
}

# Ask mode - search database and show results
mode_ask() {
  local query="$1"

  if [ -z "$query" ]; then
    echo -e "${RED}Error: No query provided${NC}"
    echo "Usage: super-man ask \"your question\""
    return 1
  fi

  echo -e "${CYAN}Searching for:${NC} \"$query\""

  # Search database
  local results=$(search_by_keywords "$query" 5)

  if [ -z "$results" ]; then
    echo ""
    echo -e "${YELLOW}No matches found for: \"$query\"${NC}"
    echo ""
    echo "Try:"
    echo "  • Using different keywords"
    echo "  • Browse by category: super-man category files"
    echo "  • List all commands: super-man --list"
    return 1
  fi

  # Count results
  local count=$(echo "$results" | jq -s 'length')

  if [ "$count" -eq 1 ]; then
    # Single result - show full details
    show_task "$results"
  else
    # Multiple results - show compact list
    echo ""
    echo -e "${GREEN}Found $count matches:${NC}"
    echo ""

    local i=1
    echo "$results" | jq -c '.' | while read -r task; do
      show_task_compact "$task" "$i"
      i=$((i+1))
    done

    echo -e "${YELLOW}Tip:${NC} Use more specific keywords to narrow results"
  fi
}

# Category mode - browse tasks by category
mode_category() {
  local cat_name="$1"

  if ! check_jq || ! check_database; then
    return 1
  fi

  if [ -z "$cat_name" ]; then
    echo -e "${YELLOW}Available categories:${NC}"
    echo ""
    jq -r '.categories | to_entries[] | "  \(.key) : \(.value.name)"' "$DB_FILE"
    echo ""
    echo "Usage: super-man category NAME"
    return 1
  fi

  # Get category info
  local cat_data=$(jq --arg cat "$cat_name" '.categories[$cat]' "$DB_FILE")

  if [ "$cat_data" = "null" ]; then
    echo -e "${RED}Category not found:${NC} $cat_name"
    echo ""
    echo "Available categories:"
    jq -r '.categories | keys[]' "$DB_FILE" | sed 's/^/  /'
    return 1
  fi

  local cat_title=$(echo "$cat_data" | jq -r '.name')
  local task_ids=$(echo "$cat_data" | jq -r '.tasks[]')

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}Category:${NC} ${GREEN}$cat_title${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  local i=1
  for task_id in $task_ids; do
    local task=$(jq --arg id "$task_id" '.tasks[] | select(.id == $id)' "$DB_FILE")
    if [ -n "$task" ] && [ "$task" != "null" ]; then
      show_task_compact "$task" "$i"
      i=$((i+1))
    fi
  done
}

# AI mode - use NL2SH model for complex queries
# Generate bash one-liners from natural language via a local ollama model.
# The model is configurable so we can A/B different local LLMs:
#   SUPERMAN_AI_MODEL          default model (default: qwen2.5-coder:1.5b)
#   SUPERMAN_AI_COMPARE_MODELS space-separated list used by `ai --compare`
# Override per call with `--model NAME`; run every comparison model side by
# side with `--compare`. NL2SH is purpose-built for NL->shell so it receives
# the raw query; general coder models get an instruction wrapper plus markdown
# fence stripping so they too emit a single bare command.
SUPERMAN_AI_MODEL="${SUPERMAN_AI_MODEL:-westenfelder/NL2SH}"
SUPERMAN_AI_COMPARE_MODELS="${SUPERMAN_AI_COMPARE_MODELS:-westenfelder/NL2SH qwen2.5-coder:1.5b}"

# Build a model-appropriate prompt for a query.
ai_build_prompt() {
  local model="$1" query="$2"
  case "$model" in
    *NL2SH*|*nl2sh*)
      printf '%s' "$query"
      ;;
    *)
      printf 'You are a bash expert. Output ONLY a single bash one-liner that accomplishes the task. No explanation, no comments, no markdown code fences. Task: %s' "$query"
      ;;
  esac
}

# Strip markdown fences, surrounding blank lines, and a single pair of inline
# backticks wrapping the whole line (coder models often emit `cmd`). Only a
# matching leading+trailing pair is removed, so command substitution like
# `date` inside a longer command is left untouched.
ai_clean_response() {
  awk '/^[[:space:]]*```/ { next } { print }' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | sed -E 's/^`(.*)`$/\1/' \
    | sed '/^$/d'
}

# True if an ollama model is pulled locally.
ai_model_installed() {
  ollama list 2>/dev/null | grep -q "$1"
}

# Generate a cleaned command from one model for a query.
ai_generate() {
  local model="$1" query="$2"
  ollama run "$model" "$(ai_build_prompt "$model" "$query")" 2>/dev/null | ai_clean_response
}

# Print the man/help NAME line for the base command of a generated one-liner.
ai_explain_base() {
  local base_cmd
  base_cmd=$(echo "$1" | awk '{print $1}')
  if type "$base_cmd" 2>/dev/null | grep -q "shell builtin"; then
    echo -e "${YELLOW}Command Info:${NC}"
    help "$base_cmd" 2>/dev/null | head -3
    echo ""
  elif command -v "$base_cmd" &> /dev/null; then
    echo -e "${YELLOW}Command Info:${NC}"
    man "$base_cmd" 2>/dev/null | col -b | grep -A 2 "^NAME" | tail -2
    echo ""
  fi
}

mode_ai() {
  local compare=false
  local quiet=false
  local model="$SUPERMAN_AI_MODEL"
  local args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --compare|-c) compare=true ;;
      --quiet|--raw|-q) quiet=true ;;
      --model|-m) shift; model="$1" ;;
      *) args+=("$1") ;;
    esac
    shift
  done
  local user_query="${args[*]}"

  if [ -z "$user_query" ]; then
    echo -e "${RED}Error: No query provided${NC}" >&2
    echo "Usage: super-man ai [--model NAME] [--quiet|--compare] \"your query\"" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  super-man ai \"find all python files modified in last week\"" >&2
    echo "  super-man ai -q \"count lines in all js files\"   # prints only the command" >&2
    echo "  super-man ai --compare \"list the 5 largest files\"" >&2
    return 1
  fi

  # Check if ollama is available
  if ! command -v ollama &> /dev/null; then
    echo -e "${RED}Error: Ollama is not installed${NC}" >&2
    echo "" >&2
    echo "Install Ollama:" >&2
    echo "  curl -fsSL https://ollama.com/install.sh | sh" >&2
    echo "" >&2
    echo "For now, try: super-man ask \"$user_query\"" >&2
    return 1
  fi

  # ── Quiet/raw mode: print ONLY the generated command (pipeable, scriptable) ─
  if $quiet; then
    if ! ai_model_installed "$model"; then
      echo "Error: model '$model' not installed. Pull with: ollama pull $model" >&2
      return 1
    fi
    local out
    out=$(ai_generate "$model" "$user_query")
    if [ -z "$out" ]; then
      echo "Error: no response from $model" >&2
      return 1
    fi
    printf '%s\n' "$out"
    return 0
  fi

  # ── Compare mode: run every configured model side by side ──────────────────
  if $compare; then
    echo ""
    echo -e "${CYAN}🤖 AI Compare${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Query:${NC} $user_query"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    local m
    for m in $SUPERMAN_AI_COMPARE_MODELS; do
      echo ""
      echo -e "${BOLD}${MAGENTA}▸ $m${NC}"
      if ! ai_model_installed "$m"; then
        echo -e "  ${DIM}not installed — pull with: ollama pull $m${NC}"
        continue
      fi
      local start end elapsed out
      start=$(date +%s.%N)
      out=$(ai_generate "$m" "$user_query")
      end=$(date +%s.%N)
      elapsed=$(awk "BEGIN{printf \"%.1f\", $end-$start}")
      if [ -z "$out" ]; then
        echo -e "  ${RED}(no response)${NC}  ${DIM}(${elapsed}s)${NC}"
      else
        echo -e "  ${GREEN}$out${NC}  ${DIM}(${elapsed}s)${NC}"
      fi
    done
    echo ""
    echo -e "${DIM}Note: Always review AI-generated commands before running them!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    return 0
  fi

  # ── Single-model mode ──────────────────────────────────────────────────────
  if ! ai_model_installed "$model"; then
    echo -e "${YELLOW}Model '$model' not found. Installed models:${NC}"
    ollama list
    echo ""
    echo "Pull it with:    ollama pull $model"
    echo "Or pick another: super-man ai --model NAME \"$user_query\""
    return 1
  fi

  echo ""
  echo -e "${CYAN}🤖 AI Assistant — $model${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}Query:${NC} $user_query"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${DIM}Generating bash command...${NC}"
  echo ""

  local response=$(ai_generate "$model" "$user_query")

  if [ -z "$response" ]; then
    echo -e "${RED}Error: No response from AI model${NC}"
    echo ""
    echo "Try a simpler query or use: super-man ask \"$user_query\""
    return 1
  fi

  # Display the generated command
  echo -e "${GREEN}Generated Command:${NC}"
  echo -e "  ${MAGENTA}$response${NC}"
  echo ""

  ai_explain_base "$response"

  echo -e "${DIM}Note: Always review AI-generated commands before running them!${NC}"
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Explain mode - parse and explain a command
mode_explain() {
  local cmd_line="$1"

  if [ -z "$cmd_line" ]; then
    echo -e "${RED}Error: No command provided${NC}"
    echo "Usage: super-man explain \"command with flags\""
    echo ""
    echo "Example:"
    echo "  super-man explain \"tar -czf archive.tar.gz folder/\""
    return 1
  fi

  # Extract the base command
  local base_cmd=$(echo "$cmd_line" | awk '{print $1}')

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}Command:${NC} ${MAGENTA}$cmd_line${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  # Get syntax from man page SYNOPSIS section
  if command -v "$base_cmd" &> /dev/null || type "$base_cmd" 2>/dev/null | grep -q "shell builtin"; then
    echo -e "${CYAN}${BOLD}SYNTAX:${NC}"

    local raw_syntax=""
    if type "$base_cmd" 2>/dev/null | grep -q "shell builtin"; then
      # For builtins, get the first line of help
      raw_syntax=$(help "$base_cmd" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')
      [ -z "$raw_syntax" ] && raw_syntax="$base_cmd [options]"
    else
      # For regular commands, extract SYNOPSIS section from man page
      local synopsis=$(man "$base_cmd" 2>/dev/null | col -b | sed -n '/^SYNOPSIS/,/^DESCRIPTION/p' | head -15 | tail -n +2 | sed '$d' | tr '\n' ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      if [ -n "$synopsis" ]; then
        raw_syntax="$synopsis"
      else
        # Fallback: try to get usage from command itself
        local usage=$("$base_cmd" --help 2>&1 | grep -i "usage" | head -1 | sed 's/^[Uu]sage: //')
        if [ -n "$usage" ]; then
          raw_syntax="$usage"
        else
          raw_syntax="$base_cmd [options]"
        fi
      fi
    fi

    # Display colorized syntax
    if [ -n "$raw_syntax" ]; then
      local colored=$(colorize_syntax "$raw_syntax")
      printf "  %b\n" "$colored"
    fi
    echo ""

    # Add practical example
    echo -e "${CYAN}${BOLD}EXAMPLE:${NC}"
    local example=$(get_practical_example "$base_cmd")
    if [ -n "$example" ]; then
      echo -e "  ${GREEN}$example${NC}"
    fi
    echo ""
  fi

  # Try to find in database
  local found_in_db=false
  if check_jq && check_database; then
    local task=$(jq --arg cmd "$base_cmd" '.tasks[] | select(.command | contains($cmd))' "$DB_FILE" 2>/dev/null | jq -s '.[0]' 2>/dev/null)

    if [ -n "$task" ] && [ "$task" != "null" ] && [ "$task" != "" ]; then
      local desc=$(echo "$task" | jq -r '.description // empty' 2>/dev/null)
      if [ -n "$desc" ]; then
        echo -e "${GREEN}Description:${NC} $desc"
        echo ""
        found_in_db=true

        # Show flags if available
        local flags=$(echo "$task" | jq -r '.flags_explained // empty' 2>/dev/null)
        if [ -n "$flags" ] && [ "$flags" != "null" ]; then
          echo -e "${YELLOW}Flag explanations:${NC}"
          echo "$task" | jq -r '.flags_explained | to_entries[] | "  \(.key) : \(.value)"' 2>/dev/null
          echo ""
        fi
      fi
    fi
  fi

  # Fall back to man page if not found in database
  if [ "$found_in_db" = false ]; then
    if command -v "$base_cmd" &> /dev/null || type "$base_cmd" 2>/dev/null | grep -q "shell builtin"; then
      echo -e "${YELLOW}Getting help from man page...${NC}"
      echo ""

      if type "$base_cmd" 2>/dev/null | grep -q "shell builtin"; then
        help "$base_cmd" 2>/dev/null | head -20
      else
        man "$base_cmd" 2>/dev/null | col -b | head -30
      fi
    else
      echo -e "${RED}Command not found:${NC} $base_cmd"
    fi
  fi

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Get quick syntax for a command
get_quick_syntax() {
  local cmd="$1"
  local syntax=""

  if type "$cmd" 2>/dev/null | grep -q "shell builtin"; then
    syntax=$(help "$cmd" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' | cut -c1-60)
  else
    # Try to get first line from man page SYNOPSIS
    syntax=$(man "$cmd" 2>/dev/null | col -b | sed -n '/^SYNOPSIS/,/^DESCRIPTION/p' | sed -n '2p' | sed 's/^[[:space:]]*//' | cut -c1-60)

    if [ -z "$syntax" ]; then
      # Fallback to --help
      syntax=$("$cmd" --help 2>&1 | grep -i "usage" | head -1 | sed 's/^[Uu]sage: //' | cut -c1-60)
    fi

    if [ -z "$syntax" ]; then
      syntax="$cmd [options]"
    fi
  fi

  echo "$syntax"
}

# Get practical example for a command
get_practical_example() {
  local cmd="$1"
  local example=""

  case "$cmd" in
    # File Operations
    ls) example="ls -lah                    # List all files with human-readable sizes";;
    cd) example="cd /path/to/directory      # Change to a directory";;
    cp) example="cp file.txt backup.txt     # Copy a file";;
    mv) example="mv old.txt new.txt         # Rename or move a file";;
    rm) example="rm file.txt                # Delete a file";;
    mkdir) example="mkdir new_folder         # Create a new directory";;
    touch) example="touch newfile.txt        # Create an empty file";;
    cat) example="cat file.txt              # Display file contents";;
    chmod) example="chmod 755 script.sh      # Make a script executable";;
    chown) example="chown user:group file    # Change file owner";;
    ln) example="ln -s /path/to/file link   # Create a symbolic link";;

    # Text Processing
    grep) example="grep 'pattern' file.txt   # Search for text in a file";;
    sed) example="sed 's/old/new/g' file    # Replace text in a file";;
    awk) example="awk '{print \$1}' file     # Print first column";;
    cut) example="cut -d',' -f1 file.csv    # Extract first column from CSV";;
    sort) example="sort file.txt             # Sort lines alphabetically";;
    uniq) example="sort file.txt | uniq      # Remove duplicate lines";;
    wc) example="wc -l file.txt             # Count lines in a file";;
    diff) example="diff file1.txt file2.txt # Compare two files";;

    # File Search
    find) example="find . -name '*.txt'      # Find all .txt files";;
    locate) example="locate filename          # Quickly find a file";;
    which) example="which python              # Show full path of command";;

    # Compression
    tar) example="tar -czf archive.tar.gz folder/  # Compress a folder";;
    gzip) example="gzip file.txt             # Compress a file";;
    gunzip) example="gunzip file.txt.gz       # Decompress a file";;
    zip) example="zip archive.zip file1.txt file2.txt  # Create zip archive";;
    unzip) example="unzip archive.zip         # Extract zip archive";;

    # Network
    ping) example="ping google.com            # Test network connectivity";;
    curl) example="curl https://example.com   # Download webpage";;
    wget) example="wget https://example.com/file.zip  # Download a file";;
    ssh) example="ssh user@hostname          # Connect to remote server";;
    scp) example="scp file.txt user@host:/path/  # Copy file to remote server";;

    # System Info
    top) example="top                        # Monitor system processes";;
    ps) example="ps aux                     # List all running processes";;
    df) example="df -h                      # Show disk space usage";;
    du) example="du -sh folder/             # Show folder size";;
    free) example="free -h                    # Show memory usage";;
    uname) example="uname -a                   # Show system information";;

    # Process Management
    kill) example="kill 1234                  # Terminate process with PID 1234";;
    pkill) example="pkill firefox              # Kill all firefox processes";;

    # System Control
    sudo) example="sudo apt update            # Run command as root";;
    systemctl) example="systemctl status nginx  # Check service status";;

    # Package Management
    apt) example="apt install package        # Install a package";;
    dpkg) example="dpkg -i package.deb        # Install .deb package";;

    # Misc
    echo) example="echo 'Hello World'         # Print text to screen";;
    date) example="date '+%Y-%m-%d'           # Show current date";;
    history) example="history                   # Show command history";;
    man) example="man ls                     # Show manual for 'ls' command";;
    *)
      # Generic fallback
      example="$cmd --help                 # Show help for $cmd"
      ;;
  esac

  echo "$example"
}

# Colorize syntax elements by type for instant recognition
# Returns raw string with ANSI codes (caller should use echo -e or printf %b)
colorize_syntax() {
  local syntax="$1"
  local colored_syntax="$syntax"

  # Color scheme for syntax elements:
  # - Command name (first word): Bright cyan + bold
  # - [OPTIONS], [OPTION], etc.: Yellow
  # - UPPERCASE args (FILE, STRING, SET1, etc.): Magenta
  # - Lowercase/optional args: Green
  # - ... (ellipsis): Dim white

  # Extract command name (first word) - escape special chars for sed
  local cmd_word=$(echo "$syntax" | awk '{print $1}' | sed 's/[]\/$*.^[]/\\&/g')

  # Start with command in themed primary + bold
  colored_syntax=$(echo "$syntax" | sed "s/^$cmd_word/${C_PRIMARY}${C_BOLD}$cmd_word${C_RESET}/")

  # Color [OPTIONS], [OPTION], [EXPRESSION], etc. in themed flag color
  colored_syntax=$(echo "$colored_syntax" | sed -E "s/\[([A-Z][A-Z_-]*)\]/[${C_FLAG}\1${C_RESET}]/g")

  # Color UPPERCASE arguments in themed accent (FILE, STRING, PATH, SET1, etc.)
  colored_syntax=$(echo "$colored_syntax" | sed -E "s/([[:space:]])([A-Z][A-Z0-9_-]*[A-Z])([[:space:][:punct:]$])/\1${C_ARG}\2${C_RESET}\3/g")

  # Color lowercase optional arguments in themed value color
  colored_syntax=$(echo "$colored_syntax" | sed -E "s/\[([a-z][a-z-]*)\]/[${C_OPT}\1${C_RESET}]/g")

  # Color ellipsis (...) dim
  colored_syntax=$(echo "$colored_syntax" | sed "s/\.\.\./${C_DIM}...${C_RESET}/g")

  # Return raw string (no echo -e, let caller handle interpretation)
  printf "%s" "$colored_syntax"
}

# Extract flags with descriptions from man pages
# New enhanced version that includes what each flag does
extract_all_flags() {
  local cmd_name="$1"
  local flags_output=""

  if type "$cmd_name" 2>/dev/null | grep -q "shell builtin"; then
    # Shell builtin - parse the "Options:" block from `help`, formatting each
    # entry as "flag — description" to match the man-page output below.
    flags_output=$(help "$cmd_name" 2>/dev/null | awk -v cf="$C_FLAGB" -v cd="$C_DIM" -v cr="$C_RESET" '
      /^[[:space:]]+-/ {
        line=$0; sub(/^[[:space:]]+/, "", line);
        if (match(line, /[ ][ ]+|\t/)) {
          flag=substr(line,1,RSTART-1);
          desc=substr(line,RSTART+RLENGTH); gsub(/^[[:space:]]+|[[:space:]]+$/,"",desc);
          printf "%s%s%s %s—%s %s\n", cf, flag, cr, cd, cr, desc;
        } else {
          printf "%s%s%s\n", cf, line, cr;
        }
      }')
  elif command -v "$cmd_name" &> /dev/null; then
    # External command - parse the FULL man page. Instead of reading a single
    # section (the old behaviour, which truncated curl/find/ps/git/tar/... to a
    # handful of flags), classify every section as option-bearing or not, then
    # extract every flag with its description across all option sections.
    # `col -bx` normalises tabs to spaces so indentation can be compared.
    local man_content=$(man "$cmd_name" 2>/dev/null | col -bx)

    if [ -n "$man_content" ]; then
      flags_output=$(printf '%s\n' "$man_content" | awk -v cf="$C_FLAGB" -v cd="$C_DIM" -v cr="$C_RESET" '
        { lines[++N]=$0; }
        END {
          # --- pre-pass: mark which sections actually contain option tags ---
          secid=0;
          for (i=1; i<=N; i++) {
            raw=lines[i];
            if (raw ~ /^[A-Z]/) { secid++; sname[secid]=fw(raw); }
            lsec[i]=secid;
            if (taglike(i)) tcount[secid]++;
          }
          for (s=1; s<=secid; s++)
            secscan[s] = (sname[s] ~ /^OPTION/ || tcount[s] >= 3) ? 1 : 0;

          # --- main pass: emit "flag — description" for every option ---
          flag=""; desc=""; curind=-1;
          for (i=1; i<=N; i++) {
            raw=lines[i];
            if (raw ~ /^[[:space:]]*$/) continue;                 # blank line
            if (raw ~ /^[A-Z]/) { flush(); curind=-1; continue; } # section header
            if (!secscan[lsec[i]]) continue;                      # skip prose sections
            ind = match(raw, /[^ ]/) - 1;
            t = raw; sub(/^[ ]+/, "", t);

            if (t ~ /^-/) {
              if (ncommaopt(t) >= 3) {                            # comma-list prose, not a tag
                if (flag != "" && ind > curind) adddesc(t);
                continue;
              }
              if (flag != "" && ind > curind) { adddesc(t); continue; }   # wrapped desc line
              if (flag != "" && desc == "" && ind == curind) {            # stacked alias
                if (match(t, /  +/)) { flag=flag", "substr(t,1,RSTART-1); desc=trim(substr(t,RSTART+RLENGTH)); }
                else                 { flag=flag", "t; }
                continue;
              }
              if (match(t, /  +/)) {                              # description on same line
                start_flag(substr(t,1,RSTART-1), trim(substr(t,RSTART+RLENGTH)), ind); continue;
              }
              j=i+1; while (j<=N && lines[j] ~ /^[[:space:]]*$/) j++;      # look ahead
              deeper = (j<=N && (match(lines[j],/[^ ]/)-1) > ind && trim(lines[j]) !~ /^-/);
              if (deeper) { start_flag(t, "", ind); continue; }   # description on next line(s)
              split_tag(t, ind); continue;                        # single-space inline desc
            }
            if (flag != "") adddesc(t);                           # description continuation
          }
          flush();
        }
        function fw(s,  w){ w=s; sub(/[[:space:]].*$/, "", w); return w; }
        function ncommaopt(s,  c,tmp){ tmp=s; c=gsub(/, +--?[A-Za-z]/, "", tmp); return c; }
        function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s; }
        function adddesc(s){ desc = (desc=="") ? trim(s) : desc" "trim(s); }
        function start_flag(sig, d, k){ flush(); flag=sig; desc=d; curind=k; }
        function taglike(i,  raw,t,ind,j,nind){
          raw=lines[i];
          if (raw !~ /^[ ]+-/) return 0;
          if (raw ~ /^[ ]+-{1,2}[A-Za-z0-9?][A-Za-z0-9?+._=-]*  /) return 1;
          ind = match(raw,/[^ ]/)-1;
          j=i+1; while (j<=N && lines[j] ~ /^[[:space:]]*$/) j++;
          if (j<=N) { nind=match(lines[j],/[^ ]/)-1; if (nind>ind && trim(lines[j]) !~ /^-/) return 1; }
          return 0;
        }
        function split_tag(s, k,   n,toks,p,tk,optend,sig,d){
          n=split(s,toks,/[ ]+/); optend=0;
          for (p=1;p<=n;p++){ tk=toks[p];
            if (tk ~ /^-/) { optend=p; continue; }
            if (tk ~ /^[A-Z0-9][A-Z0-9_<>|.=-]*[,]?$/) { optend=p; continue; }
            if (tk ~ /^[<\[]/) { optend=p; continue; }
            break;
          }
          if (optend==0) optend=1;
          sig=""; for(p=1;p<=optend;p++) sig=(sig=="")?toks[p]:sig" "toks[p];
          d="";   for(p=optend+1;p<=n;p++) d=(d=="")?toks[p]:d" "toks[p];
          start_flag(sig, d, k);
        }
        function flush(){
          if (flag != "") {
            desc=trim(desc);
            if (desc != "") printf "%s%s%s %s—%s %s\n", cf, flag, cr, cd, cr, desc;
            else printf "%s%s%s\n", cf, flag, cr;
          }
          flag=""; desc="";
        }
      ')
    fi

    # Fallback: nothing parsed (e.g. no man page) - grab raw flag lines
    if [ -z "$flags_output" ]; then
      flags_output=$(printf '%s\n' "$man_content" | grep -E '^[[:space:]]*-' | head -100)
    fi
  fi

  echo "$flags_output"
}

# Interactive flag browser with fuzzy search
# Now includes syntax and description in the fzf interface itself
browse_flags_fuzzy() {
  local cmd_name="$1"
  local cmd_syntax="$2"
  local cmd_desc="$3"

  # Extract all flags silently
  local all_flags=$(extract_all_flags "$cmd_name")

  if [ -z "$all_flags" ]; then
    echo ""
    echo -e "${RED}No flags found for: $cmd_name${NC}"
    echo ""
    return 1
  fi

  # Count flags
  local flag_count=$(echo "$all_flags" | wc -l)

  # Colorize the syntax for the header
  # colorize_syntax now returns raw \033 codes that printf %b will interpret
  local colored_syntax=$(colorize_syntax "$cmd_syntax")

  # Create multi-line header with command info using printf %b for proper escape code interpretation
  # Use actual ANSI codes for command and description, use %b for colored syntax
  local header
  printf -v header "╔═══════════════════════════════════════════════════════════════════════════════╗\n║ Command: ${C_PRIMARY}${C_BOLD}%s${C_RESET}\n║ Syntax:  %b\n║ Desc:    ${C_OPT}%s${C_RESET}\n╚═══════════════════════════════════════════════════════════════════════════════╝\n🔍 Fuzzy search %d flags | Multi-select: Ctrl-A/D | Esc: Back to menu" \
    "$cmd_name" \
    "$colored_syntax" \
    "$cmd_desc" \
    "$flag_count"

  # Export themed colors so the fzf preview subshell can use them
  export C_FLAGB C_OPT C_DIM C_RESET

  # Show in fzf with integrated command info and enhanced bottom display
  echo "$all_flags" | fzf \
    --height 95% \
    --border=none \
    --header "$header" \
    --preview 'line=$(echo {} | sed -E "s/\x1b\[[0-9;]*m//g");
               if echo "$line" | grep -qF " — "; then
                 flag=$(echo "$line" | awk -F " — " "{print \$1}" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//");
                 desc=$(echo "$line" | awk -F " — " "{for(i=2;i<=NF;i++) printf \"%s \", \$i; print \"\"}" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//");
               else
                 flag=$(echo "$line" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//");
                 desc="(No description available)";
               fi;
               if [ -z "$desc" ] || [ "$desc" = "$flag" ]; then
                 desc="(No description available)";
               fi;
               echo "┌─────────────────────────────────────────────────────────────────────────────┐";
               printf "│ 🏴  Flag:  ${C_FLAGB}%-66s${C_RESET}│\n" "$flag";
               echo "├─────────────────────────────────────────────────────────────────────────────┤";
               echo "│ 📝  Description:                                                            │";
               if [ "$desc" != "(No description available)" ]; then
                 echo "$desc" | fold -s -w 72 | while IFS= read -r dline; do
                   printf "│    ${C_OPT}%-72s${C_RESET}│\n" "$dline";
                 done;
               else
                 printf "│    ${C_DIM}%-72s${C_RESET}│\n" "$desc";
               fi;
               echo "└─────────────────────────────────────────────────────────────────────────────┘"' \
    --preview-window=down:8:wrap \
    --prompt "⚡ Search: " \
    --multi \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-d:deselect-all' \
    --ansi \
    --color=header:bold:cyan

  return 0
}

show_flags() {
  CMD_NAME=$1
  CMD_SYNTAX=$2
  CMD_DESC=$3

  # Extract syntax if not provided
  if [ -z "$CMD_SYNTAX" ]; then
    if type "$CMD_NAME" 2>/dev/null | grep -q "shell builtin"; then
      # For builtins, get the first line of help
      CMD_SYNTAX=$(help "$CMD_NAME" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')
      [ -z "$CMD_SYNTAX" ] && CMD_SYNTAX="$CMD_NAME [options]"
    else
      # For regular commands, extract SYNOPSIS section from man page
      local synopsis=$(man "$CMD_NAME" 2>/dev/null | col -b | sed -n '/^SYNOPSIS/,/^DESCRIPTION/p' | head -15 | tail -n +2 | sed '$d' | tr '\n' ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      if [ -n "$synopsis" ]; then
        CMD_SYNTAX="$synopsis"
      else
        # Fallback: try to get usage from command itself
        local usage=$("$CMD_NAME" --help 2>&1 | grep -i "usage" | head -1 | sed 's/^[Uu]sage: //')
        if [ -n "$usage" ]; then
          CMD_SYNTAX="$usage"
        else
          CMD_SYNTAX="$CMD_NAME [options]"
        fi
      fi
    fi
  fi

  # Default description if not provided
  [ -z "$CMD_DESC" ] && CMD_DESC="No description available"

  # Directly open fuzzy flag browser with integrated command info (no wasted space)
  browse_flags_fuzzy "$CMD_NAME" "$CMD_SYNTAX" "$CMD_DESC"

  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

list_commands() {
  echo "Available commands:"
  echo ""
  for cmd in "${COMMANDS[@]}"; do
    CMD_NAME=${cmd%%:*}
    REST=${cmd#*:}

    # Extract description (before pipe) and syntax (after pipe)
    if [[ "$REST" =~ (.+)\ \|\ (.+) ]]; then
      DESC="${BASH_REMATCH[1]}"
      SYNTAX="${BASH_REMATCH[2]}"
      printf "  %-10s - %-40s | %s\n" "$CMD_NAME" "$DESC" "$SYNTAX"
    else
      printf "  %-10s - %s\n" "$CMD_NAME" "$REST"
    fi
  done
}

get_command_description() {
  local search_cmd=$1
  for cmd in "${COMMANDS[@]}"; do
    CMD_NAME=${cmd%%:*}
    REST=${cmd#*:}
    if [ "$CMD_NAME" = "$search_cmd" ]; then
      # Extract just the description part (before the pipe)
      if [[ "$REST" =~ (.+)\ \|\ (.+) ]]; then
        echo "${BASH_REMATCH[1]}"
      else
        echo "$REST"
      fi
      return 0
    fi
  done
  echo "Command help"
}

# Command definitions for interactive mode (format: "cmd:Description | Syntax")
COMMANDS=(
  # File Operations
  "ls:List directory contents | ls [OPTION]... [FILE]..."
  "cd:Change the current directory | cd [DIRECTORY]"
  "pwd:Print the name of the current working directory | pwd [OPTION]"
  "cp:Copy files and directories | cp [OPTION]... SOURCE DEST"
  "mv:Move or rename files and directories | mv [OPTION]... SOURCE DEST"
  "rm:Remove files or directories | rm [OPTION]... FILE..."
  "mkdir:Create a new directory | mkdir [OPTION]... DIRECTORY..."
  "rmdir:Remove an empty directory | rmdir [OPTION]... DIRECTORY..."
  "touch:Create empty file or update timestamp | touch [OPTION]... FILE..."
  "cat:Concatenate and display files | cat [OPTION]... [FILE]..."
  "less:View file contents with pagination | less [OPTION]... [FILE]..."
  "head:Display first lines of a file | head [OPTION]... [FILE]..."
  "tail:Display last lines of a file | tail [OPTION]... [FILE]..."
  "chmod:Change file permissions | chmod [OPTION] MODE FILE..."
  "chown:Change file owner | chown [OPTION]... OWNER[:GROUP] FILE..."
  "ln:Create links between files | ln [OPTION]... TARGET LINK_NAME"
  "file:Determine file type | file [OPTION]... FILE..."
  "stat:Display file status | stat [OPTION]... FILE..."

  # Text Processing
  "grep:Search for patterns in files | grep [OPTION]... PATTERN [FILE]..."
  "sed:Stream editor for text manipulation | sed [OPTION]... SCRIPT [FILE]..."
  "awk:Pattern scanning and text processing | awk [OPTION]... PROGRAM [FILE]..."
  "cut:Remove sections from lines of files | cut [OPTION]... [FILE]..."
  "sort:Sort lines of text | sort [OPTION]... [FILE]..."
  "uniq:Report or filter out repeated lines | uniq [OPTION]... [FILE]..."
  "tr:Translate or delete characters | tr [OPTION]... SET1 [SET2]"
  "wc:Count lines, words, and characters | wc [OPTION]... [FILE]..."
  "diff:Compare files line by line | diff [OPTION]... FILE1 FILE2"

  # File Search
  "find:Search for files in directory hierarchy | find [PATH] [OPTIONS] [EXPRESSION]"
  "locate:Find files by name quickly | locate [OPTION]... PATTERN..."
  "which:Show full path of commands | which [OPTION]... COMMAND..."
  "whereis:Locate binary, source, and manual pages | whereis [OPTION]... COMMAND..."

  # Compression
  "tar:Archive files | tar [OPTION]... [FILE]..."
  "gzip:Compress files | gzip [OPTION]... [FILE]..."
  "gunzip:Decompress gzip files | gunzip [OPTION]... [FILE]..."
  "zip:Package and compress files | zip [OPTION]... ZIPFILE FILES..."
  "unzip:Extract compressed zip files | unzip [OPTION]... FILE..."

  # Network
  "ping:Test network connectivity | ping [OPTION]... HOST"
  "curl:Transfer data from URLs | curl [OPTION]... URL..."
  "wget:Download files from the web | wget [OPTION]... URL..."
  "ssh:Secure shell remote login | ssh [OPTION]... USER@HOST [COMMAND]"
  "scp:Secure copy files between hosts | scp [OPTION]... SOURCE DEST"
  "netstat:Network statistics | netstat [OPTION]..."
  "ss:Socket statistics | ss [OPTION]..."
  "ip:Show/manipulate routing and devices | ip [OPTION]... OBJECT {COMMAND}"
  "ifconfig:Configure network interfaces | ifconfig [INTERFACE] [OPTIONS]"

  # System Info
  "top:Display system processes | top [OPTION]..."
  "htop:Interactive process viewer | htop [OPTION]..."
  "ps:Report process status | ps [OPTION]..."
  "df:Show disk space usage | df [OPTION]... [FILE]..."
  "du:Estimate file space usage | du [OPTION]... [FILE]..."
  "free:Display memory usage | free [OPTION]..."
  "uname:Print system information | uname [OPTION]..."
  "uptime:Show how long system has been running | uptime [OPTION]..."

  # Process Management
  "kill:Send signal to a process | kill [OPTION]... PID..."
  "pkill:Kill processes by name | pkill [OPTION]... PATTERN"
  "killall:Kill processes by name | killall [OPTION]... NAME..."
  "bg:Put job in background | bg [JOB_SPEC]"
  "fg:Bring job to foreground | fg [JOB_SPEC]"
  "jobs:List active jobs | jobs [OPTION]..."

  # System Control
  "sudo:Execute command as another user | sudo [OPTION]... COMMAND"
  "systemctl:Control systemd services | systemctl [OPTION]... COMMAND"
  "service:Control system services | service COMMAND [OPTIONS]"
  "reboot:Reboot the system | reboot [OPTION]..."
  "shutdown:Shut down the system | shutdown [OPTION]... [TIME]"

  # Package Management
  "apt:Package manager (Debian/Ubuntu) | apt [OPTION]... COMMAND"
  "apt-get:APT package handling utility | apt-get [OPTION]... COMMAND"
  "dpkg:Debian package manager | dpkg [OPTION]... ACTION"
  "snap:Snap package manager | snap [OPTION]... COMMAND"

  # User Management
  "useradd:Create new user | useradd [OPTION]... LOGIN"
  "userdel:Delete user account | userdel [OPTION]... LOGIN"
  "passwd:Change user password | passwd [OPTION]... [USER]"
  "su:Switch user | su [OPTION]... [USER]"
  "whoami:Print current username | whoami"
  "w:Show who is logged in | w [OPTION]... [USER]"
  "who:Show who is logged in | who [OPTION]..."

  # Misc Utilities
  "echo:Display a line of text | echo [OPTION]... [STRING]..."
  "date:Display or set system date and time | date [OPTION]... [+FORMAT]"
  "cal:Display calendar | cal [OPTION]... [[MONTH] YEAR]"
  "history:Show command history | history [n]"
  "alias:Create command aliases | alias [NAME[=VALUE]...]"
  "export:Set environment variables | export [NAME[=VALUE]...]"
  "env:Display environment variables | env [OPTION]... [NAME=VALUE]... [COMMAND]"
  "man:Display manual pages | man [OPTION]... [SECTION] PAGE"
  "watch:Execute command periodically | watch [OPTION]... COMMAND"

  # File Operations (extended)
  "dd:Convert and copy a file (block-level) | dd if=SOURCE of=DEST [OPERAND]..."
  "shred:Overwrite a file to securely delete it | shred [OPTION]... FILE..."
  "truncate:Shrink or extend file size | truncate [OPTION]... -s SIZE FILE..."
  "mktemp:Create a temporary file or directory | mktemp [OPTION]... [TEMPLATE]"
  "mkfifo:Create a named pipe (FIFO) | mkfifo [OPTION]... NAME..."
  "install:Copy files and set attributes | install [OPTION]... SOURCE DEST"
  "basename:Strip directory and suffix from a path | basename NAME [SUFFIX]"
  "dirname:Strip last component from a path | dirname [OPTION] NAME..."
  "realpath:Print the resolved absolute path | realpath [OPTION]... FILE..."
  "readlink:Print resolved symbolic link target | readlink [OPTION]... FILE..."
  "tree:List directory contents as a tree | tree [OPTION]... [DIRECTORY]"
  "rsync:Fast incremental file transfer/sync | rsync [OPTION]... SOURCE DEST"
  "pushd:Push directory onto the stack | pushd [DIRECTORY]"
  "popd:Pop directory off the stack | popd [+N|-N]"
  "rename:Rename multiple files via pattern | rename [OPTION]... EXPRESSION FILE..."

  # Text Processing (extended)
  "tee:Read stdin and write to files and stdout | tee [OPTION]... [FILE]..."
  "tac:Concatenate and print files in reverse | tac [OPTION]... [FILE]..."
  "nl:Number lines of files | nl [OPTION]... [FILE]..."
  "fold:Wrap lines to a fixed width | fold [OPTION]... [FILE]..."
  "fmt:Reformat paragraph text | fmt [OPTION]... [FILE]..."
  "paste:Merge lines of files side by side | paste [OPTION]... [FILE]..."
  "join:Join lines of two files on a field | join [OPTION]... FILE1 FILE2"
  "comm:Compare two sorted files line by line | comm [OPTION]... FILE1 FILE2"
  "column:Format input into columns | column [OPTION]... [FILE]..."
  "expand:Convert tabs to spaces | expand [OPTION]... [FILE]..."
  "unexpand:Convert spaces to tabs | unexpand [OPTION]... [FILE]..."
  "rev:Reverse characters in each line | rev [OPTION]... [FILE]..."
  "split:Split a file into pieces | split [OPTION]... [FILE [PREFIX]]"
  "csplit:Split a file by context lines | csplit [OPTION]... FILE PATTERN..."
  "od:Dump files in octal/other formats | od [OPTION]... [FILE]..."
  "hexdump:Display file contents in hex | hexdump [OPTION]... [FILE]..."
  "xxd:Make a hexdump or reverse it | xxd [OPTION]... [FILE]"
  "strings:Print printable strings in a file | strings [OPTION]... [FILE]..."
  "iconv:Convert text between encodings | iconv [OPTION]... [FILE]..."
  "jq:Process and query JSON data | jq [OPTION]... FILTER [FILE]..."
  "pr:Paginate/columnate files for printing | pr [OPTION]... [FILE]..."
  "printf:Format and print data | printf FORMAT [ARGUMENT]..."

  # File Search (extended)
  "type:Describe how a command name is resolved | type [OPTION]... NAME..."
  "command:Run a command bypassing aliases | command [OPTION]... NAME [ARG]..."
  "apropos:Search the manual page names | apropos [OPTION]... KEYWORD..."
  "updatedb:Update the locate file database | updatedb [OPTION]..."
  "xargs:Build and execute commands from stdin | xargs [OPTION]... [COMMAND]"

  # Compression (extended)
  "bzip2:Compress files with bzip2 | bzip2 [OPTION]... [FILE]..."
  "bunzip2:Decompress bzip2 files | bunzip2 [OPTION]... [FILE]..."
  "xz:Compress files with xz/LZMA | xz [OPTION]... [FILE]..."
  "unxz:Decompress xz files | unxz [OPTION]... [FILE]..."
  "zcat:Print gzip-compressed files | zcat [OPTION]... [FILE]..."
  "zstd:Compress files with Zstandard | zstd [OPTION]... [FILE]..."
  "7z:7-Zip archive manager | 7z COMMAND [OPTION]... ARCHIVE [FILE]..."
  "cpio:Copy files to/from archives | cpio [OPTION]..."

  # Network (extended)
  "dig:DNS lookup utility | dig [OPTION]... [@SERVER] NAME [TYPE]"
  "nslookup:Query DNS records interactively | nslookup [OPTION]... [HOST] [SERVER]"
  "host:DNS lookup utility (simple) | host [OPTION]... NAME [SERVER]"
  "traceroute:Trace route packets take to a host | traceroute [OPTION]... HOST"
  "mtr:Combined traceroute and ping tool | mtr [OPTION]... HOST"
  "nc:Netcat - read/write network connections | nc [OPTION]... [HOST] [PORT]"
  "telnet:Connect to a host over Telnet | telnet [OPTION]... [HOST [PORT]]"
  "sftp:Secure file transfer over SSH | sftp [OPTION]... USER@HOST"
  "nmap:Network exploration and port scanner | nmap [OPTION]... TARGET..."
  "arp:Show/manipulate the ARP cache | arp [OPTION]..."
  "route:Show/manipulate the routing table | route [OPTION]..."
  "tcpdump:Capture and analyze network traffic | tcpdump [OPTION]... [EXPRESSION]"
  "iptables:Configure IPv4 packet filtering | iptables [OPTION]... CHAIN [RULE]"
  "ethtool:Query/control network driver settings | ethtool [OPTION]... DEVICE"
  "nmcli:Control NetworkManager from the CLI | nmcli [OPTION]... OBJECT {COMMAND}"
  "hostname:Show or set the system hostname | hostname [OPTION]... [NAME]"
  "whois:Look up domain/IP registration info | whois [OPTION]... OBJECT"
  "ssh-keygen:Generate/manage SSH keys | ssh-keygen [OPTION]..."

  # System Info (extended)
  "lscpu:Display CPU architecture information | lscpu [OPTION]..."
  "lsblk:List block devices | lsblk [OPTION]... [DEVICE]..."
  "lsusb:List USB devices | lsusb [OPTION]..."
  "lspci:List PCI devices | lspci [OPTION]..."
  "lsmod:Show status of kernel modules | lsmod"
  "lsof:List open files and the processes using them | lsof [OPTION]..."
  "vmstat:Report virtual memory statistics | vmstat [OPTION]... [DELAY [COUNT]]"
  "iostat:Report CPU and I/O statistics | iostat [OPTION]... [DELAY [COUNT]]"
  "dmidecode:Dump DMI/SMBIOS hardware table | dmidecode [OPTION]..."
  "dmesg:Print kernel ring buffer messages | dmesg [OPTION]..."
  "journalctl:Query the systemd journal | journalctl [OPTION]..."
  "timedatectl:Query/change system clock settings | timedatectl [OPTION]... [COMMAND]"
  "hostnamectl:Query/change system hostname | hostnamectl [OPTION]... [COMMAND]"
  "nproc:Print the number of processing units | nproc [OPTION]..."
  "sysctl:Read/modify kernel parameters | sysctl [OPTION]... [VARIABLE[=VALUE]]..."

  # Process Management (extended)
  "nice:Run a program with modified priority | nice [OPTION]... [COMMAND]"
  "renice:Alter priority of running processes | renice [OPTION]... PRIORITY PID..."
  "nohup:Run a command immune to hangups | nohup COMMAND [ARG]..."
  "disown:Remove jobs from the shell's job table | disown [OPTION]... [JOB]..."
  "pgrep:Find process IDs by name/attributes | pgrep [OPTION]... PATTERN"
  "pidof:Find the PID of a running program | pidof [OPTION]... PROGRAM..."
  "fuser:Identify processes using files/sockets | fuser [OPTION]... NAME..."
  "time:Time a command's execution | time [OPTION]... COMMAND"
  "timeout:Run a command with a time limit | timeout [OPTION]... DURATION COMMAND"
  "strace:Trace system calls and signals | strace [OPTION]... COMMAND"
  "ltrace:Trace library calls | ltrace [OPTION]... COMMAND"
  "at:Schedule a command for later | at [OPTION]... TIME"
  "crontab:Manage cron job schedules | crontab [OPTION]... [FILE]"
  "sleep:Pause for a specified duration | sleep NUMBER[SUFFIX]..."

  # System Control / Disk (extended)
  "mount:Mount a filesystem | mount [OPTION]... DEVICE DIR"
  "umount:Unmount a filesystem | umount [OPTION]... {DIR|DEVICE}"
  "fdisk:Manipulate disk partition tables | fdisk [OPTION]... DEVICE"
  "parted:Partition manipulation program | parted [OPTION]... [DEVICE [COMMAND]]"
  "mkfs:Build a Linux filesystem | mkfs [OPTION]... DEVICE"
  "fsck:Check and repair a filesystem | fsck [OPTION]... [DEVICE]..."
  "swapon:Enable devices/files for swapping | swapon [OPTION]... [DEVICE]"
  "swapoff:Disable swapping on devices/files | swapoff [OPTION]... [DEVICE]"
  "blkid:Locate/print block device attributes | blkid [OPTION]... [DEVICE]..."
  "sync:Flush filesystem buffers to disk | sync [OPTION]... [FILE]..."
  "modprobe:Add or remove kernel modules | modprobe [OPTION]... MODULE"
  "poweroff:Power off the machine | poweroff [OPTION]..."
  "ncdu:NCurses disk usage analyzer | ncdu [OPTION]... [DIRECTORY]"

  # Package Management (extended)
  "yum:Package manager (RHEL/CentOS) | yum [OPTION]... COMMAND"
  "dnf:Package manager (Fedora/RHEL) | dnf [OPTION]... COMMAND"
  "rpm:RPM package manager | rpm [OPTION]... PACKAGE..."
  "pacman:Package manager (Arch Linux) | pacman [OPTION]... [TARGET]..."
  "zypper:Package manager (openSUSE) | zypper [OPTION]... COMMAND"
  "flatpak:Manage Flatpak applications | flatpak [OPTION]... COMMAND"
  "pip:Python package installer | pip [OPTION]... COMMAND"
  "npm:Node.js package manager | npm [OPTION]... COMMAND"
  "apt-cache:Query the APT package cache | apt-cache [OPTION]... COMMAND"

  # User & Group Management (extended)
  "usermod:Modify a user account | usermod [OPTION]... LOGIN"
  "groupadd:Create a new group | groupadd [OPTION]... GROUP"
  "groupdel:Delete a group | groupdel [OPTION]... GROUP"
  "groupmod:Modify a group | groupmod [OPTION]... GROUP"
  "groups:Show groups a user belongs to | groups [USER]..."
  "id:Print user and group IDs | id [OPTION]... [USER]"
  "chage:Change user password expiry info | chage [OPTION]... LOGIN"
  "newgrp:Log in to a new group | newgrp [GROUP]"
  "last:Show last logged-in users | last [OPTION]... [NAME]..."
  "logname:Print the user's login name | logname"

  # Permissions & Security (extended)
  "umask:Set default file permission mask | umask [OPTION]... [MODE]"
  "chgrp:Change group ownership | chgrp [OPTION]... GROUP FILE..."
  "setfacl:Set file access control lists | setfacl [OPTION]... FILE..."
  "getfacl:Get file access control lists | getfacl [OPTION]... FILE..."
  "chattr:Change file attributes on Linux FS | chattr [OPTION]... [+-=MODE] FILE..."
  "lsattr:List file attributes on Linux FS | lsattr [OPTION]... [FILE]..."
  "gpg:Encrypt, sign, and manage keys | gpg [OPTION]... [FILE]..."
  "openssl:Cryptography and TLS toolkit | openssl COMMAND [OPTION]..."
  "md5sum:Compute/check MD5 checksums | md5sum [OPTION]... [FILE]..."
  "sha256sum:Compute/check SHA-256 checksums | sha256sum [OPTION]... [FILE]..."
  "sha1sum:Compute/check SHA-1 checksums | sha1sum [OPTION]... [FILE]..."
  "cksum:Compute CRC checksum and byte count | cksum [OPTION]... [FILE]..."
  "base64:Encode/decode data in base64 | base64 [OPTION]... [FILE]"

  # Shell & Scripting (extended)
  "read:Read a line into shell variables | read [OPTION]... [NAME]..."
  "test:Evaluate a conditional expression | test EXPRESSION"
  "eval:Evaluate arguments as a command | eval [ARG]..."
  "exec:Replace the shell with a command | exec [COMMAND [ARG]...]"
  "source:Execute commands from a file | source FILE [ARG]..."
  "set:Set shell options and positional params | set [OPTION]... [ARG]..."
  "unset:Unset shell variables or functions | unset [OPTION]... NAME..."
  "shift:Shift positional parameters | shift [N]"
  "getopts:Parse positional option arguments | getopts OPTSTRING NAME [ARG]..."
  "declare:Declare variables and attributes | declare [OPTION]... [NAME[=VALUE]]..."
  "trap:Run commands on signals/events | trap [OPTION]... [ARG] [SIGNAL]..."
  "ulimit:Set/show user resource limits | ulimit [OPTION]... [LIMIT]"
  "hash:Remember/show command locations | hash [OPTION]... [NAME]..."
  "true:Return a successful exit status | true"
  "false:Return an unsuccessful exit status | false"
  "seq:Print a sequence of numbers | seq [OPTION]... [FIRST [INC]] LAST"
  "yes:Repeatedly print a string | yes [STRING]..."
  "expr:Evaluate expressions | expr EXPRESSION"
  "bc:Arbitrary-precision calculator | bc [OPTION]... [FILE]..."
  "shuf:Generate random permutations | shuf [OPTION]... [FILE]"
  "factor:Print the prime factors of numbers | factor [NUMBER]..."

  # Terminal & Misc (extended)
  "clear:Clear the terminal screen | clear [OPTION]..."
  "reset:Reset the terminal to defaults | reset [OPTION]..."
  "tput:Query/set terminal capabilities | tput [OPTION]... CAPNAME [ARG]..."
  "stty:Change/print terminal line settings | stty [OPTION]... [SETTING]..."
  "tty:Print the terminal connected to stdin | tty [OPTION]..."
  "screen:Terminal multiplexer | screen [OPTION]... [COMMAND]"
  "tmux:Terminal multiplexer | tmux [OPTION]... [COMMAND]"
  "nano:Simple terminal text editor | nano [OPTION]... [FILE]..."
  "vim:Vi IMproved text editor | vim [OPTION]... [FILE]..."
  "xdg-open:Open a file/URL in the default app | xdg-open {FILE|URL}"
  "notify-send:Send a desktop notification | notify-send [OPTION]... TITLE [BODY]"
  "lolcat:Rainbow-colorize text output | lolcat [OPTION]... [FILE]..."
  "figlet:Render text as ASCII art banners | figlet [OPTION]... [MESSAGE]"
)

# Show a swatch + metadata for the active theme
sm_theme_preview() {
  echo ""
  echo -e "  ${CYAN}${BOLD}Super Man${NC} theme   ${DIM}seed${NC} ${MAGENTA}${SM_THEME_SEED}${NC}   ${DIM}harmony${NC} ${SM_SCHEME}   ${DIM}hue${NC} ${SM_HUE}°"
  echo ""
  echo -e "  ${CYAN}██ primary${NC}   ${BLUE}██ header${NC}   ${MAGENTA}██ accent${NC}   ${YELLOW}██ flags${NC}   ${GREEN}██ values${NC}"
  echo ""
  echo -e "  ${DIM}Reproduce${NC} super-man theme ${SM_THEME_SEED}      ${DIM}Reset${NC} super-man theme off"
  echo ""
}

# theme subcommand: random | <seed> | off | show
mode_theme() {
  local arg="$1"
  local quiet=false
  case "$2" in -q|--quiet) quiet=true;; esac
  case "$1" in -q|--quiet) quiet=true; arg="";; esac

  case "$arg" in
    off|none|reset|disable)
      rm -f "$SM_THEME_FILE"
      $quiet || echo -e "${YELLOW}Theme reset${NC} — back to default colors."
      return 0
      ;;
    show|current|status)
      if [ -f "$SM_THEME_FILE" ]; then
        sm_gen_theme "$(cat "$SM_THEME_FILE" 2>/dev/null)"
        sm_theme_preview
      else
        echo "No theme set (using default colors). Try: super-man theme random"
      fi
      return 0
      ;;
    ""|random|new|shuffle|next|rand)
      if ! _sm_truecolor; then
        echo "Your terminal doesn't advertise truecolor (COLORTERM unset)."
        echo "Themes need 24-bit color. Try a modern terminal, or export COLORTERM=truecolor."
        return 1
      fi
      sm_gen_theme
      ;;
    *)
      # Treat anything else as an explicit seed (reproducible theme)
      sm_gen_theme "$arg"
      ;;
  esac

  mkdir -p "$SM_THEME_DIR"
  printf '%s\n' "$SM_THEME_SEED" > "$SM_THEME_FILE"
  $quiet && return 0
  sm_theme_preview
}

# Parse arguments
MODE=""
QUERY=""
INTERACTIVE=false
COMMAND=""
FILTER=""

if [ $# -eq 0 ]; then
  INTERACTIVE=true
else
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -l|--list)
      list_commands
      exit 0
      ;;
    -i|--interactive)
      INTERACTIVE=true
      ;;
    ask)
      MODE="ask"
      QUERY="$2"
      ;;
    task)
      MODE="task"
      QUERY="$2"
      ;;
    explain)
      MODE="explain"
      QUERY="$2"
      ;;
    category)
      MODE="category"
      QUERY="$2"
      ;;
    ai)
      shift
      mode_ai "$@"
      exit $?
      ;;
    theme)
      shift
      mode_theme "$@"
      exit $?
      ;;
    --emit-list)
      EMIT_LIST=true
      ;;
    -*)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
    *)
      COMMAND=$1
      FILTER=$2
      ;;
  esac
fi

# Handle new modes
if [ -n "$MODE" ]; then
  case "$MODE" in
    ask|task)
      mode_ask "$QUERY"
      exit $?
      ;;
    explain)
      mode_explain "$QUERY"
      exit $?
      ;;
    category)
      mode_category "$QUERY"
      exit $?
      ;;
  esac
fi

# Format commands for display - called once and cached for performance
format_commands_for_display() {
  # Get terminal width for proper alignment
  local term_width=$(tput cols 2>/dev/null || echo 120)

  # Conservative approach to prevent ANY clipping
  # Account for fzf border, padding, and any other overhead
  local safe_width=$((term_width - 6))  # 2 for border + 4 buffer for safety

  # Fixed 2-column layout: description on left, syntax on right
  # Prioritize syntax visibility - give it 50% of space
  local syntax_col_width=$((safe_width * 50 / 100))
  [ $syntax_col_width -lt 30 ] && syntax_col_width=30

  # Description gets the rest (with separator space)
  local desc_col_width=$((safe_width - syntax_col_width - 8))
  [ $desc_col_width -lt 25 ] && desc_col_width=25

  # Format all commands with fixed column widths
  FORMATTED_COMMANDS=()
  for cmd in "${COMMANDS[@]}"; do
    local cmd_name=${cmd%%:*}
    local rest=${cmd#*:}

    # Extract description and syntax
    local desc_part syntax_part
    if [[ "$rest" =~ (.+)\ \|\ (.+) ]]; then
      desc_part="${BASH_REMATCH[1]}"
      syntax_part="${BASH_REMATCH[2]}"
    else
      desc_part="$rest"
      syntax_part="$cmd_name [options]"
    fi

    # Truncate description to fit column (cmd: + desc)
    local cmd_desc_str="${cmd_name}: ${desc_part}"
    local max_cmd_desc_len=$desc_col_width

    if [ ${#cmd_desc_str} -gt $max_cmd_desc_len ]; then
      # Truncate description, keeping command name intact
      local desc_available=$((max_cmd_desc_len - ${#cmd_name} - 5))  # 2 for ": ", 3 for "..."
      if [ $desc_available -gt 10 ]; then
        desc_part="${desc_part:0:$desc_available}..."
      else
        desc_part="..."
      fi
      cmd_desc_str="${cmd_name}: ${desc_part}"
    fi

    # Truncate syntax to fit its column
    local plain_syntax="$syntax_part"
    if [ ${#syntax_part} -gt $syntax_col_width ]; then
      plain_syntax="${syntax_part:0:$((syntax_col_width-3))}..."
    fi

    # Colorize syntax after truncation
    local colorized_syntax=$(colorize_syntax "$plain_syntax")

    # Calculate padding to place syntax in its column
    local left_len=${#cmd_desc_str}
    local syntax_len=${#plain_syntax}

    # Place syntax at fixed position (right-aligned within safe width)
    local padding=$((safe_width - left_len - syntax_len - 2))
    [ $padding -lt 3 ] && padding=3

    local spaces=$(printf '%*s' "$padding" '')

    # Format line with colors (themed primary for the command name)
    local formatted_line="${CYAN}${cmd_name}${NC}: ${desc_part}${spaces}${colorized_syntax}"

    FORMATTED_COMMANDS+=("$formatted_line")
  done
}

# Hidden helper: emit the colored command list (used by the fzf Ctrl-T theme reload)
if [ "$EMIT_LIST" = true ]; then
  format_commands_for_display
  printf "%b\n" "${FORMATTED_COMMANDS[@]}"
  exit 0
fi

# Interactive mode with fzf (loopable)
if [ "$INTERACTIVE" = true ]; then
  # Check if fzf is available
  if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed"
    echo "Install it with:"
    echo "  Debian/Ubuntu: sudo apt install fzf"
    echo "  macOS:         brew install fzf"
    echo "  Fedora/RHEL:   sudo dnf install fzf"
    echo "  Arch:          sudo pacman -S fzf"
    echo ""
    echo "Or use direct mode: super-man COMMAND [FILTER]"
    exit 1
  fi

  # Format commands once before entering loop (performance optimization)
  format_commands_for_display

  # Set up window resize detection to trigger reformatting
  NEEDS_REFORMAT=false
  trap 'NEEDS_REFORMAT=true' WINCH

  # Main interactive loop
  while true; do
    # Reformat commands if terminal was resized
    if [ "$NEEDS_REFORMAT" = true ]; then
      format_commands_for_display
      NEEDS_REFORMAT=false
    fi

    # Show in fzf with formatted display
    SELECTED=$(printf "%b\n" "${FORMATTED_COMMANDS[@]}" | fzf \
      --height 60% \
      --border \
      --header "Select a command (Esc to exit) | Ctrl-T: shuffle theme 🎨" \
      --prompt "🔍 Search: " \
      --preview-window=hidden \
      --bind "ctrl-t:execute($SM_SELF theme random -q)+reload($SM_SELF --emit-list)" \
      --ansi)

    if [ -z "$SELECTED" ]; then
      # User pressed Esc or cancelled
      echo ""
      echo -e "${YELLOW}Exiting Super Man. Happy coding! 👋${NC}"
      exit 0
    fi

    # Extract command name from selection (strip color codes)
    CMD=$(echo "$SELECTED" | sed 's/\x1b\[[0-9;]*m//g' | awk -F: '{print $1}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    # Find the original command entry to get full details
    for cmd in "${COMMANDS[@]}"; do
      CMD_NAME=${cmd%%:*}
      if [ "$CMD_NAME" = "$CMD" ]; then
        REST=${cmd#*:}

        # Extract description and syntax
        if [[ "$REST" =~ (.+)\ \|\ (.+) ]]; then
          DESC="${BASH_REMATCH[1]}"
          SYNTAX="${BASH_REMATCH[2]}"
        else
          DESC="$REST"
          SYNTAX="$CMD [options]"
        fi
        break
      fi
    done

    # Directly show fuzzy flag browser with integrated command info (no wasted space)
    clear
    show_flags "$CMD" "$SYNTAX" "$DESC"

    # Esc in the flag browser returns straight to the home menu (no intermediary step)
    clear
  done
# Direct mode
elif [ -n "$COMMAND" ]; then
  # Validate command exists in our list
  FOUND=false
  DESC_PART=""
  SYNTAX_PART=""

  for cmd in "${COMMANDS[@]}"; do
    CMD_NAME=${cmd%%:*}
    if [ "$CMD_NAME" = "$COMMAND" ]; then
      FOUND=true
      REST=${cmd#*:}

      # Extract description and syntax
      if [[ "$REST" =~ (.+)\ \|\ (.+) ]]; then
        DESC_PART="${BASH_REMATCH[1]}"
        SYNTAX_PART="${BASH_REMATCH[2]}"
      else
        DESC_PART="$REST"
        SYNTAX_PART="$COMMAND [options]"
      fi
      break
    fi
  done

  if [ "$FOUND" = false ]; then
    echo "Warning: '$COMMAND' is not in the predefined list"
    echo "Available commands:"
    list_commands
    echo ""
    echo "Attempting to show flags anyway..."
    echo ""
    DESC_PART=$(get_command_description "$COMMAND")
    SYNTAX_PART="$COMMAND [options]"
  fi

  # Show command info in enhanced format
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}Command:${NC} ${MAGENTA}$COMMAND${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${CYAN}${BOLD}SYNTAX:${NC}"
  echo -e "  ${GREEN}$SYNTAX_PART${NC}"
  echo ""
  echo -e "${GREEN}Description:${NC} $DESC_PART"
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  show_flags "$COMMAND" "$FILTER"
else
  show_help
  exit 1
fi
