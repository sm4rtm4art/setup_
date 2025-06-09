# syntax=docker/dockerfile:1.7
# =============================================================================
# Multi-stage Dockerfile following security and performance best practices
# =============================================================================

# -----------------------------------------------------------------------------
# Build stage - Download and prepare tools
# -----------------------------------------------------------------------------
FROM debian:12-slim AS builder

# Copy version configuration and set TARGETPLATFORM
COPY config/versions.conf /tmp/versions.conf
ARG TARGETPLATFORM

# ARG overrides for versions
ARG EZA_VERSION_OVERRIDE
ARG UV_VERSION_OVERRIDE
ARG MAVEN_VERSION_OVERRIDE
ARG GRADLE_VERSION_OVERRIDE

# Avoid warnings during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies with cache mount for faster rebuilds
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    unzip

# Create download directory
WORKDIR /downloads

# Download CLI tools using centralized versions and multi-arch support
RUN . /tmp/versions.conf && \
    EZA_VERSION=${EZA_VERSION_OVERRIDE:-$EZA_VERSION} && \
    case ${TARGETPLATFORM} in \
        "linux/amd64") \
            ARCH_SUFFIX="x86_64-unknown-linux-gnu"; \
            EZA_SHA256="21459705857a08dacd48ee5b6ed2ef878e85096b645eb60938bac5238e3056e7"; \
            ;; \
        "linux/arm64") \
            ARCH_SUFFIX="aarch64-unknown-linux-gnu"; \
            EZA_SHA256="df458f76662b5aa1e87fcc0d4ff5eb1063905127acd41e2aee0e20fc187394da"; \
            ;; \
        *) echo "Unsupported architecture: ${TARGETPLATFORM}"; exit 1 ;; \
    esac && \
    curl -fsSL -o eza.tar.gz \
    "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_${ARCH_SUFFIX}.tar.gz" && \
    echo "${EZA_SHA256}  eza.tar.gz" | sha256sum -c - && \
    tar -xzf eza.tar.gz && \
    mv eza ./eza-binary

RUN . /tmp/versions.conf && \
    UV_VERSION=${UV_VERSION_OVERRIDE:-$UV_VERSION} && \
    # Although uv has a version in its install url, the script itself does not have a checksum.
    # We are trusting astral.sh here. A more secure alternative would be to build from source.
    curl -fsSL -o uv-installer.sh \
    "https://astral.sh/uv/install.sh"

# Download Java build tools using centralized versions
RUN . /tmp/versions.conf && \
    MAVEN_VERSION=${MAVEN_VERSION_OVERRIDE:-$MAVEN_VERSION} && \
    MAVEN_SHA512="d6a2c88f0e57b8c381c706691c53b3e34b8982390f845d554a7375a0d2417539f1388b4334339e3f169f91a329d59218d655e81d115e10e470878328c68a48b5" && \
    curl -fsSL -o maven.tar.gz \
    "https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" && \
    echo "${MAVEN_SHA512}  maven.tar.gz" | sha512sum -c - && \
    tar -xzf maven.tar.gz && \
    mv apache-maven-${MAVEN_VERSION} maven

RUN . /tmp/versions.conf && \
    GRADLE_VERSION=${GRADLE_VERSION_OVERRIDE:-$GRADLE_VERSION} && \
    GRADLE_SHA256="9d926787066a081739e8200858338b4a69e837c3a821a33aca9db09dd4a41026" && \
    curl -fsSL -o gradle.zip \
    "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" && \
    echo "${GRADLE_SHA256}  gradle.zip" | sha256sum -c - && \
    unzip -q gradle.zip && \
    mv gradle-${GRADLE_VERSION} gradle

# -----------------------------------------------------------------------------
# Runtime stage - Final secure image
# -----------------------------------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime

# Copy version configuration
COPY config/versions.conf /tmp/versions.conf

# ARG overrides for versions
ARG PYTHON_VERSION_OVERRIDE
ARG RUST_VERSION_OVERRIDE

