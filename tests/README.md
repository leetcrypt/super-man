# Super Man Test Suite

Comprehensive testing framework for Super Man with performance analysis and automated reporting.

## Overview

This test suite provides:
- **Automated testing** for all operating modes
- **Performance benchmarking** with statistical analysis
- **Interactive mode testing** using expect automation
- **Detailed reporting** in JSON, Markdown, and HTML formats
- **CI/CD integration** support

## Quick Start

### Run All Tests

```bash
cd tests/
./run-all-tests.sh
```

This will:
1. Run all non-interactive mode tests
2. Run interactive mode tests (if fzf available)
3. Generate performance benchmarks
4. Create comprehensive reports

### Run Specific Test Suites

```bash
# Test non-interactive modes only
./test-all-modes.sh

# Test interactive mode only
./test-interactive-mode.sh

# Analyze performance data
./analyze-performance.sh
```

## Test Suite Structure

```
tests/
├── run-all-tests.sh           # Master test runner
├── test-all-modes.sh          # Non-interactive mode tests
├── test-interactive-mode.sh   # Interactive mode tests
├── test-framework.sh          # Testing utilities & framework
├── analyze-performance.sh     # Performance analysis tool
├── logs/                      # Test execution logs
│   ├── test_*.log            # Individual test logs
│   └── test-report.json      # JSON test results
├── performance/               # Performance data
│   └── benchmarks.csv        # Benchmark results
└── reports/                   # Generated reports
    ├── performance-report.md # Markdown report
    ├── performance-report.html # HTML report
    └── ci-report.txt         # CI/CD compatible report
```

## Test Coverage

### Non-Interactive Modes

#### Help & Informational
- `--help` / `-h` - Help display with ASCII banner
- `--list` / `-l` - List all commands

#### Natural Language Queries
- `ask "query"` - Database search (5 test cases)
- `task "description"` - Task search (2 test cases)

#### Category Browsing
- `category files` - File operations
- `category text` - Text processing
- `category network` - Network operations
- `category system` - System monitoring
- `category` - List all categories
- Invalid category handling

#### Command Explanation
- `explain "command"` - Command breakdown (4 test cases)

#### Direct Flag Lookup
- `command filter` - Flag search (6 test cases)
- Command without filter

#### AI Mode (if available)
- `ai "query"` - AI-powered command generation (3 test cases with 30s timeout)

#### Error Handling
- Invalid mode
- Empty queries
- Special characters
- Long queries

### Interactive Mode Tests

#### Functionality Tests
1. **Launch and Exit** - Verify interactive mode starts
2. **Command Selection** - Select command and view flags
3. **Filtering** - Filter commands by category/keyword
4. **Multiple Commands** - Test ls, tar, find selections

#### Performance Tests
- Startup time benchmarking (5 iterations)
- Average response time analysis

## Performance Benchmarks

### Targets

| Mode | Target | Typical |
|------|--------|---------|
| Database search | <100ms | ~50ms |
| Category browse | <100ms | ~30ms |
| Direct lookup | <200ms | ~100ms |
| Help display | <100ms | ~20ms |
| Interactive startup | <100ms | ~50ms |
| AI mode (first) | <20s | 5-15s |
| AI mode (cached) | <5s | 1-3s |

### Metrics Collected

For each test:
- **Execution time** (milliseconds)
- **Exit code** (success/failure)
- **Output validation** (content checks)

For benchmarks (10 iterations):
- **Average time**
- **Min/Max times**
- **Success rate**
- **Standard deviation**

## Reports

### JSON Report (`logs/test-report.json`)

```json
{
  "timestamp": "2025-01-XX XX:XX:XX",
  "summary": {
    "total": 45,
    "passed": 43,
    "failed": 0,
    "skipped": 2
  },
  "tests": [
    {
      "name": "Ask mode - find large files",
      "result": "PASSED",
      "duration_ms": 52
    }
  ]
}
```

### Performance Report (`reports/performance-report.md`)

Markdown report with:
- Benchmark results table
- Performance targets comparison
- Summary statistics
- Historical trends

### HTML Report (`reports/performance-report.html`)

Interactive HTML dashboard with:
- Visual metrics
- Color-coded results
- Responsive design
- Print-friendly layout

## Requirements

### Required
- **bash** 4.0+ - Shell interpreter
- **super-man.sh** - Script being tested

