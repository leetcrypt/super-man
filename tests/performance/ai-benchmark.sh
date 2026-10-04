#!/bin/bash
# AI mode benchmark harness for super-man.
# Runs a fixed query suite against each model and records latency + the
# generated command to a pipe-delimited CSV for analysis/reporting.
#
# Usage: ./ai-benchmark.sh [model1 model2 ...]
# Default models: qwen2.5-coder:1.5b qwen2.5:3b westenfelder/NL2SH
#
# Output: tests/performance/ai-results.csv  (model|id|category|difficulty|query|latency_s|command)

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPERMAN="$SCRIPT_DIR/../../super-man.sh"
OUT="$SCRIPT_DIR/ai-results.csv"

MODELS=("$@")
if [ ${#MODELS[@]} -eq 0 ]; then
  MODELS=("qwen2.5-coder:1.5b" "qwen2.5:3b" "westenfelder/NL2SH")
fi

# Suite: id|category|difficulty|query
SUITE=(
  "q01|files|easy|list the 5 largest files in the current directory"
  "q02|files|easy|show hidden files in long format"
  "q03|files|medium|find files larger than 100MB under the home directory"
  "q04|files|medium|recursively change permissions of all directories to 755"
  "q05|files|hard|find duplicate files by content in the current tree"
  "q06|text|easy|count the number of lines in all python files"
  "q07|text|medium|replace all tabs with two spaces in config.txt in place"
  "q08|text|medium|print the 10 most common words in access.log"
  "q09|text|hard|sum the numbers in the third column of data.csv"
  "q10|search|easy|recursively search for the word TODO in all js files"
  "q11|search|medium|find files modified in the last 24 hours"
  "q12|search|hard|find python files that import requests but not os"
  "q13|process|easy|show the top 10 processes by memory usage"
  "q14|process|medium|kill the process listening on port 8080"
  "q15|process|hard|show the total cpu time used by all chrome processes"
  "q16|network|easy|download a file from a url and save it as out.bin"
  "q17|network|medium|list all open listening tcp ports with the owning process"
  "q18|network|hard|test whether port 443 is open on example.com"
  "q19|archive|easy|compress the folder logs into a gzip tarball"
  "q20|archive|medium|extract only txt files from archive.tar.gz"
  "q21|system|easy|show disk usage of the current directory in human readable form"
  "q22|system|medium|show the 5 largest directories under /var"
  "q23|git|easy|show the last 5 git commits in one line each"
  "q24|git|medium|list files changed in the last commit"
  "q25|git|hard|find the commit that introduced the string getUserById"
)

strip() { sed -E 's/\x1b\[[0-9;]*m//g'; }

echo "model|id|category|difficulty|query|latency_s|command" > "$OUT"

for m in "${MODELS[@]}"; do
  echo ">> Warming up $m ..."
  ollama run "$m" "echo hi" >/dev/null 2>&1
  echo ">> Benchmarking $m (${#SUITE[@]} queries)"
  for row in "${SUITE[@]}"; do
    IFS='|' read -r id cat diff q <<< "$row"
    start=$(date +%s.%N)
    cmd=$("$SUPERMAN" ai --model "$m" "$q" 2>&1 | strip \
          | awk '/Generated Command:/{getline; gsub(/^[[:space:]]+/,""); print; exit}')
    end=$(date +%s.%N)
    el=$(awk "BEGIN{printf \"%.2f\", $end-$start}")
    # squash any embedded pipes/newlines in the captured command for CSV safety
    cmd=$(printf '%s' "$cmd" | tr '\n' ' ' | sed 's/|/¦/g')
    printf "%s|%s|%s|%s|%s|%s|%s\n" "$m" "$id" "$cat" "$diff" "$q" "$el" "$cmd" >> "$OUT"
    printf "  [%s] %-5s %5ss  %s\n" "$m" "$id" "$el" "$cmd"
  done
done

echo ""
echo "Done -> $OUT"
