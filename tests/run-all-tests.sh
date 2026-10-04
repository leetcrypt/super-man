#!/bin/bash
# Master Test Runner for Super Man
# Runs all test suites and generates comprehensive reports

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
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Test scripts
ALL_MODES_TEST="$SCRIPT_DIR/test-all-modes.sh"
INTERACTIVE_TEST="$SCRIPT_DIR/test-interactive-mode.sh"
ANALYZE_SCRIPT="$SCRIPT_DIR/analyze-performance.sh"

# Make scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# ============================================================================
# FUNCTIONS
# ============================================================================

print_banner() {
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
    ____             __       ____            __    __
   / __ )____ ______/ /_     / __ )__  ______/ /___/ /_  __
  / __  / __ `/ ___/ __ \   / __  / / / / __  / __  / / / /
 / /_/ / /_/ (__  ) / / /  / /_/ / /_/ / /_/ / /_/ / /_/ /
/_____/\__,_/____/_/ /_/  /_____/\__,_/\__,_/\__,_/\__, /
                                                   /____/
        Test Suite - Comprehensive Testing & Analysis
EOF
    echo -e "${NC}"
    echo -e "${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${BOLD}${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

run_test_suite() {
    local suite_name="$1"
    local suite_script="$2"
    local suite_log="$SCRIPT_DIR/logs/${suite_name// /_}_suite.log"

    echo -e "\n${CYAN}Running: $suite_name${NC}"

    if [ ! -f "$suite_script" ]; then
        echo -e "${RED}✗ Test suite not found: $suite_script${NC}"
        return 1
    fi

    # Run test suite and capture output
    "$suite_script" 2>&1 | tee "$suite_log"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}✓ $suite_name completed successfully${NC}"
        return 0
    else
        echo -e "\n${RED}✗ $suite_name had failures${NC}"
        return 1
    fi
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

print_banner

print_section "Pre-flight Checks"

# Check if script exists
if [ ! -f "$PROJECT_DIR/super-man.sh" ]; then
    echo -e "${RED}Error: super-man.sh not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ super-man.sh found${NC}"

# Check dependencies
MISSING_DEPS=()

if ! command -v jq &> /dev/null; then
    MISSING_DEPS+=("jq")
fi

if ! command -v fzf &> /dev/null; then
    MISSING_DEPS+=("fzf")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠ Missing optional dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}  Some tests may be skipped${NC}"
else
    echo -e "${GREEN}✓ All dependencies available${NC}"
fi

# Check Ollama and AI models
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama installed${NC}"

    if ollama list | grep -q "westenfelder/NL2SH"; then
        echo -e "${GREEN}✓ NL2SH model available${NC}"
    else
        echo -e "${YELLOW}⚠ NL2SH model not found (AI tests will be skipped)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Ollama not installed (AI tests will be skipped)${NC}"
fi

# Create log directories
mkdir -p "$SCRIPT_DIR/logs"
mkdir -p "$SCRIPT_DIR/performance"
mkdir -p "$SCRIPT_DIR/reports"

echo -e "${GREEN}✓ Test directories created${NC}"

# ============================================================================
# RUN TEST SUITES
# ============================================================================

print_section "Test Execution"

SUITE_RESULTS=()
SUITE_EXIT_CODES=()

# Test Suite 1: All Non-Interactive Modes
run_test_suite "All Non-Interactive Modes" "$ALL_MODES_TEST"
SUITE_EXIT_CODES+=($?)
SUITE_RESULTS+=("Non-Interactive Modes")

# Test Suite 2: Interactive Mode (if fzf available)
if command -v fzf &> /dev/null; then
    run_test_suite "Interactive Mode" "$INTERACTIVE_TEST"
    SUITE_EXIT_CODES+=($?)
    SUITE_RESULTS+=("Interactive Mode")
else
    echo -e "\n${YELLOW}Skipping Interactive Mode tests (fzf not available)${NC}"
fi

# ============================================================================
# PERFORMANCE ANALYSIS
# ============================================================================

print_section "Performance Analysis"

if [ -f "$ANALYZE_SCRIPT" ]; then
    echo -e "\n${CYAN}Running performance analysis...${NC}\n"
    "$ANALYZE_SCRIPT"
else
    echo -e "${YELLOW}Performance analysis script not found${NC}"
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================

print_section "Overall Summary"

TOTAL_SUITES=${#SUITE_RESULTS[@]}
PASSED_SUITES=0
FAILED_SUITES=0

for i in "${!SUITE_RESULTS[@]}"; do
    if [ "${SUITE_EXIT_CODES[$i]}" -eq 0 ]; then
        echo -e "  ${GREEN}✓ ${SUITE_RESULTS[$i]}${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        echo -e "  ${RED}✗ ${SUITE_RESULTS[$i]}${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi
done

echo ""
echo -e "${BOLD}Test Suites Summary:${NC}"
echo -e "  Total:  $TOTAL_SUITES"
echo -e "  ${GREEN}Passed: $PASSED_SUITES${NC}"
echo -e "  ${RED}Failed: $FAILED_SUITES${NC}"

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}🎉 All test suites passed!${NC}"
    OVERALL_EXIT_CODE=0
else
    echo -e "\n${RED}${BOLD}⚠ Some test suites failed${NC}"
    OVERALL_EXIT_CODE=1
fi

# ============================================================================
# REPORT LOCATIONS
# ============================================================================

echo -e "\n${CYAN}${BOLD}Reports & Logs:${NC}"
echo -e "  ${CYAN}Test Logs:        $SCRIPT_DIR/logs/${NC}"
echo -e "  ${CYAN}Performance Data: $SCRIPT_DIR/performance/${NC}"
echo -e "  ${CYAN}Reports:          $SCRIPT_DIR/reports/${NC}"

if [ -f "$SCRIPT_DIR/reports/performance-report.html" ]; then
    echo -e "\n${GREEN}View HTML report:${NC}"
    echo -e "  ${CYAN}file://$SCRIPT_DIR/reports/performance-report.html${NC}"
fi

if [ -f "$SCRIPT_DIR/logs/test-report.json" ]; then
    echo -e "\n${GREEN}JSON report available:${NC}"
    echo -e "  ${CYAN}$SCRIPT_DIR/logs/test-report.json${NC}"
fi

# ============================================================================
# CI/CD INTEGRATION
# ============================================================================

# Generate CI-friendly output
CI_REPORT="$SCRIPT_DIR/reports/ci-report.txt"
cat > "$CI_REPORT" << EOF
Super Man Test Results
========================
Date: $(date '+%Y-%m-%d %H:%M:%S')

Test Suites:
- Total: $TOTAL_SUITES
- Passed: $PASSED_SUITES
- Failed: $FAILED_SUITES

Exit Code: $OVERALL_EXIT_CODE
EOF

echo -e "\n${CYAN}CI report: $CI_REPORT${NC}"

# ============================================================================
# CLEANUP AND EXIT
# ============================================================================

echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Test execution complete!${NC}\n"

exit $OVERALL_EXIT_CODE
