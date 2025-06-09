#!/bin/bash

echo "🧪 Testing Dev Container Setup..."
echo "================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test if we're in a container
if [ -f /.dockerenv ]; then
    echo -e "${GREEN}✓${NC} Running inside Docker container"
else
    echo -e "${RED}✗${NC} Not running in container - please run this inside the dev container"
    exit 1
fi

# Test installed tools
echo ""
echo "📦 Checking installed tools:"
echo "----------------------------"

# Function to check if command exists
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        $1 --version 2>&1 | head -n1 | sed 's/^/  /'
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
    fi
}

# Check essential tools
check_command "git"
check_command "zsh"
check_command "python3"
check_command "node"
check_command "shellcheck"
check_command "eza"
check_command "bat"
check_command "fd"
check_command "rg"

echo ""
echo "🐍 Checking Python development tools:"
echo "------------------------------------"
check_command "uv"
check_command "ruff"
check_command "mypy"

echo ""
echo "🏠 Environment Info:"
echo "-------------------"
echo "User: $(whoami)"
echo "Shell: $SHELL"
echo "Working Dir: $(pwd)"
echo "Home: $HOME"

echo ""
echo "📂 Workspace Contents:"
echo "---------------------"
eza -la --icons --group-directories-first | head -10

echo ""
echo -e "${GREEN}✅ Dev container is working correctly!${NC}"
echo ""
echo "💡 Next steps:"
echo "   1. Try editing a file - changes will persist on your host"
echo "   2. Run 'shellcheck setup_wsl.sh' to lint your bash scripts"
echo "   3. Use 'pre-commit run --all-files' to run all checks" 