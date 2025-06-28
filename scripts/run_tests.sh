#!/bin/bash

# Test runner script for Power Grid Love2D client
# This script provides easy access to various automated test modes

echo "Power Grid Love2D Test Runner"
echo "============================="

# Function to run a test
run_test() {
    local test_name=$1
    local flag=$2
    echo "Running $test_name test..."
    echo "Command: love . $flag"
    love . $flag
    echo "Test completed."
    echo ""
}

# Check if specific test was requested
if [ "$1" = "full" ]; then
    run_test "Full Game" "--test-full"
elif [ "$1" = "building" ]; then
    run_test "Building Phase" "--test-building"
elif [ "$1" = "phase" ]; then
    run_test "Phase Transition" "--test-phase"
elif [ "$1" = "all" ]; then
    echo "Running all tests..."
    run_test "Building Phase" "--test-building"
    run_test "Phase Transition" "--test-phase"
    run_test "Full Game" "--test-full"
else
    echo "Available tests:"
    echo "  ./scripts/run_tests.sh full      - Run complete game simulation"
    echo "  ./scripts/run_tests.sh building  - Test building phase mechanics"
    echo "  ./scripts/run_tests.sh phase     - Test phase transitions"
    echo "  ./scripts/run_tests.sh all       - Run all tests sequentially"
    echo ""
    echo "Manual test commands:"
    echo "  love . --test-full      - Full game automation"
    echo "  love . --test-building  - Building phase test"
    echo "  love . --test-phase     - Phase transition test"
    echo "  love . --auction        - Start in auction phase"
    echo "  love . --resource       - Start in resource buying phase"
    echo ""
    echo "Example: ./scripts/run_tests.sh building"
fi