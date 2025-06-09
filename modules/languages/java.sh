#!/bin/bash
# =============================================================================
# Java Development Environment Module
# Installs Java with SDKMAN and build tools (Maven, Gradle)
# =============================================================================

# Module metadata
MODULE_NAME="java"
MODULE_DESCRIPTION="Java development environment with SDKMAN, Maven, and Gradle"
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

# Install Java prerequisites
java_prereqs() {
    log_info "Installing Java prerequisites..."
    
    install_packages \
        curl zip unzip
}

# Install SDKMAN
install_sdkman() {
    if [[ -d "$HOME/.sdkman" ]]; then
        log_info "SDKMAN already installed"
        return 0
    fi
    
    log_info "Installing SDKMAN..."
    
    if curl -s "https://get.sdkman.io" | bash; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        log_success "SDKMAN installed successfully"
    else
        log_error "SDKMAN installation failed"
        return 1
    fi
}

# Install Java versions via SDKMAN
install_java_versions() {
    log_info "Installing Java versions..."
    
    # Source SDKMAN
    if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    else
        log_error "SDKMAN not found"
        return 1
    fi
    
    # Install Java versions from config
    for java_version in "${JAVA_VERSIONS[@]}"; do
        if sdk list java | grep -q "$java_version.*installed"; then
            log_info "Java $java_version already installed"
        else
            log_info "Installing Java $java_version..."
            sdk install java "$java_version" < /dev/null
        fi
    done
    
    # Set default Java version
    log_info "Setting default Java version to $DEFAULT_JAVA"
    sdk default java "$DEFAULT_JAVA" < /dev/null
}

# Install build tools
install_build_tools() {
    log_info "Installing Java build tools..."
    
    # Source SDKMAN
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    # Install Maven
    if sdk list maven | grep -q "$MAVEN_VERSION.*installed"; then
        log_info "Maven $MAVEN_VERSION already installed"
    else
        log_info "Installing Maven $MAVEN_VERSION..."
        sdk install maven "$MAVEN_VERSION" < /dev/null
    fi
    
    # Install Gradle
    if sdk list gradle | grep -q "$GRADLE_VERSION.*installed"; then
        log_info "Gradle $GRADLE_VERSION already installed"
    else
        log_info "Installing Gradle $GRADLE_VERSION..."
        sdk install gradle "$GRADLE_VERSION" < /dev/null
    fi
}

# Configure Java environment
java_configure() {
    log_info "Configuring Java environment..."
    
    # Add SDKMAN to shell configuration
    add_to_shell_config 'export SDKMAN_DIR="$HOME/.sdkman"' "$HOME/.zshrc"
    add_to_shell_config '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' "$HOME/.zshrc"
    
    # Also add to bashrc for compatibility
    add_to_shell_config 'export SDKMAN_DIR="$HOME/.sdkman"' "$HOME/.bashrc"
    add_to_shell_config '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' "$HOME/.bashrc"
    
    log_success "Java environment configured"
}

# Verify Java installation
java_verify() {
    log_info "Verifying Java installation..."
    
    local sdkman_ok=0
    local java_ok=0
    local maven_ok=0
    local gradle_ok=0
    
    # Check SDKMAN
    if [[ -d "$HOME/.sdkman" ]]; then
        sdkman_ok=1
        log_debug "✓ SDKMAN available"
    else
        log_warning "✗ SDKMAN not found"
    fi
    
    # Source SDKMAN for checks
    if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
    
    # Check Java
    if command_exists java; then
        local java_version=$(java -version 2>&1 | head -n1)
        java_ok=1
        log_debug "✓ Java: $java_version"
    else
        log_warning "✗ Java not found"
    fi
    
    # Check Maven
    if command_exists mvn; then
        maven_ok=1
        log_debug "✓ Maven available"
    else
        log_warning "✗ Maven not found"
    fi
    
    # Check Gradle
    if command_exists gradle; then
        gradle_ok=1
        log_debug "✓ Gradle available"
    else
        log_warning "✗ Gradle not found"
    fi
    
    # Overall verification
    if [[ $sdkman_ok -eq 1 && $java_ok -eq 1 && $maven_ok -eq 1 && $gradle_ok -eq 1 ]]; then
        log_success "Java environment verification passed"
        return 0
    else
        log_warning "Java environment verification had issues"
        return 1
    fi
}

# =============================================================================
# MODULE INTERFACE
# =============================================================================

# Module entry point
module_install() {
    log_info "Installing Java module..."
    
    java_prereqs
    install_sdkman
    install_java_versions
    install_build_tools
    java_configure
    java_verify
    
    log_success "Java module installation completed"
}

# Module status check
module_status() {
    echo "=== Java Environment ==="
    
    if [[ -d "$HOME/.sdkman" ]]; then
        echo "✅ SDKMAN installed"
        
        # Source SDKMAN
        if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
            source "$HOME/.sdkman/bin/sdkman-init.sh"
            
            if command_exists java; then
                echo "✅ Java: $(java -version 2>&1 | head -n1)"
            else
                echo "❌ Java not available"
            fi
            
            if command_exists mvn; then
                echo "✅ Maven: $(mvn --version 2>/dev/null | head -n1)"
            else
                echo "❌ Maven not available"
            fi
            
            if command_exists gradle; then
                echo "✅ Gradle: $(gradle --version 2>/dev/null | head -n1)"
            else
                echo "❌ Gradle not available"
            fi
        fi
    else
        echo "❌ SDKMAN not installed"
    fi
}

# Module cleanup
module_clean() {
    log_info "Cleaning up Java environment..."
    
    if confirm "Remove SDKMAN and all Java versions?" "n"; then
        rm -rf "$HOME/.sdkman"
        log_info "SDKMAN and Java tools removed"
    fi
}

# Export module interface functions
export -f module_install module_status module_clean 