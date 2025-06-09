#!/bin/bash
# =============================================================================
# Data Processing & API Container Build Script
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKERFILE="$PROJECT_ROOT/.devcontainer/Dockerfile.ml-enhanced"
CONFIG_FILE="$PROJECT_ROOT/config/versions.conf"

# Default values
IMAGE_NAME="wsl-setup-tool-ml"
TARGET="development"
CACHE_FROM=""
PLATFORM="linux/amd64"
PUSH=false
INCLUDE_TENSORFLOW=0
INCLUDE_PYTORCH=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build data processing & API development container with various configurations.

OPTIONS:
    -t, --target TARGET         Build target (development|production) [default: development]
    -n, --name NAME            Image name [default: wsl-setup-tool-ml]
    -p, --platform PLATFORM   Target platform [default: linux/amd64]
    --cache-from IMAGE         Use cache from another image
    --no-tensorflow           Exclude TensorFlow from build (default: excluded)
    --no-pytorch             Exclude PyTorch from build (default: excluded)
    --with-tensorflow         Include TensorFlow in build
    --with-pytorch           Include PyTorch in build
    --with-ml                Include both TensorFlow and PyTorch
    --push                   Push image to registry after build
    --slim                   Build without optional ML frameworks (faster)
    -h, --help               Show this help message

EXAMPLES:
    # Standard data processing build
    $0

    # Build with ML frameworks included
    $0 --with-ml

    # Production build
    $0 --target production

    # Multi-architecture build
    $0 --platform linux/amd64,linux/arm64

    # Build with cache from existing image
    $0 --cache-from wsl-setup-tool-ml:latest

    # Build and push to registry
    $0 --target production --push

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        --cache-from)
            CACHE_FROM="$2"
            shift 2
            ;;
        --no-tensorflow)
            INCLUDE_TENSORFLOW=0
            shift
            ;;
        --no-pytorch)
            INCLUDE_PYTORCH=0
            shift
            ;;
        --with-tensorflow)
            INCLUDE_TENSORFLOW=1
            shift
            ;;
        --with-pytorch)
            INCLUDE_PYTORCH=1
            shift
            ;;
        --with-ml)
            INCLUDE_TENSORFLOW=1
            INCLUDE_PYTORCH=1
            shift
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --slim)
            INCLUDE_TENSORFLOW=0
            INCLUDE_PYTORCH=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ ! "$TARGET" =~ ^(development|production)$ ]]; then
    log_error "Invalid target: $TARGET. Must be 'development' or 'production'"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
fi

if [[ ! -f "$DOCKERFILE" ]]; then
    log_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

# Source version configuration
log_info "Loading version configuration..."
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# Generate build tags
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
BUILD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
VERSION_TAG="${PYTHON_VERSION}-${BUILD_COMMIT}"

# Determine final image tag
if [[ "$TARGET" == "production" ]]; then
    FINAL_TAG="${IMAGE_NAME}:${VERSION_TAG}-prod"
    LATEST_TAG="${IMAGE_NAME}:latest-prod"
else
    FINAL_TAG="${IMAGE_NAME}:${VERSION_TAG}-dev"
    LATEST_TAG="${IMAGE_NAME}:latest-dev"
fi

# Build command construction
BUILD_ARGS=(
    "--file" "$DOCKERFILE"
    "--target" "$TARGET"
    "--platform" "$PLATFORM"
    "--tag" "$FINAL_TAG"
    "--tag" "$LATEST_TAG"
    "--build-arg" "PYTHON_VERSION_OVERRIDE=${PYTHON_VERSION}"
    "--build-arg" "DUCKDB_VERSION_OVERRIDE=${DUCKDB_VERSION}"
    "--build-arg" "INCLUDE_TENSORFLOW=${INCLUDE_TENSORFLOW}"
    "--build-arg" "INCLUDE_PYTORCH=${INCLUDE_PYTORCH}"
    "--label" "build.date=${BUILD_DATE}"
    "--label" "build.commit=${BUILD_COMMIT}"
    "--label" "build.version=${VERSION_TAG}"
)

# Add cache configuration
if [[ -n "$CACHE_FROM" ]]; then
    BUILD_ARGS+=("--cache-from" "$CACHE_FROM")
fi

# Add multi-platform support if needed
if [[ "$PLATFORM" == *","* ]]; then
    BUILD_ARGS+=("--push")
    PUSH=true
fi

log_info "Building data processing & API container..."
log_info "Target: $TARGET"
log_info "Platform: $PLATFORM"
log_info "Python: $PYTHON_VERSION"
log_info "DuckDB: $DUCKDB_VERSION"
log_info "TensorFlow: $([ $INCLUDE_TENSORFLOW -eq 1 ] && echo "included" || echo "excluded")"
log_info "PyTorch: $([ $INCLUDE_PYTORCH -eq 1 ] && echo "included" || echo "excluded")"
log_info "Final tag: $FINAL_TAG"

# Change to project root for build context
cd "$PROJECT_ROOT"

# Build the image
log_info "Starting Docker build..."
if docker buildx build "${BUILD_ARGS[@]}" .; then
    log_success "Build completed successfully!"
    
    # Show image information
    log_info "Image details:"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    # Push if requested
    if [[ "$PUSH" == "true" && "$PLATFORM" != *","* ]]; then
        log_info "Pushing images to registry..."
        docker push "$FINAL_TAG"
        docker push "$LATEST_TAG"
        log_success "Images pushed successfully!"
    fi
    
    # Generate usage instructions
    cat << EOF

🚀 Build completed! 

Quick start commands:
  # Run development container
  docker run -it --rm -v \$(pwd):/workspace $FINAL_TAG

  # Run with docker-compose (recommended)
  docker-compose -f docker-compose.yml up -d

  # Check container health
  docker run --rm $FINAL_TAG /home/vscode/.local/bin/health-check

  # View installed packages
  docker run --rm $FINAL_TAG /home/vscode/.local/bin/ml-versions

EOF

else
    log_error "Build failed!"
    exit 1
fi 