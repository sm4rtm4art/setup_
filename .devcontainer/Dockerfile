# syntax=docker/dockerfile:1.7
# =============================================================================
# Multi-stage Dockerfile following security and performance best practices
# =============================================================================

# -----------------------------------------------------------------------------
# Build stage - Download and prepare tools
# -----------------------------------------------------------------------------
FROM debian:12-slim AS builder

# Pin specific versions for reproducible builds
ARG BAT_VERSION=0.24.0
ARG EZA_VERSION=0.20.0
ARG UV_VERSION=0.5.11
ARG RUFF_VERSION=0.6.9
ARG MYPY_VERSION=1.11.2

# Java versions
ARG JAVA_VERSION=21
ARG MAVEN_VERSION=3.9.6
ARG GRADLE_VERSION=8.6

# Rust versions
ARG RUST_VERSION=1.75.0

# Security: Add checksums for supply chain verification
ARG BAT_SHA256=907554a9eff239f256ee8fe05a922aad84febe4fe10a499def72a4557211d00da
ARG EZA_SHA256=ee1319db52de02075b0e71a0a9e48ae83ad2d1b7c11b1c8ab38b8af15651c7a8
ARG MAVEN_SHA256=6eedd2cae3626d6ad3a5c9ee324bd265853d64297f07f033430755bd0e0c3a4b
ARG GRADLE_SHA256=9ed7abccc1a58b1bb5b0a2b9b481e6fb6e42c0dd83bf5b32f3e5de68c7da49c9

# Avoid warnings during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies with cache mount for faster rebuilds
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg

# Create download directory
WORKDIR /downloads

# Download CLI tools with version pinning and checksum verification
RUN curl -fsSL -o bat.deb \
    "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_amd64.deb" \
    && echo "${BAT_SHA256}  bat.deb" | sha256sum -c -

RUN curl -fsSL -o eza.tar.gz \
    "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" \
    && echo "${EZA_SHA256}  eza.tar.gz" | sha256sum -c - \
    && tar -xzf eza.tar.gz \
    && mv eza ./eza-binary

RUN curl -fsSL -o uv-installer.sh \
    "https://astral.sh/uv/${UV_VERSION}/install.sh"

# Download Java build tools
RUN curl -fsSL -o maven.tar.gz \
    "https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    && echo "${MAVEN_SHA256}  maven.tar.gz" | sha256sum -c - \
    && tar -xzf maven.tar.gz \
    && mv apache-maven-${MAVEN_VERSION} maven

RUN curl -fsSL -o gradle.zip \
    "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    && echo "${GRADLE_SHA256}  gradle.zip" | sha256sum -c - \
    && unzip -q gradle.zip \
    && mv gradle-${GRADLE_VERSION} gradle

# -----------------------------------------------------------------------------
# Runtime stage - Final secure image
# -----------------------------------------------------------------------------
FROM debian:12-slim AS runtime

# Copy version args from builder
ARG BAT_VERSION=0.24.0
ARG EZA_VERSION=0.20.0
ARG UV_VERSION=0.5.11
ARG RUFF_VERSION=0.6.9
ARG MYPY_VERSION=1.11.2
ARG JAVA_VERSION=21
ARG MAVEN_VERSION=3.9.6
ARG GRADLE_VERSION=8.6
ARG RUST_VERSION=1.75.0

# Build metadata for OCI compliance
ARG VCS_REF
ARG BUILD_DATE
LABEL org.opencontainers.image.title="wsl-setup-tool" \
      org.opencontainers.image.description="Multi-language development container (Python, Java, Rust)" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.source="https://github.com/martin/setup_tool"

# Create non-root user first (security best practice)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# Create user and group (fix ARG variable expansion)
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# Set environment variables early so PATH is available for installations
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH="/home/$USERNAME/.local/bin:/home/$USERNAME/.cargo/bin:/opt/maven/bin:/opt/gradle/bin:$PATH" \
    JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64 \
    MAVEN_HOME=/opt/maven \
    GRADLE_HOME=/opt/gradle \
    CARGO_HOME=/home/$USERNAME/.cargo \
    RUSTUP_HOME=/home/$USERNAME/.rustup

# Install tini for proper init process
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends tini

# Install system packages in a single optimized layer with cache mount
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    # Essential tools
    git \
    curl \
    ca-certificates \
    unzip \
    # Python ecosystem
    python3 \
    python3-pip \
    python3-venv \
    # Java ecosystem
    openjdk-${JAVA_VERSION}-jdk-headless \
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
    # Locale support
    locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

# Create symbolic link for fd
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Copy and install downloaded tools from builder stage
COPY --from=builder /downloads/bat.deb /tmp/
RUN dpkg -i /tmp/bat.deb && rm /tmp/bat.deb

# Fix eza installation path
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

# Use uv consistently for Python package management
RUN uv pip install --system \
    ruff==$RUFF_VERSION \
    mypy==$MYPY_VERSION \
    pytest \
    black \
    isort

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
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

# Set working directory
WORKDIR /workspace

# Use tini as entrypoint for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Add comprehensive health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 --version && java --version && rustc --version && mvn --version || exit 1

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=dialog

# Document exposed ports
EXPOSE 8000 3000 8080

# Use exec form for proper signal handling
CMD ["sleep", "infinity"] 