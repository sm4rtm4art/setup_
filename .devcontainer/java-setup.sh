#!/bin/bash
set -e

echo "☕ Setting up Java development environment..."

# Install SDKMAN if not present
if [ ! -d "$HOME/.sdkman" ]; then
    echo "📦 Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
else
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Install multiple Java versions for compatibility testing
echo "📦 Installing Java versions..."
sdk install java 21.0.1-tem || echo "Java 21 already installed"
sdk install java 17.0.9-tem || echo "Java 17 already installed"
sdk install java 11.0.21-tem || echo "Java 11 already installed"

# Set Java 21 as default
sdk default java 21.0.1-tem

# Install build tools
echo "🔧 Installing build tools..."
sdk install gradle 8.5 || echo "Gradle already installed"
sdk install maven 3.9.6 || echo "Maven already installed"

# Install Spring Boot CLI
sdk install springboot 3.2.0 || echo "Spring Boot CLI already installed"

# Install JBang for easy scripting
sdk install jbang 0.114.0 || echo "JBang already installed"

# Setup shell aliases for Java development
cat >> ~/.zshrc << 'EOF'

# Java Development Aliases
alias j8='sdk use java 8.0.392-tem'
alias j11='sdk use java 11.0.21-tem'
alias j17='sdk use java 17.0.9-tem'
alias j21='sdk use java 21.0.1-tem'

# Build tool aliases
alias mw='./mvnw'
alias gw='./gradlew'
alias sb='spring'

# Spring Boot aliases
alias sbrun='spring run'
alias sbtest='spring test'
alias sbjar='spring jar'

# Maven aliases
alias mci='mvn clean install'
alias mcp='mvn clean package'
alias mct='mvn clean test'
alias mrun='mvn spring-boot:run'

# Gradle aliases
alias gci='gradle clean build'
alias gcp='gradle clean build -x test'
alias gct='gradle clean test'
alias grun='gradle bootRun'

# JBang aliases
alias jb='jbang'
alias jbr='jbang run'

EOF

echo "✅ Java development environment setup complete!"
echo ""
echo "☕ Available Java Development Tools:"
echo "   - SDKMAN for managing Java versions and tools"
echo "   - Java 21, 17, 11 (switch with j21, j17, j11)"
echo "   - Gradle 8.5 and Maven 3.9.6"
echo "   - Spring Boot CLI and JBang"
echo ""
echo "🚀 Quick Start Commands:"
echo "   - 'spring init myapp' - Create new Spring Boot project"
echo "   - 'jbang init hello.java' - Create Java script" 