# 🛠️ Master Shell Script Refactoring Guide

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture & Structure](#architecture)
3. [Implementation Strategy](#implementation)
4. [Best Practices & Patterns](#best-practices)
5. [Testing & Validation](#testing)
6. [Launch Plan](#launch-plan)
7. [Resources & Learning](#resources)

## 🚀 Quick Start {#quick-start}

### Initial Analysis Template

```bash
I need help refactoring this shell script:

Script Details:
- Name: [script_name]
- Lines: [number]
- Purpose: [brief description]
- Current Issues: [list main problems]

Please provide:
1. Quick analysis of current state
2. Most critical improvements needed
3. First 3 steps to start refactoring
4. Example of one refactored component
```

### Emergency Rescue Block

For broken systems, start with this minimal rescue script:

```bash
#!/bin/bash
set -euo pipefail

# Core rescue functions
fix_apt() {
    sudo dpkg --configure -a
    sudo apt-get update --fix-missing
    sudo apt-get install -f
}

restore_base_tools() {
    sudo apt-get install -y curl wget git sudo unzip
}

fix_sources() {
    sudo find /etc/apt/sources.list.d/ -type f -name '*.list' -exec bash -c '
        for file do
            if ! grep -q "^deb" "$file"; then
                sudo rm "$file"
            fi
        done
    ' bash {} +
}

# Run rescue operations
fix_apt
restore_base_tools
fix_sources
```

## 📐 Architecture & Structure {#architecture}

### Directory Structure

```
project/
├── setup.sh                 # Main entry point
├── lib/                     # Core libraries
│   ├── core.sh             # Logging, utilities
│   ├── installer.sh        # Installation patterns
│   ├── platform.sh         # Platform-specific code
│   └── validation.sh       # Input/dependency checks
├── modules/                 # Feature modules
│   ├── base/               # Core functionality
│   ├── languages/          # Programming languages
│   ├── tools/              # Development tools
│   └── databases/          # Database systems
├── config/                 # Configuration
│   ├── versions.conf      # Software versions
│   ├── defaults.conf      # Default settings
│   └── user.conf         # User overrides
├── tests/                  # Test suite
└── docs/                   # Documentation
```

### Module Interface

```bash
# Standard module template
MODULE_NAME="example"
MODULE_DESCRIPTION="Example module"
MODULE_DEPS=("base" "other_module")

# Required functions
module_install()    # Main installation
module_verify()     # Verification
module_status()     # Status reporting
module_clean()      # Cleanup/uninstall
```

## 🔄 Implementation Strategy {#implementation}

### Phase 1: Core Infrastructure (Week 1)

1. **Essential Libraries**

   ```bash
   # lib/core.sh
   set -euo pipefail

   log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
   log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

   trap 'error_handler $? $LINENO' ERR
   ```

2. **Base Modules**

   - Python environment (pyenv + uv)
   - Java environment (SDKMAN)
   - Shell configuration (Zsh + Oh My Zsh)

3. **Configuration System**
   ```bash
   # config/versions.conf
   PYTHON_VERSION="${PYTHON_VERSION:-3.12.7}"
   NODE_VERSION="${NODE_VERSION:-20.0.0}"
   ```

### Phase 2: Module System (Week 2)

1. **Module Loader**

   - Dependency resolution
   - Installation orchestration
   - Status tracking

2. **First Modules**
   - Base system tools
   - Development environments
   - Shell configuration

### Phase 3: Testing & Documentation (Week 3)

1. **Test Suite Setup**

   - Unit tests for core functions
   - Integration tests for modules
   - System tests for full setup

2. **Documentation**
   - Architecture guide
   - User guide
   - Developer guide

## 🔧 Best Practices & Patterns {#best-practices}

### Function Design

```bash
# Good: Pure function with error handling
install_tool() {
    local tool_name="$1"
    local version="$2"

    [[ -z "$tool_name" ]] && {
        log_error "Tool name required"
        return 1
    }

    require_command curl || return 1
    download_tool "$tool_name" "$version" || return 1
    configure_tool "$tool_name" || return 1
}
```

### Error Handling

```bash
# Input validation pattern
validate_input() {
    local input="$1"
    [[ -z "$input" ]] && {
        log_error "Input required"
        return 1
    }
    return 0
}

# Command checking pattern
require_command() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || {
        log_error "Required command not found: $cmd"
        return 1
    }
}
```

## 🧪 Testing & Validation {#testing}

### Unit Test Template

```bash
#!/bin/bash
source "lib/core.sh"

test_download_file() {
    # Arrange
    local url="https://example.com/file"
    local output="/tmp/test"

    # Act
    download_file "$url" "$output"

    # Assert
    [[ -f "$output" ]] || fail "File not downloaded"
}
```

### Integration Test Example

```bash
test_python_installation() {
    # Setup
    cleanup_environment

    # Test
    ./setup.sh install python

    # Verify
    assert_command_exists "python3"
    assert_version_matches "python3" "$EXPECTED_VERSION"
}
```

## 📅 Launch Plan {#launch-plan}

### Week 1: Core Structure

- [ ] Core libraries implementation
- [ ] Essential modules (Python, Java, Shell)
- [ ] Basic test framework

### Week 2: Team Essentials

- [ ] Documentation
- [ ] Development presets
- [ ] CI/CD integration

### Week 3: Testing & Handover

- [ ] Complete test suite
- [ ] Team training
- [ ] Support process setup

## 📚 Resources & Learning {#resources}

### Shell Scripting Concepts

```bash
# 1. Strict mode explained
set -e  # Exit on error
set -u  # Error on undefined variables
set -o pipefail  # Exit on pipe failures

# 2. Array handling
"${array[@]}"  # All elements as separate words
"${array[*]}"  # All elements as single string
```

### Common Patterns

```bash
# Temporary file handling
cleanup() {
    rm -f "$tempfile"
}
trap cleanup EXIT
tempfile=$(mktemp)

# Safe directory navigation
pushd "$dir" >/dev/null || exit
# ... work in directory
popd >/dev/null
```

## 📋 Validation Checklist

Before completing refactoring, verify:

### Code Quality

- [ ] Uses strict mode (`set -euo pipefail`)
- [ ] All variables are quoted
- [ ] Functions have single responsibility
- [ ] No function exceeds 50 lines
- [ ] Maximum nesting depth of 3
- [ ] Local variables used appropriately
- [ ] Consistent naming conventions
- [ ] Proper command substitution

### Architecture

- [ ] Clear separation of concerns
- [ ] Modules are independent
- [ ] Dependencies explicitly declared
- [ ] Configuration centralized
- [ ] Platform differences abstracted
- [ ] Logging is consistent
- [ ] Error handling is comprehensive

### Testing & Documentation

- [ ] Each module is testable
- [ ] Critical paths have tests
- [ ] Error messages are helpful
- [ ] Documentation is current
- [ ] Examples provided
- [ ] Migration guide exists
