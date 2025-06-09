#!/bin/bash
# =============================================================================
# Professional WSL Debian 12 Setup (Refactored - Modular Architecture)
# Demonstrates clean separation of concerns and modular design
# =============================================================================

set -euo pipefail

# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load core libraries
source "${SCRIPT_DIR}/lib/core.sh"
source "${SCRIPT_DIR}/lib/wsl.sh"
source "${SCRIPT_DIR}/lib/installer.sh"

# Load configuration
load_config "${SCRIPT_DIR}/config/versions.conf"

# Global module registry
declare -A MODULES=()
declare -A MODULE_DEPS=()
declare -A MODULE_STATUS=()

# =============================================================================
# MODULE MANAGEMENT SYSTEM
# =============================================================================

# Discover and register available modules
discover_modules() {
    log_info "Discovering available modules..."
    
    # Find all module files
    local module_count=0
    while IFS= read -r -d '' module_file; do
        load_module "$module_file"
        ((module_count++))
    done < <(find "${SCRIPT_DIR}/modules" -name "*.sh" -type f -print0 2>/dev/null)
    
    log_success "Discovered $module_count modules"
}

# Load a single module
load_module() {
    local module_path="$1"
    
    # Extract module directory structure for organization
    local relative_path="${module_path#$SCRIPT_DIR/modules/}"
    local category=$(dirname "$relative_path")
    local filename=$(basename "$relative_path" .sh)
    
    # Source the module to get metadata
    if source "$module_path" 2>/dev/null; then
        local module_id="${category}/${filename}"
        if [[ "$category" == "." ]]; then
            module_id="$filename"
        fi
        
        # Register module
        MODULES["$module_id"]="$module_path"
        
        # Store dependencies if defined
        if [[ -n "${MODULE_DEPS:-}" ]]; then
            MODULE_DEPS["$module_id"]="${MODULE_DEPS[*]}"
        fi
        
        log_debug "Loaded module: $module_id (${MODULE_DESCRIPTION:-No description})"
    else
        log_warning "Failed to load module: $module_path"
    fi
}

# Check if module exists
module_exists() {
    local module_id="$1"
    [[ -n "${MODULES[$module_id]:-}" ]]
}

# Get module dependencies
get_module_deps() {
    local module_id="$1"
    echo "${MODULE_DEPS[$module_id]:-}"
}

# =============================================================================
# DEPENDENCY RESOLUTION
# =============================================================================

# Resolve module dependencies (topological sort)
resolve_dependencies() {
    local target_modules=("$@")
    local resolved=()
    local visited=()
    
    # Recursive dependency resolver
    resolve_module() {
        local module="$1"
        
        # Check if already visited (circular dependency)
        if [[ " ${visited[*]} " == *" $module "* ]]; then
            log_error "Circular dependency detected involving: $module"
            return 1
        fi
        
        # Check if already resolved
        if [[ " ${resolved[*]} " == *" $module "* ]]; then
            return 0
        fi
        
        # Add to visited
        visited+=("$module")
        
        # Resolve dependencies first
        local deps=($(get_module_deps "$module"))
        for dep in "${deps[@]}"; do
            if module_exists "$dep"; then
                resolve_module "$dep"
            else
                log_warning "Dependency '$dep' not found for module '$module'"
            fi
        done
        
        # Add to resolved list
        resolved+=("$module")
        
        # Remove from visited (for other branches)
        visited=("${visited[@]/$module}")
    }
    
    # Resolve all target modules
    for module in "${target_modules[@]}"; do
        if module_exists "$module"; then
            resolve_module "$module"
        else
            log_error "Module not found: $module"
            return 1
        fi
    done
    
    echo "${resolved[@]}"
}

# =============================================================================
# MODULE EXECUTION
# =============================================================================

# Install a single module
install_module_by_id() {
    local module_id="$1"
    local module_path="${MODULES[$module_id]}"
    
    log_info "Installing module: $module_id"
    
    # Source the module
    source "$module_path"
    
    # Call the module installation function
    if command_exists module_install; then
        if module_install; then
            MODULE_STATUS["$module_id"]="installed"
            log_success "Module $module_id installed successfully"
        else
            MODULE_STATUS["$module_id"]="failed"
            log_error "Module $module_id installation failed"
            return 1
        fi
    else
        log_error "Module $module_id has no installation function"
        return 1
    fi
}

# Install multiple modules with dependency resolution
install_modules() {
    local target_modules=("$@")
    
    log_info "Resolving dependencies for: ${target_modules[*]}"
    
    # Resolve dependencies
    local resolved_modules
    if ! resolved_modules=($(resolve_dependencies "${target_modules[@]}")); then
        log_error "Failed to resolve module dependencies"
        return 1
    fi
    
    log_info "Installation order: ${resolved_modules[*]}"
    
    # Install modules in dependency order
    for module_id in "${resolved_modules[@]}"; do
        install_module_by_id "$module_id"
    done
}

