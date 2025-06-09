#!/bin/bash

# =============================================================================
# Professional WSL Debian 12 Development Environment Setup (Modular)
# One WSL Instance - Selective Component Installation
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# config/versions.conf
PYTHON_VERSION="${PYTHON_VERSION:-3.12.7}"
RUST_VERSION="${RUST_VERSION:-1.82.0}"
NODE_LTS_SETUP="${NODE_LTS_SETUP:-setup_lts.x}"
DUCKDB_VERSION="${DUCKDB_VERSION:-v1.2.2}"
NEOVIM_VERSION="${NEOVIM_VERSION:-v0.10.2}"
UV_VERSION="${UV_VERSION:-0.5.11}"

# config/defaults.conf
DEFAULT_SHELL_PRESET="standard"
DEFAULT_THEME="agnoster"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_wsl() {
    if ! (grep -q -i microsoft /proc/version 2>/dev/null || grep -q -i wsl /proc/version 2>/dev/null || [ -n "$WSL_DISTRO_NAME" ] || [ -d "/mnt/c" ]); then
        log_error "This script is designed for WSL. Please run it in WSL environment."
        exit 1
    fi
}

# Configure WSL-specific environment settings
configure_wsl_environment() {
    if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        export NEEDRESTART_MODE=a
        export NEEDRESTART_SUSPEND=1
        log_info "Detected WSL environment - using non-interactive installation mode"
        
        # Check for and handle the common libc6 systemd issue
        if dpkg --get-selections | grep -q "libc6.*install" && ! systemctl is-system-running >/dev/null 2>&1; then
            log_warning "Detected WSL systemd connectivity issue - will ignore systemd-related package errors"
            # Force configure broken packages while ignoring systemd errors
            sudo dpkg --force-depends --configure -a 2>/dev/null || true
            # Mark systemd-related errors as acceptable
            export WSL_SYSTEMD_WORKAROUND=1
        else
            # Standard broken package fix
            sudo dpkg --configure -a 2>/dev/null || true
        fi
        return 0
    fi
    return 1
}

# =============================================================================
# COMPONENT FUNCTIONS
# =============================================================================

# Base system setup
setup_base() {
    log_info "Setting up base system..."
    check_wsl
    
    # Configure WSL-specific environment
    configure_wsl_environment
    
    sudo apt update && sudo apt upgrade -y
    
    # Install base packages with robust error handling
    sudo apt install -y --fix-broken curl wget git build-essential software-properties-common || {
        log_warning "Some packages failed to install - attempting individual installation"
        sudo apt install -y curl || true
        sudo apt install -y wget || true
        sudo apt install -y git || true
        sudo apt install -y build-essential || true
        sudo apt install -y software-properties-common || true
    }
    
    log_success "Base system setup completed"
}

# Shell configuration
setup_shell() {
    log_info "Setting up Zsh with Oh My Zsh..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Preset selection for shell configuration
    local preset="standard"  # Default
    
    if [ -t 0 ]; then  # Only prompt if running interactively
        echo ""
        echo "Choose your shell configuration preset:"
        echo ""
        echo "  1) MINIMAL    - Fast & lightweight (git + autosuggestions)"
        echo "  2) STANDARD   - Balanced for developers (+ syntax highlighting, docker, colors) [DEFAULT]"
        echo "  3) FULL       - Feature-rich (+ fzf, tmux, completions, all enhancements)"
        echo ""
        echo "Most developers choose STANDARD (option 2)"
        echo ""
        read -p "Enter your choice (1, 2, or 3) [default: 2]: " preset_choice
        echo ""
        
        case "$preset_choice" in
            1) 
                preset="minimal"
                echo "Selected: MINIMAL preset - fastest shell startup"
                ;;
            3) 
                preset="full"
                echo "Selected: FULL preset - maximum features"
                ;;
            *) 
                preset="standard"
                echo "Selected: STANDARD preset - recommended for most developers"
                ;;
        esac
        echo ""
    fi
    
    # Install Zsh
    sudo apt install -y zsh
    
    # Install Oh My Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install plugins based on preset
    case "$preset" in
        "minimal")
            install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
            ;;
        "standard")
            install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
            install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
            install_zsh_plugin "k" "https://github.com/supercrabtree/k"
            ;;
        "full")
            install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
            install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
            install_zsh_plugin "k" "https://github.com/supercrabtree/k"
            install_zsh_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions"
            install_zsh_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting"
            install_zsh_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"
            ;;
    esac
    
    # Install Powerlevel10k if needed (for themes that require it)
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        log_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi
    
    # Generate .zshrc with selected preset
    generate_zshrc "$preset"
    
    log_success "Shell configuration completed with $preset preset"
}

# Python environment
setup_python() {
    log_info "Setting up Python environment..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Install Python build dependencies
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev
    
    # Install pyenv if not present
    if [ ! -d "$HOME/.pyenv" ]; then
        curl https://pyenv.run | bash
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
    fi
    
    # Install Python version
    if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
        pyenv install "$PYTHON_VERSION"
        pyenv global "$PYTHON_VERSION"
    fi
    
    # Install uv
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    log_success "Python environment setup completed"
}

