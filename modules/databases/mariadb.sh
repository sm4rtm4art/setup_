#!/bin/bash
# =============================================================================
# MariaDB Database Module
# Installs MariaDB server and client tools
# =============================================================================

# Module metadata
MODULE_NAME="mariadb"
MODULE_DESCRIPTION="MariaDB SQL database server and client tools"
MODULE_DEPS=("base")

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/core.sh"
source "${SCRIPT_DIR}/lib/wsl.sh"
source "${SCRIPT_DIR}/lib/installer.sh"
source "${SCRIPT_DIR}/config/versions.conf"

# =============================================================================
# MODULE FUNCTIONS
# =============================================================================

# Install MariaDB prerequisites
mariadb_prereqs() {
    log_info "Installing MariaDB prerequisites..."
    
    install_packages \
        software-properties-common dirmngr apt-transport-https
}

# Install MariaDB server and client
install_mariadb() {
    if command_exists mysql; then
        log_info "MariaDB already installed"
        return 0
    fi
    
    log_info "Installing MariaDB server and client..."
    
    # Update package list and install
    if install_packages mariadb-server mariadb-client; then
        log_success "MariaDB installed successfully"
    else
        log_error "MariaDB installation failed"
        return 1
    fi
}

# Secure MariaDB installation
secure_mariadb() {
    log_info "Securing MariaDB installation..."
    
    # Start MariaDB service if not running
    if ! systemctl is-active --quiet mariadb; then
        sudo systemctl start mariadb
        sudo systemctl enable mariadb
    fi
    
    # Run mysql_secure_installation non-interactively
    log_info "Running security configuration..."
    
    # Create a temporary SQL file for security setup
    local temp_sql=$(mktemp)
    cat > "$temp_sql" << 'EOF'
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    # Execute security setup
    if sudo mysql < "$temp_sql"; then
        log_success "MariaDB security configuration completed"
    else
        log_warning "Some security configurations may have failed"
    fi
    
    # Cleanup
    rm -f "$temp_sql"
}

