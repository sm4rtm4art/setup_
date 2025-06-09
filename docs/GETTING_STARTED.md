# Getting Started with Dev Containers 🚀

## What You Need

1. **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop)
2. **VS Code** - [Download here](https://code.visualstudio.com/)
3. **Dev Containers Extension** - [Install here](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## First Time Setup (5 minutes)

### Step 1: Install Prerequisites

```bash
# On macOS with Homebrew
brew install docker
brew install --cask visual-studio-code

# On Windows (using winget)
winget install Docker.DockerDesktop
winget install Microsoft.VisualStudioCode

# On Linux (Ubuntu/Debian)
sudo apt update
sudo apt install docker.io docker-compose
```

### Step 2: Start Docker Desktop

- Open Docker Desktop and wait for it to start
- Make sure Docker is running (green icon in system tray/menu bar)

### Step 3: Open Your Project

```bash
# Clone this repository
git clone <your-repo-url>
cd <repo-name>

# Open in VS Code
code .
```

### Step 4: Open in Container

1. Press `F1` in VS Code
2. Type "Dev Containers: Reopen in Container"
3. Press Enter
4. Wait for the container to build (first time takes 2-5 minutes)

### Step 5: Start Coding!

- Your terminal now runs inside the container
- All tools are pre-installed
- Your code changes are automatically synced

## 🚀 Deployment Methods (How to Use Your Dev Container)

Now that you understand the basics, here are all the ways you can deploy and use your dev container:

### Method 1: VS Code Dev Containers (Recommended)

**Prerequisites:**

```bash
# Install VS Code Dev Containers extension
code --install-extension ms-vscode-remote.remote-containers
```

**Deploy Steps:**

1. **Open Project in VS Code:**

   ```bash
   cd /path/to/your/project
   code .
   ```

2. **Open in Container:**

   - Press `F1` (or `Cmd+Shift+P` on Mac)
   - Type: "Dev Containers: Reopen in Container"
   - Press Enter
   - Wait 2-5 minutes for first-time build

3. **Verify Setup:**
   ```bash
   # Inside container terminal
   .devcontainer/test-container.sh
   ```

### Method 2: Docker Compose (CLI Users)

**Deploy Steps:**

```bash
# Build and start the container
docker-compose up -d

# Enter the container
docker exec -it wsl-setup-dev /bin/zsh

# Verify everything works
python3 --version && ruff --version && mypy --version

# When done, stop the container
docker-compose down
```

### Method 3: Direct Docker Commands

**For Advanced Users:**

```bash
# Build the image
docker build -t my-dev-env -f .devcontainer/Dockerfile .

# Run interactively
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.ssh:/home/vscode/.ssh:ro \
  -v ~/.gitconfig:/home/vscode/.gitconfig:ro \
  -w /workspace \
  my-dev-env /bin/zsh

# Or run as daemon
docker run -d \
  --name my-dev-container \
  -v $(pwd):/workspace \
  -w /workspace \
  my-dev-env

# Enter the running container
docker exec -it my-dev-container /bin/zsh
```

### Method 4: Remote Development (SSH/Cloud)

**Deploy to Remote Server:**

```bash
# Copy project to remote server
scp -r .devcontainer/ user@server:/path/to/project/

# SSH into server
ssh user@server

# Build and run on remote server
cd /path/to/project
docker-compose up -d
docker exec -it wsl-setup-dev /bin/zsh
```

**Use with VS Code Remote SSH:**

1. Install "Remote - SSH" extension in VS Code
2. Connect to remote server via SSH
3. Open project folder on remote server
4. Use Method 1 (Dev Containers) on the remote machine

### Method 5: CI/CD Pipeline Integration

**GitHub Actions:**

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and test in dev container
        uses: devcontainers/ci@v0.3
        with:
          imageName: ghcr.io/${{ github.repository }}/devcontainer
          runCmd: |
            # Run the same commands developers use
            .devcontainer/test-container.sh
            ruff check
            mypy .
            python -m pytest
```

**GitLab CI:**

```yaml
# .gitlab-ci.yml
test:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -f .devcontainer/Dockerfile -t test-env .
    - docker run --rm -v $PWD:/workspace -w /workspace test-env bash -c "ruff check && mypy ."
```

## 🔄 Deployment Workflows

### For Individual Developers:

```bash
# 1. Clone repository
git clone <repository-url>
cd <repository-name>

# 2. Open in VS Code with dev container
code .
# F1 → "Reopen in Container"

# 3. Start developing immediately!
uv add requests  # Add dependencies
ruff check      # Lint code
mypy .          # Type check
```

### For Team Onboarding:

```bash
# New team member setup (2 minutes!)
git clone <team-repository>
cd <repository-name>
code .
# F1 → "Reopen in Container"
# Done! Same environment as everyone else
```

### For Production Deployment:

```bash
# Build production image from dev container
docker build -t myapp:prod -f .devcontainer/Dockerfile .

# Or extend dev container for production
FROM myapp-dev:latest
COPY . /app
WORKDIR /app
CMD ["python", "main.py"]
```

## 🛠️ Configuration Management

### Switch Development Stacks:

```bash
# Switch to Java development
cp .devcontainer/examples/java-project.json .devcontainer/devcontainer.json
# F1 → "Rebuild Container"

# Switch to Node.js development
cp .devcontainer/examples/node-project.json .devcontainer/devcontainer.json
# F1 → "Rebuild Container"

# Switch back to Python (default)
git checkout .devcontainer/devcontainer.json
# F1 → "Rebuild Container"
```

### Update Tool Versions:

```bash
# Edit .devcontainer/Dockerfile
# Update version numbers:
ARG RUFF_VERSION=0.7.0  # New version
ARG MYPY_VERSION=1.12.0  # New version

# Rebuild container
# F1 → "Rebuild Container (No Cache)"
```

## 📊 Deployment Status Check

### Verify Successful Deployment:

```bash
# Run comprehensive test
.devcontainer/test-container.sh

# Quick health check
python3 --version && ruff --version && mypy --version

# Check container resources
docker stats wsl-setup-dev

# View container logs
docker logs wsl-setup-dev
```

## Choosing Your Development Stack

### Python Development

```bash
# Use the main devcontainer.json (already configured)
# Includes: uv, ruff, mypy, Python 3.12
```

### Java Development

```bash
# Copy the Java configuration
cp .devcontainer/examples/java-project.json .devcontainer/devcontainer.json

# Rebuild container
# F1 → "Dev Containers: Rebuild Container"
```

### Node.js Development

```bash
# Copy the Node.js configuration
cp .devcontainer/examples/node-project.json .devcontainer/devcontainer.json

# Rebuild container
# F1 → "Dev Containers: Rebuild Container"
```

## Common Commands

### Container Management

```bash
# Rebuild container (after config changes)
F1 → "Dev Containers: Rebuild Container"

# Reopen in container
F1 → "Dev Containers: Reopen in Container"

# Open new terminal in container
Ctrl+Shift+` (or Cmd+Shift+` on Mac)
```

### Python Development (in container terminal)

```bash
# Package management with uv
uv add requests        # Add dependency
uv remove requests     # Remove dependency
uv sync               # Install all dependencies

# Code quality
ruff check            # Lint code
ruff format           # Format code
mypy .               # Type check
check                # Run all checks
fix                  # Auto-fix issues
```

### Java Development (in container terminal)

```bash
# Switch Java versions
j21                  # Use Java 21
j17                  # Use Java 17
j11                  # Use Java 11

# Create new Spring Boot project
spring init myapp --dependencies=web,actuator

# Build and run
./gradlew bootRun    # Gradle
./mvnw spring-boot:run  # Maven
```

## Troubleshooting

### Container Won't Start

```bash
# Check Docker is running
docker ps

# Check container logs
docker logs wsl-setup-dev

# Rebuild without cache
F1 → "Dev Containers: Rebuild Container (No Cache)"
```

### Slow Performance

- **Windows**: Enable WSL2 in Docker Desktop settings
- **macOS**: Increase Docker Desktop memory allocation
- **All**: Use `cached` volume mounts in devcontainer.json

### Extensions Not Loading

```bash
# Reinstall extensions in container
F1 → "Extensions: Reinstall Local Extensions in Dev Container"
```

### Permission Issues

```bash
# Fix file permissions
sudo chown -R $(whoami):$(whoami) /workspace
```

## Best Practices

### 1. Keep Containers Small

Only install tools you actually need:

```dockerfile
# Bad: Installing everything
RUN apt-get install -y *

# Good: Installing specific tools
RUN apt-get install -y git curl python3
```

### 2. Use Layer Caching

Group related installations:

```dockerfile
# Good: Group package installations
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    && rm -rf /var/lib/apt/lists/*
```

### 3. Mount Caches

Speed up builds with persistent caches:

```json
"mounts": [
  "source=${localEnv:HOME}/.cache,target=/home/vscode/.cache,type=bind,consistency=cached"
]
```

### 4. Version Pin Everything

```dockerfile
# Good: Specific versions
RUN curl -LsSf https://astral.sh/uv/0.5.11/install.sh | sh

# Bad: Latest versions
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Next Steps

1. **Customize your environment**: Edit `.devcontainer/devcontainer.json`
2. **Add team configurations**: Commit your `.devcontainer/` folder
3. **Set up CI/CD**: Use the same tools in your pipeline
4. **Explore examples**: Check `.devcontainer/examples/` for more setups

## Need Help?

- Check the [FAQ](FAQ.md)
- Read the [Advanced Guide](ADVANCED.md)
- Look at [Examples](../examples/)
- File an issue in the repository