# Java development environment
setup_java() {
    log_info "Setting up Java development environment..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Install SDKMAN if not present
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk selfupdate force
        sdk update
    fi
    
    # Add SDKMAN to .zshrc if not present
    if [ -f "$HOME/.zshrc" ] && ! grep -q "sdkman-init.sh" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# SDKMAN Configuration" >> "$HOME/.zshrc"
        echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> "$HOME/.zshrc"
        echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> "$HOME/.zshrc"
    fi
    
    # Java versions to install
    JAVA_VERSIONS=("21.0.1-tem" "17.0.9-tem" "21.0.1-graal")
    DEFAULT_JAVA="21.0.1-tem"
    
    # Install Java versions
    for java_version in "${JAVA_VERSIONS[@]}"; do
        if sdk list java | grep -q "$java_version.*installed"; then
            log_info "Java $java_version already installed"
        else
            log_info "Installing Java $java_version..."
            sdk install java "$java_version" </dev/null
        fi
    done
    
    # Set default Java
    sdk default java "$DEFAULT_JAVA" </dev/null
    
    # Install build tools
    sdk install gradle 8.5 </dev/null || log_info "Gradle already installed"
    sdk install maven 3.9.6 </dev/null || log_info "Maven already installed"
    
    log_success "Java development environment setup completed"
}

# Java frameworks
setup_java_frameworks() {
    log_info "Setting up Java frameworks..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Ensure SDKMAN is available
    if [ -d "$HOME/.sdkman" ]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        
        # Install Spring Boot CLI
        sdk install springboot 3.2.0 </dev/null || log_info "Spring Boot CLI already installed"
        
        # Install JBang
        sdk install jbang 0.114.0 </dev/null || log_info "JBang already installed"
        
        log_success "Java frameworks setup completed"
    else
        log_warning "SDKMAN not found. Please install Java component first."
    fi
}

# Rust environment
setup_rust() {
    log_info "Setting up Rust environment..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        source ~/.cargo/env
        rustup toolchain install "$RUST_VERSION"
        rustup default "$RUST_VERSION"
    fi
    
    log_success "Rust environment setup completed"
}

# Modern JavaScript runtime environment
setup_nodejs() {
    log_info "Setting up modern JavaScript runtime environment..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Install Node.js LTS (for compatibility)
    curl -fsSL "https://deb.nodesource.com/${NODE_LTS_SETUP}" | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Install modern package managers
    npm install -g pnpm@latest yarn@latest
    
    # Install modern frameworks and tools
    npm install -g @next/codemod create-next-app@latest
    npm install -g @nuxt/cli@latest
    npm install -g vite@latest
    npm install -g typescript@latest
    
    log_success "Node.js environment with modern tools completed"
}

# Deno 2 - Modern TypeScript-first runtime
setup_deno() {
    log_info "Setting up Deno 2 runtime..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    if ! command -v deno &> /dev/null; then
        curl -fsSL https://deno.land/install.sh | sh
        
        # Add deno to PATH
        echo 'export DENO_INSTALL="$HOME/.deno"' >> ~/.zshrc
        echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> ~/.zshrc
        
        # Source for current session
        export DENO_INSTALL="$HOME/.deno"
        export PATH="$DENO_INSTALL/bin:$PATH"
        
        log_success "Deno 2 runtime installed"
    else
        log_info "Deno already installed"
    fi
}

# Bun - Fast all-in-one JavaScript runtime
setup_bun() {
    log_info "Setting up Bun runtime..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
        
        # Source for current session
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        
        log_success "Bun runtime installed"
    else
        log_info "Bun already installed"
    fi
}

# Docker
setup_docker() {
    log_info "Setting up Docker..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Install Docker prerequisites
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker setup completed"
}

# DuckDB
setup_duckdb() {
    log_info "Setting up DuckDB..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    if ! command -v duckdb &> /dev/null; then
        wget "https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/duckdb_cli-linux-amd64.zip"
        unzip duckdb_cli-linux-amd64.zip
        sudo mv duckdb /usr/local/bin/
        rm duckdb_cli-linux-amd64.zip
    fi
    
    log_success "DuckDB setup completed"
}

# MariaDB
setup_mariadb() {
    log_info "Setting up MariaDB..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    sudo apt install -y mariadb-server mariadb-client
    
    log_success "MariaDB setup completed"
}

# Neovim
setup_neovim() {
    log_info "Setting up Neovim..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    if ! command -v nvim &> /dev/null; then
        wget "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz"
        tar xzf nvim-linux64.tar.gz --no-same-owner 2>/dev/null || tar xzf nvim-linux64.tar.gz
        sudo mv nvim-linux64 /opt/nvim
        sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
        rm nvim-linux64.tar.gz
    fi
    
    # Install vim-plug
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
           https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    
    log_success "Neovim setup completed"
}

