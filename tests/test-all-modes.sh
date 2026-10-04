#!/bin/bash
# Comprehensive test suite for all Super Man operating modes
# Tests all non-interactive modes with performance analysis

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Set script path
SCRIPT_PATH="$PROJECT_DIR/super-man.sh"

# Verify script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: super-man.sh not found at $SCRIPT_PATH${NC}"
    exit 1
fi

# Initialize
print_header
init_perf_log

echo "Testing script: $SCRIPT_PATH"
echo "Test logs: $TEST_LOG_DIR"
echo ""

# ============================================================================
# TEST SUITE: HELP & INFORMATIONAL MODES
# ============================================================================
print_section "Help & Informational Modes"

run_test_with_output_check \
    "Help display (--help)" \
    "$SCRIPT_PATH --help" \
    "Super Man"

run_test_with_output_check \
    "Help display (-h)" \
    "$SCRIPT_PATH -h" \
    "QUICK START"

run_test_with_output_check \
    "List all commands (--list)" \
    "$SCRIPT_PATH --list" \
    "Available commands"

run_test_with_output_check \
    "List all commands (-l)" \
    "$SCRIPT_PATH -l" \
    "commands"

# ============================================================================
# TEST SUITE: NATURAL LANGUAGE QUERY MODES
# ============================================================================
print_section "Natural Language Query Modes"

# Ask mode tests
run_test_with_output_check \
    "Ask mode - find large files" \
    "$SCRIPT_PATH ask 'find large files'" \
    "find"

run_test_with_output_check \
    "Ask mode - compress folder" \
    "$SCRIPT_PATH ask 'compress folder'" \
    "tar"

run_test_with_output_check \
    "Ask mode - disk usage" \
    "$SCRIPT_PATH ask 'disk usage'" \
    "du"

run_test_with_output_check \
    "Ask mode - search text" \
    "$SCRIPT_PATH ask 'search text'" \
    "grep"

run_test_with_output_check \
    "Ask mode - symlink" \
    "$SCRIPT_PATH ask 'symlink'" \
    "ln -s"

# Task mode tests (alias for ask)
run_test_with_output_check \
    "Task mode - find files" \
    "$SCRIPT_PATH task 'find files'" \
    "find"

run_test_with_output_check \
    "Task mode - network" \
    "$SCRIPT_PATH task 'network'" \
    "ping\|curl\|wget"

# ============================================================================
# TEST SUITE: CATEGORY BROWSING
# ============================================================================
print_section "Category Browsing"

run_test_with_output_check \
    "Category - files" \
    "$SCRIPT_PATH category files" \
    "File Operations"

run_test_with_output_check \
    "Category - text" \
    "$SCRIPT_PATH category text" \
    "Text Processing"

run_test_with_output_check \
    "Category - network" \
    "$SCRIPT_PATH category network" \
    "Network Operations"

run_test_with_output_check \
    "Category - system" \
    "$SCRIPT_PATH category system" \
    "System Monitoring"

run_test_with_output_check \
    "Category - list all (no argument)" \
    "$SCRIPT_PATH category" \
    "Available categories"

run_test \
    "Category - invalid category" \
    "$SCRIPT_PATH category invalid_category" \
    1

# ============================================================================
# TEST SUITE: COMMAND EXPLANATION
# ============================================================================
print_section "Command Explanation"

run_test_with_output_check \
    "Explain - tar command" \
    "$SCRIPT_PATH explain 'tar -czf archive.tar.gz folder/'" \
    "tar"

run_test_with_output_check \
    "Explain - find command" \
    "$SCRIPT_PATH explain 'find . -name \"*.txt\"'" \
    "find"

run_test_with_output_check \
    "Explain - grep command" \
    "$SCRIPT_PATH explain 'grep -r \"pattern\" .'" \
    "grep"

run_test_with_output_check \
    "Explain - simple command" \
    "$SCRIPT_PATH explain 'ls -la'" \
    "ls"

# ============================================================================
# TEST SUITE: DIRECT FLAG LOOKUP
# ============================================================================
print_section "Direct Flag Lookup"

run_test_with_output_check \
    "Direct lookup - ls size" \
    "$SCRIPT_PATH ls size" \
    "size\|SIZE"

