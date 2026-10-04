#!/bin/bash
# Super Man Test Framework
# Provides utilities for testing all operating modes with performance analysis

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test statistics
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Performance tracking
declare -A TEST_TIMES
declare -A TEST_RESULTS

# Configuration
TEST_LOG_DIR="./tests/logs"
PERF_LOG_DIR="./tests/performance"
SCRIPT_PATH="./super-man.sh"

# Create directories
mkdir -p "$TEST_LOG_DIR"
mkdir -p "$PERF_LOG_DIR"

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get milliseconds timestamp
get_ms_timestamp() {
    date '+%s%3N'
}

# Print test header
print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Super Man Test Suite"
    echo "  $(get_timestamp)"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Print test section
print_section() {
    local section_name="$1"
    echo -e "\n${BOLD}${BLUE}▶ Testing: $section_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run a test with timing
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    local timeout="${4:-10}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -e "\n${CYAN}Test #$TOTAL_TESTS: $test_name${NC}"

    # Create log file for this test
    local log_file="$TEST_LOG_DIR/test_${TOTAL_TESTS}_$(echo "$test_name" | tr ' ' '_' | tr -cd '[:alnum:]_').log"

    # Measure execution time
    local start_time=$(get_ms_timestamp)

    # Run the command with timeout
    timeout "$timeout" bash -c "$test_command" > "$log_file" 2>&1
    local exit_code=$?

    local end_time=$(get_ms_timestamp)
    local duration=$((end_time - start_time))

    # Store timing
    TEST_TIMES["$test_name"]=$duration

    # Check result
    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}✗ TIMEOUT${NC} (>${timeout}s)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS["$test_name"]="TIMEOUT"
        return 1
    elif [ $exit_code -eq $expected_exit_code ]; then
        echo -e "${GREEN}✓ PASSED${NC} (${duration}ms)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS["$test_name"]="PASSED"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} (exit code: $exit_code, expected: $expected_exit_code)"
        echo -e "${YELLOW}  Log: $log_file${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS["$test_name"]="FAILED"
        return 1
    fi
}

# Run a test and check output contains expected string
run_test_with_output_check() {
    local test_name="$1"
    local test_command="$2"
    local expected_string="$3"
    local timeout="${4:-10}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -e "\n${CYAN}Test #$TOTAL_TESTS: $test_name${NC}"

    # Create log file for this test
    local log_file="$TEST_LOG_DIR/test_${TOTAL_TESTS}_$(echo "$test_name" | tr ' ' '_' | tr -cd '[:alnum:]_').log"

    # Measure execution time
    local start_time=$(get_ms_timestamp)

    # Run the command with timeout
    timeout "$timeout" bash -c "$test_command" > "$log_file" 2>&1
    local exit_code=$?

    local end_time=$(get_ms_timestamp)
    local duration=$((end_time - start_time))

    # Store timing
    TEST_TIMES["$test_name"]=$duration

    # Check if output contains expected string
    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}✗ TIMEOUT${NC} (>${timeout}s)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS["$test_name"]="TIMEOUT"
        return 1
    elif grep -q "$expected_string" "$log_file"; then
        echo -e "${GREEN}✓ PASSED${NC} (${duration}ms) - Output contains: \"$expected_string\""
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS["$test_name"]="PASSED"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} - Output does not contain: \"$expected_string\""
        echo -e "${YELLOW}  Log: $log_file${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS["$test_name"]="FAILED"
        return 1
    fi
}

# Run a performance benchmark
run_benchmark() {
    local bench_name="$1"
    local bench_command="$2"
    local iterations="${3:-10}"

    echo -e "\n${MAGENTA}Benchmark: $bench_name${NC} (${iterations} iterations)"

    local total_time=0
    local min_time=999999
    local max_time=0
    local success_count=0

    for i in $(seq 1 $iterations); do
        local start_time=$(get_ms_timestamp)
        timeout 30 bash -c "$bench_command" > /dev/null 2>&1
        local exit_code=$?
        local end_time=$(get_ms_timestamp)
        local duration=$((end_time - start_time))

        if [ $exit_code -eq 0 ]; then
            success_count=$((success_count + 1))
            total_time=$((total_time + duration))

            if [ $duration -lt $min_time ]; then
                min_time=$duration
            fi

            if [ $duration -gt $max_time ]; then
                max_time=$duration
            fi
        fi

        # Progress indicator
        echo -n "."
    done

    echo "" # newline after dots

    if [ $success_count -gt 0 ]; then
        local avg_time=$((total_time / success_count))
        echo -e "${GREEN}  Average: ${avg_time}ms${NC}"
        echo -e "${CYAN}  Min: ${min_time}ms | Max: ${max_time}ms${NC}"
        echo -e "${YELLOW}  Success rate: $success_count/$iterations${NC}"

        # Log to performance file
        echo "$(get_timestamp)|$bench_name|$avg_time|$min_time|$max_time|$success_count|$iterations" >> "$PERF_LOG_DIR/benchmarks.csv"
    else
        echo -e "${RED}  All iterations failed${NC}"
    fi
}