# Modern CLI tools
setup_tools() {
    log_info "Setting up modern CLI tools..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Install tools available via apt
    sudo apt install -y htop btop tree jq ripgrep fd-find bat fzf tmux unzip zip gpg curl wget
    
    # Install eza (modern exa replacement) from GitHub releases
    install_eza
    
    # Install external tools
    install_external_tool "delta" "git-delta" "0.18.2" "git-delta_0.18.2_amd64.deb"
    install_external_tool "zoxide" "" "" ""
    install_external_tool "lazygit" "" "0.44.1" "lazygit_0.44.1_Linux_x86_64.tar.gz"
    
    log_success "Modern CLI tools setup completed"
}

# Install eza (modern exa replacement)
install_eza() {
    log_info "Installing eza (modern exa replacement)..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    if ! command -v eza &> /dev/null; then
        local EZA_VERSION="v0.20.0"
        local EZA_URL="https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
        
        # Download and install eza
        wget -O /tmp/eza.tar.gz "$EZA_URL"
        cd /tmp
        tar -xzf eza.tar.gz
        sudo mv eza /usr/local/bin/
        rm -f eza.tar.gz
        cd - >/dev/null
        
        log_success "eza installed successfully"
    else
        log_info "eza already installed"
    fi
}

# Setup essential tools that should always be available
setup_essentials() {
    log_info "Setting up essential tools and environment..."
    
    # Configure WSL-specific environment
    configure_wsl_environment
    
    # Ensure base system is updated
    sudo apt update && sudo apt upgrade -y
    
    # Install base packages with robust error handling
    sudo apt install -y --fix-broken curl wget git build-essential software-properties-common || {
        log_warning "Some base packages failed to install - attempting individual installation"
        sudo apt install -y curl || true
        sudo apt install -y wget || true
        sudo apt install -y git || true
        sudo apt install -y build-essential || true
        sudo apt install -y software-properties-common || true
    }
    
    # Install zsh if not present
    sudo apt install -y zsh || log_warning "Failed to install zsh"
    
    # Install essential CLI tools with error tolerance
    sudo apt install -y htop tree jq ripgrep fd-find bat fzf tmux unzip zip gpg || {
        log_warning "Some CLI tools failed to install - continuing with available tools"
    }
    
    # Install clipboard tools for WSL
    sudo apt install -y xclip wl-clipboard || log_warning "Failed to install clipboard tools"
    
    # Install eza (modern ls replacement)
    install_eza
    
    # Set zsh as default shell
    set_default_shell
    
    log_success "Essential tools setup completed"
}

# Set Zsh as default shell
set_default_shell() {
    log_info "Setting Zsh as default shell..."
    
    local current_shell="$(basename "$SHELL")"
    
    if [ "$current_shell" != "zsh" ]; then
        log_info "Attempting to set Zsh as the default shell..."
        
        # Check if zsh is in /etc/shells
        if ! grep -q "$(which zsh)" /etc/shells; then
            echo "$(which zsh)" | sudo tee -a /etc/shells
        fi
        
        # Change default shell
        if chsh -s "$(which zsh)"; then
            log_success "Zsh set as default shell. Please log out and back in for changes to take effect."
        else
            log_warning "Failed to set Zsh as default shell automatically. You can set it manually:"
            log_warning "  chsh -s \$(which zsh)"
        fi
    else
        log_info "Zsh is already the default shell."
    fi
}

# Clipboard integration
setup_clipboard() {
    log_info "Setting up clipboard integration..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    sudo apt install -y xclip wl-clipboard
    
    log_success "Clipboard integration setup completed"
}

# Data development stack
setup_data_stack() {
    log_info "Setting up data development stack..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Ensure Python is available
    if ! command -v python3 &> /dev/null; then
        log_error "Python not found. Please run './setup-modular.sh python' first."
        exit 1
    fi
    
    # Install data packages
    local packages=("dbt-core" "dbt-postgres" "dbt-duckdb" "pandas" "numpy" "matplotlib" "seaborn" "jupyter" "polars" "pyarrow")
    
    if command -v uv &> /dev/null; then
        for package in "${packages[@]}"; do
            uv pip install "$package"
        done
    else
        pip install "${packages[@]}"
    fi
    
    log_success "Data development stack setup completed"
}

