#!/bin/bash

# Integration Test Script for Power Grid Love2D Client
# This script starts the Go server and runs automated tests on the Love2D client

echo "Power Grid Integration Test Runner"
echo "=================================="

# Configuration
SERVER_DIR="../go_server"
CLIENT_DIR="."
SERVER_PORT=4080
TEST_TIMEOUT=120
LOG_DIR="../logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

# Function to wait for server to start
wait_for_server() {
    print_status "Waiting for server to start on port $SERVER_PORT..."
    for i in {1..30}; do
        if check_port $SERVER_PORT; then
            print_status "Server is running on port $SERVER_PORT"
            return 0
        fi
        sleep 1
    done
    print_error "Server failed to start within 30 seconds"
    return 1
}

# Function to cleanup processes
cleanup() {
    print_status "Cleaning up processes..."
    
    # Kill server if running
    if [ ! -z "$SERVER_PID" ]; then
        print_status "Stopping server (PID: $SERVER_PID)"
        kill $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null
    fi
    
    # Kill any remaining server processes on our port
    if check_port $SERVER_PORT; then
        print_warning "Killing remaining processes on port $SERVER_PORT"
        lsof -ti:$SERVER_PORT | xargs kill -9 2>/dev/null
    fi
    
    print_status "Cleanup complete"
}

# Set up cleanup on script exit
trap cleanup EXIT

# Create log directory
mkdir -p "$LOG_DIR"

# Step 1: Build and start the Go server
print_status "Building Go server..."
cd "$SERVER_DIR"

if ! make build; then
    print_error "Failed to build server"
    exit 1
fi

print_status "Starting Go server..."
./powergrid_server -addr=:$SERVER_PORT > "$LOG_DIR/integration_test_server.log" 2>&1 &
SERVER_PID=$!

if ! wait_for_server; then
    print_error "Server startup failed"
    exit 1
fi

# Step 2: Return to client directory
cd - > /dev/null

# Step 3: Check if Love2D is available
if ! command -v love >/dev/null 2>&1; then
    print_error "Love2D not found. Please install Love2D first."
    exit 1
fi

print_status "Love2D found: $(love --version)"

# Step 4: Run the integration tests
print_status "Starting Love2D client with integration tests..."

# Create a temporary Love2D test runner
cat > test_runner.lua << 'EOF'
-- Temporary test runner for integration tests
local IntegrationTestHarness = require("test.integration_test_harness")

-- Override love.load to start tests
local originalLoad = love.load
love.load = function()
    print("Starting integration test mode...")
    
    -- Call original load
    if originalLoad then
        originalLoad()
    end
    
    -- Set up test harness
    _G.testHarness = IntegrationTestHarness:new()
    _G.testHarness:installGlobalHooks()
    _G.testHarness:addBasicNetworkTests()
    
    -- Start tests after a brief delay to let UI initialize
    love.timer.sleep(2)
    _G.testHarness:start()
end

-- Override love.update to run test harness
local originalUpdate = love.update
love.update = function(dt)
    if originalUpdate then
        originalUpdate(dt)
    end
    
    if _G.testHarness then
        _G.testHarness:update(dt)
        
        -- Auto-exit when tests complete
        if not _G.testHarness.isRunning and _G.testHarness.results and #_G.testHarness.results > 0 then
            print("All tests completed, exiting...")
            love.event.quit()
        end
    end
end
EOF

# Run Love2D with our test runner and capture output
print_status "Running integration tests (timeout: ${TEST_TIMEOUT}s)..."

timeout $TEST_TIMEOUT love . --test-integration > "$LOG_DIR/integration_test_client.log" 2>&1 &
CLIENT_PID=$!

# Wait for client to finish or timeout
wait $CLIENT_PID
CLIENT_EXIT_CODE=$?

# Clean up temporary file
rm -f test_runner.lua

# Step 5: Analyze results
print_status "Analyzing test results..."

if [ $CLIENT_EXIT_CODE -eq 0 ]; then
    print_status "Client exited normally"
elif [ $CLIENT_EXIT_CODE -eq 124 ]; then
    print_warning "Client tests timed out after ${TEST_TIMEOUT} seconds"
else
    print_warning "Client exited with code: $CLIENT_EXIT_CODE"
fi

# Check for test results files
RESULTS_FILE=$(ls test_results_*.json 2>/dev/null | head -1)
if [ -f "$RESULTS_FILE" ]; then
    print_status "Test results found: $RESULTS_FILE"
    
    # Parse JSON results (basic parsing)
    PASSED=$(grep -o '"passed":[0-9]*' "$RESULTS_FILE" | cut -d':' -f2)
    FAILED=$(grep -o '"failed":[0-9]*' "$RESULTS_FILE" | cut -d':' -f2)
    TIMEOUTS=$(grep -o '"timeouts":[0-9]*' "$RESULTS_FILE" | cut -d':' -f2)
    
    echo
    echo "=== Test Summary ==="
    echo "Passed:   $PASSED"
    echo "Failed:   $FAILED"
    echo "Timeouts: $TIMEOUTS"
    echo
    
    if [ "$FAILED" -gt 0 ] || [ "$TIMEOUTS" -gt 0 ]; then
        print_error "Some tests failed or timed out"
        EXIT_CODE=1
    else
        print_status "All tests passed!"
        EXIT_CODE=0
    fi
else
    print_warning "No test results file found"
    EXIT_CODE=1
fi

# Show log file locations
echo
print_status "Log files:"
echo "  Server: $LOG_DIR/integration_test_server.log"
echo "  Client: $LOG_DIR/integration_test_client.log"

# Show recent server logs for debugging
if [ -f "$LOG_DIR/integration_test_server.log" ]; then
    echo
    print_status "Recent server activity:"
    tail -10 "$LOG_DIR/integration_test_server.log"
fi

exit $EXIT_CODE