#!/bin/bash

# OpenNebula Tools Installation Script
# This script installs OpenNebula tools on Ubuntu 24.04

set -e

echo "=== OpenNebula Tools Installation ==="

# Create keyring directory
echo "Creating keyring directory..."
sudo mkdir -p /etc/apt/keyrings

# Add OpenNebula GPG key
echo "Adding OpenNebula GPG key..."
wget -q -O- https://downloads.opennebula.io/repo/repo2.key | sudo gpg --dearmor --yes --output /etc/apt/keyrings/opennebula.gpg

# Add OpenNebula repository
echo "Adding OpenNebula repository..."
echo "deb [signed-by=/etc/apt/keyrings/opennebula.gpg] https://downloads.opennebula.io/repo/6.10/Ubuntu/24.04/ stable opennebula" | sudo tee /etc/apt/sources.list.d/opennebula.list

# Update package list and install OpenNebula tools
echo "Updating package list and installing OpenNebula tools..."
sudo apt-get update
sudo apt-get install -y opennebula-tools

echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Configure OpenNebula credentials in /etc/opennebula-watcher/config"
echo "2. Run ./setup-service.sh to install the watcher service"
