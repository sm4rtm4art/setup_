# 🐳 Docker Development Guide

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Container Architecture](#container-architecture)
4. [Development Workflow](#development-workflow)
5. [Multi-Language Support](#multi-language-support)
6. [Configuration & Customization](#configuration--customization)
7. [Performance Optimization](#performance-optimization)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [Advanced Usage](#advanced-usage)

## 📖 Introduction

This project provides a **production-ready, multi-language development container** that supports Python, Java, and Rust development with modern tooling and security best practices.

### Why Use Our Container?

- ✅ **Multi-language support** - Python, Java, Rust in one container
- ✅ **Security-first** - Non-root user, checksums, minimal attack surface
- ✅ **Performance optimized** - BuildKit caching, layer optimization
- ✅ **Cross-platform** - Works on Linux, macOS, Windows
- ✅ **Reproducible** - Version-pinned tools and dependencies

## 🚀 Quick Start

### Option 1: Make Commands (Recommended)

```bash
# Start development environment
make dev              # Build, start, and open shell

# Individual commands
make dev-up           # Build and start container
make dev-shell        # Open shell in running container
make dev-down         # Stop container
make dev-clean        # Remove everything (careful!)
```

### Option 2: Direct Docker Compose

```bash
# Build and start
docker compose up -d

# Open shell
docker compose exec devcontainer bash

# Stop
docker compose down
```

### Option 3: VS Code Integration

```bash
# Open in VS Code with Remote Containers
code .
# Then: Ctrl+Shift+P -> "Reopen in Container"
```

## 🏗️ Container Architecture

### Multi-Stage Build Structure

```dockerfile
# Stage 1: Builder (Downloads & Preparation)
FROM debian:12-slim AS builder
- Downloads tools with checksums
- Prepares Maven, Gradle, etc.
- Security verification

# Stage 2: Runtime (Final Container)
FROM debian:12-slim AS runtime
- Installs system packages
- Copies verified tools from builder
- Sets up non-root user
- Configures environments
```

### Installed Languages & Tools

| Category        | Tools                                     | Versions       |
| --------------- | ----------------------------------------- | -------------- |
| **Python**      | `python3`, `uv`, `ruff`, `mypy`, `pytest` | 3.x, latest    |
| **Java**        | OpenJDK, Maven, Gradle                    | 21, 3.9.6, 8.6 |
| **Rust**        | `rustc`, `cargo`, `clippy`, `rustfmt`     | 1.75.0         |
| **CLI Tools**   | `bat`, `eza`, `ripgrep`, `fd`, `fzf`      | Latest         |
| **Development** | `git`, `tmux`, `shellcheck`, `pre-commit` | Latest         |

### Directory Structure Inside Container

```
/workspace/          # Your project (mounted)
/home/vscode/        # User home directory
├── .cargo/          # Rust tools
├── .local/bin/      # User binaries
└── .cache/          # Package caches (persistent)
/opt/                # System tools
├── maven/           # Maven installation
└── gradle/          # Gradle installation
```

## 💻 Development Workflow

### Daily Development Cycle

```bash
# 1. Start your day
make dev-up

# 2. Work on code (auto-synced to container)
# Edit files in your IDE on host

# 3. Run tests/builds inside container
make test            # All languages
make py-test         # Python only
make rust-build      # Rust only
make java-test       # Java only

# 4. Quality checks
make lint            # All linters
make format          # All formatters

# 5. End of day
make dev-down
```

### Working with Multiple Projects

```bash
# Different project in same container
cd /workspace/another-project
cargo init .          # Create Rust project
mvn archetype:generate # Create Java project
uv init               # Create Python project
```

## 🌍 Multi-Language Support

### Python Development

```bash
# Inside container
uv init my-python-app
cd my-python-app
uv add fastapi
uv run python main.py

# From host
make py-test          # Run pytest
make py-lint          # Run ruff
make py-format        # Format with ruff
```

### Java Development

```bash
# Inside container
mvn archetype:generate -DgroupId=com.example -DartifactId=my-app
cd my-app
mvn compile
mvn test

# From host
make java-build       # Maven compile
make java-test        # Maven test
make gradle-build     # Gradle alternative
```

### Rust Development

```bash
# Inside container
cargo init my-rust-app
cd my-rust-app
cargo build
cargo test

# From host
make rust-build       # Cargo build
make rust-test        # Cargo test
make rust-lint        # Clippy
```

### Cross-Language Projects

```bash
# Polyglot project structure
my-project/
├── backend/          # Rust API
├── frontend/         # Node.js/TypeScript
├── scripts/          # Python automation
├── services/         # Java microservices
└── Makefile          # Unified commands
```

## 🔧 Configuration & Customization

### Environment Variables

Create `.env` file (auto-generated by `make dev-up`):

```bash
# User configuration
LOCAL_UID=1000        # Your host UID
LOCAL_GID=1000        # Your host GID

# Build metadata
VCS_REF=abc123        # Git commit
BUILD_DATE=2024-01-01 # Build timestamp
```

### Version Customization

Edit `config/versions.conf`:

```bash
# Override default versions
PYTHON_VERSION="3.11.0"
RUST_VERSION="1.74.0"
JAVA_VERSION="17"
```

Then rebuild:

```bash
make dev-rebuild
```

### Port Mapping

Edit `docker-compose.yml`:

```yaml
ports:
  - "8000:8000" # Python/Django
  - "3000:3000" # Node.js
  - "8080:8080" # Java/Spring
  - "9000:9000" # Rust/Actix
```

### Volume Mounts

```yaml
volumes:
  - .:/workspace:cached # Project files
  - uv-cache:/home/vscode/.cache/uv # Python cache
  - cargo-cache:/home/vscode/.cargo # Rust cache
```

## ⚡ Performance Optimization

### Build Performance

```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1

# Leverage build cache
make dev-build        # Uses cache
make dev-rebuild      # Forces rebuild
```

### Runtime Performance

1. **Named Volumes**: Package caches persist between rebuilds
2. **Cached Mounts**: Project files use `:cached` flag
3. **Multi-stage**: Minimal runtime image size
4. **Layer Optimization**: Dependencies installed before code

### Container Resource Limits

```yaml
# docker-compose.yml
services:
  devcontainer:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: "2.0"
```

## 🆘 Troubleshooting

### Common Issues

#### 1. Permission Problems

```bash
# Symptoms: Files owned by root, can't edit
# Solution: Fix UID/GID mapping
echo "LOCAL_UID=$(id -u)" > .env
echo "LOCAL_GID=$(id -g)" >> .env
make dev-rebuild
```

#### 2. Container Won't Start

```bash
# Check logs
docker compose logs devcontainer

# Common fixes
make dev-clean        # Remove everything
make dev-rebuild      # Fresh start
```

#### 3. Build Failures

```bash
# Check specific stage
docker build --target builder .

# Network issues
docker system prune   # Clean up
docker compose build --no-cache --pull
```

#### 4. Out of Disk Space

```bash
# Clean Docker system
docker system prune -a

# Remove old images
docker image prune -a

# Check volume usage
docker system df
```

### Platform-Specific Issues

#### macOS

```bash
# If BuildKit fails
export DOCKER_BUILDKIT=0
make dev-rebuild
```

#### Windows WSL2

```bash
# Memory issues
echo "[wsl2]\nmemory=8GB" > /c/Users/$USER/.wslconfig
# Restart WSL
```

#### Linux

```bash
# Rootless Docker issues
docker context use rootless
```

## 🎯 Best Practices

### Development

1. **Use named volumes** for caches - faster rebuilds
2. **Mount project as cached** - better I/O performance
3. **Don't run as root** - security and permission issues
4. **Use .dockerignore** - faster builds

### Container Management

1. **Regular cleanup** - `make dev-clean` weekly
2. **Version pinning** - update `config/versions.conf`
3. **Health checks** - monitor container status
4. **Resource limits** - prevent resource exhaustion

### Security

1. **Verify checksums** - enabled by default
2. **Non-root user** - all development as `vscode` user
3. **Minimal base image** - `debian:12-slim`
4. **No secrets in image** - use environment variables

## 🔬 Advanced Usage

### Custom Tool Installation

```dockerfile
# Add to Dockerfile
RUN curl -fsSL https://get.example.com/tool | sh
```

### Multi-Architecture Builds

```bash
# Build for ARM64 (Apple Silicon)
docker buildx build --platform linux/arm64 .
```

### Development vs Production

```yaml
# Override for production
services:
  app:
    image: your-registry/app:latest
    command: ["./your-app"] # Override development CMD
    user: "app:app" # Production user
```

### Integration with CI/CD

```yaml
# .gitlab-ci.yml
test:
  image: $CI_REGISTRY_IMAGE/dev:latest
  script:
    - make test
    - make lint
```

### Custom Presets

Create your own module combinations:

```bash
# In setup-refactored.sh
install_data_science() {
    install_modules "languages/python" "tools" "jupyter"
}
```

## 💡 Tips & Tricks

### Performance

- Use `--parallel` flag for faster downloads
- Enable BuildKit: `export DOCKER_BUILDKIT=1`
- Use `docker compose up -d` to run in background

### Debugging

- Check health status: `make status`
- View logs: `make logs`
- Shell into container: `make dev-shell`

### Automation

- Add container startup to your shell profile
- Use VS Code tasks for common operations
- Create aliases for frequent commands

## 🤝 Contributing to Container Setup

1. **Test changes locally**:

   ```bash
   make dev-rebuild
   make test
   ```

2. **Update documentation** if adding new tools

3. **Verify security**:

   - Add checksums for new downloads
   - Test with non-root user
   - Check for vulnerabilities

4. **Performance test**:
   - Measure build time impact
   - Test with different platforms

Remember: The container should work out-of-the-box for new team members! 🚀
