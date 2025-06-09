# Development in Docker Containers 🐳

Welcome to modern containerized development! This guide shows you how to create **isolated, reproducible development environments** that work the same on any machine.

## 🎯 What is a Dev Container?

A dev container is a Docker container specifically configured for development. It includes all the tools, dependencies, and configurations needed for your project, ensuring everyone on your team has the exact same development environment.

## 🚀 Why Dev Containers are Game-Changers

### Traditional Development Problems:

- 😫 "It works on my machine" syndrome
- 🔄 Inconsistent tool versions across team
- 💥 Dependency conflicts between projects
- 📦 Complex setup instructions for new developers
- 🧹 Difficult to clean up development environment

### Dev Container Solutions:

- ✅ **Identical environments** for entire team
- ✅ **Isolated per project** - no conflicts
- ✅ **Cross-platform** - works on Windows, macOS, Linux
- ✅ **Instant onboarding** - clone and code in minutes
- ✅ **Version controlled** - environment lives with your code
- ✅ **Production parity** - dev matches deployment

## 🆚 Comparison: WSL vs Dev Containers vs Traditional

| Feature         | Traditional Setup     | WSL Setup             | Dev Container       |
| --------------- | --------------------- | --------------------- | ------------------- |
| Isolation       | ❌ Shared system      | ❌ Shared WSL         | ✅ Fully isolated   |
| Reproducibility | ❌ Manual steps       | ⚠️ Script-based       | ✅ Automated        |
| Cross-Platform  | ❌ OS-specific        | ❌ Windows only       | ✅ Any OS           |
| Version Control | ❌ Documentation only | ⚠️ Script only        | ✅ Full environment |
| Cleanup         | ❌ Very difficult     | ⚠️ Possible           | ✅ Delete container |
| Team Sync       | ❌ Manual effort      | ⚠️ Script updates     | ✅ Automatic        |
| Resource Usage  | ✅ Native performance | ✅ Native performance | ⚠️ Some overhead    |
| Setup Time      | 😫 30-60 minutes      | ⚠️ 10-20 minutes      | ✅ 2-5 minutes      |

## 🛠️ Supported Development Stacks

### 🐍 Python Development (Modern Toolchain)

- **uv** - Ultra-fast package manager (10-100x faster than pip)
- **ruff** - Lightning-fast linter & formatter (replaces black, flake8, isort)
- **mypy** - Static type checking
- **Python 3.12** with all modern features
- **Pre-commit hooks** for code quality

### ☕ Java Development (Full Enterprise Stack)

- **Java 21, 17, 11** - Multiple versions via SDKMAN
- **Gradle & Maven** - Modern build tools
- **Spring Boot CLI** - Rapid application development
- **GraalVM support** - Native compilation
- **JBang** - Java scripting

### 🟨 Node.js Development (Modern JavaScript)

- **Node.js LTS** - Latest stable version
- **pnpm, yarn, npm** - Multiple package managers
- **TypeScript** - Type-safe JavaScript
- **Vite, Next.js** - Modern frameworks
- **ESLint, Prettier** - Code quality tools

## 🏃‍♂️ Quick Start (5 Minutes)

### Prerequisites