# Print test summary
print_summary() {
    echo -e "\n${BOLD}${CYAN}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"

    echo -e "${BOLD}Results:${NC}"
    echo -e "  Total Tests:  $TOTAL_TESTS"
    echo -e "  ${GREEN}Passed:       $PASSED_TESTS${NC}"
    echo -e "  ${RED}Failed:       $FAILED_TESTS${NC}"
    echo -e "  ${YELLOW}Skipped:      $SKIPPED_TESTS${NC}"

    if [ $TOTAL_TESTS -gt 0 ]; then
        local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo -e "\n${BOLD}Pass Rate: ${pass_rate}%${NC}"
    fi

    # Performance summary
    if [ ${#TEST_TIMES[@]} -gt 0 ]; then
        echo -e "\n${BOLD}Performance:${NC}"
        echo -e "${CYAN}  Fastest tests:${NC}"

        # Sort and show top 5 fastest
        for test_name in "${!TEST_TIMES[@]}"; do
            echo "${TEST_TIMES[$test_name]}|$test_name"
        done | sort -n | head -5 | while IFS='|' read -r time name; do
            echo -e "    ${time}ms - $name"
        done

        echo -e "${YELLOW}  Slowest tests:${NC}"

        # Sort and show top 5 slowest
        for test_name in "${!TEST_TIMES[@]}"; do
            echo "${TEST_TIMES[$test_name]}|$test_name"
        done | sort -rn | head -5 | while IFS='|' read -r time name; do
            echo -e "    ${time}ms - $name"
        done
    fi

    echo -e "\n${CYAN}Logs saved to: $TEST_LOG_DIR${NC}"
    echo -e "${CYAN}Performance data: $PERF_LOG_DIR${NC}"

    echo -e "\n${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

    # Generate JSON report
    generate_json_report

    # Return exit code based on results
    if [ $FAILED_TESTS -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Generate JSON report
generate_json_report() {
    local report_file="$TEST_LOG_DIR/test-report.json"

    echo "{" > "$report_file"
    echo "  \"timestamp\": \"$(get_timestamp)\"," >> "$report_file"
    echo "  \"summary\": {" >> "$report_file"
    echo "    \"total\": $TOTAL_TESTS," >> "$report_file"
    echo "    \"passed\": $PASSED_TESTS," >> "$report_file"
    echo "    \"failed\": $FAILED_TESTS," >> "$report_file"
    echo "    \"skipped\": $SKIPPED_TESTS" >> "$report_file"
    echo "  }," >> "$report_file"
    echo "  \"tests\": [" >> "$report_file"

    local first=true
    for test_name in "${!TEST_RESULTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$report_file"
        fi

        echo "    {" >> "$report_file"
        echo "      \"name\": \"$test_name\"," >> "$report_file"
        echo "      \"result\": \"${TEST_RESULTS[$test_name]}\"," >> "$report_file"
        echo "      \"duration_ms\": ${TEST_TIMES[$test_name]}" >> "$report_file"
        echo -n "    }" >> "$report_file"
    done

    echo "" >> "$report_file"
    echo "  ]" >> "$report_file"
    echo "}" >> "$report_file"

    echo -e "${GREEN}JSON report generated: $report_file${NC}"
}

# Skip a test
skip_test() {
    local test_name="$1"
    local reason="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))

    echo -e "\n${YELLOW}Test #$TOTAL_TESTS: $test_name - SKIPPED${NC}"
    echo -e "${YELLOW}  Reason: $reason${NC}"

    TEST_RESULTS["$test_name"]="SKIPPED"
}

# Initialize performance log
init_perf_log() {
    if [ ! -f "$PERF_LOG_DIR/benchmarks.csv" ]; then
        echo "timestamp|benchmark_name|avg_ms|min_ms|max_ms|success_count|iterations" > "$PERF_LOG_DIR/benchmarks.csv"
    fi
}

# Export functions for use in other scripts
export -f run_test
export -f run_test_with_output_check
export -f run_benchmark
export -f print_section
export -f print_summary
export -f skip_test
