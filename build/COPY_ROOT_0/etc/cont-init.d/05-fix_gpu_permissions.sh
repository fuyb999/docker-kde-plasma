#!/bin/bash

# fix_gpu_permissions.sh - Auto detect and fix GPU device permissions

set -euo pipefail

# Get all GPU devices
discover_gpu_devices() {
    local gpu_devices=()

    # Check DRM device directory
    if [ -d "/dev/dri" ]; then
        echo "Detected DRM device directory: /dev/dri" >&2  # 输出到stderr，避免污染结果

        # Get all render and card devices (只找字符设备，不找目录)
        while IFS= read -r -d '' device; do
            if [ -c "$device" ]; then  # 确保是字符设备
                gpu_devices+=("$device")
                echo "Found GPU device: $device" >&2
            fi
        done < <(find /dev/dri -type c \( -name "renderD*" -o -name "card*" \) -print0 2>/dev/null)
    fi

    # Check NVIDIA devices directory
    if [ -d "/dev/nvidia" ]; then
        echo "Detected NVIDIA device directory: /dev/nvidia" >&2

        # 查找 /dev/nvidia 目录下的所有字符设备
        while IFS= read -r -d '' device; do
            if [ -c "$device" ]; then  # 确保是字符设备
                gpu_devices+=("$device")
                echo "Found NVIDIA device: $device" >&2
            fi
        done < <(find /dev/nvidia -type c -print0 2>/dev/null)
    fi

    # Check NVIDIA special devices
    local nvidia_devices=(
        "/dev/nvidia-uvm"
        "/dev/nvidia-uvm-tools"
        "/dev/nvidia-modeset"
        "/dev/nvidiactl"
    )

    for device in "${nvidia_devices[@]}"; do
        if [ -c "$device" ]; then
            gpu_devices+=("$device")
            echo "Found NVIDIA device: $device" >&2
        fi
    done

    # Check AMD KFD device
    if [ -c "/dev/kfd" ]; then
        gpu_devices+=("/dev/kfd")
        echo "Found AMD KFD device: /dev/kfd" >&2
    fi

    # 额外检测：查找所有 NVIDIA 设备（通过设备号模式）
    while IFS= read -r -d '' device; do
        if [ -c "$device" ] && [[ "$device" =~ /dev/nvidia[0-9]+ ]]; then
            gpu_devices+=("$device")
            echo "Found NVIDIA device: $device" >&2
        fi
    done < <(find /dev -type c -name "nvidia*" -print0 2>/dev/null)

    if [ ${#gpu_devices[@]} -eq 0 ]; then
        echo "No GPU devices found" >&2
    else
        echo "Total found ${#gpu_devices[@]} GPU devices" >&2
    fi

    # 输出设备列表（只包含设备路径）
    for device in "${gpu_devices[@]}"; do
        echo "$device"
    done
}

# Fix device permissions
fix_device_permissions() {
    local device="$1"

    if [ ! -e "$device" ]; then
        echo "Device does not exist: $device" >&2
        return 1
    fi

    if [ ! -c "$device" ]; then
        echo "Not a character device, skipping: $device" >&2
        return 1
    fi

    echo "Fixing permissions for: $device" >&2

    # Get current permissions
    local current_perms
    current_perms=$(stat -c "%a" "$device" 2>/dev/null || echo "unknown")

    # Try to change permissions
    if sudo chmod 666 "$device" 2>/dev/null; then
        local new_perms
        new_perms=$(stat -c "%a" "$device" 2>/dev/null || echo "unknown")
        echo "Successfully set permissions: $device ($current_perms → $new_perms)" >&2
        return 0
    else
        echo "Failed to set permissions: $device" >&2
        return 1
    fi
}

# Main function
main() {
    echo "Starting automatic GPU device permission detection and repair" >&2

    # Discover all GPU devices
    mapfile -t gpu_devices < <(discover_gpu_devices)

    if [ ${#gpu_devices[@]} -eq 0 ]; then
        echo "No GPU devices found, no need to fix permissions" >&2
        return 0
    fi

    echo "Starting to fix permissions for ${#gpu_devices[@]} devices..." >&2

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
    echo "Permission repair completed: Success: $success_count, Failed: $fail_count, Total: ${#gpu_devices[@]}" >&2

    if [ $fail_count -eq 0 ]; then
        echo "All GPU device permissions repaired successfully" >&2
    else
        echo "Some device permissions repair failed" >&2
        return 1
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@" || true

    # If arguments provided, execute the original command
    if [ $# -gt 0 ]; then
        echo "Executing command: $*" >&2
        exec "$@"
    fi
fi