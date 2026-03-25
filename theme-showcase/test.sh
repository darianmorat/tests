#!/bin/bash

# Script configuration and colors
set -euo pipefail  # Exit on error, undefined vars, pipe failures
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/system_monitor.log"

# ANSI color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
declare -A SERVICES=([nginx]=80 [ssh]=22 [mysql]=3306)
declare -a REQUIRED_DIRS=("/tmp" "/var/log" "/opt/app")

# Function definitions
usage() {
    cat << EOF
Usage: $0 [OPTION]...
System monitoring and maintenance script.

OPTIONS:
    -c, --check         Check system health
    -m, --monitor       Start continuous monitoring
    -r, --repair        Attempt to repair common issues
    -s, --services      Check service status
    -h, --help          Show this help message

EXAMPLES:
    $0 --check          # Quick health check
    $0 -m 30            # Monitor for 30 seconds
    $0 --services ssh mysql nginx
EOF
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_message "ERROR" "Required command '$cmd' not found"
        return 1
    fi
}

# System health checks
check_disk_usage() {
    log_message "INFO" "Checking disk usage..."
    
    while IFS= read -r line; do
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        mount=$(echo "$line" | awk '{print $6}')
        
        if [[ $usage -gt 90 ]]; then
            echo -e "${RED}CRITICAL: ${mount} is ${usage}% full${NC}"
        elif [[ $usage -gt 80 ]]; then
            echo -e "${YELLOW}WARNING: ${mount} is ${usage}% full${NC}"
        else
            echo -e "${GREEN}OK: ${mount} is ${usage}% full${NC}"
        fi
    done < <(df -h | grep -vE '^Filesystem|tmpfs|cdrom')
}

check_memory() {
    log_message "INFO" "Checking memory usage..."
    
    local total_mem=$(free | grep "Mem:" | awk '{print $2}')
    local used_mem=$(free | grep "Mem:" | awk '{print $3}')
    local mem_usage=$((used_mem * 100 / total_mem))
    
    if [[ $mem_usage -gt 90 ]]; then
        echo -e "${RED}CRITICAL: Memory usage at ${mem_usage}%${NC}"
    elif [[ $mem_usage -gt 80 ]]; then
        echo -e "${YELLOW}WARNING: Memory usage at ${mem_usage}%${NC}"
    else
        echo -e "${GREEN}OK: Memory usage at ${mem_usage}%${NC}"
    fi
}

check_services() {
    local services_to_check=("$@")
    
    if [[ ${#services_to_check[@]} -eq 0 ]]; then
        services_to_check=("${!SERVICES[@]}")
    fi
    
    log_message "INFO" "Checking services: ${services_to_check[*]}"
    
    for service in "${services_to_check[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}✓ $service is running${NC}"
            
            # Check if service has a port defined
            if [[ -n "${SERVICES[$service]:-}" ]]; then
                local port="${SERVICES[$service]}"
                if netstat -tuln | grep -q ":$port "; then
                    echo -e "  ${GREEN}Port $port is listening${NC}"
                else
                    echo -e "  ${YELLOW}Port $port not listening${NC}"
                fi
            fi
        else
            echo -e "${RED}✗ $service is not running${NC}"
        fi
    done
}

monitor_system() {
    local duration="${1:-60}"
    local interval=5
    local count=$((duration / interval))
    
    log_message "INFO" "Starting system monitoring for ${duration}s"
    
    for ((i=1; i<=count; i++)); do
        clear
        echo -e "${BLUE}=== System Monitor (${i}/${count}) ===${NC}"
        echo "Time: $(date)"
        echo
        
        # CPU usage
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        echo -e "CPU Usage: ${cpu_usage}%"
        
        # Load average
        local load_avg=$(uptime | awk -F'load average:' '{print $2}')
        echo -e "Load Average:${load_avg}"
        
        # Network connections
        local connections=$(ss -tuln | wc -l)
        echo -e "Network Connections: $connections"
        
        # Top processes by CPU
        echo -e "\n${BLUE}Top CPU Processes:${NC}"
        ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -6
        
        sleep $interval
    done
}

repair_common_issues() {
    log_message "INFO" "Running repair tasks..."
    
    # Clean temporary files
    echo "Cleaning temporary files..."
    find /tmp -type f -atime +7 -delete 2>/dev/null || true
    
    # Check and create required directories
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            echo "Creating missing directory: $dir"
            mkdir -p "$dir"
        fi
    done
    
    # Fix permissions on log directory
    if [[ -d "/var/log" ]]; then
        chmod 755 /var/log
        echo "Fixed /var/log permissions"
    fi
    
    # Update package database (if running as root)
    if [[ $EUID -eq 0 ]]; then
        echo "Updating package database..."
        if command -v apt-get &> /dev/null; then
            apt-get update -qq
        elif command -v yum &> /dev/null; then
            yum makecache -q
        fi
    fi
    
    echo -e "${GREEN}Repair tasks completed${NC}"
}

# Signal handling
cleanup() {
    log_message "INFO" "Script interrupted, cleaning up..."
    exit 130
}

trap cleanup SIGINT SIGTERM

# Main function
main() {
    # Check if running as root for certain operations
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Note: Some checks require root privileges${NC}"
    fi
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--check)
                echo -e "${BLUE}=== System Health Check ===${NC}"
                check_disk_usage
                echo
                check_memory
                echo
                check_services
                ;;
            -m|--monitor)
                local duration="${2:-60}"
                monitor_system "$duration"
                shift
                ;;
            -r|--repair)
                repair_common_issues
                ;;
            -s|--services)
                shift
                check_services "$@"
                break
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
    
    # Default action if no arguments
    if [[ $# -eq 0 ]]; then
        echo -e "${BLUE}Running default system check...${NC}"
        check_disk_usage
        echo
        check_memory
        echo
        check_services
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
