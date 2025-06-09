# 🛠️ WSL Setup Tool

> **Professional WSL Debian 12 Development Environment Setup**  
> Modern, modular architecture with multi-language support and containerized development.

[![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-GitLab-orange)](/.gitlab-ci.yml)
[![Docker Support](https://img.shields.io/badge/Docker-Ready-blue)](/docker-compose.yml)
[![Multi-Language](https://img.shields.io/badge/Languages-Python%20%7C%20Java%20%7C%20Rust-green)](#language-support)

## 🚀 **Quick Start**

### Option 1: Native Installation (WSL)

```bash
# Clone the repository
git clone <your-gitlab-repo>
cd wsl-setup-tool

# Run the modular setup script
./setup-refactored.sh dev-minimal
```

### Option 2: Containerized Development (Any Platform)

```bash
# One command setup
make dev

# Or manually
docker compose up -d
docker compose exec devcontainer bash
```

## 🏗️ **Architecture Overview**

This project uses a **clean, modular architecture** that replaced a 1400+ line monolithic script:

```
wsl-setup-tool/
├── 🚀 setup-refactored.sh    # Main entry point (428 lines)
├── 📚 lib/                   # Core libraries
│   ├── core.sh              # Logging, error handling, utilities
│   ├── installer.sh         # Installation patterns
│   └── wsl.sh               # WSL-specific functionality
├── 🔧 config/                # Configuration management
│   └── versions.conf        # Centralized version control
├── 📦 modules/               # Feature modules
│   └── languages/           # Language-specific installers
├── 🐳 .devcontainer/         # Multi-language development container
├── 🛠️ Makefile              # Development workflow automation
└── 📖 docs/                  # Comprehensive documentation
```

## 💻 **Language Support**

### ✅ **Fully Supported**

- **🐍 Python** - `uv`, `ruff`, `mypy`, `pytest`
- **☕ Java** - OpenJDK 21, Maven, Gradle, Spring Boot
- **🦀 Rust** - `rustup`, `cargo`, `clippy`, `rustfmt`

### 🛠️ **Development Tools**

- **Shell**: Zsh + Oh My Zsh with smart presets
- **CLI Tools**: `bat`, `eza`, `ripgrep`, `fd`, `fzf`, `tmux`
- **Containers**: Docker + Docker Compose
- **Quality**: Pre-commit hooks, CI/CD pipeline

## 📖 **Usage Examples**

### Modular Installation

```bash
# Install specific components
./setup-refactored.sh install languages/python languages/rust

# Pre-configured environments
./setup-refactored.sh dev-minimal    # Essential dev tools
./setup-refactored.sh dev-full       # Complete environment
./setup-refactored.sh web-dev        # Web development stack
```

### Container Development

```bash
# Development workflow
make dev-up        # Build and start container
make test          # Run all tests (Python, Java, Rust)
make lint          # Run all linters
make format        # Format all code
make versions      # Show tool versions

# Language-specific commands
make py-test       # Python tests only
make rust-build    # Rust compilation
make java-package  # Maven packaging
```

## 🔧 **Configuration**

### Version Management

Edit `config/versions.conf` to customize software versions:

```bash
# Programming Languages
PYTHON_VERSION="3.12.7"
RUST_VERSION="1.82.0"
JAVA_VERSION="21"

# Build Tools
MAVEN_VERSION="3.9.6"
GRADLE_VERSION="8.6"
```

### Environment Customization

```bash
# Override defaults
LOCAL_UID=1000 make dev-up
VCS_REF=main BUILD_DATE=$(date -u +%Y-%m-%d) make dev-rebuild
```

## 🧪 **Quality Assurance**

### Pre-commit Hooks

```bash
# Install development tools
pip install pre-commit
pre-commit install

# Run checks
pre-commit run --all-files
```

### CI/CD Pipeline

- **Linting**: Shell, Python, Rust, Java code quality
- **Testing**: Multi-language test execution
- **Building**: Container and release builds
- **Documentation**: Automated docs deployment

## 📚 **Documentation**

| Document                                                               | Purpose                                 |
| ---------------------------------------------------------------------- | --------------------------------------- |
| [`docs/REFACTORING_MASTER_GUIDE.md`](docs/REFACTORING_MASTER_GUIDE.md) | Architecture and implementation details |
| [`docs/CI_CD_GUIDE.md`](docs/CI_CD_GUIDE.md)                           | Automation and quality processes        |
| [`docs/DOCKER_GUIDE.md`](docs/DOCKER_GUIDE.md)                         | Container development workflow          |

## 🆘 **Troubleshooting**

### Common Issues

**WSL Environment Detection**:

```bash
# Verify WSL
grep -i microsoft /proc/version
```

**Container Build Issues**:

```bash
# Clean rebuild
make dev-clean
make dev-rebuild
```

**Permission Problems**:

```bash
# Fix UID/GID
echo "LOCAL_UID=$(id -u)" > .env
echo "LOCAL_GID=$(id -g)" >> .env
```

## 🤝 **Contributing**

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Run quality checks**: `make check`
4. **Commit changes**: `git commit -m "feat: add amazing feature"`
5. **Push and create MR**: `git push origin feature/amazing-feature`

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **Modern CLI Tools**: Built on excellent tools like `uv`, `ruff`, `eza`
- **Container Best Practices**: Security-focused multi-stage builds
- **WSL Community**: Extensive testing and feedback from WSL users
