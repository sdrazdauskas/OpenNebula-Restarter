#!/bin/bash

# OpenNebula VM Watcher Script
# Monitors a VM and restarts it if suspended or stopped

# Configuration file
CONFIG_FILE="/etc/opennebula-watcher/config"
LOG_FILE="/var/log/opennebula-watcher.log"
CHECK_INTERVAL=60  # Check every 60 seconds

# Global variables for authentication
ONE_USER=""
ONE_PASSWORD=""
ONE_ENDPOINT=""

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to load configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_message "ERROR: Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    source "$CONFIG_FILE"
    
    if [ -z "$ONE_USER" ] || [ -z "$ONE_PASSWORD" ] || [ -z "$ONE_ENDPOINT" ] || [ -z "$VM_ID" ]; then
        log_message "ERROR: Missing required configuration. Please set ONE_USER, ONE_PASSWORD, ONE_ENDPOINT, and VM_ID"
        exit 1
    fi
}

# Function to get VM state
get_vm_state() {
    local vm_id=$1
    local state=$(onevm show "$vm_id" --user "$ONE_USER" --password "$ONE_PASSWORD" --endpoint "$ONE_ENDPOINT" --xml | grep -oP '(?<=<STATE>)[^<]+' | head -1)
    echo "$state"
}

# Function to get VM LCM state (more detailed state)
get_vm_lcm_state() {
    local vm_id=$1
    local lcm_state=$(onevm show "$vm_id" --user "$ONE_USER" --password "$ONE_PASSWORD" --endpoint "$ONE_ENDPOINT" --xml | grep -oP '(?<=<LCM_STATE>)[^<]+' | head -1)
    echo "$lcm_state"
}

# Function to restart VM
restart_vm() {
    local vm_id=$1
    local current_state=$2
    
    log_message "VM $vm_id is in state $current_state. Attempting to restart..."
    
    # Try to resume the VM - OpenNebula's resume command works for SUSPENDED, UNDEPLOYED, STOPPED, POWEROFF states
    log_message "Resuming VM $vm_id from state $current_state..."
    onevm resume "$vm_id" --user "$ONE_USER" --password "$ONE_PASSWORD" --endpoint "$ONE_ENDPOINT"
    
    if [ $? -eq 0 ]; then
        log_message "Successfully triggered restart for VM $vm_id"
    else
        log_message "ERROR: Failed to restart VM $vm_id"
    fi
}

# Function to check and restart VM if needed
check_vm() {
    local vm_id=$1
    
    # Get VM state
    local state=$(get_vm_state "$vm_id")
    
    if [ -z "$state" ]; then
        log_message "ERROR: Could not retrieve state for VM $vm_id"
        return 1
    fi
    
    # VM States:
    # 0 = INIT
    # 1 = PENDING
    # 2 = HOLD
    # 3 = ACTIVE (running)
    # 4 = STOPPED
    # 5 = SUSPENDED
    # 6 = DONE
    # 7 = FAILED
    # 8 = POWEROFF
    # 9 = UNDEPLOYED
    # 10 = CLONING
    
    case "$state" in
        3)
            # VM is ACTIVE (running) - all good
            if [ "$VERBOSE" = "true" ]; then
                log_message "VM $vm_id is running (state: ACTIVE)"
            fi
            ;;
        4|5|6|8|9)
            # VM is STOPPED, SUSPENDED, DONE, POWEROFF, or UNDEPLOYED - needs restart
            log_message "WARNING: VM $vm_id is not running (state: $state)"
            restart_vm "$vm_id" "$state"
            ;;
        7)
            # VM is FAILED
            log_message "ERROR: VM $vm_id is in FAILED state"
            restart_vm "$vm_id" "$state"
            ;;
        *)
            # Other states (INIT, PENDING, HOLD, etc.)
            log_message "INFO: VM $vm_id is in state $state"
            ;;
    esac
}

# Main function
main() {
    log_message "OpenNebula VM Watcher started"
    
    # Load configuration
    load_config
    
    log_message "Monitoring VM ID: $VM_ID"
    log_message "Check interval: $CHECK_INTERVAL seconds"
    
    # Main loop
    while true; do
        check_vm "$VM_ID"
        sleep "$CHECK_INTERVAL"
    done
}

# Run main function
main
