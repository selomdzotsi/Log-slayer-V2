#!/bin/bash

# Script: Splunk Enterprise Installer
# Description: Automated Splunk Enterprise deployment script for Linux systems
# Version: 1.5

# Set error handling
set -e
set -o pipefail

# Constants
LOG_FILE="splunk_install.log"
SPLUNK_DEB="splunk-9.4.2-e9664af3d956-linux-amd64.deb"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/9.4.2/linux/splunk-9.4.2-e9664af3d956-linux-amd64.deb"

# Function to log messages
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to validate password strength
validate_password() {
    local password=$1
    local length=${#password}
    
    if [ $length -lt 8 ]; then
        echo "Password must be at least 8 characters long"
        return 1
    fi
    
    if ! echo "$password" | grep -q "[A-Z]"; then
        echo "Password must contain at least one uppercase letter"
        return 1
    fi
    
    if ! echo "$password" | grep -q "[a-z]"; then
        echo "Password must contain at least one lowercase letter"
        return 1
    fi
    
    if ! echo "$password" | grep -q "[0-9]"; then
        echo "Password must contain at least one number"
        return 1
    fi
    
    if ! echo "$password" | grep -q "[!@#$%^&*()_+]"; then
        echo "Password must contain at least one special character (!@#$%^&*()_+)"
        return 1
    fi
    
    return 0
}

# Function to get credentials
get_credentials() {
    local valid_credentials=false
    
    echo "Setting up Splunk admin credentials"
    echo "--------------------------------"
    
    while [ "$valid_credentials" = false ]; do
        # Get username
        read -p "Enter Splunk admin username: " SPLUNK_USERNAME
        if [ -z "$SPLUNK_USERNAME" ]; then
            echo "Username cannot be empty"
            continue
        fi
        
        # Get password
        while true; do
            read -s -p "Enter Splunk admin password: " SPLUNK_PASSWORD
            echo
            read -s -p "Confirm password: " SPLUNK_PASSWORD_CONFIRM
            echo
            
            if [ "$SPLUNK_PASSWORD" = "$SPLUNK_PASSWORD_CONFIRM" ]; then
                if validate_password "$SPLUNK_PASSWORD"; then
                    valid_credentials=true
                    break
                fi
            else
                echo "Passwords do not match"
            fi
        done
    done
    
    echo "--------------------------------"
    log_message "Credentials configured successfully"
}

# Function to check system requirements
check_system_requirements() {
    log_message "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR: This script must be run as root"
        exit 1
    fi

    # Check Linux distribution
    if ! command -v lsb_release &> /dev/null; then
        if [ -f "/etc/os-release" ]; then
            . /etc/os-release
            OS_NAME=$NAME
            OS_VERSION=$VERSION_ID
        else
            log_message "ERROR: Cannot determine Linux distribution"
            exit 1
        fi
    else
        OS_NAME=$(lsb_release -si)
        OS_VERSION=$(lsb_release -sr)
    fi

    log_message "Detected OS: $OS_NAME $OS_VERSION"

    # Check for supported distributions
    case "$OS_NAME" in
        *Ubuntu*|*Debian*)
            log_message "Supported distribution detected"
            ;;
        *)
            log_message "ERROR: Unsupported Linux distribution. This script is designed for Ubuntu/Debian"
            exit 1
            ;;
    esac

    # Check available disk space (minimum 5GB)
    available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 5 ]; then
        log_message "ERROR: Insufficient disk space. Minimum 5GB required"
        exit 1
    fi

    # Check if wget is installed
    if ! command -v wget &> /dev/null; then
        log_message "Installing wget..."
        apt-get update && apt-get install -y wget
    fi
}

# Function to download Splunk
download_splunk() {
    log_message "Downloading Splunk Enterprise..."
    echo "Starting download of Splunk Enterprise package..."
    if wget --progress=bar:force:noscroll -O "$SPLUNK_DEB" "$SPLUNK_URL" 2>&1; then
        log_message "Download completed successfully"
    else
        log_message "ERROR: Splunk download failed. Check $LOG_FILE for details"
   exit 1
fi
}

# Function to install Splunk
install_splunk() {
    log_message "Installing Splunk Enterprise..."
    if dpkg -i "$SPLUNK_DEB" 2>> "$LOG_FILE"; then
        dpkg --status splunk >> "$LOG_FILE"
        log_message "Installation completed successfully"
    else
        log_message "ERROR: Splunk installation failed. Check $LOG_FILE for details"
exit 1
fi
}

# Function to start Splunk
start_splunk() {
    log_message "Starting and configuring Splunk..."
    cd /opt/splunk/bin || exit 1
    
    # Create user-seed.conf with admin credentials
    cat > "/opt/splunk/etc/system/local/user-seed.conf" << EOF
[user_info]
USERNAME = $SPLUNK_USERNAME
PASSWORD = $SPLUNK_PASSWORD
EOF

    if ./splunk start --accept-license --no-prompt 2>> "$LOG_FILE"; then
        log_message "Splunk services started successfully"
        ./splunk enable boot-start -user splunk -systemd-managed 1 >> "$LOG_FILE" 2>&1
        
        # Get server IP address
        SERVER_IP=$(hostname -I | awk '{print $1}')
        log_message "Installation Complete!"
        echo
        echo "Splunk web interface available at: http://$SERVER_IP:8000"
        echo "Login with your configured credentials:"
        echo "Username: $SPLUNK_USERNAME"
        echo
    else
        log_message "ERROR: Splunk failed to start. Check $LOG_FILE for details"
exit 1
fi
}

# Main execution
main() {
    # Clear screen for better visibility
    clear
    
    echo "Splunk Enterprise Installation"
    echo "=============================="
    echo
    
    get_credentials
    check_system_requirements
    download_splunk
    install_splunk
    start_splunk
    
    echo "=============================="
}

# Execute main function
main