1. **[Docker Desktop](https://www.docker.com/products/docker-desktop)** - Container runtime
2. **[VS Code](https://code.visualstudio.com/)** - Code editor
3. **[Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** - VS Code extension

### Get Started

```bash
# 1. Clone and open project
git clone <your-repo>
cd <your-repo>
code .

# 2. Open in container
# Press F1 → "Dev Containers: Reopen in Container"

# 3. Start coding! 🎉
# All tools are pre-installed and ready
```

## 🚀 All Deployment Options

### Method 1: VS Code (Recommended)

```bash
code .
# F1 → "Reopen in Container"
```

**✅ Best for:** Individual developers, team collaboration

### Method 2: Docker Compose

```bash
docker-compose up -d
docker exec -it wsl-setup-dev /bin/zsh
```

**✅ Best for:** CLI users, automation scripts

### Method 3: Direct Docker

```bash
docker build -t my-dev-env -f .devcontainer/Dockerfile .
docker run -it --rm -v $(pwd):/workspace my-dev-env
```

**✅ Best for:** Advanced users, custom configurations

### Method 4: Remote/Cloud Development

```bash
# Copy to remote server
scp -r .devcontainer/ user@server:/project/
# Use VS Code Remote SSH + Dev Containers
```

**✅ Best for:** Cloud development, powerful remote machines

### Method 5: CI/CD Integration

```yaml
# GitHub Actions / GitLab CI
uses: devcontainers/ci@v0.3
# Same environment in development and CI
```

**✅ Best for:** Automated testing, deployment pipelines

**📖 [Complete Deployment Guide →](guides/GETTING_STARTED.md#🚀-deployment-methods-how-to-use-your-dev-container)**

## 🎯 Choose Your Stack

### 🐍 Python Development (Default)

```bash
# Already configured! Just open in container
# Includes: uv, ruff, mypy, Python 3.12
```

### ☕ Java Development

```bash
# Switch to Java configuration
cp .devcontainer/examples/java-project.json .devcontainer/devcontainer.json

# Rebuild container: F1 → "Dev Containers: Rebuild Container"
```

### 🟨 Node.js Development

```bash
# Switch to Node.js configuration
cp .devcontainer/examples/node-project.json .devcontainer/devcontainer.json

# Rebuild container: F1 → "Dev Containers: Rebuild Container"
```

## 💡 How This Compares to Your WSL Setup

**Your WSL setup script is still valuable!** Here's how they work together:

### WSL Setup Script (`setup_wsl.sh`):

- ✅ **Perfect for:** Personal Linux environment on Windows
- ✅ **Use when:** You want a persistent development environment
- ✅ **Great for:** Learning Linux tools and setting up WSL

### Dev Containers:

- ✅ **Perfect for:** Project-specific environments
- ✅ **Use when:** Working on team projects
- ✅ **Great for:** Ensuring consistency across team

### Best of Both Worlds:

```bash
# Use WSL for your general environment
wsl --install

# Use dev containers for specific projects
cd ~/projects/my-python-app
code .  # Opens in Python container

cd ~/projects/my-java-app
code .  # Opens in Java container
```

## 🔧 How to Use This Dev Container

### Option 1: VS Code Dev Containers (Recommended)

1. **Install Prerequisites:**

   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Open in Container:**

   - Open this project in VS Code
   - Press `F1` and select "Dev Containers: Reopen in Container"
   - VS Code will build and connect to the container automatically

3. **Start Coding:**
   - All tools are pre-installed
   - Your code is automatically synced
   - Terminal runs inside the container

### Option 2: Docker Compose (CLI)

```bash
# Build and start the container
docker-compose up -d

# Enter the container
docker exec -it wsl-setup-dev /bin/zsh

# Stop the container
docker-compose down
```

### Option 3: Direct Docker Commands

```bash
# Build the image
docker build -t wsl-setup-dev -f .devcontainer/Dockerfile .

# Run the container
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.ssh:/home/vscode/.ssh:ro \
  -w /workspace \
  wsl-setup-dev /bin/zsh
```

## What's Included

This dev container includes:

### 🖥️ Base Environment

- **OS**: Debian 12 (same as your WSL setup)
- **Shell**: Zsh with Oh My Zsh
- **User**: Non-root vscode user for security

### 🔧 Development Tools

- **Version Control**: Git with pre-commit hooks
- **Container Runtime**: Docker-in-Docker support
- **Modern CLI**: eza (ls), bat (cat), ripgrep (grep), fd (find), fzf
- **Shell Tools**: shellcheck, bats for bash development

### 🐍 Python Stack (Default)

- **Runtime**: Python 3.12 (latest stable)
- **Package Manager**: uv (10-100x faster than pip)
- **Linter/Formatter**: ruff (10-100x faster than black/flake8)
- **Type Checker**: mypy with strict configuration
- **Configuration**: All in pyproject.toml (modern approach)

### ☕ Java Stack (Optional)

- **Runtimes**: Java 21, 17, 11 via SDKMAN
- **Build Tools**: Gradle 8.5, Maven 3.9.6
- **Frameworks**: Spring Boot CLI, JBang
- **IDE Support**: Full VS Code Java extension pack

### 🟨 Node.js Stack (Optional)

- **Runtime**: Node.js LTS
- **Package Managers**: npm, pnpm, yarn
- **Type Safety**: TypeScript
- **Frameworks**: Vite, Next.js, Nuxt

## ⚡ Quick Commands (Inside Container)

### 🐍 Python Development

```bash
# Package management (uv is ultra-fast!)
uv add requests         # Add dependency
uv add --dev pytest     # Add dev dependency
uv remove requests      # Remove dependency
uv sync                 # Install all dependencies
uv lock                 # Update lock file

# Code quality (all tools work together)
lint                    # Check code with ruff
format                  # Format code with ruff
typecheck              # Check types with mypy
check                  # Run all checks (lint + format + types)
fix                    # Auto-fix all issues

# Aliases for convenience
py                     # python3
pip                    # uv pip (for muscle memory)
```

### ☕ Java Development

```bash
# Switch Java versions instantly
j21                    # Use Java 21
j17                    # Use Java 17
j11                    # Use Java 11

# Create new projects
spring init myapp --dependencies=web,actuator,data-jpa

# Build and run (works with both Gradle & Maven)
grun                   # gradle bootRun
mrun                   # mvn spring-boot:run
gw bootRun            # ./gradlew bootRun
mw spring-boot:run    # ./mvnw spring-boot:run

# Build aliases
gci                   # gradle clean build
mci                   # mvn clean install
```

### 🟨 Node.js Development

```bash
# Package management
pnpm add express       # Fast package manager
npm install react     # Traditional npm
yarn add typescript   # Alternative package manager

# Development
npm run dev           # Start dev server
pnpm build           # Build for production
yarn test            # Run tests
```

### 🔧 Container Management

```bash
# Test everything works
.devcontainer/test-container.sh

# Rebuild container (after config changes)
# F1 → "Dev Containers: Rebuild Container"

# View container logs
docker logs wsl-setup-dev
```

## 🛠️ Customization

### Adding New Tools

Edit `.devcontainer/Dockerfile`:

```dockerfile
# Add your tool installation
RUN apt-get update && apt-get install -y your-tool
```

### Adding VS Code Extensions

Edit `.devcontainer/devcontainer.json`:

```json
"customizations": {
  "vscode": {
    "extensions": [
      "your-extension-id"
    ]
  }
}
```

### Environment Variables

Add to `.devcontainer/devcontainer.json`:

```json
"remoteEnv": {
  "YOUR_VAR": "value"
}
```

## Team Collaboration

1. **Onboarding New Developers:**

   ```bash
   git clone <repo>
   code <repo>
   # Press F1 → "Reopen in Container"
   # Done! They're ready to code
   ```

2. **Updating the Environment:**
   - Make changes to `.devcontainer/` files
   - Commit and push
   - Team members: `F1` → "Rebuild Container"

## Best Practices

1. **Keep Images Small**: Only install what you need
2. **Layer Caching**: Group related installations
3. **Non-Root User**: Always use non-root user (vscode)
4. **Mount Performance**: Use `:cached` for better performance on macOS
5. **Secrets**: Never commit secrets; mount them as volumes

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs wsl-setup-dev

# Rebuild without cache
docker-compose build --no-cache
```

### Permission Issues

```bash
# Fix ownership
docker exec -it wsl-setup-dev sudo chown -R vscode:vscode /workspace
```

### Slow Performance on Windows/macOS

- Enable Docker Desktop's virtualization features
- Allocate more resources in Docker Desktop settings
- Use WSL2 backend on Windows

## 📚 Documentation & Guides

### 📖 Getting Started

- **[Getting Started Guide](guides/GETTING_STARTED.md)** - Complete setup walkthrough
- **[FAQ](guides/FAQ.md)** - Common questions and solutions
- **[Advanced Configuration](guides/ADVANCED.md)** - Power user features

### 🎯 Quick References

- **[Python Example](examples/sample_python_code.py)** - Modern Python with type hints
- **[Java Configuration](examples/java-project.json)** - Enterprise Java setup
- **[Node.js Configuration](examples/node-project.json)** - Modern JavaScript stack

### 🔧 Configuration Templates

- **[pyproject.toml](config/pyproject.toml)** - Python tools configuration
- **[pre-commit](config/.pre-commit-config.yaml)** - Code quality automation

## 🚀 Next Steps

### For First-Time Users:

1. **[Install Prerequisites](guides/GETTING_STARTED.md#what-you-need)** - Docker Desktop + VS Code
2. **[Try the Quick Start](#🏃‍♂️-quick-start-5-minutes)** - Get coding in 5 minutes
3. **[Read the FAQ](guides/FAQ.md)** - Understand the concepts
4. **[Explore Examples](examples/)** - See different language setups

### For Teams:

1. **Customize** the `.devcontainer/` configuration for your project
2. **Commit** the configuration to your repository
3. **Share** the [Getting Started Guide](guides/GETTING_STARTED.md) with your team
4. **Set up CI/CD** using the same containers (see [Advanced Guide](guides/ADVANCED.md))

### For Advanced Users:

1. **[Multi-container setups](guides/ADVANCED.md#multi-container-development)** - Microservices
2. **[Custom features](guides/ADVANCED.md#custom-features)** - Build your own tools
3. **[Performance optimization](guides/ADVANCED.md#performance-optimization)** - Speed tips
4. **[CI/CD integration](guides/ADVANCED.md#cicd-integration)** - Use in pipelines

## 🤝 Relationship to WSL Setup

**Your WSL setup script (`setup_wsl.sh`) is still valuable!** Here's how they complement each other:

### WSL Setup - Perfect For:

- ✅ Personal development environment on Windows
- ✅ Learning Linux tools and commands
- ✅ One-time setup for general development
- ✅ Direct hardware access and performance

### Dev Containers - Perfect For:

- ✅ Team collaboration and consistency
- ✅ Project-specific isolated environments
- ✅ Cross-platform development (Windows, Mac, Linux)
- ✅ Reproducible builds and deployments

### Use Both Together:

```bash
# WSL for your general environment
wsl --install
bash setup_wsl.sh

# Dev containers for specific projects
cd ~/projects/python-api && code .     # Python container
cd ~/projects/java-service && code .   # Java container
cd ~/projects/react-app && code .      # Node.js container
```

## 💬 Community & Support

- **Questions?** Check the [FAQ](guides/FAQ.md) or file an issue
- **Found a bug?** Please report it with details
- **Want a feature?** Open a feature request
- **Success story?** Share it with the team!

---

**Happy Coding! 🎉**

_Remember: The best development environment is the one your whole team can use effortlessly._
