#!/bin/bash
# =============================================================================
# Python Development Environment Module
# Installs Python with pyenv and uv package manager
# =============================================================================

# Module metadata
MODULE_NAME="python"
MODULE_DESCRIPTION="Python development environment with pyenv and uv"
MODULE_DEPS=("base")

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/core.sh"
source "${SCRIPT_DIR}/lib/wsl.sh"
source "${SCRIPT_DIR}/lib/installer.sh"
source "${SCRIPT_DIR}/config/versions.conf"

# =============================================================================
# MODULE FUNCTIONS
# =============================================================================

# Install Python build dependencies
python_prereqs() {
    log_info "Installing Python build dependencies..."
    
    install_packages \
        make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev \
        wget curl llvm libncursesw5-dev xz-utils \
        tk-dev libxml2-dev libxmlsec1-dev libffi-dev \
        liblzma-dev
}

# Install pyenv
install_pyenv() {
    if [[ -d "$HOME/.pyenv" ]]; then
        log_info "pyenv already installed"
        return 0
    fi
    
    log_info "Installing pyenv..."
    
    # Try different installation methods
    if command_exists curl; then
        curl https://pyenv.run | bash
    elif command_exists git; then
        git clone https://github.com/pyenv/pyenv.git ~/.pyenv
        git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
    else
        log_error "No suitable method to install pyenv (need curl or git)"
        return 1
    fi
    
    # Set up environment for current session
    export PYENV_ROOT="$HOME/.pyenv"
    add_to_path "$PYENV_ROOT/bin" "start"
    
    if command_exists pyenv; then
        eval "$(pyenv init -)"
        log_success "pyenv installed successfully"
    else
        log_error "pyenv installation failed"
        return 1
    fi
}

# Install Python version via pyenv
install_python_version() {
    local version="$1"
    
    log_info "Installing Python $version..."
    
    # Check if already installed
    if pyenv versions 2>/dev/null | grep -q "$version"; then
        log_info "Python $version already installed"
        pyenv global "$version"
        return 0
    fi
    
    # Install Python version
    if pyenv install "$version"; then
        pyenv global "$version"
        log_success "Python $version installed and set as global"
    else
        log_error "Failed to install Python $version"
        return 1
    fi
}

# Install uv package manager
install_uv() {
    if command_exists uv; then
        log_info "uv already installed"
        return 0
    fi
    
    log_info "Installing uv package manager..."
    
    if command_exists curl; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command_exists pip; then
        pip install uv
    else
        log_error "Cannot install uv - need curl or pip"
        return 1
    fi
    
    # Add to current session
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if command_exists uv; then
        log_success "uv installed successfully"
    else
        log_error "uv installation failed"
        return 1
    fi
}

# Main installation function
python_install() {
    install_pyenv
    install_python_version "$PYTHON_VERSION"
    install_uv
}

# Configure Python environment
python_configure() {
    log_info "Configuring Python environment..."
    
    # Add pyenv to shell configuration
    add_shell_init 'export PYENV_ROOT="$HOME/.pyenv"' "Python/pyenv configuration"
    add_shell_init 'export PATH="$PYENV_ROOT/bin:$PATH"'
    add_shell_init 'command -v pyenv &>/dev/null && eval "$(pyenv init -)"'
    
    # Add cargo/uv to PATH
    add_shell_init 'export PATH="$HOME/.cargo/bin:$PATH"' "Rust/Cargo/uv tools"
    
    log_success "Python environment configured"
}

# Verify Python installation
python_verify() {
    log_info "Verifying Python installation..."
    
    local python_ok=0
    local pyenv_ok=0
    local uv_ok=0
    
    # Check pyenv
    if command_exists pyenv; then
        pyenv_ok=1
        log_debug "✓ pyenv available"
    else
        log_warning "✗ pyenv not found in PATH"
    fi
    
    # Check Python version
    if command_exists python3; then
        local installed_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        if [[ "$installed_version" == "$PYTHON_VERSION"* ]]; then
            python_ok=1
            log_debug "✓ Python $installed_version"
        else
            log_warning "✗ Python version mismatch: got $installed_version, expected $PYTHON_VERSION"
        fi
    else
        log_warning "✗ python3 not found"
    fi
    
    # Check uv
    if command_exists uv; then
        uv_ok=1
        log_debug "✓ uv package manager available"
    else
        log_warning "✗ uv not found in PATH"
    fi
    
    # Overall verification
    if [[ $pyenv_ok -eq 1 && $python_ok -eq 1 && $uv_ok -eq 1 ]]; then
        log_success "Python environment verification passed"
        return 0
    else
        log_warning "Python environment verification had issues"
        return 1
    fi
}

# Install common Python packages
python_install_common_packages() {
    log_info "Installing common Python development packages..."
    
    local packages=(
        "pip"
        "setuptools"
        "wheel"
        "pipx"
        "black"
        "isort"
        "mypy"
        "pytest"
        "ipython"
    )
    
    for package in "${packages[@]}"; do
        if command_exists uv; then
            uv pip install "$package" || log_warning "Failed to install $package"
        else
            pip install "$package" || log_warning "Failed to install $package"
        fi
    done
    
    log_success "Common Python packages installed"
}

# =============================================================================
# MODULE INTERFACE
# =============================================================================

# Module entry point (called by main script)
module_install() {
    log_info "Installing Python module..."
    
    python_prereqs
    python_install
    python_configure
    python_verify
    
    # Optional: install common packages
    if confirm "Install common Python development packages?" "y"; then
        python_install_common_packages
    fi
    
    log_success "Python module installation completed"
}

# Module status check
module_status() {
    echo "=== Python Environment ==="
    
    if command_exists pyenv; then
        echo "✅ pyenv: $(pyenv --version 2>/dev/null)"
        
        if pyenv versions 2>/dev/null | grep -q "$PYTHON_VERSION"; then
            echo "✅ Python $PYTHON_VERSION installed"
        else
            echo "❌ Python $PYTHON_VERSION not installed"
        fi
    else
        echo "❌ pyenv not installed"
    fi
    
    if command_exists uv; then
        echo "✅ uv: $(uv --version 2>/dev/null)"
    else
        echo "❌ uv not installed"
    fi
    
    if command_exists python3; then
        echo "✅ python3: $(python3 --version 2>/dev/null)"
    else
        echo "❌ python3 not available"
    fi
}

# Module cleanup
module_clean() {
    log_info "Cleaning up Python environment..."
    
    if confirm "Remove pyenv and all Python versions?" "n"; then
        rm -rf "$HOME/.pyenv"
        log_info "pyenv removed"
    fi
    
    if confirm "Remove uv?" "n"; then
        rm -f "$HOME/.cargo/bin/uv"
        log_info "uv removed"
    fi
}

# Export module interface functions
export -f module_install module_status module_clean 