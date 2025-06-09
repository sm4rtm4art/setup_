#!/bin/bash
# =============================================================================
# Container Build Script with Centralized Version Management
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load centralized version configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSIONS_FILE="$PROJECT_ROOT/config/versions.conf"

if [[ ! -f "$VERSIONS_FILE" ]]; then
    echo -e "${RED}Error: versions.conf not found at $VERSIONS_FILE${NC}"
    exit 1
fi

# Source the version configuration
source "$VERSIONS_FILE"

echo -e "${BLUE}=== Building Containers with Centralized Versions ===${NC}"
echo -e "${YELLOW}Using versions from: $VERSIONS_FILE${NC}"
echo ""
echo -e "Python: ${GREEN}$PYTHON_VERSION${NC}"
echo -e "Rust: ${GREEN}$RUST_VERSION${NC}"
echo -e "Java: ${GREEN}$DEFAULT_JAVA${NC}"
echo -e "Maven: ${GREEN}$MAVEN_VERSION${NC}"
echo -e "Gradle: ${GREEN}$GRADLE_VERSION${NC}"
echo -e "Spring Boot: ${GREEN}$SPRINGBOOT_VERSION${NC}"
echo -e "UV: ${GREEN}$UV_VERSION${NC}"
echo ""

# Function to build containers
build_container() {
    local dockerfile="$1"
    local tag="$2"
    local target="${3:-}"
    
    echo -e "${BLUE}Building $tag...${NC}"
    
    # Build command with version arguments
    local build_cmd=(
        docker build
        --file "$dockerfile"
        --tag "$tag"
        --build-arg "PYTHON_VERSION=$PYTHON_VERSION"
        --build-arg "RUST_VERSION=$RUST_VERSION"
        --build-arg "MAVEN_VERSION=$MAVEN_VERSION"
        --build-arg "GRADLE_VERSION=$GRADLE_VERSION"
        --build-arg "UV_VERSION=$UV_VERSION"
        --build-arg "EZA_VERSION=$EZA_VERSION"
        --build-arg "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        --build-arg "VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    )
    
    if [[ -n "$target" ]]; then
        build_cmd+=(--target "$target")
    fi
    
    build_cmd+=("$PROJECT_ROOT")
    
    if "${build_cmd[@]}"; then
        echo -e "${GREEN}✓ Successfully built $tag${NC}"
    else
        echo -e "${RED}✗ Failed to build $tag${NC}"
        return 1
    fi
}

# Parse command line arguments
CONTAINER_TYPE="${1:-all}"

case "$CONTAINER_TYPE" in
    "dev"|"development")
        echo -e "${BLUE}Building development container...${NC}"
        build_container ".devcontainer/Dockerfile" "wsl-setup-tool-dev:latest"
        ;;
    
    "ml"|"ml-enhanced")
        echo -e "${BLUE}Building ML-enhanced development container...${NC}"
        build_container ".devcontainer/Dockerfile.ml-enhanced" "wsl-setup-tool-ml:latest"
        ;;
    
    "prod"|"production")
        echo -e "${BLUE}Building production containers...${NC}"
        
        # Build all production services
        build_container ".devcontainer/Dockerfile.production" "myapp/rust-service:latest" "rust-service"
        build_container ".devcontainer/Dockerfile.production" "myapp/python-service:latest" "python-service"
        build_container ".devcontainer/Dockerfile.production" "myapp/java-service:latest" "java-service"
        build_container ".devcontainer/Dockerfile.production" "myapp/api-gateway:latest" "api-gateway"
        ;;
    
    "all")
        echo -e "${BLUE}Building all containers...${NC}"
        
        # Development containers
        build_container ".devcontainer/Dockerfile" "wsl-setup-tool-dev:latest"
        build_container ".devcontainer/Dockerfile.ml-enhanced" "wsl-setup-tool-ml:latest"
        
        # Production containers
        build_container ".devcontainer/Dockerfile.production" "myapp/rust-service:latest" "rust-service"
        build_container ".devcontainer/Dockerfile.production" "myapp/python-service:latest" "python-service"
        build_container ".devcontainer/Dockerfile.production" "myapp/java-service:latest" "java-service"
        build_container ".devcontainer/Dockerfile.production" "myapp/api-gateway:latest" "api-gateway"
        ;;
    
    "check"|"versions")
        echo -e "${BLUE}=== Current Version Configuration ===${NC}"
        echo ""
        echo -e "${YELLOW}Languages:${NC}"
        echo -e "  Python: $PYTHON_VERSION"
        echo -e "  Rust: $RUST_VERSION"
        echo -e "  Java: $DEFAULT_JAVA"
        echo ""
        echo -e "${YELLOW}Build Tools:${NC}"
        echo -e "  Maven: $MAVEN_VERSION"
        echo -e "  Gradle: $GRADLE_VERSION"
        echo -e "  Spring Boot: $SPRINGBOOT_VERSION"
        echo ""
        echo -e "${YELLOW}Package Managers:${NC}"
        echo -e "  UV (Python): $UV_VERSION"
        echo ""
        echo -e "${YELLOW}CLI Tools:${NC}"
        echo -e "  EZA: $EZA_VERSION"
        echo -e "  DuckDB: $DUCKDB_VERSION"
        echo ""
        echo -e "${GREEN}All versions sourced from: $VERSIONS_FILE${NC}"
        exit 0
        ;;
    
    "help"|"-h"|"--help")
        echo -e "${BLUE}Container Build Script Usage:${NC}"
        echo ""
        echo -e "${YELLOW}Commands:${NC}"
        echo -e "  dev        Build development container only"
        echo -e "  ml         Build ML-enhanced development container"
        echo -e "  prod       Build all production containers"
        echo -e "  all        Build all containers (default)"
        echo -e "  check      Show current version configuration"
        echo -e "  help       Show this help message"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo -e "  $0 dev      # Build just the dev container"
        echo -e "  $0 prod     # Build production services"
        echo -e "  $0 check    # Show versions being used"
        echo ""
        echo -e "${GREEN}All versions are read from: $VERSIONS_FILE${NC}"
        exit 0
        ;;
    
    *)
        echo -e "${RED}Error: Unknown container type '$CONTAINER_TYPE'${NC}"
        echo -e "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=== Build Complete! ===${NC}"
echo -e "${BLUE}To start development environment:${NC}"
echo -e "  docker-compose up -d"
echo ""
echo -e "${BLUE}To check built images:${NC}"
echo -e "  docker images | grep -E 'wsl-setup-tool|myapp'" 