### Optional
- **jq** - JSON parsing (for detailed analysis)
- **fzf** - Fuzzy finder (for interactive tests)
- **expect** - Interactive automation (auto-installed if missing)
- **ollama** - AI integration (for AI mode tests)
- **bc** - Calculator (for percentage calculations)

### Installing Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install -y jq fzf expect bc

# Fedora/RHEL
sudo dnf install -y jq fzf expect bc

# macOS
brew install jq fzf expect bc
```

## Usage Examples

### Basic Test Run

```bash
./run-all-tests.sh
```

**Output:**
```
═══════════════════════════════════════════════════════════
  Super Man Test Suite
  2025-01-XX XX:XX:XX
═══════════════════════════════════════════════════════════

▶ Testing: Help & Informational Modes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test #1: Help display (--help)
✓ PASSED (45ms) - Output contains: "Super Man"

Test #2: List all commands (--list)
✓ PASSED (32ms) - Output contains: "Available commands"

...

═══════════════════════════════════════════════════════════
  Test Summary
═══════════════════════════════════════════════════════════

Results:
  Total Tests:  45
  Passed:       43
  Failed:       0
  Skipped:      2

Pass Rate: 95%
```

### Run Specific Mode Tests

```bash
# Test only natural language queries
./test-all-modes.sh 2>&1 | grep -A 20 "Natural Language"

# Test only AI mode
./test-all-modes.sh 2>&1 | grep -A 10 "AI Mode"
```

### Performance Analysis

```bash
./analyze-performance.sh
```

**Output:**
```
═══════════════════════════════════════════════════════════
  Super Man Performance Analysis
  2025-01-XX XX:XX:XX
═══════════════════════════════════════════════════════════

Benchmark Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ask mode - find large files
  Timestamp: 2025-01-XX XX:XX:XX
  Average:   48ms
  Range:     42ms - 55ms
  Success:   10/10 iterations
```

### CI/CD Integration

```bash
# Run tests and capture exit code
./run-all-tests.sh
EXIT_CODE=$?

# Check CI report
cat reports/ci-report.txt

# Exit with test result code
exit $EXIT_CODE
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Test Super Man

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq fzf expect bc

      - name: Run tests
        run: |
          cd tests/
          ./run-all-tests.sh

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: tests/reports/
```

### Gitea CI Example

```yaml
# .gitea/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Run tests
        run: |
          cd tests/
          ./run-all-tests.sh

      - name: Publish results
        if: always()
        run: |
          echo "Test results:"
          cat tests/reports/ci-report.txt