# Helper function to ensure basic dependencies are available
ensure_base_dependencies() {
    if ! command -v wget &> /dev/null || ! command -v curl &> /dev/null || ! command -v git &> /dev/null; then
        log_info "Installing essential base dependencies..."
        
        # Configure WSL-specific environment
        configure_wsl_environment
        
        # Update package lists
        sudo apt update
        
        # Install essential tools with WSL-aware error handling
        if ! sudo apt install -y --fix-broken curl wget git build-essential software-properties-common; then
            if [ "$WSL_SYSTEMD_WORKAROUND" = "1" ]; then
                log_warning "WSL systemd issue detected - installing packages individually and ignoring configuration errors"
                # Install packages while accepting configuration failures
                sudo apt install -y curl 2>/dev/null || sudo dpkg --force-depends -i /var/cache/apt/archives/curl*.deb 2>/dev/null || true
                sudo apt install -y wget 2>/dev/null || sudo dpkg --force-depends -i /var/cache/apt/archives/wget*.deb 2>/dev/null || true
                sudo apt install -y git 2>/dev/null || sudo dpkg --force-depends -i /var/cache/apt/archives/git*.deb 2>/dev/null || true
                sudo apt install -y build-essential 2>/dev/null || true
                sudo apt install -y software-properties-common 2>/dev/null || true
            else
                log_warning "Some packages failed to install - attempting individual installation"
                sudo apt install -y curl || true
                sudo apt install -y wget || true  
                sudo apt install -y git || true
                sudo apt install -y build-essential || true
                sudo apt install -y software-properties-common || true
            fi
        fi
        
        # Verify essential tools are available (check if they can actually run)
        local working_tools=()
        local broken_tools=()
        
        # Test curl
        if command -v curl &> /dev/null && curl --version &> /dev/null; then
            working_tools+=("curl")
        else
            broken_tools+=("curl")
        fi
        
        # Test wget  
        if command -v wget &> /dev/null && wget --version &> /dev/null; then
            working_tools+=("wget")
        else
            broken_tools+=("wget")
        fi
        
        # Test git
        if command -v git &> /dev/null && git --version &> /dev/null; then
            working_tools+=("git")
        else
            broken_tools+=("git")
        fi
        
        if [ ${#working_tools[@]} -eq 3 ]; then
            log_success "All essential tools installed and working"
        elif [ ${#working_tools[@]} -eq 0 ]; then
            log_warning "No essential tools are fully working due to WSL dependency issues"
            log_warning "This is common in fresh WSL instances. You can fix this by:"
            log_warning "  1. Restarting WSL: wsl --shutdown && wsl"
            log_warning "  2. Or running: sudo apt --fix-broken install"
            log_warning "Most components will still install successfully using alternative methods"
        else
            log_info "Working tools: ${working_tools[*]}"
            log_warning "Tools with dependency issues: ${broken_tools[*]}"
            log_info "This is normal in fresh WSL - continuing with available tools"
            
            # Continue regardless - many things can work with git or alternative methods
            if [[ " ${working_tools[*]} " =~ " curl " ]] || [[ " ${working_tools[*]} " =~ " wget " ]]; then
                log_info "Download tools available - full functionality enabled"
            elif [[ " ${working_tools[*]} " =~ " git " ]]; then
                log_info "Git available - most components can still be installed"
            else
                log_warning "Limited functionality - some components may need manual installation"
            fi
        fi
    fi
}

# Bootstrap: Install just if not available
setup_bootstrap() {
    log_info "Bootstrapping environment..."
    
    # Ensure base dependencies are available
    ensure_base_dependencies
    
    # Check if just is installed
    if ! command -v just &> /dev/null; then
        log_info "Installing just command runner..."
        
        # Try working download tools
        local download_success=false
        
        # Try curl first if it's working
        if command -v curl &> /dev/null && curl --version &> /dev/null 2>&1; then
            log_info "Using curl to download just..."
            if curl -L "https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz" -o /tmp/just.tar.gz 2>/dev/null; then
                download_success=true
            fi
        fi
        
        # Fallback to wget if curl failed
        if [ "$download_success" = false ] && command -v wget &> /dev/null && wget --version &> /dev/null 2>&1; then
            log_info "Using wget to download just..."
            if wget "https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz" -O /tmp/just.tar.gz 2>/dev/null; then
                download_success=true
            fi
        fi
        
        # Check if download succeeded
        if [ "$download_success" = false ]; then
            log_warning "Cannot download just automatically due to WSL dependency issues"
            log_info "You can install just manually later with:"
            log_info "  curl -L https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz -o /tmp/just.tar.gz"
            log_info "  cd /tmp && tar xzf just.tar.gz && sudo mv just /usr/local/bin/"
            log_info "For now, you can use './setup-modular.sh' directly"
            log_success "Bootstrap completed (just installation skipped due to dependency issues)"
            return 0
        fi
        
        # Extract and install
        cd /tmp
        tar xzf just.tar.gz
        sudo mv just /usr/local/bin/
        rm -f just.tar.gz
        cd - >/dev/null
        
        # Verify installation
        if command -v just &> /dev/null; then
            log_success "just installed successfully ($(just --version))"
        else
            log_error "Failed to install just. Please install manually:"
            log_error "  curl -L https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz | tar xz"
            log_error "  sudo mv just /usr/local/bin/"
            exit 1
        fi
    else
        log_info "just is already installed ($(just --version))"
    fi
    
    log_success "Bootstrap completed"
}

# Clean up broken configurations
setup_clean() {
    log_info "Cleaning up broken configurations..."
    
    # Clean up broken .zshrc files
    if [ -f "$HOME/.zshrc.bak" ]; then
        log_info "Removing .zshrc backup files..."
        rm -f "$HOME/.zshrc.bak"*
    fi
    
    # Clean up Oh My Zsh if corrupted
    if [ -d "$HOME/.oh-my-zsh" ] && [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        log_warning "Removing corrupted Oh My Zsh installation..."
        rm -rf "$HOME/.oh-my-zsh"
    fi
    
    # Clean up temporary files
    rm -f /tmp/setup-*
    
    log_success "Cleanup completed"
}

# Status check - Fixed to detect actual installations, not just system packages
setup_status() {
    log_info "Checking system status..."
    
    echo "=== Installed Components ==="
    
    # Zsh: Check if properly configured with Oh My Zsh, not just if command exists
    if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.zshrc" ] && grep -q "oh-my-zsh" "$HOME/.zshrc" 2>/dev/null; then
        if [ "$SHELL" = "$(which zsh)" ]; then
            echo "✅ Zsh (active shell + Oh My Zsh)"
        else
            echo "🟡 Zsh (installed but not default shell)"
        fi
    else
        echo "❌ Zsh"
    fi
    
    # Python: Check for our pyenv installation, not just system python3
    if command -v pyenv >/dev/null 2>&1 && command -v uv >/dev/null 2>&1; then
        echo "✅ Python (pyenv + uv)"
    elif [ -d "$HOME/.pyenv" ]; then
        echo "🟡 Python (pyenv installed but not in PATH)"
    else
        echo "❌ Python"
    fi
    
    # Rust: Check for rustup installation
    if command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
        echo "✅ Rust ($(rustc --version 2>/dev/null | cut -d' ' -f2))"
    elif [ -d "$HOME/.cargo" ]; then
        echo "🟡 Rust (installed but not in PATH)"
    else
        echo "❌ Rust"
    fi
    
    # Java: Check for SDKMAN installation
    if [ -d "$HOME/.sdkman" ] && command -v java >/dev/null 2>&1; then
        echo "✅ Java (SDKMAN + $(java -version 2>&1 | head -1 | cut -d'"' -f2))"
    elif [ -d "$HOME/.sdkman" ]; then
        echo "🟡 Java (SDKMAN installed but not active)"
    else
        echo "❌ Java"
    fi
    
    echo ""
    echo "=== JavaScript Runtimes ==="
    command -v node >/dev/null && echo "✅ Node.js $(node --version 2>/dev/null)" || echo "❌ Node.js"
    command -v deno >/dev/null && echo "✅ Deno $(deno --version 2>/dev/null | head -1)" || echo "❌ Deno"
    command -v bun >/dev/null && echo "✅ Bun $(bun --version 2>/dev/null)" || echo "❌ Bun"
    command -v pnpm >/dev/null && echo "✅ pnpm $(pnpm --version 2>/dev/null)" || echo "❌ pnpm"
    
    echo ""
    echo "=== Other Tools ==="
    command -v docker >/dev/null && echo "✅ Docker" || echo "❌ Docker"
    command -v nvim >/dev/null && echo "✅ Neovim" || echo "❌ Neovim"
    command -v duckdb >/dev/null && echo "✅ DuckDB" || echo "❌ DuckDB"
    command -v mariadb >/dev/null && echo "✅ MariaDB" || echo "❌ MariaDB"
    command -v just >/dev/null && echo "✅ just" || echo "❌ just"
    
    echo ""
    echo "=== Configuration Files ==="
    if [ -f "$HOME/.zshrc" ] && grep -q "Professional .zshrc Configuration" "$HOME/.zshrc" 2>/dev/null; then
        echo "✅ .zshrc (generated by our setup)"
    elif [ -f "$HOME/.zshrc" ]; then
        echo "🟡 .zshrc (exists but not from our setup)"
    else
        echo "❌ .zshrc"
    fi
    
    if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        echo "✅ Oh My Zsh"
    else
        echo "❌ Oh My Zsh"
    fi
    
    [ -f "$HOME/.p10k.zsh" ] && echo "✅ Powerlevel10k config" || echo "❌ Powerlevel10k config"
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Generic GitHub release installer
install_github_release() {
    local tool_name="$1"
    local github_repo="$2"
    local version="$3"
    local asset_pattern="$4"
    local binary_name="${5:-$tool_name}"
    
    if ! command -v "$binary_name" &> /dev/null; then
        log_info "Installing $tool_name $version..."
        local download_url="https://github.com/$github_repo/releases/download/$version/$asset_pattern"
        
        case "$asset_pattern" in
            *.deb)
                wget "$download_url"
                sudo dpkg -i "$asset_pattern" || sudo apt-get install -f -y
                rm "$asset_pattern"
                ;;
            *.tar.gz)
                wget "$download_url"
                tar xzf "$asset_pattern"
                # Extract binary and move to /usr/local/bin
                find . -name "$binary_name" -type f -executable | head -1 | xargs sudo mv /usr/local/bin/
                rm -rf "${asset_pattern%.*.*}" "$asset_pattern"
                ;;
            *)
                log_warning "Unsupported asset format for $tool_name"
                return 1
                ;;
        esac
        
        log_success "$tool_name $version installed"
    else
        log_info "$tool_name already installed"
    fi
}

install_zsh_plugin() {
    local plugin_name="$1"
    local plugin_url="$2"
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
    
    if [ ! -d "$plugin_dir" ]; then
        git clone "$plugin_url" "$plugin_dir"
    fi
}

install_external_tool() {
    local tool_name="$1"
    local package_name="$2"
    local version="$3"
    local filename="$4"
    
    if ! command -v "$tool_name" &> /dev/null; then
        case "$tool_name" in
            "zoxide")
                curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
                ;;
            *)
                if [ -n "$filename" ] && [ -n "$version" ]; then
                    local url="https://github.com/dandavison/delta/releases/download/${version}/${filename}"
                    if [[ "$filename" == *.deb ]]; then
                        wget "$url" && sudo dpkg -i "$filename" && rm "$filename"
                    elif [[ "$filename" == *.tar.gz ]]; then
                        wget "$url" && tar xzf "$filename" && sudo mv "$tool_name" /usr/local/bin/ && rm "$filename"
                    fi
                fi
                ;;
        esac
    fi
}

generate_zshrc() {
    local preset="${1:-standard}"  # Accept preset parameter, default to standard
    log_info "Generating clean .zshrc configuration with $preset preset..."
    
    # Theme selection - prompt user for preference
    local theme_choice="agnoster"  # Default to agnoster
    
    if [ -t 0 ]; then  # Only prompt if running interactively
        echo ""
        echo "Choose your Zsh theme:"
        echo ""
        echo "  1) AGNOSTER     - Classic, clean with git status [DEFAULT]"
        echo "  2) ROBBYRUSSELL - Minimal, fastest startup"  
        echo "  3) SPACESHIP    - Modern, colorful, feature-rich"
        echo "  4) POWERLEVEL10K - Ultimate customization (setup wizard)"
        echo ""
        echo "AGNOSTER is recommended for most users - professional and informative"
        echo ""
        read -p "Enter your choice (1, 2, 3, or 4) [default: 1]: " choice
        echo ""
        
        case "$choice" in
            2) 
                theme_choice="robbyrussell"
                echo "Selected: ROBBYRUSSELL - minimal and fast"
                ;;
            3) 
                theme_choice="spaceship"
                echo "Selected: SPACESHIP - modern and colorful"
                ;;
            4) 
                theme_choice="powerlevel10k/powerlevel10k"
                echo "Selected: POWERLEVEL10K - will run setup wizard"
                ;;
            *) 
                theme_choice="agnoster"
                echo "Selected: AGNOSTER - professional and clean"
                ;;
        esac
        echo ""
    fi
    
    # Backup existing .zshrc with timestamp
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing .zshrc backed up"
    fi
    
    # Install additional themes if needed
    if [[ "$theme_choice" == "spaceship" ]]; then
        local spaceship_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt"
        if [ ! -d "$spaceship_dir" ]; then
            log_info "Installing Spaceship theme..."
            git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$spaceship_dir" --depth=1
            ln -sf "$spaceship_dir/spaceship.zsh-theme" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship.zsh-theme"
        fi
        theme_choice="spaceship"
    fi
    
    # Generate clean .zshrc configuration
    cat > "$HOME/.zshrc" << EOF
