# Frequently Asked Questions (FAQ) 🤔

## General Questions

### Q: What's the difference between WSL and Docker dev containers?

**A:** Both provide Linux environments, but serve different purposes:

| Aspect             | WSL                         | Docker Dev Containers                     |
| ------------------ | --------------------------- | ----------------------------------------- |
| **Purpose**        | Linux subsystem for Windows | Project-specific development environments |
| **Isolation**      | Shared environment          | Fully isolated per project                |
| **Portability**    | Windows only                | Works on any OS                           |
| **Setup**          | One-time installation       | Per-project configuration                 |
| **Resource Usage** | Lower overhead              | Some overhead, but manageable             |

**Use WSL when:** You want a permanent Linux environment on Windows
**Use Dev Containers when:** You want isolated, reproducible project environments

### Q: Can I use both WSL and dev containers together?

**A:** Absolutely! In fact, it's a great combination:

- Use WSL as your primary development environment on Windows
- Use dev containers for specific projects that need isolation
- Docker Desktop on Windows uses WSL2 as the backend

### Q: Do dev containers work on macOS and Linux?

**A:** Yes! Dev containers work identically on:

- ✅ Windows (with Docker Desktop)
- ✅ macOS (with Docker Desktop)
- ✅ Linux (with Docker CE/Docker Desktop)

## Performance Questions

### Q: Are dev containers slow?

**A:** Modern dev containers are quite fast:

- **Startup:** 30-60 seconds (after first build)
- **File operations:** Near-native with proper volume mounting
- **Build tools:** Same speed as native (uv, ruff are extremely fast)
- **VS Code:** Feels native with proper configuration

**Tips for speed:**

- Use volume caches for package managers
- Mount only necessary directories
- Use multi-stage Dockerfile builds
- Pin tool versions to avoid rebuilds

### Q: Why is the first build so slow?

**A:** First builds download and install everything:

- Base Docker image (500MB-1GB)
- System packages
- Development tools
- Language runtimes

**Subsequent builds are faster because:**

- Docker layer caching reuses unchanged layers
- Only changed layers are rebuilt
- Package caches are persistent

### Q: How can I speed up container builds?

```dockerfile
# 1. Use specific base images
FROM python:3.11-slim  # Instead of python:latest

# 2. Group package installations
RUN apt-get update && apt-get install -y \
    git curl wget \
    && rm -rf /var/lib/apt/lists/*

# 3. Copy requirements first for better caching
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .  # This comes last

# 4. Use multi-stage builds
FROM python:3.11-slim AS builder
# Build steps here
FROM python:3.11-slim AS runtime
COPY --from=builder /app /app
```

## Development Workflow Questions

### Q: How do I install new packages in a dev container?

**For Python (uv):**

```bash
uv add requests          # Add to project
uv add --dev pytest      # Add development dependency
uv sync                  # Install all dependencies
```

**For Node.js:**

```bash
npm install express      # Add to project
pnpm add -D typescript   # Add dev dependency
```

**For Java:**

```gradle
// Edit build.gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```

### Q: How do I update the development environment for my team?

1. **Update configuration files:**

   ```bash
   # Edit .devcontainer/devcontainer.json
   # Edit .devcontainer/Dockerfile
   ```

2. **Commit and push:**

   ```bash
   git add .devcontainer/
   git commit -m "Update dev environment"
   git push
   ```

3. **Team members rebuild:**
   - `F1` → "Dev Containers: Rebuild Container"

### Q: Can I run multiple projects in containers simultaneously?

**A:** Yes! Each project gets its own container:

```bash
# Project 1 (Python)
cd ~/projects/api
code .  # Opens in Python container

# Project 2 (Java)
cd ~/projects/web-app
code .  # Opens in Java container

# Project 3 (Node.js)
cd ~/projects/frontend
code .  # Opens in Node.js container
```

## Technical Questions

### Q: How do I access localhost from the container?

**A:** Use port forwarding in `devcontainer.json`:

```json
{
  "forwardPorts": [3000, 8080, 5432],
  "portsAttributes": {
    "3000": {
      "label": "Frontend",
      "onAutoForward": "openBrowser"
    }
  }
}
```

Then access via:

- `http://localhost:3000` (from your host browser)
- `http://localhost:8080` (from inside container)

### Q: How do I access files on my host system?

**Your project files are automatically mounted:**

```bash
# Inside container
/workspace/  # Your project files (automatically synced)

# Additional mounts in devcontainer.json
"mounts": [
  "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind",
  "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind"
]
```

### Q: How do I use environment variables?

**In devcontainer.json:**

```json
{
  "remoteEnv": {
    "API_KEY": "${localEnv:API_KEY}",
    "NODE_ENV": "development",
    "DATABASE_URL": "postgresql://localhost:5432/mydb"
  }
}
```

**In .env files:**

```bash
# .env (in project root)
API_KEY=your-secret-key
DATABASE_URL=postgresql://localhost:5432/mydb
```

### Q: How do I debug applications in containers?

**Python:**

```json
// .vscode/launch.json
{
  "type": "python",
  "request": "launch",
  "program": "${file}",
  "console": "integratedTerminal"
}
```

**Java:**

```json
// .vscode/launch.json
{
  "type": "java",
  "request": "launch",
  "mainClass": "com.example.Application"
}
```

**Node.js:**

```json
// .vscode/launch.json
{
  "type": "node",
  "request": "launch",
  "program": "${workspaceFolder}/src/index.js"
}
```

## Troubleshooting

### Q: Container builds fail with permission errors

**A:** Common on Linux. Fix Docker permissions:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Restart terminal/relogin
# Or run with sudo temporarily
sudo docker build .
```

### Q: VS Code extensions don't work in container

**A:** Extensions need to be container-compatible:

```json
// devcontainer.json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python", // ✅ Container-compatible
        "ms-vscode.remote-ssh" // ❌ Host-only extension
      ]
    }
  }
}
```

### Q: Files disappear when container stops

**A:** Data persists in:

- ✅ **Mounted volumes** (your project files)
- ✅ **Named volumes** (databases, caches)
- ❌ **Container filesystem** (temporary files)

**Solution:** Use proper mounts:

```json
{
  "mounts": ["source=project-cache,target=/home/vscode/.cache,type=volume"]
}
```

### Q: Container uses too much disk space

**A:** Clean up regularly:

```bash
# Remove unused containers and images
docker system prune -a

# Remove unused volumes
docker volume prune

# Check disk usage
docker system df
```

## Best Practices

### Q: Should I commit the .devcontainer folder?

**A:** Yes! Always commit your `.devcontainer/` folder:

- ✅ Ensures team consistency
- ✅ Documents your environment
- ✅ Makes onboarding instant
- ✅ Enables CI/CD integration

### Q: How do I handle secrets in dev containers?

**A:** Never commit secrets! Use:

1. **Environment variables:**

   ```json
   "remoteEnv": {
     "API_KEY": "${localEnv:API_KEY}"
   }
   ```

2. **Volume mounts:**

   ```json
   "mounts": [
     "source=${localEnv:HOME}/.aws,target=/home/vscode/.aws,type=bind"
   ]
   ```

3. **Init scripts:**
   ```bash
   # .devcontainer/post-create.sh
   if [ -f ~/.env.local ]; then
     cp ~/.env.local /workspace/.env
   fi
   ```

### Q: How often should I rebuild containers?

**A:** Rebuild when:

- ✅ You update `.devcontainer/` files
- ✅ You add new system dependencies
- ✅ Base images get security updates (monthly)
- ❌ Not needed for code changes
- ❌ Not needed for package additions (use package managers)

## Need More Help?

- 📖 [Getting Started Guide](GETTING_STARTED.md)
- 🚀 [Advanced Configuration](ADVANCED.md)
- 💡 [Examples](../examples/)
- 🐛 [File an Issue](../../issues)
