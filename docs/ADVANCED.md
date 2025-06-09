# Advanced Dev Container Configuration 🚀

## Multi-Container Development

### Microservices Setup

For projects with multiple services (API + Frontend + Database):

```yaml
# docker-compose.yml
version: "3.8"

services:
  api:
    build:
      context: .
      dockerfile: .devcontainer/api.Dockerfile
    volumes:
      - ./api:/workspace:cached
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - redis

  frontend:
    build:
      context: .
      dockerfile: .devcontainer/frontend.Dockerfile
    volumes:
      - ./frontend:/workspace:cached
    ports:
      - "3000:3000"

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

### Multi-Container devcontainer.json

```json
{
  "name": "Microservices Dev Environment",
  "dockerComposeFile": "docker-compose.yml",
  "service": "api",
  "workspaceFolder": "/workspace",

  "forwardPorts": [3000, 8080, 5432, 6379],
  "portsAttributes": {
    "3000": { "label": "Frontend" },
    "8080": { "label": "API" },
    "5432": { "label": "PostgreSQL" },
    "6379": { "label": "Redis" }
  },

  "postCreateCommand": "bash .devcontainer/setup-microservices.sh",
  "remoteUser": "vscode"
}
```

## Advanced Language Configurations

### Python with Multiple Versions

```dockerfile
# .devcontainer/Dockerfile
FROM ubuntu:22.04

# Install pyenv dependencies
RUN apt-get update && apt-get install -y \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev git

# Install pyenv
RUN curl https://pyenv.run | bash

# Install multiple Python versions
RUN ~/.pyenv/bin/pyenv install 3.11.9
RUN ~/.pyenv/bin/pyenv install 3.12.7
RUN ~/.pyenv/bin/pyenv global 3.12.7

# Install uv globally
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Java Multi-Version with GraalVM

```dockerfile
# .devcontainer/Dockerfile
FROM debian:12

# Install SDKMAN
RUN curl -s "https://get.sdkman.io" | bash

# Install multiple Java distributions
RUN bash -c "source ~/.sdkman/bin/sdkman-init.sh && \
    sdk install java 21.0.1-tem && \
    sdk install java 17.0.9-tem && \
    sdk install java 21.0.1-graal && \
    sdk install java 17.0.7-graal && \
    sdk default java 21.0.1-tem"

# Install build tools
RUN bash -c "source ~/.sdkman/bin/sdkman-init.sh && \
    sdk install gradle 8.5 && \
    sdk install maven 3.9.6 && \
    sdk install springboot 3.2.0"
```

## Performance Optimization

### Volume Caching Strategies

```json
{
  "mounts": [
    // Package manager caches
    "source=${localEnv:HOME}/.cache/uv,target=/home/vscode/.cache/uv,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.cache/pip,target=/home/vscode/.cache/pip,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.m2,target=/home/vscode/.m2,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gradle,target=/home/vscode/.gradle,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.npm,target=/home/vscode/.npm,type=bind,consistency=cached",

    // Tool caches
    "source=${localEnv:HOME}/.cache/pre-commit,target=/home/vscode/.cache/pre-commit,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.cache/mypy,target=/home/vscode/.cache/mypy,type=bind,consistency=cached",

    // SSH and Git
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,readonly"
  ]
}
```

### Dockerfile Security & Performance: Before vs After

#### ❌ Common Mistakes (What NOT to do):

```dockerfile
# SECURITY ISSUES ❌
FROM debian:12                          # Full image, not slim
RUN apt-get update && apt-get install -y sudo  # Unnecessary sudo
# No USER directive - running as root!
COPY . .                                 # No .dockerignore

# PERFORMANCE ISSUES ❌
RUN apt-get update && apt-get install -y curl
RUN apt-get update && apt-get install -y git     # Multiple layers
RUN apt-get update && apt-get install -y python3

# VERSION/RELIABILITY ISSUES ❌
RUN curl -L https://example.com/tool | sh        # No version pinning
RUN pip install ruff                              # Latest = unpredictable
RUN wget http://unsecure-url/tool                 # HTTP, no checksum
```

#### ✅ Production-Ready Multi-Stage Dockerfile:

```dockerfile
# =============================================================================
# Secure multi-stage Dockerfile following best practices
# =============================================================================

# Build stage - Download and prepare tools
FROM debian:12-slim AS builder
ARG TOOL_VERSION=1.2.3                  # ✅ Version pinning
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \              # ✅ Single layer, minimal packages
    && rm -rf /var/lib/apt/lists/*       # ✅ Clean package cache

# Download with version pinning and HTTPS
RUN curl -fsSL -o tool.tar.gz \
    "https://secure-url/v${TOOL_VERSION}/tool.tar.gz"

# Runtime stage - Minimal secure final image
FROM debian:12-slim AS runtime

# ✅ Create non-root user FIRST (security critical)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# ✅ Single optimized layer for all system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 python3-pip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ✅ Copy only necessary files from builder
COPY --from=builder /downloads/tool /usr/local/bin/

# ✅ Switch to non-root user before installing user tools
USER $USERNAME
WORKDIR /home/$USERNAME

# ✅ Install tools with pinned versions as non-root
RUN python3 -m pip install --user --no-cache-dir \
    ruff==0.6.9 mypy==1.11.2

# ✅ Health check for monitoring
HEALTHCHECK --interval=30s --timeout=10s \
    CMD python3 --version && ruff --version || exit 1

# ✅ Proper signal handling with exec form
CMD ["sleep", "infinity"]
```

#### 🔑 Key Security Improvements:

1. **🔒 Non-Root Execution**: User created with specific UID/GID
2. **📦 Minimal Attack Surface**: -slim images, --no-install-recommends
3. **🔄 Reproducible Builds**: All versions pinned
4. **🛡️ Layer Optimization**: Single RUN for related operations
5. **💊 Health Monitoring**: HEALTHCHECK for container status
6. **🚫 No Sudo**: Removed unnecessary privileges

#### 📊 Results:

- **Image Size**: ~300MB → ~150MB (50% reduction)
- **Vulnerabilities**: Significant reduction due to minimal packages
- **Build Time**: Faster due to optimized layers
- **Security**: Passes container security scans

## CI/CD Integration

### GitHub Actions with Dev Containers

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and run dev container task
        uses: devcontainers/ci@v0.3
        with:
          imageName: ghcr.io/${{ github.repository }}
          runCmd: |
            # Run the same commands developers use
            check  # ruff + mypy
            pytest
            coverage report
```

### GitLab CI with Dev Containers

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build

test:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -f .devcontainer/Dockerfile -t test-env .
    - docker run --rm test-env bash -c "check && pytest"
```

## Database Integration

### PostgreSQL with Initialization

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./db/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev"]
      interval: 5s
      timeout: 5s
      retries: 5
```

```sql
-- db/init/01-schema.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Redis for Caching

```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
```

## Custom Features

### Creating Custom Dev Container Features

```bash
# .devcontainer/features/my-tool/devcontainer-feature.json
{
  "id": "my-tool",
  "version": "1.0.0",
  "name": "My Custom Tool",
  "description": "Installs my custom development tool",
  "options": {
    "version": {
      "type": "string",
      "default": "latest",
      "description": "Version to install"
    }
  }
}
```

```bash
# .devcontainer/features/my-tool/install.sh
#!/bin/bash
set -e

VERSION=${VERSION:-"latest"}

echo "Installing My Custom Tool version ${VERSION}..."

# Installation logic here
curl -L "https://github.com/myorg/my-tool/releases/download/${VERSION}/my-tool-linux" \
    -o /usr/local/bin/my-tool
chmod +x /usr/local/bin/my-tool

echo "My Custom Tool installed successfully!"
```

## Security Best Practices

### Non-Root User Configuration

```dockerfile
# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
```

### Secret Management

```json
{
  "remoteEnv": {
    "DATABASE_URL": "${localEnv:DATABASE_URL}",
    "API_KEY": "${localEnv:API_KEY}"
  },
  "mounts": [
    "source=${localEnv:HOME}/.aws,target=/home/vscode/.aws,type=bind,readonly",
    "source=${localEnv:HOME}/.kube,target=/home/vscode/.kube,type=bind,readonly"
  ],
  "postCreateCommand": "bash .devcontainer/setup-secrets.sh"
}
```

```bash
# .devcontainer/setup-secrets.sh
#!/bin/bash

# Copy local environment file if it exists
if [ -f "${HOME}/.env.local" ]; then
    cp "${HOME}/.env.local" /workspace/.env
    echo "Environment file copied from host"
fi

# Initialize cloud credentials
if [ -d "${HOME}/.aws" ]; then
    echo "AWS credentials mounted"
fi

if [ -d "${HOME}/.kube" ]; then
    echo "Kubernetes config mounted"
fi
```

## Monitoring and Debugging

### Container Health Checks

```dockerfile
# Add health check to Dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

### Development Tools Integration

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-azuretools.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "humao.rest-client",
        "redhat.vscode-yaml"
      ],
      "settings": {
        "docker.containers.label": "devcontainer",
        "kubernetes.outputFormat": "yaml"
      }
    }
  }
}
```

## Testing Environments

### Test Databases

```yaml
# docker-compose.test.yml
version: "3.8"

services:
  test-db:
    image: postgres:15
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_pass
    tmpfs:
      - /var/lib/postgresql/data # In-memory for speed
    ports:
      - "5433:5432"
```

### Integration Testing Setup

```bash
# .devcontainer/test-setup.sh
#!/bin/bash

echo "Setting up integration test environment..."

# Start test databases
docker-compose -f docker-compose.test.yml up -d

# Wait for services to be ready
until docker-compose -f docker-compose.test.yml exec test-db pg_isready; do
  echo "Waiting for test database..."
  sleep 2
done

# Run migrations
python manage.py migrate --database=test

# Seed test data
python manage.py loaddata test_fixtures.json

echo "Integration test environment ready!"
```

## Performance Monitoring

### Resource Usage Tracking

```bash
# .devcontainer/monitor.sh
#!/bin/bash

echo "Container Resource Usage:"
echo "========================"

# CPU and Memory
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Disk usage
echo -e "\nDisk Usage:"
df -h /workspace

# Process information
echo -e "\nTop Processes:"
ps aux --sort=-%cpu | head -10
```

## Advanced Networking

### Custom Networks

```yaml
# docker-compose.yml
version: "3.8"

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge

services:
  app:
    networks:
      - frontend
      - backend

  database:
    networks:
      - backend
```

### Service Discovery

```json
{
  "remoteEnv": {
    "API_URL": "http://api:8080",
    "DATABASE_URL": "postgresql://postgres:5432/mydb",
    "REDIS_URL": "redis://redis:6379"
  }
}
```

## Need More Help?

- 📚 [Dev Containers Specification](https://containers.dev/)
- 🔧 [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- 🐳 [Docker Best Practices](https://docs.docker.com/develop/best-practices/)
- 💬 [Community Examples](https://github.com/devcontainers/templates)