# =============================================================================
# Professional .zshrc Configuration for WSL Debian 12
# Clean Data Development Environment
# =============================================================================

# Oh My Zsh configuration
export ZSH="\$HOME/.oh-my-zsh"

# Theme configuration
ZSH_THEME="$theme_choice"

# Theme-specific configurations
$(if [[ "$theme_choice" == "agnoster" ]]; then
    echo '# Agnoster theme customization'
    echo 'DEFAULT_USER="$USER"  # Hide username when you are the default user'
    echo '# To hide username completely: prompt_context() {}'
elif [[ "$theme_choice" == "spaceship" ]]; then
    echo '# Spaceship theme customization'
    echo 'SPACESHIP_PROMPT_ORDER=('
    echo '  user          # Username section'
    echo '  dir           # Current directory section'
    echo '  host          # Hostname section'
    echo '  git           # Git section (git_branch + git_status)'
    echo '  node          # Node.js section'
    echo '  python        # Python section'
    echo '  rust          # Rust section'
    echo '  java          # Java section'
    echo '  docker        # Docker section'
    echo '  exec_time     # Execution time'
    echo '  line_sep      # Line break'
    echo '  battery       # Battery level and status'
    echo '  vi_mode       # Vi-mode indicator'
    echo '  jobs          # Background jobs indicator'
    echo '  exit_code     # Exit code section'
    echo '  char          # Prompt character'
    echo ')'
    echo 'SPACESHIP_TIME_SHOW=true'
    echo 'SPACESHIP_DIR_TRUNC=3'
    echo 'SPACESHIP_CHAR_SYMBOL="❯ "'
    echo 'SPACESHIP_CHAR_SUFFIX=" "'
elif [[ "$theme_choice" == "robbyrussell" ]]; then
    echo '# Robbyrussell theme (minimal, fast)'
    echo '# No additional configuration needed - clean and lightweight'
fi)