run_test_with_output_check \
    "Direct lookup - grep -v" \
    "$SCRIPT_PATH grep -v" \
    "invert"

run_test_with_output_check \
    "Direct lookup - tar extract" \
    "$SCRIPT_PATH tar extract" \
    "extract"

run_test_with_output_check \
    "Direct lookup - find name" \
    "$SCRIPT_PATH find name" \
    "name"

run_test_with_output_check \
    "Direct lookup - df human" \
    "$SCRIPT_PATH df human" \
    "human"

# Test without filter
run_test_with_output_check \
    "Direct lookup - ls (no filter)" \
    "$SCRIPT_PATH ls" \
    "ls"

# ============================================================================
# TEST SUITE: AI MODE (if Ollama available)
# ============================================================================
print_section "AI Mode"

# Check if Ollama is available
if command -v ollama &> /dev/null; then
    # Check if NL2SH model is available
    if ollama list | grep -q "westenfelder/NL2SH"; then
        run_test_with_output_check \
            "AI mode - find python files" \
            "$SCRIPT_PATH ai 'find all python files'" \
            "find" \
            30

        run_test_with_output_check \
            "AI mode - compress logs" \
            "$SCRIPT_PATH ai 'compress all log files'" \
            "tar\|gzip\|zip" \
            30

        run_test_with_output_check \
            "AI mode - disk usage" \
            "$SCRIPT_PATH ai 'show disk usage by directory'" \
            "du\|df" \
            30
    else
        skip_test "AI mode tests" "NL2SH model not installed"
    fi
else
    skip_test "AI mode tests" "Ollama not available"
fi

# ============================================================================
# TEST SUITE: ERROR HANDLING
# ============================================================================
print_section "Error Handling"

run_test \
    "Invalid mode" \
    "$SCRIPT_PATH invalid_mode 'test'" \
    1

run_test_with_output_check \
    "Empty query to ask mode" \
    "$SCRIPT_PATH ask ''" \
    "Error\|Usage"

run_test_with_output_check \
    "Empty query to explain mode" \
    "$SCRIPT_PATH explain ''" \
    "Error\|Usage"

# ============================================================================
# TEST SUITE: EDGE CASES
# ============================================================================
print_section "Edge Cases"

run_test_with_output_check \
    "Query with special characters" \
    "$SCRIPT_PATH ask 'find *.txt files'" \
    "find"

run_test_with_output_check \
    "Very long query" \
    "$SCRIPT_PATH ask 'find all files larger than 100MB that were modified in the last week and contain specific text patterns'" \
    "find"

run_test_with_output_check \
    "Query with quotes" \
    "$SCRIPT_PATH ask \"search for 'pattern' in files\"" \
    "grep"

run_test_with_output_check \
    "Multiple word filter" \
    "$SCRIPT_PATH ls sort by" \
    "sort"

# ============================================================================
# PERFORMANCE BENCHMARKS
# ============================================================================
print_section "Performance Benchmarks"

echo -e "\n${MAGENTA}${BOLD}Running performance benchmarks (10 iterations each)${NC}\n"

run_benchmark \
    "Ask mode - find large files" \
    "$SCRIPT_PATH ask 'find large files'" \
    10

run_benchmark \
    "Category - files" \
    "$SCRIPT_PATH category files" \
    10

run_benchmark \
    "Explain - tar command" \
    "$SCRIPT_PATH explain 'tar -czf'" \
    10

run_benchmark \
    "Direct lookup - ls size" \
    "$SCRIPT_PATH ls size" \
    10

run_benchmark \
    "Help display" \
    "$SCRIPT_PATH --help" \
    10

run_benchmark \
    "List commands" \
    "$SCRIPT_PATH --list" \
    10

# ============================================================================
# GENERATE REPORTS
# ============================================================================

# Print summary
print_summary

# Save summary exit code
EXIT_CODE=$?

echo -e "${CYAN}Test execution complete!${NC}"
echo -e "${CYAN}View detailed logs in: $TEST_LOG_DIR${NC}"
echo -e "${CYAN}View performance data in: $PERF_LOG_DIR${NC}"

exit $EXIT_CODE
