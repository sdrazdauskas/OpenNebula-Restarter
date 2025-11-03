#!/bin/bash

# Setup script for OpenNebula VM Watcher systemd service

set -e

echo "=== OpenNebula VM Watcher Service Setup ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Create configuration directory
echo "Creating configuration directory..."
mkdir -p /etc/opennebula-watcher

# Copy the watcher script
echo "Installing watcher script..."
cp vm-watcher.sh /usr/local/bin/opennebula-vm-watcher.sh
chmod +x /usr/local/bin/opennebula-vm-watcher.sh

# Create configuration file if it doesn't exist
if [ ! -f /etc/opennebula-watcher/config ]; then
    echo "Creating configuration file..."
    cat > /etc/opennebula-watcher/config << 'EOF'
# OpenNebula VM Watcher Configuration

# OpenNebula authentication file path
# Format: username:password
# Example: ONE_AUTH="/var/lib/one/.one/one_auth"
ONE_AUTH=""

# OpenNebula XML-RPC endpoint
# Example: ONE_XMLRPC="http://localhost:2633/RPC2"
ONE_XMLRPC=""

# VM ID to monitor
# Get this by running: onevm list
VM_ID=""

# Enable verbose logging (optional)
VERBOSE=false
EOF
    echo ""
    echo "Configuration file created at: /etc/opennebula-watcher/config"
    echo "Please edit this file and set your OpenNebula credentials and VM ID"
    echo ""
    read -p "Press Enter to edit the configuration file now, or Ctrl+C to exit..."
    ${EDITOR:-nano} /etc/opennebula-watcher/config
fi

# Create systemd service file
echo "Creating systemd service..."
cat > /etc/systemd/system/opennebula-vm-watcher.service << 'EOF'
[Unit]
Description=OpenNebula VM Watcher
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/opennebula-vm-watcher.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security options
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Create log file
echo "Creating log file..."
touch /var/log/opennebula-watcher.log
chmod 644 /var/log/opennebula-watcher.log

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload

# Enable and start service
echo "Enabling service to start on boot..."
systemctl enable opennebula-vm-watcher.service

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To start the service:"
echo "  sudo systemctl start opennebula-vm-watcher"
echo ""
echo "To check service status:"
echo "  sudo systemctl status opennebula-vm-watcher"
echo ""
echo "To view logs:"
echo "  sudo tail -f /var/log/opennebula-watcher.log"
echo "  or"
echo "  sudo journalctl -u opennebula-vm-watcher -f"
echo ""
echo "To edit configuration:"
echo "  sudo nano /etc/opennebula-watcher/config"
echo "  then restart: sudo systemctl restart opennebula-vm-watcher"
