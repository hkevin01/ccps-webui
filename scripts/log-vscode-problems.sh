#!/bin/bash
# Script to log and examine all problems listed in backend/build/reports/problems/problems-report.html

LOG_DIR="logs"
if [ ! -d "$LOG_DIR" ]; then
    mkdir "$LOG_DIR"
fi
LOG_FILE="$LOG_DIR/vscode-problems.log"

PROBLEMS_HTML="backend/build/reports/problems/problems-report.html"

{
    if [ ! -f "$PROBLEMS_HTML" ]; then
        echo "No problems-report.html found at $PROBLEMS_HTML"
        echo "Try running a Gradle build first to generate the report."
        exit 1
    fi

    echo "==== VSCode/Gradle Problems Report ===="
    echo "File: $PROBLEMS_HTML"
    echo "---------------------------------------"
    # Print a summary of problems (extract lines with 'problem' or 'error' or 'exception' or 'fail')
    grep -i -E 'problem|error|exception|fail' "$PROBLEMS_HTML" | sed 's/<[^>]*>//g' | uniq

    echo ""
    echo "==== Full problems-report.html (text only) ===="
    # Print the full report as plain text (strip HTML tags)
    sed 's/<[^>]*>//g' "$PROBLEMS_HTML"

    echo ""
    echo "==== End of Problems Report ===="
} | tee "$LOG_FILE"
