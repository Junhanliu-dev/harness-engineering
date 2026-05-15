#!/bin/bash
# Pre-push quality gate
# Blocks git push unless all conditions are met

# Find the current requirement's pipeline state
CHANGES_DIR="harness/changes"
LATEST=$(ls -t "$CHANGES_DIR" 2>/dev/null | grep -v _template | head -1)

if [ -z "$LATEST" ]; then
  echo "WARNING: No harness change record found. Pushing without pipeline tracking."
  exit 0  # Allow but warn
fi

STATE_FILE="$CHANGES_DIR/$LATEST/pipeline-state.md"

if [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: No pipeline state file. Pushing without pipeline verification."
  exit 0
fi

# Check pipeline stage (must be ≥ 7)
CURRENT_STAGE=$(grep "Current Stage:" "$STATE_FILE" | grep -oE '[0-9]+')
if [ -n "$CURRENT_STAGE" ] && [ "$CURRENT_STAGE" -lt 7 ]; then
  echo "BLOCKED: Pipeline is at Stage $CURRENT_STAGE (need ≥ 7 for push)"
  echo "Complete code review and tests before pushing."
  exit 1
fi

# Run build check
{build_command} 2>/dev/null
if [ $? -ne 0 ]; then
  echo "BLOCKED: Build fails"
  exit 1
fi

# Run lint check
{lint_command} 2>/dev/null
if [ $? -ne 0 ]; then
  echo "BLOCKED: Lint fails"
  exit 1
fi

# Run tests and check count
TEST_OUTPUT=$({test_command} 2>&1)
TEST_EXIT=$?
TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ (passed|tests)' | grep -oE '[0-9]+' | head -1)

if [ $TEST_EXIT -ne 0 ]; then
  echo "BLOCKED: Tests fail"
  exit 1
fi

if [ -z "$TEST_COUNT" ] || [ "$TEST_COUNT" -eq 0 ]; then
  echo "BLOCKED: No tests found (total_tests must be > 0)"
  exit 1
fi

echo "All gates passed. Push allowed."
exit 0