# Plugins (based on $preset preset)
$(case "$preset" in
    "minimal")
        echo 'plugins=('
        echo '    git'
        echo '    zsh-autosuggestions'
        echo ')'
        ;;
    "standard")
        echo 'plugins=('
        echo '    git'
        echo '    zsh-autosuggestions'
        echo '    zsh-syntax-highlighting'
        echo '    docker'
        echo '    docker-compose'
        echo '    python'
        echo '    rust'
        echo '    k'
        echo '    colored-man-pages'
        echo '    command-not-found'
        echo ')'
        ;;
    "full")
        echo 'plugins=('
        echo '    git'
        echo '    zsh-autosuggestions'
        echo '    zsh-syntax-highlighting'
        echo '    fast-syntax-highlighting'
        echo '    zsh-completions'
        echo '    zsh-history-substring-search'
        echo '    docker'
        echo '    docker-compose'
        echo '    python'
        echo '    rust'
        echo '    k'
        echo '    fzf'
        echo '    tmux'
        echo '    colored-man-pages'
        echo '    command-not-found'
        echo '    history-substring-search'
        echo ')'
        ;;
esac)

# Load Oh My Zsh
source \$ZSH/oh-my-zsh.sh

# =============================================================================
# MacOS-like Aliases
# =============================================================================