# Create development database and user
create_dev_database() {
    if ! confirm "Create development database and user?" "y"; then
        return 0
    fi
    
    log_info "Creating development database..."
    
    local db_name="dev_db"
    local db_user="dev_user"
    local db_pass="dev_password"
    
    # Ask for custom values
    if is_interactive; then
        read -p "Database name [dev_db]: " custom_db_name
        read -p "Database user [dev_user]: " custom_db_user
        read -s -p "Database password [dev_password]: " custom_db_pass
        echo
        
        db_name="${custom_db_name:-$db_name}"
        db_user="${custom_db_user:-$db_user}"
        db_pass="${custom_db_pass:-$db_pass}"
    fi
    
    # Create SQL commands
    local temp_sql=$(mktemp)
    cat > "$temp_sql" << EOF
CREATE DATABASE IF NOT EXISTS \`${db_name}\`;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Execute database creation
    if sudo mysql < "$temp_sql"; then
        log_success "Development database created: $db_name"
        log_info "Database user: $db_user"
        log_info "Connection: mysql -u $db_user -p $db_name"
    else
        log_error "Failed to create development database"
    fi
    
    # Cleanup
    rm -f "$temp_sql"
}

# Install MariaDB Python connector (if Python is available)
install_mariadb_python() {
    if ! command_exists python3; then
        log_info "Python not available, skipping MariaDB Python connector"
        return 0
    fi
    
    log_info "Installing MariaDB Python connector..."
    
    # Install required system packages for Python connector
    install_packages libmariadb-dev pkg-config
    
    if command_exists uv; then
        uv pip install mariadb
    elif command_exists pip; then
        pip install mariadb
    else
        log_warning "No Python package manager available"
        return 1
    fi
    
    log_success "MariaDB Python connector installed"
}

# Configure MariaDB
mariadb_configure() {
    log_info "Configuring MariaDB..."
    
    # Create custom configuration for development
    local config_file="/etc/mysql/mariadb.conf.d/99-dev.cnf"
    
    sudo tee "$config_file" > /dev/null << 'EOF'
[mysqld]
# Development-friendly settings
bind-address = 127.0.0.1
max_connections = 100
innodb_buffer_pool_size = 128M
query_cache_size = 16M
query_cache_limit = 1M

# Logging
general_log = 1
general_log_file = /var/log/mysql/mysql.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 2

[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4
EOF
    
    # Restart MariaDB to apply configuration
    sudo systemctl restart mariadb
    
    log_success "MariaDB configured for development"
}

# Verify MariaDB installation
mariadb_verify() {
    log_info "Verifying MariaDB installation..."
    
    local server_ok=0
    local client_ok=0
    local python_ok=0
    
    # Check server status
    if systemctl is-active --quiet mariadb; then
        server_ok=1
        log_debug "✓ MariaDB server running"
    else
        log_warning "✗ MariaDB server not running"
    fi
    
    # Check client
    if command_exists mysql; then
        local version=$(mysql --version 2>/dev/null)
        client_ok=1
        log_debug "✓ MariaDB client: $version"
    else
        log_warning "✗ MariaDB client not found"
    fi
    
    # Check Python connector
    if command_exists python3; then
        if python3 -c "import mariadb; print('MariaDB Python connector available')" 2>/dev/null; then
            python_ok=1
            log_debug "✓ MariaDB Python connector available"
        else
            log_debug "- MariaDB Python connector not installed"
        fi
    fi
    
    # Overall verification
    if [[ $server_ok -eq 1 && $client_ok -eq 1 ]]; then
        log_success "MariaDB verification passed"
        return 0
    else
        log_warning "MariaDB verification had issues"
        return 1
    fi
}

# =============================================================================
# MODULE INTERFACE
# =============================================================================

# Module entry point
module_install() {
    log_info "Installing MariaDB module..."
    
    mariadb_prereqs
    install_mariadb
    secure_mariadb
    mariadb_configure
    create_dev_database
    
    # Optional: install Python connector
    if confirm "Install MariaDB Python connector?" "y"; then
        install_mariadb_python
    fi
    
    mariadb_verify
    
    log_success "MariaDB module installation completed"
}

# Module status check
module_status() {
    echo "=== MariaDB Environment ==="
    
    if command_exists mysql; then
        echo "✅ MariaDB Client: $(mysql --version 2>/dev/null | cut -d' ' -f1-3)"
    else
        echo "❌ MariaDB client not installed"
    fi
    
    if systemctl is-active --quiet mariadb 2>/dev/null; then
        echo "✅ MariaDB Server: Running"
        
        # Show server version
        local server_version=$(sudo mysql -e "SELECT VERSION();" 2>/dev/null | tail -n1)
        if [[ -n "$server_version" ]]; then
            echo "📋 Server Version: $server_version"
        fi
    else
        echo "❌ MariaDB server not running"
    fi
    
    if command_exists python3; then
        if python3 -c "import mariadb; print('✅ MariaDB Python connector available')" 2>/dev/null; then
            :  # Success message already printed
        else
            echo "❌ MariaDB Python connector not available"
        fi
    fi
}

# Module cleanup
module_clean() {
    log_info "Cleaning up MariaDB..."
    
    if confirm "Stop MariaDB service?" "n"; then
        sudo systemctl stop mariadb
        sudo systemctl disable mariadb
        log_info "MariaDB service stopped"
    fi
    
    if confirm "Remove MariaDB packages?" "n"; then
        sudo apt-get remove --purge mariadb-server mariadb-client -y
        sudo apt-get autoremove -y
        log_info "MariaDB packages removed"
    fi
    
    if confirm "Remove MariaDB data directory?" "n"; then
        sudo rm -rf /var/lib/mysql
        log_warning "All MariaDB data has been removed!"
    fi
}

# Export module interface functions
export -f module_install module_status module_clean 