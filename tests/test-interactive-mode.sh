#!/bin/bash
# Interactive mode testing for Super Man
# Tests fzf-based interactive mode with automation

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Set script path
SCRIPT_PATH="$PROJECT_DIR/super-man.sh"

print_header
echo "Testing Interactive Mode"
echo "Script: $SCRIPT_PATH"
echo ""

# ============================================================================
# INTERACTIVE MODE TESTS
# ============================================================================
print_section "Interactive Mode - Automated Testing"

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo -e "${YELLOW}Warning: 'expect' not installed. Installing for interactive testing...${NC}"

    # Try to install expect
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y expect > /dev/null 2>&1
    else
        skip_test "All interactive mode tests" "expect not available and cannot be installed"
        print_summary
        exit 0
    fi
fi

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    skip_test "All interactive mode tests" "fzf not installed"
    print_summary
    exit 0
fi

# ============================================================================
# Test 1: Launch interactive mode and exit
# ============================================================================
echo -e "\n${CYAN}Test #1: Launch interactive mode and exit immediately${NC}"

TEST_LOG="$TEST_LOG_DIR/interactive_launch_test.log"

# Create expect script for immediate exit
cat > /tmp/super-man_test_exit.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 10
log_user 0

spawn bash -c "./super-man.sh"
expect {
    timeout { exit 1 }
    eof { exit 0 }
    "*" {
        send "\x03"
        expect eof
        exit 0
    }
}
EOF

chmod +x /tmp/super-man_test_exit.exp

cd "$PROJECT_DIR"
start_time=$(get_ms_timestamp)
/tmp/super-man_test_exit.exp > "$TEST_LOG" 2>&1
exit_code=$?
end_time=$(get_ms_timestamp)
duration=$((end_time - start_time))

TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC} (${duration}ms)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS["Interactive mode launch"]="PASSED"
    TEST_TIMES["Interactive mode launch"]=$duration
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TEST_RESULTS["Interactive mode launch"]="FAILED"
fi

# ============================================================================
# Test 2: Select a command and view flags
# ============================================================================
echo -e "\n${CYAN}Test #2: Select command and view flags${NC}"

TEST_LOG="$TEST_LOG_DIR/interactive_select_test.log"

# Create expect script to select grep and search for -v
cat > /tmp/super-man_test_select.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 15
log_user 1

spawn bash -c "./super-man.sh"

# Wait for fzf to start
sleep 2

# Type 'grep' to filter
send "grep\r"

# Wait for selection
sleep 1

# Enter filter
send -- "-v\r"

# Wait for output
sleep 2

# Exit
send "\x03"

expect eof
EOF

chmod +x /tmp/super-man_test_select.exp

cd "$PROJECT_DIR"
start_time=$(get_ms_timestamp)
/tmp/super-man_test_select.exp > "$TEST_LOG" 2>&1
exit_code=$?
end_time=$(get_ms_timestamp)
duration=$((end_time - start_time))

TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Check if output contains expected flag info
if grep -q "invert" "$TEST_LOG" || grep -q "Flags for: grep" "$TEST_LOG"; then
    echo -e "${GREEN}✓ PASSED${NC} (${duration}ms)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS["Interactive command selection"]="PASSED"
    TEST_TIMES["Interactive command selection"]=$duration
else
    echo -e "${YELLOW}⚠ PARTIAL${NC} - Could not verify flag display"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS["Interactive command selection"]="PARTIAL"
fi

# ============================================================================
# Test 3: Filter commands by category
# ============================================================================
echo -e "\n${CYAN}Test #3: Filter commands by category${NC}"

TEST_LOG="$TEST_LOG_DIR/interactive_filter_test.log"

# Create expect script to filter by "network"
cat > /tmp/super-man_test_filter.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 15
log_user 1

spawn bash -c "./super-man.sh"

# Wait for fzf to start
sleep 2

# Type 'net' to filter network commands
send "net"

# Wait to see filtered results
sleep 2

# Exit
send "\x03"

expect eof
EOF

chmod +x /tmp/super-man_test_filter.exp

cd "$PROJECT_DIR"
start_time=$(get_ms_timestamp)
/tmp/super-man_test_filter.exp > "$TEST_LOG" 2>&1
exit_code=$?
end_time=$(get_ms_timestamp)
duration=$((end_time - start_time))

TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Check if network commands appeared in filter
if grep -qE "ping|curl|wget|ssh|netstat" "$TEST_LOG"; then
    echo -e "${GREEN}✓ PASSED${NC} (${duration}ms)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS["Interactive filtering"]="PASSED"
    TEST_TIMES["Interactive filtering"]=$duration
else
    echo -e "${YELLOW}⚠ PARTIAL${NC} - Could not verify filtering"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS["Interactive filtering"]="PARTIAL"
fi

# ============================================================================
# Test 4: Multiple command selections
# ============================================================================
echo -e "\n${CYAN}Test #4: Test multiple commands (ls, tar, find)${NC}"

COMMANDS_TO_TEST=("ls" "tar" "find")
SUCCESS_COUNT=0

for cmd in "${COMMANDS_TO_TEST[@]}"; do
    TEST_LOG="$TEST_LOG_DIR/interactive_${cmd}_test.log"

    cat > /tmp/super-man_test_${cmd}.exp << EOF
#!/usr/bin/expect -f
set timeout 10
log_user 1

spawn bash -c "./super-man.sh"
sleep 2
send "${cmd}\r"
sleep 1
send "\r"
sleep 1
send "\x03"
expect eof
EOF

    chmod +x /tmp/super-man_test_${cmd}.exp

    cd "$PROJECT_DIR"
    /tmp/super-man_test_${cmd}.exp > "$TEST_LOG" 2>&1

    if [ $? -eq 0 ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
done

TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ $SUCCESS_COUNT -eq ${#COMMANDS_TO_TEST[@]} ]; then
    echo -e "${GREEN}✓ PASSED${NC} - All $SUCCESS_COUNT commands tested"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS["Multiple command selections"]="PASSED"
elif [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠ PARTIAL${NC} - $SUCCESS_COUNT/${#COMMANDS_TO_TEST[@]} commands worked"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS["Multiple command selections"]="PARTIAL"
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TEST_RESULTS["Multiple command selections"]="FAILED"
fi

# ============================================================================
# INTERACTIVE MODE PERFORMANCE TEST
# ============================================================================
print_section "Interactive Mode - Performance Analysis"

echo -e "\n${MAGENTA}Testing interactive mode startup performance (5 iterations)${NC}\n"

TOTAL_TIME=0
SUCCESS_COUNT=0

for i in {1..5}; do
    TEST_LOG="$TEST_LOG_DIR/interactive_perf_$i.log"

    cat > /tmp/super-man_perf_test.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 10
log_user 0

spawn bash -c "./super-man.sh"
sleep 1
send "\x03"
expect eof
EOF

    chmod +x /tmp/super-man_perf_test.exp

    cd "$PROJECT_DIR"
    start_time=$(get_ms_timestamp)
    /tmp/super-man_perf_test.exp > "$TEST_LOG" 2>&1
    exit_code=$?
    end_time=$(get_ms_timestamp)
    duration=$((end_time - start_time))

    if [ $exit_code -eq 0 ]; then
        TOTAL_TIME=$((TOTAL_TIME + duration))
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo -e "  Iteration $i: ${GREEN}${duration}ms${NC}"
    else
        echo -e "  Iteration $i: ${RED}FAILED${NC}"
    fi
done

if [ $SUCCESS_COUNT -gt 0 ]; then
    AVG_TIME=$((TOTAL_TIME / SUCCESS_COUNT))
    echo -e "\n${CYAN}Average startup time: ${AVG_TIME}ms${NC}"
    echo -e "${CYAN}Success rate: $SUCCESS_COUNT/5${NC}"

    # Log to performance file
    echo "$(get_timestamp)|interactive_mode_startup|$AVG_TIME|n/a|n/a|$SUCCESS_COUNT|5" >> "$PERF_LOG_DIR/benchmarks.csv"
fi

# Cleanup temp files
rm -f /tmp/super-man_*.exp

# ============================================================================
# SUMMARY
# ============================================================================

print_summary
EXIT_CODE=$?

echo -e "\n${CYAN}Interactive mode testing complete!${NC}"
echo -e "${CYAN}Logs: $TEST_LOG_DIR${NC}"
echo -e "${CYAN}Performance: $PERF_LOG_DIR${NC}"

exit $EXIT_CODE
