#!/bin/bash
# Run IRC integration tests
#
# Usage:
#   ./scripts/run_integration_tests.sh
#   ./scripts/run_integration_tests.sh --debug
#   ./scripts/run_integration_tests.sh connection_test.dart

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Conduit IRC Integration Tests"
echo "=============================="
echo ""

# Check required environment variables
check_env() {
    local var_name=$1
    local var_value="${!var_name}"

    if [ -z "$var_value" ]; then
        echo -e "${RED}ERROR: $var_name is not set${NC}"
        return 1
    fi
    echo -e "${GREEN}OK${NC} $var_name = $var_value"
    return 0
}

echo "Checking environment variables..."
echo ""

MISSING=0

check_env "IRC_TEST_HOST" || MISSING=1
check_env "IRC_TEST_NICK" || MISSING=1
check_env "IRC_TEST_USER" || MISSING=1

echo ""

# Optional variables
if [ -n "$IRC_TEST_PORT" ]; then
    echo -e "${GREEN}OK${NC} IRC_TEST_PORT = $IRC_TEST_PORT"
else
    echo -e "${YELLOW}--${NC} IRC_TEST_PORT not set (default: 6697)"
fi

if [ -n "$IRC_TEST_CHANNEL" ]; then
    echo -e "${GREEN}OK${NC} IRC_TEST_CHANNEL = $IRC_TEST_CHANNEL"
else
    echo -e "${YELLOW}--${NC} IRC_TEST_CHANNEL not set (default: #conduit-test)"
fi

if [ -n "$IRC_TEST_PASS" ]; then
    echo -e "${GREEN}OK${NC} IRC_TEST_PASS = [set]"
fi

if [ -n "$IRC_TEST_ALLOW_INVALID_CERTS" ]; then
    echo -e "${YELLOW}!!${NC} IRC_TEST_ALLOW_INVALID_CERTS = $IRC_TEST_ALLOW_INVALID_CERTS"
fi

echo ""

if [ $MISSING -eq 1 ]; then
    echo -e "${RED}Missing required environment variables!${NC}"
    echo ""
    echo "Required:"
    echo "  export IRC_TEST_HOST=\"irc.example.com\""
    echo "  export IRC_TEST_NICK=\"conduit-test\""
    echo "  export IRC_TEST_USER=\"conduit\""
    echo ""
    echo "Optional:"
    echo "  export IRC_TEST_PORT=\"6697\""
    echo "  export IRC_TEST_CHANNEL=\"#conduit-test\""
    echo "  export IRC_TEST_PASS=\"password\""
    echo "  export IRC_TEST_ALLOW_INVALID_CERTS=\"true\""
    exit 1
fi

# Parse arguments
DEBUG=""
TEST_FILE=""

for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG="--reporter expanded"
            ;;
        *.dart)
            TEST_FILE="integration_test/$arg"
            ;;
    esac
done

# Run tests
echo "Running integration tests..."
echo ""

cd "$PROJECT_DIR"

if [ -n "$TEST_FILE" ]; then
    echo "Test file: $TEST_FILE"
    flutter test $DEBUG "$TEST_FILE"
else
    flutter test $DEBUG integration_test/
fi

echo ""
echo -e "${GREEN}Integration tests completed!${NC}"
