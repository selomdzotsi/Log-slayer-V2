#!/bin/bash

# Script: Splunk Enterprise Installer
# Description: Automated Splunk Enterprise deployment script for Linux systems
# Version: 1.2

# Set error handling
set -e
set -o pipefail

# Constants
LOG_FILE="splunk_install.log"
SPLUNK_DEB="splunk-9.4.2-e9664af3d956-linux-amd64.deb"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/9.4.2/linux/splunk-9.4.2-e9664af3d956-linux-amd64.deb"

# Progress bar variables
PROGRESS_BAR_WIDTH=50  # Width of the progress bar
TOTAL_STEPS=5         # Total number of installation steps

# Function to display progress bar
show_progress() {
    local current_step=$1
    local message=$2
    local percentage=$((current_step * 100 / TOTAL_STEPS))
    local filled_width=$((percentage * PROGRESS_BAR_WIDTH / 100))
    local empty_width=$((PROGRESS_BAR_WIDTH - filled_width))

    # Create the progress bar
    printf "\r[" # Start of progress bar
    printf "%${filled_width}s" '' | tr ' ' '='
    printf "%${empty_width}s" '' | tr ' ' ' '
    printf "] %3d%% - %s" "$percentage" "$message"

    # If this is the last step, add a newline
    if [ "$current_step" -eq "$TOTAL_STEPS" ]; then
        printf "\n"
    fi
}

# Function to log messages
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    # Only show progress bar if it's not an error message
    if [[ ! "$1" == ERROR* ]]; then
        show_progress "$2" "$1"
    else
        echo "$1"
    fi
}

# Function to check system requirements
check_system_requirements() {
    log_message "Checking system requirements..." 1
    
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

    log_message "Detected OS: $OS_NAME $OS_VERSION" 1

    # Check for supported distributions
    case "$OS_NAME" in
        *Ubuntu*|*Debian*)
            log_message "Supported distribution detected" 1
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
        log_message "Installing wget..." 1
        apt-get update && apt-get install -y wget
    fi
}

# Function to download Splunk
download_splunk() {
    log_message "Downloading Splunk Enterprise Debian Package..." 2
    if wget -O "$SPLUNK_DEB" "$SPLUNK_URL" 2>> "$LOG_FILE"; then
        log_message "Download successful" 2
    else
        log_message "ERROR: Splunk download failed. Check $LOG_FILE for details"
        exit 1
    fi
}

# Function to install Splunk
install_splunk() {
    log_message "Installing Splunk Enterprise..." 3
    if dpkg -i "$SPLUNK_DEB" 2>> "$LOG_FILE"; then
        dpkg --status splunk >> "$LOG_FILE"
        log_message "Splunk Enterprise successfully installed" 3
    else
        log_message "ERROR: Splunk installation failed. Check $LOG_FILE for details"
        exit 1
    fi
}

# Function to start Splunk
start_splunk() {
    log_message "Starting Splunk..." 4
    cd /opt/splunk/bin || exit 1
    
    if ./splunk start --accept-license --answer-yes --no-prompt 2>> "$LOG_FILE"; then
        log_message "Splunk successfully started" 4
        ./splunk enable boot-start -user splunk -systemd-managed 1 >> "$LOG_FILE" 2>&1
        log_message "Splunk boot-start enabled" 4
        
        # Get server IP address
        SERVER_IP=$(hostname -I | awk '{print $1}')
        log_message "Installation Complete!" 5
        echo -e "\nSplunk web interface available at: http://$SERVER_IP:8000"
        echo "Default credentials: admin/changeme"
    else
        log_message "ERROR: Splunk failed to start. Check $LOG_FILE for details"
        exit 1
    fi
}

# Main execution
main() {
    echo "Starting Splunk installation process..."
    echo "----------------------------------------"
    check_system_requirements
    download_splunk
    install_splunk
    start_splunk
    echo "----------------------------------------"
    log_message "Splunk installation completed successfully" 5
}

# Execute main function
main