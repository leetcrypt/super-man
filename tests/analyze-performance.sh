#!/bin/bash
# Performance Analysis Tool for Super Man
# Analyzes test logs and benchmark data to generate insights

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERF_LOG_DIR="$SCRIPT_DIR/performance"
TEST_LOG_DIR="$SCRIPT_DIR/logs"
REPORT_DIR="$SCRIPT_DIR/reports"

mkdir -p "$REPORT_DIR"

# ============================================================================
# FUNCTIONS
# ============================================================================

print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Super Man Performance Analysis"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

analyze_benchmarks() {
    local bench_file="$PERF_LOG_DIR/benchmarks.csv"

    if [ ! -f "$bench_file" ]; then
        echo -e "${RED}No benchmark data found${NC}"
        return 1
    fi

    echo -e "\n${BOLD}${BLUE}Benchmark Analysis${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Skip header
    tail -n +2 "$bench_file" | while IFS='|' read -r timestamp name avg_ms min_ms max_ms success iterations; do
        echo -e "${CYAN}$name${NC}"
        echo -e "  Timestamp: $timestamp"
        echo -e "  Average:   ${GREEN}${avg_ms}ms${NC}"
        echo -e "  Range:     ${min_ms}ms - ${max_ms}ms"
        echo -e "  Success:   $success/$iterations iterations"
        echo ""
    done
}

generate_performance_report() {
    local bench_file="$PERF_LOG_DIR/benchmarks.csv"
    local report_file="$REPORT_DIR/performance-report.md"

    echo "# Super Man Performance Report" > "$report_file"
    echo "" >> "$report_file"
    echo "**Generated:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$report_file"
    echo "" >> "$report_file"

    if [ ! -f "$bench_file" ]; then
        echo "No benchmark data available" >> "$report_file"
        return 1
    fi

    echo "## Benchmark Results" >> "$report_file"
    echo "" >> "$report_file"
    echo "| Benchmark | Avg (ms) | Min (ms) | Max (ms) | Success Rate |" >> "$report_file"
    echo "|-----------|----------|----------|----------|--------------|" >> "$report_file"

    # Skip header and process data
    tail -n +2 "$bench_file" | while IFS='|' read -r timestamp name avg_ms min_ms max_ms success iterations; do
        local success_rate=$(echo "scale=1; $success * 100 / $iterations" | bc)
        echo "| $name | $avg_ms | $min_ms | $max_ms | ${success_rate}% |" >> "$report_file"
    done

    echo "" >> "$report_file"
    echo "## Performance Targets" >> "$report_file"
    echo "" >> "$report_file"
    echo "| Mode | Target | Status |" >> "$report_file"
    echo "|------|--------|--------|" >> "$report_file"

    # Analyze against targets
    tail -n +2 "$bench_file" | while IFS='|' read -r timestamp name avg_ms min_ms max_ms success iterations; do
        local status="✅"
        local target="<100ms"

        if [[ "$name" == *"AI"* ]]; then
            target="<15000ms"
            if [ "$avg_ms" -gt 15000 ]; then
                status="❌"
            fi
        elif [ "$avg_ms" -gt 100 ]; then
            status="⚠️"
        fi

        echo "| $name | $target | $status ($avg_ms ms) |" >> "$report_file"
    done

    echo "" >> "$report_file"

    # Summary statistics
    echo "## Summary Statistics" >> "$report_file"
    echo "" >> "$report_file"

    local total_benchmarks=$(tail -n +2 "$bench_file" | wc -l)
    local fast_count=$(tail -n +2 "$bench_file" | awk -F'|' '$3 < 100 {count++} END {print count}')
    local slow_count=$(tail -n +2 "$bench_file" | awk -F'|' '$3 >= 100 && $3 < 1000 {count++} END {print count}')

    echo "- **Total Benchmarks:** $total_benchmarks" >> "$report_file"
    echo "- **Fast (<100ms):** $fast_count" >> "$report_file"
    echo "- **Moderate (100-1000ms):** $slow_count" >> "$report_file"

    echo -e "\n${GREEN}Performance report generated: $report_file${NC}"
}

