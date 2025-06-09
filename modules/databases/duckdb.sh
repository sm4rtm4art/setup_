#!/bin/bash
# =============================================================================
# DuckDB Database Module
# Installs DuckDB CLI and development tools
# =============================================================================

# Module metadata
MODULE_NAME="duckdb"
MODULE_DESCRIPTION="DuckDB analytical database with CLI and extensions"
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

# Install DuckDB prerequisites
duckdb_prereqs() {
    log_info "Installing DuckDB prerequisites..."
    
    install_packages \
        curl wget unzip
}

# Install DuckDB CLI
install_duckdb_cli() {
    if command_exists duckdb; then
        log_info "DuckDB CLI already installed"
        return 0
    fi
    
    log_info "Installing DuckDB CLI..."
    
    local version="${DUCKDB_VERSION:-latest}"
    local download_url
    
    if [[ "$version" == "latest" ]]; then
        download_url="https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip"
    else
        # Remove 'v' prefix if present
        version="${version#v}"
        download_url="https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-linux-amd64.zip"
    fi
    
    # Download and install
    local temp_dir=$(mktemp -d)
    if wget -O "$temp_dir/duckdb_cli.zip" "$download_url"; then
        unzip -q "$temp_dir/duckdb_cli.zip" -d "$temp_dir"
        
        # Install to system location
        if sudo mv "$temp_dir/duckdb" /usr/local/bin/; then
            sudo chmod +x /usr/local/bin/duckdb
            log_success "DuckDB CLI installed successfully"
        else
            log_error "Failed to install DuckDB CLI"
            return 1
        fi
    else
        log_error "Failed to download DuckDB CLI"
        return 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Install DuckDB Python extension (if Python is available)
install_duckdb_python() {
    if ! command_exists python3; then
        log_info "Python not available, skipping DuckDB Python extension"
        return 0
    fi
    
    log_info "Installing DuckDB Python extension..."
    
    if command_exists uv; then
        uv pip install duckdb
    elif command_exists pip; then
        pip install duckdb
    else
        log_warning "No Python package manager available"
        return 1
    fi
    
    log_success "DuckDB Python extension installed"
}

# Configure DuckDB
duckdb_configure() {
    log_info "Configuring DuckDB..."
    
    # Create DuckDB config directory
    mkdir -p "$HOME/.duckdb"
    
    # Create basic config file
    cat > "$HOME/.duckdb/config" << 'EOF'
# DuckDB Configuration
.mode table
.headers on
.nullvalue NULL
EOF
    
    log_success "DuckDB configured"
}

# Verify DuckDB installation
duckdb_verify() {
    log_info "Verifying DuckDB installation..."
    
    local cli_ok=0
    local python_ok=0
    
    # Check CLI
    if command_exists duckdb; then
        local version=$(duckdb --version 2>/dev/null | head -n1)
        cli_ok=1
        log_debug "✓ DuckDB CLI: $version"
    else
        log_warning "✗ DuckDB CLI not found"
    fi
    
    # Check Python extension
    if command_exists python3; then
        if python3 -c "import duckdb; print('DuckDB Python:', duckdb.__version__)" 2>/dev/null; then
            python_ok=1
            log_debug "✓ DuckDB Python extension available"
        else
            log_debug "- DuckDB Python extension not installed"
        fi
    fi
    
    # Overall verification
    if [[ $cli_ok -eq 1 ]]; then
        log_success "DuckDB verification passed"
        return 0
    else
        log_warning "DuckDB verification had issues"
        return 1
    fi
}

# =============================================================================
# MODULE INTERFACE
# =============================================================================

# Module entry point
module_install() {
    log_info "Installing DuckDB module..."
    
    duckdb_prereqs
    install_duckdb_cli
    duckdb_configure
    
    # Optional: install Python extension
    if confirm "Install DuckDB Python extension?" "y"; then
        install_duckdb_python
    fi
    
    duckdb_verify
    
    log_success "DuckDB module installation completed"
}

# Module status check
module_status() {
    echo "=== DuckDB Environment ==="
    
    if command_exists duckdb; then
        echo "✅ DuckDB CLI: $(duckdb --version 2>/dev/null | head -n1)"
    else
        echo "❌ DuckDB CLI not installed"
    fi
    
    if command_exists python3; then
        if python3 -c "import duckdb; print('✅ DuckDB Python:', duckdb.__version__)" 2>/dev/null; then
            :  # Success message already printed
        else
            echo "❌ DuckDB Python extension not available"
        fi
    fi
    
    # Show config location
    if [[ -f "$HOME/.duckdb/config" ]]; then
        echo "📁 Config: $HOME/.duckdb/config"
    fi
}

# Module cleanup
module_clean() {
    log_info "Cleaning up DuckDB..."
    
    if confirm "Remove DuckDB CLI?" "n"; then
        sudo rm -f /usr/local/bin/duckdb
        log_info "DuckDB CLI removed"
    fi
    
    if confirm "Remove DuckDB Python extension?" "n"; then
        if command_exists uv; then
            uv pip uninstall duckdb
        elif command_exists pip; then
            pip uninstall duckdb -y
        fi
        log_info "DuckDB Python extension removed"
    fi
    
    if confirm "Remove DuckDB configuration?" "n"; then
        rm -rf "$HOME/.duckdb"
        log_info "DuckDB configuration removed"
    fi
}

# Export module interface functions
export -f module_install module_status module_clean 