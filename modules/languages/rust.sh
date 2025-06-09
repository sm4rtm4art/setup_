#!/bin/bash
# =============================================================================
# Rust Development Environment Module
# Installs Rust with rustup and common development tools
# =============================================================================

# Module metadata
MODULE_NAME="rust"
MODULE_DESCRIPTION="Rust development environment with rustup and cargo tools"
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

# Install Rust prerequisites
rust_prereqs() {
    log_info "Installing Rust prerequisites..."
    
    install_packages \
        curl build-essential pkg-config libssl-dev
}

# Install Rust via rustup
install_rust() {
    if command_exists rustc; then
        log_info "Rust already installed"
        return 0
    fi
    
    log_info "Installing Rust via rustup..."
    
    # Download and install rustup
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable; then
        # Source cargo environment
        source "$HOME/.cargo/env"
        log_success "Rust installed successfully"
    else
        log_error "Rust installation failed"
        return 1
    fi
}

# Install specific Rust version if configured
install_rust_version() {
    if [[ -n "${RUST_VERSION:-}" ]]; then
        log_info "Installing Rust version $RUST_VERSION..."
        
        # Source cargo environment
        source "$HOME/.cargo/env"
        
        if rustup toolchain install "$RUST_VERSION"; then
            rustup default "$RUST_VERSION"
            log_success "Rust $RUST_VERSION set as default"
        else
            log_warning "Failed to install Rust $RUST_VERSION, using stable"
        fi
    fi
}

# Install Rust components
install_rust_components() {
    log_info "Installing Rust components..."
    
    # Source cargo environment
    source "$HOME/.cargo/env"
    
    local components=(
        "clippy"      # Linting
        "rustfmt"     # Formatting
        "rust-analyzer"  # Language server
    )
    
    for component in "${components[@]}"; do
        if rustup component add "$component"; then
            log_debug "✓ $component installed"
        else
            log_warning "✗ Failed to install $component"
        fi
    done
}

# Install common Rust tools
install_rust_tools() {
    log_info "Installing common Rust tools..."
    
    # Source cargo environment
    source "$HOME/.cargo/env"
    
    local tools=(
        "cargo-watch"     # Auto-rebuild on file changes
        "cargo-edit"      # Add/remove dependencies from CLI
        "cargo-audit"     # Security vulnerability scanner
        "sccache"         # Compilation cache for faster builds
    )
    
    for tool in "${tools[@]}"; do
        if cargo install "$tool"; then
            log_debug "✓ $tool installed"
        else
            log_warning "✗ Failed to install $tool"
        fi
    done
}

# Configure Rust environment
rust_configure() {
    log_info "Configuring Rust environment..."
    
    # Add cargo to shell configuration
    add_to_shell_config 'source "$HOME/.cargo/env"' "$HOME/.zshrc"
    add_to_shell_config 'source "$HOME/.cargo/env"' "$HOME/.bashrc"
    
    # Add cargo bin to PATH
    add_to_shell_config 'export PATH="$HOME/.cargo/bin:$PATH"' "$HOME/.zshrc"
    add_to_shell_config 'export PATH="$HOME/.cargo/bin:$PATH"' "$HOME/.bashrc"
    
    log_success "Rust environment configured"
}

# Verify Rust installation
rust_verify() {
    log_info "Verifying Rust installation..."
    
    # Source cargo environment
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    local rustc_ok=0
    local cargo_ok=0
    local clippy_ok=0
    local rustfmt_ok=0
    
    # Check rustc
    if command_exists rustc; then
        local rust_version=$(rustc --version 2>/dev/null)
        rustc_ok=1
        log_debug "✓ $rust_version"
    else
        log_warning "✗ rustc not found"
    fi
    
    # Check cargo
    if command_exists cargo; then
        cargo_ok=1
        log_debug "✓ cargo available"
    else
        log_warning "✗ cargo not found"
    fi
    
    # Check clippy
    if command_exists cargo-clippy; then
        clippy_ok=1
        log_debug "✓ clippy available"
    else
        log_warning "✗ clippy not found"
    fi
    
    # Check rustfmt
    if command_exists rustfmt; then
        rustfmt_ok=1
        log_debug "✓ rustfmt available"
    else
        log_warning "✗ rustfmt not found"
    fi
    
    # Overall verification
    if [[ $rustc_ok -eq 1 && $cargo_ok -eq 1 && $clippy_ok -eq 1 && $rustfmt_ok -eq 1 ]]; then
        log_success "Rust environment verification passed"
        return 0
    else
        log_warning "Rust environment verification had issues"
        return 1
    fi
}

# =============================================================================
# MODULE INTERFACE
# =============================================================================

# Module entry point
module_install() {
    log_info "Installing Rust module..."
    
    rust_prereqs
    install_rust
    install_rust_version
    install_rust_components
    rust_configure
    rust_verify
    
    # Optional: install common tools
    if confirm "Install common Rust development tools?" "y"; then
        install_rust_tools
    fi
    
    log_success "Rust module installation completed"
}

# Module status check
module_status() {
    echo "=== Rust Environment ==="
    
    # Source cargo environment
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    if command_exists rustc; then
        echo "✅ Rust: $(rustc --version 2>/dev/null)"
        
        if command_exists cargo; then
            echo "✅ Cargo: $(cargo --version 2>/dev/null)"
        else
            echo "❌ Cargo not available"
        fi
        
        if command_exists cargo-clippy; then
            echo "✅ Clippy available"
        else
            echo "❌ Clippy not available"
        fi
        
        if command_exists rustfmt; then
            echo "✅ Rustfmt available"
        else
            echo "❌ Rustfmt not available"
        fi
        
        # Show installed toolchains
        if command_exists rustup; then
            echo "📋 Toolchains:"
            rustup toolchain list 2>/dev/null | sed 's/^/   /'
        fi
    else
        echo "❌ Rust not installed"
    fi
}

# Module cleanup
module_clean() {
    log_info "Cleaning up Rust environment..."
    
    if confirm "Remove Rust toolchain and cargo tools?" "n"; then
        if command_exists rustup; then
            rustup self uninstall -y
        fi
        rm -rf "$HOME/.cargo" "$HOME/.rustup"
        log_info "Rust toolchain removed"
    fi
}

# Export module interface functions
export -f module_install module_status module_clean 