analyze_test_results() {
    local json_report="$TEST_LOG_DIR/test-report.json"

    if [ ! -f "$json_report" ]; then
        echo -e "${YELLOW}No test report found${NC}"
        return 1
    fi

    echo -e "\n${BOLD}${BLUE}Test Results Analysis${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Parse JSON report (using jq if available)
    if command -v jq &> /dev/null; then
        local total=$(jq -r '.summary.total' "$json_report")
        local passed=$(jq -r '.summary.passed' "$json_report")
        local failed=$(jq -r '.summary.failed' "$json_report")
        local skipped=$(jq -r '.summary.skipped' "$json_report")

        echo -e "${BOLD}Summary:${NC}"
        echo -e "  Total:   $total"
        echo -e "  ${GREEN}Passed:  $passed${NC}"
        echo -e "  ${RED}Failed:  $failed${NC}"
        echo -e "  ${YELLOW}Skipped: $skipped${NC}"

        if [ "$total" -gt 0 ]; then
            local pass_rate=$(echo "scale=1; $passed * 100 / $total" | bc)
            echo -e "\n${BOLD}Pass Rate: ${pass_rate}%${NC}"
        fi

        # Show slowest tests
        echo -e "\n${YELLOW}Slowest Tests:${NC}"
        jq -r '.tests[] | select(.result == "PASSED") | "\(.duration_ms)|\(.name)"' "$json_report" | \
            sort -rn | head -5 | while IFS='|' read -r time name; do
            echo -e "  ${time}ms - $name"
        done

        # Show fastest tests
        echo -e "\n${GREEN}Fastest Tests:${NC}"
        jq -r '.tests[] | select(.result == "PASSED") | "\(.duration_ms)|\(.name)"' "$json_report" | \
            sort -n | head -5 | while IFS='|' read -r time name; do
            echo -e "  ${time}ms - $name"
        done

        # Show failed tests if any
        local failed_tests=$(jq -r '.tests[] | select(.result == "FAILED") | .name' "$json_report")
        if [ -n "$failed_tests" ]; then
            echo -e "\n${RED}Failed Tests:${NC}"
            echo "$failed_tests" | while read -r name; do
                echo -e "  ✗ $name"
            done
        fi

    else
        echo -e "${YELLOW}Install jq for detailed JSON analysis${NC}"
        # Basic analysis without jq
        grep -E "total|passed|failed|skipped" "$json_report"
    fi
}