```

## Troubleshooting

### Tests Fail to Run

**Problem:** `bash: ./run-all-tests.sh: Permission denied`

**Solution:**
```bash
chmod +x tests/*.sh
```

### Interactive Tests Fail

**Problem:** Interactive tests skip or fail

**Reasons:**
- `fzf` not installed
- `expect` not installed
- Running in non-interactive environment

**Solution:**
```bash
# Install dependencies
sudo apt-get install -y fzf expect

# Check if interactive shell
echo $-  # Should contain 'i'
```

### AI Tests Skipped

**Problem:** AI mode tests are skipped

**Reasons:**
- Ollama not installed
- NL2SH model not available

**Solution:**
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull NL2SH model
ollama pull westenfelder/NL2SH
```

### Performance Benchmarks Too Slow

**Problem:** Tests take too long

**Solutions:**
- Reduce iteration count in benchmark calls
- Skip AI tests (they take 5-15s per query)
- Run specific test suites instead of all tests

**Edit iterations:**
```bash
# In test scripts, change:
run_benchmark "test name" "command" 10
# to:
run_benchmark "test name" "command" 3
```

### JSON Report Not Generated

**Problem:** `jq` not available

**Solution:**
```bash
sudo apt-get install -y jq
```

## Advanced Usage

### Custom Test Configuration

Create `tests/config.sh`:
```bash
# Test configuration
export TEST_TIMEOUT=30
export BENCHMARK_ITERATIONS=10
export SKIP_AI_TESTS=false
export SKIP_INTERACTIVE_TESTS=false
```

### Add Custom Tests

1. Create test file:
```bash
cd tests/
cat > test-custom.sh << 'EOF'
#!/bin/bash
source ./test-framework.sh

print_header
print_section "Custom Tests"

run_test_with_output_check \
    "My custom test" \
    "../super-man.sh ask 'my query'" \
    "expected output"

print_summary
EOF

chmod +x test-custom.sh
```

2. Run custom test:
```bash
./test-custom.sh
```

### Parallel Test Execution

```bash
# Run multiple test suites in parallel
./test-all-modes.sh &
./test-interactive-mode.sh &
wait

# Analyze results
./analyze-performance.sh
```

### Export Test Data

```bash
# Export to CSV
./run-all-tests.sh
cat performance/benchmarks.csv | column -t -s '|'

# Export to JSON
cat logs/test-report.json | jq '.'
```

## Test Framework API

### Core Functions

#### `run_test(name, command, expected_exit_code, timeout)`
Run test with basic exit code checking.

```bash
run_test "Test name" "command to run" 0 10
```

#### `run_test_with_output_check(name, command, expected_string, timeout)`
Run test and verify output contains expected string.

```bash
run_test_with_output_check \
    "Help test" \
    "./super-man.sh --help" \
    "Super Man"
```

#### `run_benchmark(name, command, iterations)`
Run performance benchmark with statistics.

```bash
run_benchmark "Ask mode" "./super-man.sh ask 'test'" 10
```

#### `skip_test(name, reason)`
Skip test with reason.

```bash
skip_test "AI mode" "Ollama not available"
```

## Contributing Tests

### Adding New Test Cases

1. Identify test category (help, ask, explain, etc.)
2. Add test to appropriate section in `test-all-modes.sh`
3. Follow naming convention: `Mode - specific test case`
4. Include output validation
5. Document expected behavior

Example:
```bash
run_test_with_output_check \
    "Ask mode - new test case" \
    "$SCRIPT_PATH ask 'new query'" \
    "expected output keyword"
```

### Testing Checklist

Before submitting:
- [ ] Test passes locally
- [ ] Test has unique, descriptive name
- [ ] Output validation is specific
- [ ] Timeout is appropriate (10s default, 30s for AI)
- [ ] Test doesn't require manual interaction
- [ ] Dependencies are documented

## Maintenance

### Cleaning Test Data

```bash
# Remove all logs and reports
rm -rf tests/logs/* tests/performance/* tests/reports/*

# Run fresh test
./run-all-tests.sh
```

### Archiving Test Results

```bash
# Archive with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar -czf test-results-$TIMESTAMP.tar.gz \
    tests/logs tests/performance tests/reports

# Move to archive directory
mkdir -p archive/
mv test-results-$TIMESTAMP.tar.gz archive/
```

## Performance Tuning

### Speed Up Tests

1. **Skip slow tests**:
   ```bash
   # Comment out AI tests if not needed
   # Comment out benchmark sections
   ```

2. **Reduce iterations**:
   ```bash
   # Change from 10 to 3 iterations
   run_benchmark "test" "command" 3
   ```

3. **Parallel execution**:
   ```bash
   ./test-all-modes.sh & ./test-interactive-mode.sh & wait
   ```

### Optimize for CI/CD

```bash
# Fast CI mode
export TEST_TIMEOUT=5
export BENCHMARK_ITERATIONS=3
export SKIP_AI_TESTS=true
./run-all-tests.sh
```

## FAQ

**Q: How long do tests take?**
A: ~2-3 minutes for all tests (5-10 minutes with AI tests)

**Q: Can I run tests in parallel?**
A: Yes, but be careful with shared resources (log files, etc.)

**Q: Do I need root access?**
A: No, unless installing dependencies

**Q: Will tests modify my system?**
A: No, tests only read/execute super-man.sh

**Q: Can I run tests on macOS?**
A: Yes, with dependencies installed via Homebrew

**Q: How do I debug a failing test?**
A: Check `tests/logs/test_N_*.log` for detailed output

## Version History

### v1.0.0 (Current)
- Initial test framework
- 45+ test cases across all modes
- Performance benchmarking
- Interactive mode automation
- Comprehensive reporting (JSON, MD, HTML)
- CI/CD integration support

## License

Same as Super Man - see main repository

## Support

- **Issues**: Report via Gitea issue tracker
- **Documentation**: See main repository README
- **Questions**: Check FAQ above or test logs

---

**Super Man Test Suite v1.0.0**

Ensuring quality and performance at every commit! 🚀