# Create non-root user first (security best practice)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# Create user and group and install sudo
RUN apt-get update && apt-get install -y --no-install-recommends sudo && \
    groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables early so PATH is available for installations
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH="/home/$USERNAME/.local/bin:/home/$USERNAME/.cargo/bin:/opt/maven/bin:/opt/gradle/bin:$PATH" \
    MAVEN_HOME=/opt/maven \
    GRADLE_HOME=/opt/gradle \
    CARGO_HOME=/home/$USERNAME/.cargo \
    RUSTUP_HOME=/home/$USERNAME/.rustup

# Install tini for proper init process
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends tini && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install system packages in a single optimized layer with cache mount
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    # Essential tools
    git \
    curl \
    ca-certificates \
    unzip \
    # Java ecosystem
    openjdk-21-jdk-headless \
    # Build tools for native extensions
    build-essential \
    pkg-config \
    libssl-dev \
    # Development tools
    shellcheck \
    bats \
    git-flow \
    pre-commit \
    # Modern CLI tools
    htop \
    tree \
    jq \
    ripgrep \
    fd-find \
    fzf \
    tmux \
    zsh \
    # Locale support
    locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create symbolic link for fd
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Copy and install downloaded tools from builder stage
COPY --from=builder /downloads/eza-binary /usr/local/bin/eza
RUN chmod +x /usr/local/bin/eza

# Install Java build tools
COPY --from=builder /downloads/maven /opt/maven
COPY --from=builder /downloads/gradle /opt/gradle
RUN chmod +x /opt/maven/bin/mvn /opt/gradle/bin/gradle

# Switch to non-root user for language-specific installations
USER $USERNAME
WORKDIR /home/$USERNAME

# Install uv (Python package manager)
COPY --from=builder /downloads/uv-installer.sh /tmp/
RUN bash /tmp/uv-installer.sh && rm /tmp/uv-installer.sh

# Use uv for Python package management with versions from config
RUN . /tmp/versions.conf && \
    PYTHON_VERSION=${PYTHON_VERSION_OVERRIDE:-$PYTHON_VERSION} && \
    uv pip install --system \
    ruff \
    mypy \
    pytest \
    black \
    isort

# Install Rust toolchain using version from config
RUN . /tmp/versions.conf && \
    RUST_VERSION=${RUST_VERSION_OVERRIDE:-$RUST_VERSION} && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --default-toolchain ${RUST_VERSION} \
    --profile default \
    --no-modify-path \
    -y

# Install common Rust tools
RUN ~/.cargo/bin/rustup component add \
    clippy \
    rustfmt \
    rust-analyzer \
    && ~/.cargo/bin/cargo install \
    cargo-watch \
    cargo-edit \
    cargo-audit \
    sccache

# Create version info script
RUN echo '#!/bin/bash' > /home/$USERNAME/.local/bin/versions && \
    echo '. /tmp/versions.conf' >> /home/$USERNAME/.local/bin/versions && \
    echo 'echo "=== Development Environment Versions ==="' >> /home/$USERNAME/.local/bin/versions && \
    echo 'echo "Python: $(python3 --version)"' >> /home/$USERNAME/.local/bin/versions && \
    echo 'echo "Rust: $(rustc --version)"' >> /home/$USERNAME/.local/bin/versions && \
    echo 'echo "Java: $(java --version | head -n1)"' >> /home/$USERNAME/.local/bin/versions && \
    echo 'echo "Maven: $(mvn --version | head -n1)"' >> /home/$USERNAME/.local/bin/versions && \
    echo 'echo "Gradle: $(gradle --version | grep Gradle)"' >> /home/$USERNAME/.local/bin/versions && \
    echo 'echo "UV: $(uv --version)"' >> /home/$USERNAME/.local/bin/versions && \
    chmod +x /home/$USERNAME/.local/bin/versions

# Set working directory
WORKDIR /workspace

# Use tini as entrypoint for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Add comprehensive health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 --version && java --version && rustc --version || exit 1

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=dialog

# Document exposed ports
EXPOSE 8000 3000 8080

# Use exec form for proper signal handling
CMD ["sleep", "infinity"]