# =============================================================================
# STATUS AND INFORMATION
# =============================================================================

# List available modules
list_modules() {
    echo "Available modules:"
    echo ""
    
    # Group by category
    local categories=()
    for module_id in "${!MODULES[@]}"; do
        local category=$(dirname "$module_id")
        if [[ "$category" == "." ]]; then
            category="core"
        fi
        
        if [[ ! " ${categories[*]} " == *" $category "* ]]; then
            categories+=("$category")
        fi
    done
    
    # Sort categories
    IFS=$'\n' categories=($(sort <<<"${categories[*]}"))
    
    # Display modules by category
    for category in "${categories[@]}"; do
        echo "📁 $category:"
        
        for module_id in "${!MODULES[@]}"; do
            local module_category=$(dirname "$module_id")
            if [[ "$module_category" == "." ]]; then
                module_category="core"
            fi
            
            if [[ "$module_category" == "$category" ]]; then
                local module_path="${MODULES[$module_id]}"
                local description=""
                
                # Extract description
                if description=$(grep -m1 "MODULE_DESCRIPTION=" "$module_path" 2>/dev/null); then
                    description=$(echo "$description" | cut -d'"' -f2)
                fi
                
                local status_icon="⚪"
                local status="${MODULE_STATUS[$module_id]:-unknown}"
                case "$status" in
                    installed) status_icon="✅" ;;
                    failed) status_icon="❌" ;;
                esac
                
                printf "  %s %-20s - %s\n" "$status_icon" "$(basename "$module_id")" "$description"
            fi
        done
        echo ""
    done
}

# Show system status using modules
show_status() {
    log_info "Checking system status..."
    echo ""
    
    # Call status function for each module that has one
    for module_id in "${!MODULES[@]}"; do
        local module_path="${MODULES[$module_id]}"
        
        # Check if module has status function
        if source "$module_path" && command_exists module_status; then
            module_status
            echo ""
        fi
    done
}

# =============================================================================
# BUILT-IN MODULE ALIASES
# =============================================================================

# Create convenient aliases for common module combinations
install_essentials() {
    install_modules "base" "tools"
}

install_dev_minimal() {
    install_modules "base" "shell" "languages/python" "tools"
}

install_dev_full() {
    install_modules "base" "shell" "languages/python" "languages/rust" "nodejs" "tools" "docker" "editors/neovim"
}

install_web_dev() {
    install_modules "base" "nodejs" "deno" "bun" "tools" "docker"
}

# =============================================================================
# USAGE AND HELP
# =============================================================================

show_usage() {
    cat << EOF
Professional WSL Debian 12 Setup (Refactored)
Modular architecture with clean separation of concerns

Usage: $0 <command> [arguments]

Commands:
  install <module>...   Install specific modules
  list                  List all available modules
  status                Show installation status
  deps <module>         Show module dependencies
  
  # Convenience commands
  essentials            Install essential tools
  dev-minimal           Install minimal development environment  
  dev-full              Install full development environment
  web-dev               Install web development stack

Module Examples:
  languages/python      Python with pyenv and uv
  languages/rust        Rust with rustup
  nodejs                Node.js with modern tools
  shell                 Zsh with Oh My Zsh
  tools                 Modern CLI tools
  docker                Docker and Docker Compose

Options:
  -h, --help           Show this help
  -v, --verbose        Enable verbose logging
  -d, --debug          Enable debug logging

Examples:
  $0 install languages/python          # Install Python only
  $0 install shell tools               # Install shell and tools
  $0 dev-minimal                       # Quick dev setup
  $0 list                              # See all modules
  
Configuration:
  Edit config/versions.conf to customize software versions
  Create config/user.conf for personal overrides
EOF
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                LOG_LEVEL="$LOG_LEVEL_DEBUG"
                log_info "Verbose logging enabled"
                shift
                ;;
            -d|--debug)
                LOG_LEVEL="$LOG_LEVEL_DEBUG"
                log_info "Debug logging enabled"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Ensure we're in WSL
    check_wsl_requirements
    
    # Discover available modules
    discover_modules
    
    # Handle commands
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "install")
            if [[ $# -eq 0 ]]; then
                log_error "No modules specified for installation"
                show_usage
                exit 1
            fi
            install_modules "$@"
            ;;
        "list")
            list_modules
            ;;
        "status")
            show_status
            ;;
        "deps")
            if [[ $# -eq 0 ]]; then
                log_error "No module specified for dependency check"
                exit 1
            fi
            local deps=($(get_module_deps "$1"))
            if [[ ${#deps[@]} -gt 0 ]]; then
                echo "Dependencies for $1: ${deps[*]}"
            else
                echo "No dependencies for $1"
            fi
            ;;
        "essentials")
            install_essentials
            ;;
        "dev-minimal")
            install_dev_minimal
            ;;
        "dev-full")
            install_dev_full
            ;;
        "web-dev")
            install_web_dev
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 