generate_html_report() {
    local html_file="$REPORT_DIR/performance-report.html"

    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Super Man Performance Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .section {
            background: white;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #667eea;
            color: white;
        }
        .metric {
            display: inline-block;
            padding: 10px 20px;
            margin: 10px;
            background: #f0f0f0;
            border-radius: 5px;
        }
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
        .fast { color: #10b981; }
        .moderate { color: #f59e0b; }
        .slow { color: #ef4444; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Super Man Performance Report</h1>
        <p>Generated: TIMESTAMP</p>
    </div>

    <div class="section">
        <h2>📊 Test Summary</h2>
        <div class="metric">
            <div>Total Tests</div>
            <div class="metric-value">TOTAL_TESTS</div>
        </div>
        <div class="metric">
            <div>Passed</div>
            <div class="metric-value" style="color: #10b981;">PASSED_TESTS</div>
        </div>
        <div class="metric">
            <div>Failed</div>
            <div class="metric-value" style="color: #ef4444;">FAILED_TESTS</div>
        </div>
        <div class="metric">
            <div>Pass Rate</div>
            <div class="metric-value">PASS_RATE%</div>
        </div>
    </div>

    <div class="section">
        <h2>⚡ Performance Benchmarks</h2>
        <table>
            <thead>
                <tr>
                    <th>Benchmark</th>
                    <th>Average</th>
                    <th>Min</th>
                    <th>Max</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody id="benchmarks">
            </tbody>
        </table>
    </div>

    <div class="section">
        <h2>🎯 Performance Targets</h2>
        <ul>
            <li><span class="fast">●</span> Fast: &lt;100ms (Database queries, lookups)</li>
            <li><span class="moderate">●</span> Moderate: 100-1000ms (Complex operations)</li>
            <li><span class="slow">●</span> Slow: &gt;1000ms (AI queries - expected)</li>
        </ul>
    </div>
</body>
</html>
EOF

    # Replace placeholders with actual data if JSON report exists
    if [ -f "$TEST_LOG_DIR/test-report.json" ] && command -v jq &> /dev/null; then
        local total=$(jq -r '.summary.total' "$TEST_LOG_DIR/test-report.json")
        local passed=$(jq -r '.summary.passed' "$TEST_LOG_DIR/test-report.json")
        local failed=$(jq -r '.summary.failed' "$TEST_LOG_DIR/test-report.json")
        local pass_rate=$(echo "scale=1; $passed * 100 / $total" | bc)

        sed -i "s/TIMESTAMP/$(date '+%Y-%m-%d %H:%M:%S')/g" "$html_file"
        sed -i "s/TOTAL_TESTS/$total/g" "$html_file"
        sed -i "s/PASSED_TESTS/$passed/g" "$html_file"
        sed -i "s/FAILED_TESTS/$failed/g" "$html_file"
        sed -i "s/PASS_RATE/$pass_rate/g" "$html_file"
    fi

    echo -e "${GREEN}HTML report generated: $html_file${NC}"
}

compare_historical_data() {
    echo -e "\n${BOLD}${BLUE}Historical Performance Comparison${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    local bench_file="$PERF_LOG_DIR/benchmarks.csv"

    if [ ! -f "$bench_file" ]; then
        echo -e "${YELLOW}No historical data available${NC}"
        return 1
    fi

    # Group by benchmark name and show trends
    tail -n +2 "$bench_file" | awk -F'|' '{
        name=$2
        avg=$3
        if (name in benchmarks) {
            count[name]++
            sum[name] += avg
            if (avg < min[name]) min[name] = avg
            if (avg > max[name]) max[name] = avg
        } else {
            benchmarks[name] = 1
            count[name] = 1
            sum[name] = avg
            min[name] = avg
            max[name] = avg
        }
    }
    END {
        for (name in benchmarks) {
            avg = sum[name] / count[name]
            printf "%s|%.0f|%d|%d|%d\n", name, avg, min[name], max[name], count[name]
        }
    }' | while IFS='|' read -r name avg min max count; do
        echo -e "${CYAN}$name${NC}"
        echo -e "  Runs:    $count"
        echo -e "  Average: ${avg}ms"
        echo -e "  Best:    ${GREEN}${min}ms${NC}"
        echo -e "  Worst:   ${YELLOW}${max}ms${NC}"
        echo ""
    done
}

# ============================================================================
# MAIN
# ============================================================================

print_header

# Check if data exists
if [ ! -d "$PERF_LOG_DIR" ] && [ ! -d "$TEST_LOG_DIR" ]; then
    echo -e "${RED}No test data found. Run tests first.${NC}"
    echo -e "${YELLOW}Run: ./tests/run-all-tests.sh${NC}"
    exit 1
fi

# Perform analyses
analyze_test_results
analyze_benchmarks
compare_historical_data

# Generate reports
echo -e "\n${BOLD}${MAGENTA}Generating Reports${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

generate_performance_report
generate_html_report

echo -e "\n${GREEN}${BOLD}Analysis Complete!${NC}"
echo -e "${CYAN}Reports location: $REPORT_DIR${NC}"
echo -e "${CYAN}  - Markdown: $REPORT_DIR/performance-report.md${NC}"
echo -e "${CYAN}  - HTML: $REPORT_DIR/performance-report.html${NC}"
