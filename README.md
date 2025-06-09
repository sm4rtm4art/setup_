# 🛠️ Multi-Language Development Environment

> **Professional Cross-Platform Development Container Setup**  
> Modern, modular architecture with Python, Java, and Rust support in a single containerized environment.

[![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-GitLab-orange)](/.gitlab-ci.yml)
[![Docker Support](https://img.shields.io/badge/Docker-Ready-blue)](/docker-compose.yml)
[![Multi-Language](https://img.shields.io/badge/Languages-Python%20%7C%20Java%20%7C%20Rust-green)](#language-support)

## Quick Start

### Option 1: Native Installation (Linux/WSL)

```bash
# Clone the repository
git clone https://github.com/sm4rtm4art/setup_.git
cd setup_

# Run the modular setup script (Linux/WSL only)
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

## Architecture Overview

This project uses a **clean, modular architecture** that replaced a 1400+ line monolithic script:

```
multi-lang-dev-env/
├── .devcontainer/         # Multi-language development container (PRIMARY)
├── Makefile              # Development workflow automation (PRIMARY)
├── lib/                   # Core libraries
│   ├── core.sh              # Logging, error handling, utilities
│   ├── installer.sh         # Installation patterns
│   └── wsl.sh               # Platform-specific functionality
├── config/                # Configuration management
│   └── versions.conf        # Centralized version control
├── modules/               # Feature modules
│   └── languages/           # Language-specific installers
├── setup-refactored.sh    # Native installer (Linux/WSL only)
└── docs/                  # Comprehensive documentation
```

## Usage Approaches

### Container-First (Recommended)

- ✅ **Works everywhere**: Linux, macOS, Windows
- ✅ **Consistent environment**: Same setup for all team members
- ✅ **No system pollution**: Isolated from host system
- ✅ **Ready to use**: `make dev` and you're coding

### Native Installation

- ✅ **Performance**: Direct access to system resources
- ✅ **Integration**: Better with host system tools
- ❌ **Linux/WSL only**: Requires compatible environment
- ❌ **System changes**: Installs tools on host system

**Use `setup-refactored.sh` when:**

- You prefer native performance
- You're on Linux/WSL exclusively
- You want to understand the modular architecture
- You need deep system integration

**Use Docker container when:**

- You want it to "just work" everywhere
- You're collaborating with a team
- You want isolated environments
- You're on macOS or Windows

## Language Support

### Fully Supported

- **Python** - `uv`, `ruff`, `mypy`, `pytest`
- **Java** - OpenJDK 21, Maven, Gradle, Spring Boot
- **Rust** - `rustup`, `cargo`, `clippy`, `rustfmt`

### Development Tools

- **Shell**: Zsh + Oh My Zsh with smart presets
- **CLI Tools**: `bat`, `eza`, `ripgrep`, `fd`, `fzf`, `tmux`
- **Containers**: Docker + Docker Compose
- **Quality**: Pre-commit hooks, CI/CD pipeline

## Usage Examples

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

## Configuration

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

## Quality Assurance

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

## Documentation

All documentation has been consolidated in the [`/docs`](docs/) directory for easy access:

| Document                                                         | Purpose                                       | Best For             |
| ---------------------------------------------------------------- | --------------------------------------------- | -------------------- |
| [**Documentation Hub**](docs/README.md)                          | **START HERE** - Complete documentation index | All users            |
| [**Getting Started**](docs/GETTING_STARTED.md)                   | 5-minute setup guide                          | New users            |
| [**Docker Guide**](docs/DOCKER_GUIDE.md)                         | Container development workflow                | Container users      |
| [**Container Development Guide**](docs/CONTAINER_DEVELOPMENT.md) | Complete container development guide          | VS Code/Cursor users |
| [**Advanced Configuration**](docs/ADVANCED.md)                   | Power user features                           | Expert users         |
| [**FAQ**](docs/FAQ.md)                                           | Common questions and solutions                | Troubleshooting      |
| [**Architecture Guide**](docs/REFACTORING_MASTER_GUIDE.md)       | Implementation details                        | Contributors         |
| [**CI/CD Guide**](docs/CI_CD_GUIDE.md)                           | Automation processes                          | DevOps teams         |

**Quick Start:** Begin with the [Documentation Hub](docs/README.md) for guided navigation based on your needs.

## Troubleshooting

### Common Issues

**Platform Detection**:

```bash
# Verify Linux/WSL (for native installation)
grep -i microsoft /proc/version || echo "Linux environment"
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

## Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Run quality checks**: `make check`
4. **Commit changes**: `git commit -m "feat: add amazing feature"`
5. **Push and create MR**: `git push origin feature/amazing-feature`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Modern CLI Tools**: Built on excellent tools like `uv`, `ruff`, `eza`
- **Container Best Practices**: Security-focused multi-stage builds
- **Development Community**: Extensive testing and feedback from multi-platform users
