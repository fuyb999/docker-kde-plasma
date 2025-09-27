#!/bin/bash

# fix_gpu_permissions.sh - Auto detect and fix GPU device permissions

set -euo pipefail

# Get all GPU devices
discover_gpu_devices() {
    local gpu_devices=()

    # Check DRM device directory
    if [ -d "/dev/dri" ]; then
        echo "Detected DRM device directory: /dev/dri"

        # Get all render and card devices
        while IFS= read -r -d '' device; do
            if [[ "$device" =~ /dev/dri/(renderD[0-9]+|card[0-9]+) ]]; then
                gpu_devices+=("$device")
                echo "Found GPU device: $device"
            fi
        done < <(find /dev/dri -type c -name "renderD*" -o -name "card*" -print0 2>/dev/null)
    fi

    # Check NVIDIA devices
    if [ -d "/dev/nvidia" ]; then
        echo "Detected NVIDIA device directory: /dev/nvidia"

        while IFS= read -r -d '' device; do
            gpu_devices+=("$device")
            echo "Found NVIDIA device: $device"
        done < <(find /dev/nvidia -type c -print0 2>/dev/null)
    fi

    # Check NVIDIA special devices
    local nvidia_devices=(
        "/dev/nvidia-uvm"
        "/dev/nvidia-uvm-tools"
        "/dev/nvidia-modeset"
    )

    for device in "${nvidia_devices[@]}"; do
        if [ -c "$device" ]; then
            gpu_devices+=("$device")
            echo "Found NVIDIA device: $device"
        fi
    done

    # Check AMD KFD device
    if [ -c "/dev/kfd" ]; then
        gpu_devices+=("/dev/kfd")
        echo "Found AMD KFD device: /dev/kfd"
    fi

    if [ ${#gpu_devices[@]} -eq 0 ]; then
        echo "No GPU devices found"
    else
        echo "Total found ${#gpu_devices[@]} GPU devices"
    fi

    printf '%s\n' "${gpu_devices[@]}"
}

# Fix device permissions
fix_device_permissions() {
    local device="$1"

    if [ ! -e "$device" ]; then
        echo "Device does not exist: $device"
        return 1
    fi

    echo "Fixing permissions for: $device"

    # Try to change permissions
    if sudo chmod 666 "$device" 2>/dev/null; then
        echo "Successfully set permissions: $device"
        return 0
    else
        echo "Failed to set permissions: $device"
        return 1
    fi
}

# Main function
main() {
    echo "Starting automatic GPU device permission detection and repair"

    # Discover all GPU devices
    mapfile -t gpu_devices < <(discover_gpu_devices)

    if [ ${#gpu_devices[@]} -eq 0 ]; then
        echo "No GPU devices found, no need to fix permissions"
        return 0
    fi

    echo "Starting to fix permissions for ${#gpu_devices[@]} devices..."

    local success_count=0
    local fail_count=0

    # Fix permissions for each device
    for device in "${gpu_devices[@]}"; do
        if fix_device_permissions "$device"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    # Summary report
    echo "Permission repair completed: Success: $success_count, Failed: $fail_count, Total: ${#gpu_devices[@]}"

    if [ $fail_count -eq 0 ]; then
        echo "All GPU device permissions repaired successfully"
    else
        echo "Some device permissions repair failed"
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"

    # If arguments provided, execute the original command
    if [ $# -gt 0 ]; then
        echo "Executing command: $*"
        exec "$@"
    fi
fi