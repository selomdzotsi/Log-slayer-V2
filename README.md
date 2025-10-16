# Splunk Enterprise Quick Deployment Script

A streamlined script for rapidly deploying Splunk Enterprise on Ubuntu/Debian Linux systems. Ideal for Blue Teams needing quick SIEM setup during cyber challenge events.

## Features

- Automated Splunk Enterprise installation and configuration
- System compatibility checks
- Detailed logging and error reporting
- Automatic service configuration
- Visual progress bar with status updates
- Clear user feedback during installation

## Prerequisites

- Ubuntu/Debian Linux system
- Root/sudo access
- Minimum 5GB free disk space
- Internet connection for downloading Splunk

## Installation

1. Clone this repository or download the script:
```bash
git clone https://github.com/yourusername/Log-slayer-V2.git
cd Log-slayer-V2
```

2. Make the script executable:
```bash
chmod +x splunk_install.sh
```

3. Run the script with sudo:
```bash
sudo ./splunk_install.sh
```

## Post-Installation

- Access Splunk web interface at `http://your-server-ip:8000`
- Default credentials: `admin/changeme`
- Change the default password immediately after first login

## Logging

- Installation logs are stored in `splunk_install.log`
- Check this file for detailed information about the installation process and any errors

## Support

For issues or improvements, please open an issue in the GitHub repository.

## Security Note

This script is designed for rapid deployment in controlled environments. For production deployments, additional security measures should be implemented.
