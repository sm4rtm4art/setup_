#!/bin/bash
set -e

echo "🚀 Running post-create setup..."

# Setup Git configuration (if not already configured)
if [ ! -f ~/.gitconfig ]; then
    git config --global init.defaultBranch main
    git config --global pull.rebase false
fi

# Install pre-commit hooks for this project
if [ -f .pre-commit-config.yaml ]; then
    echo "📦 Installing pre-commit hooks..."
    pre-commit install
fi

# Setup Python configuration files if they don't exist
echo "🐍 Setting up Python development configuration..."

# Copy pyproject.toml template if it doesn't exist (includes ruff + mypy config)
if [ ! -f pyproject.toml ] && [ -f .devcontainer/config/pyproject.toml ]; then
    echo "📝 Creating pyproject.toml from template (includes ruff + mypy config)..."
    cp .devcontainer/config/pyproject.toml pyproject.toml
fi

# Copy pre-commit config template if it doesn't exist
if [ ! -f .pre-commit-config.yaml ] && [ -f .devcontainer/config/.pre-commit-config.yaml ]; then
    echo "📝 Creating .pre-commit-config.yaml from template..."
    cp .devcontainer/config/.pre-commit-config.yaml .pre-commit-config.yaml
fi

# Setup shell aliases
cat >> ~/.zshrc << 'EOF'

# Custom aliases
alias ll='eza -la --icons --group-directories-first'
alias la='eza -la --icons'
alias lt='eza --tree --icons'
alias cat='bat --style=plain'
alias find='fd'
alias grep='rg'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Python development aliases
alias py='python3'
alias pip='uv pip'
alias venv='uv venv'
alias run='uv run'
alias add='uv add'
alias remove='uv remove'
alias sync='uv sync'
alias lock='uv lock'

# Code quality aliases
alias lint='ruff check'
alias lintfix='ruff check --fix'
alias format='ruff format'
alias typecheck='mypy'
alias check='ruff check && ruff format --check && mypy'
alias fix='ruff check --fix && ruff format'

# Docker aliases (since we have docker-in-docker)
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'

EOF

# Create workspace settings
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
    "files.associations": {
        "*.sh": "shellscript"
    },
    "shellcheck.enable": true,
    "shellcheck.run": "onType",
    "shellcheck.executablePath": "/usr/bin/shellcheck",
    "shellformat.path": "/usr/bin/shfmt",
    "[shellscript]": {
        "editor.defaultFormatter": "foxundermoon.shell-format",
        "editor.formatOnSave": true
    }
}
EOF

echo "✅ Post-create setup complete!"
echo "💡 Tip: Your development environment is now ready!"
echo "   - All tools are pre-installed in this container" 
echo "   - Your code is mounted from your local machine" 
echo "   - Changes persist on your host, but the environment is isolated"
echo ""
echo "🐍 Python Development Tools Available:"
echo "   - uv: Ultra-fast Python package manager (alias: pip, add, sync, etc.)"
echo "   - ruff: Lightning-fast linter and formatter (alias: lint, format, fix)"
echo "   - mypy: Static type checker (alias: typecheck)"
echo ""
echo "🚀 Quick Commands:"
echo "   - check: Run all code quality checks"
echo "   - fix: Auto-fix linting and formatting issues"
echo "   - Run '.devcontainer/test-container.sh' to verify everything works" 