alias la='ls -la'
alias ll='ls -l'
alias l='ls -CF'
alias lah='ls -lah'
alias ls='ls --color=auto'

# Enhanced ls alternatives (if eza is installed)
if command -v eza &> /dev/null; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -l --group-directories-first'
    alias la='eza -la --group-directories-first'
    alias tree='eza --tree'
    alias lst='eza --tree --level=2'
elif command -v exa &> /dev/null; then
    # Fallback to exa if still available
    alias ls='exa --color=auto --group-directories-first'
    alias ll='exa -l --group-directories-first'
    alias la='exa -la --group-directories-first'
    alias tree='exa --tree'
fi

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# =============================================================================
# Clipboard Integration (WSL + Windows)
# =============================================================================
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe Get-Clipboard'
alias copy='clip.exe'
alias paste='powershell.exe Get-Clipboard'

# =============================================================================
# Development Environment
# =============================================================================

# Python/pyenv
export PYENV_ROOT="\$HOME/.pyenv"
export PATH="\$PYENV_ROOT/bin:\$PATH"
if command -v pyenv &> /dev/null; then
    eval "\$(pyenv init -)"
fi

# Rust/Cargo
export PATH="\$HOME/.cargo/bin:\$PATH"

# Node.js/npm
export PATH="\$HOME/.npm-global/bin:\$PATH"

# Local binaries
export PATH="\$HOME/.local/bin:\$PATH"

# Neovim
export EDITOR='nvim'
export VISUAL='nvim'
alias vim='nvim'
alias vi='nvim'

# =============================================================================
# Git Aliases
# =============================================================================
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias gs='git status'
alias glog='git log --oneline --decorate --graph'

# =============================================================================
# Docker Aliases
# =============================================================================
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dexec='docker exec -it'

# =============================================================================
# Database Aliases
# =============================================================================
alias duck='duckdb'
alias mysql='mariadb'

# =============================================================================
# Utility Functions
# =============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Quick file search
ff() {
    find . -name "*$1*" -type f
}

# Quick directory search
fd() {
    find . -name "*$1*" -type d
}

# =============================================================================
# Environment Variables
# =============================================================================

# History configuration
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups

# FZF configuration
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
if command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow'
elif command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
fi

# =============================================================================
# Data Development Specific
# =============================================================================

# dbt aliases
alias dbt-run='dbt run'
alias dbt-test='dbt test'
alias dbt-compile='dbt compile'
alias dbt-docs='dbt docs generate && dbt docs serve'

# Python data science quick start
pydata() {
    python3 -c "
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import duckdb
print('Data science environment loaded!')
print('Available: pandas (pd), numpy (np), matplotlib.pyplot (plt), seaborn (sns), duckdb')
exec(open('/dev/stdin').read())
"
}

# Quick DuckDB session with common imports
duckdata() {
    duckdb -c "
    INSTALL pandas;
    LOAD pandas;
    SELECT 'DuckDB data environment ready!' as message;
    "
}

# =============================================================================
# WSL Specific Configurations
# =============================================================================

# Fix for WSL file permissions
if grep -q Microsoft /proc/version; then
    if [ "$(umask)" = "0000" ]; then
        umask 0022
    fi
fi

# Windows integration
alias explorer='explorer.exe'
alias code='code.exe'

# =============================================================================
# Load Additional Configurations
# =============================================================================

# Load fzf if available
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# =============================================================================
# Theme-specific final configurations
# =============================================================================

$(if [[ "$theme_choice" == "agnoster" || "$theme_choice" == "spaceship" ]]; then
    echo '# For best results with Agnoster/Spaceship, install a Powerline font'
    echo '# Recommended fonts: Fira Code Nerd Font, Source Code Pro, MesloLGS NF'
    echo 'echo "Tip: Install a Nerd Font for optimal theme appearance"'
elif [[ "$theme_choice" == "powerlevel10k/powerlevel10k" ]]; then
    echo '# Powerlevel10k configuration'
    echo '# To configure: p10k configure'
    echo 'if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then'
    echo '  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"'
    echo 'fi'
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
fi)

