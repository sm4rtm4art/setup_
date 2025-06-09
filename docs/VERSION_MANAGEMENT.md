# Centralized Version Management

## Single Source of Truth for All Versions

Instead of hardcoding versions in multiple files, this project uses a centralized `config/versions.conf` file to manage all software versions. This ensures consistency between development and production environments.

## 📁 Version Configuration File

All versions are defined in **`config/versions.conf`**:

```bash
# Programming Languages
PYTHON_VERSION="3.12.7"
RUST_VERSION="1.82.0"

# Java Ecosystem
DEFAULT_JAVA="21.0.1-tem"
GRADLE_VERSION="8.5"
MAVEN_VERSION="3.9.6"
SPRINGBOOT_VERSION="3.2.0"

# Package Managers & Tools
UV_VERSION="0.5.11"
EZA_VERSION="v0.20.0"
DUCKDB_VERSION="v1.2.2"

# And many more...
```

## 🔧 How It Works

### 1. Dockerfiles Source the Config

All Dockerfiles automatically load versions from the config:

```dockerfile
# Load centralized version configuration
COPY config/versions.conf /tmp/versions.conf

# Use versions in build commands
RUN . /tmp/versions.conf && \
    curl -o maven.tar.gz \
    "https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
```

### 2. Build Script Uses Centralized Versions

The `scripts/build-containers.sh` script automatically reads and applies all versions:

```bash
# Check current versions
./scripts/build-containers.sh check

# Build with consistent versions
./scripts/build-containers.sh dev
```

### 3. Python Tools Configuration

The `pyproject.toml` is updated to match:

```toml
[project]
requires-python = ">=3.12"

[tool.ruff]
target-version = "py312"

[tool.mypy]
python_version = "3.12"
```

## 🚀 Usage Examples

### Check Current Versions

```bash
./scripts/build-containers.sh check
```

Output:

```
=== Current Version Configuration ===

Languages:
  Python: 3.12.7
  Rust: 1.82.0
  Java: 21.0.1-tem

Build Tools:
  Maven: 3.9.6
  Gradle: 8.5
  Spring Boot: 3.2.0

Package Managers:
  UV (Python): 0.5.11
```

### Build Containers with Consistent Versions

```bash
# Build development container
./scripts/build-containers.sh dev

# Build production containers
./scripts/build-containers.sh prod

# Build everything
./scripts/build-containers.sh all
```

### Update a Version Everywhere

1. **Edit `config/versions.conf`**:

   ```bash
   # Update Python version
   PYTHON_VERSION="3.12.8"
   ```

2. **Rebuild containers**:

   ```bash
   ./scripts/build-containers.sh all
   ```

3. **That's it!** All containers now use the new version.

## 🔄 Development Workflow

### Inside Development Container

Check which versions are being used:

```bash
# Inside container - check installed versions
versions

# Output shows:
# === Development Environment Versions ===
# Python: Python 3.12.7
# Rust: rustc 1.82.0
# Java: openjdk 21.0.1 2023-10-17
# Maven: Apache Maven 3.9.6
# Gradle: Gradle 8.5
# UV: uv 0.5.11
```

### Version Consistency Guarantees

✅ **Development** uses exact same versions as **Production**
✅ **All team members** get identical environments
✅ **CI/CD pipelines** use same versions
✅ **No version drift** between environments

## 🎯 Benefits of Centralized Versions

### Before (Problems)

```dockerfile
# Dockerfile.dev
FROM python:3.11-slim

# Dockerfile.prod
FROM python:3.12-slim  # 😱 Different version!

# pyproject.toml
requires-python = ">=3.10"  # 😱 Another version!
```

### After (Solution)

```bash
# config/versions.conf
PYTHON_VERSION="3.12.7"

# All files use this single source
# ✅ Guaranteed consistency
```

## 📝 Best Practices

### 1. Always Pin Exact Versions

```bash
# Good - Exact version
PYTHON_VERSION="3.12.7"

# Bad - Floating version
PYTHON_VERSION="3.12"
```

### 2. Update Versions Systematically

```bash
# 1. Update config/versions.conf
# 2. Test in development
# 3. Update production when ready
# 4. Document breaking changes
```

### 3. Version Update Checklist

- [ ] Update `config/versions.conf`
- [ ] Update `pyproject.toml` if needed
- [ ] Test development build
- [ ] Test production build
- [ ] Update documentation
- [ ] Notify team of changes

## 🔍 Troubleshooting

### Version Mismatch Errors

**Problem**: Container fails to build with version error

**Solution**: Check if version exists:

```bash
# Verify Python version exists
curl -s https://www.python.org/ftp/python/ | grep "3.12.7"

# Verify Rust version exists
curl -s https://api.github.com/repos/rust-lang/rust/releases | jq -r '.[].tag_name' | grep "1.82.0"
```

### Build Script Issues

**Problem**: `./scripts/build-containers.sh` not executable

**Solution**:

```bash
chmod +x scripts/build-containers.sh
```

**Problem**: Version file not found

**Solution**: Ensure you're in project root:

```bash
ls config/versions.conf  # Should exist
```

## 🚀 Future Enhancements

### Automated Version Updates

```bash
# Coming soon: Auto-update script
./scripts/update-versions.sh --check-latest
./scripts/update-versions.sh --update-rust
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Build with Centralized Versions
  run: |
    source config/versions.conf
    docker build --build-arg PYTHON_VERSION=$PYTHON_VERSION .
```

---

## Summary

**Centralized version management eliminates:**

- ❌ Version inconsistencies
- ❌ "Works on my machine" issues
- ❌ Manual version updates across files
- ❌ Production/development mismatches

**And provides:**

- ✅ Single source of truth
- ✅ Guaranteed consistency
- ✅ Easy version updates
- ✅ Professional DevOps practices

This is how modern teams manage infrastructure - you're doing it right! 🎯