# Professional welcome message
echo ""
echo "Professional WSL Development Environment Ready"
echo "Quick commands: 'la' (list files) | 'just --list' (setup options)"
$(if [[ "$theme_choice" == "agnoster" ]]; then
    echo 'echo "Theme: Agnoster - clean and informative"'
elif [[ "$theme_choice" == "spaceship" ]]; then
    echo 'echo "Theme: Spaceship - modern and feature-rich"'
elif [[ "$theme_choice" == "robbyrussell" ]]; then
    echo 'echo "Theme: Robbyrussell - minimal and fast"'
elif [[ "$theme_choice" == "powerlevel10k/powerlevel10k" ]]; then
    echo 'echo "Theme: Powerlevel10k - run p10k configure to customize"'
fi)
$(case "$preset" in
    "minimal")
        echo 'echo "Preset: Minimal - lightweight and fast"'
        ;;
    "standard")
        echo 'echo "Preset: Standard - balanced for developers"'
        ;;
    "full")
        echo 'echo "Preset: Full - feature-rich with all enhancements"'
        ;;
esac)
echo ""
EOF
    
    log_success "Clean .zshrc configuration generated"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

show_usage() {
    cat << EOF
Professional WSL Debian 12 Modular Setup (One Instance, Selective Components)

Usage: $0 <component> [options]

Components:
  all           Install EVERYTHING (complete dev environment)
  essentials    Install essential tools (eza, clipboard, zsh default shell) 
  base          Install base system packages
  shell         Install and configure Zsh with Oh My Zsh
  python        Install Python with pyenv
  rust          Install Rust with rustup
  java          Install Java with SDKMAN (JDK 21, 17, 11, GraalVM)
  java-frameworks Install Java frameworks (Spring Boot, Micronaut, Quarkus, JBang)
  nodejs        Install Node.js LTS + modern tools (Next.js, Vite, TypeScript)
  deno          Install Deno 2 runtime (modern TypeScript-first)
  bun           Install Bun runtime (fast all-in-one)
  js-runtimes   Install all JavaScript runtimes (Node.js, Deno, Bun)
  modern-web    Install modern web runtimes (Deno + Bun)
  languages     Install all programming languages
  tools         Install modern CLI tools
  docker        Install Docker and Docker Compose
  neovim        Install Neovim with vim-plug
  editors       Install all editors
  duckdb        Install DuckDB
  mariadb       Install MariaDB
  databases     Install all databases
  clipboard     Setup clipboard integration
  data-stack    Install data development packages
  bootstrap     Install just command runner
  clean         Clean up broken configurations
  status        Show installation status

Options:
  -h, --help    Show this help message

Examples:
  $0 essentials           # Install essential tools (eza, clipboard, zsh default)
  $0 base                 # Install base system only
  $0 python               # Install Python environment only
  $0 languages            # Install all programming languages
  
For better experience with 'just':
  $0 bootstrap            # Install just first
  just --list             # Show all available commands
  just python             # Install Python
  just dev-minimal        # Install minimal dev environment
EOF
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    case "$1" in
        "essentials") setup_essentials ;;
        "base") setup_base ;;
        "shell") setup_shell ;;
        "python") setup_python ;;
        "rust") setup_rust ;;
        "java") setup_java ;;
        "java-frameworks") setup_java_frameworks ;;
        "nodejs") setup_nodejs ;;
        "deno") setup_deno ;;
        "bun") setup_bun ;;
        "js-runtimes") setup_nodejs && setup_deno && setup_bun ;;
        "languages") setup_python && setup_rust && setup_nodejs && setup_java ;;
        "modern-web") setup_deno && setup_bun ;;
        "tools") setup_tools ;;
        "docker") setup_docker ;;
        "neovim") setup_neovim ;;
        "editors") setup_neovim ;;
        "duckdb") setup_duckdb ;;
        "mariadb") setup_mariadb ;;
        "databases") setup_duckdb && setup_mariadb ;;
        "clipboard") setup_clipboard ;;
        "data-stack") setup_data_stack ;;
        "bootstrap") setup_bootstrap ;;
        "clean") setup_clean ;;
        "status") setup_status ;;
        "all") 
            log_info "Installing complete development environment..."
            setup_base && 
            setup_essentials && 
            setup_shell && 
            setup_python && 
            setup_rust && 
            setup_java && 
            setup_nodejs && 
            setup_deno && 
            setup_bun && 
            setup_tools && 
            setup_neovim && 
            setup_docker && 
            setup_duckdb && 
            setup_mariadb && 
            setup_clipboard && 
            setup_data_stack &&
            log_success "Complete development environment installed!" 
            ;;
        "-h"|"--help") show_usage ;;
        *) 
            log_error "Unknown component: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"