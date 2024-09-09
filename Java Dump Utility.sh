#!/bin/bash

# Global variables
LOG_FILE=""
V_PATH=""

# Function to log messages
log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $message" >> "$LOG_FILE"
    echo "$timestamp - $message"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate required commands
validate_commands() {
    local required_commands=("jstack" "jcmd" "jmap" "top")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -ne 0 ]; then
        log "Error: The following required commands are missing: ${missing_commands[*]}"
        log "Please ensure you have the required tools installed."
        log "Press any key to exit..."
        read -n 1 -s -r -p ""
        exit 1
    fi
}

# Function to validate PID
validate_pid() {
    if [[ ! "$1" =~ ^[0-9]+$ ]] || ! kill -0 "$1" 2>/dev/null; then
        log "Invalid PID: $1"
        log "Invalid PID. Please enter a valid process ID."
        return 1
    fi
    return 0
}

# Function to create dump directory and set up logging
setup_environment() {
    V_PATH="dump_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$V_PATH"
    LOG_FILE="$V_PATH/dump_process.log"
    touch "$LOG_FILE"
    log "Created dump directory: $V_PATH"
}

# Updated function to display progress in-line
show_progress() {
    local duration=$1
    local sleep_duration=$(( duration / 5 ))
    local progress=0

    printf "Progress: 0%%"
    while [ $progress -lt 5 ]
    do
        sleep $sleep_duration
        ((progress++))
        percentage=$((progress * 20))
        printf "\rProgress: %d%%" $percentage
    done
    echo # Move to the next line after completion
}

# Function to perform jstack dump
jstack_dump() {
    local pid=$1
    local loops=$2
    log "Starting jstack dump for PID $pid, $loops iterations"
    echo "jstack Dump Start"
    for i in $(seq 1 $loops); do
        log "Collecting jstack dump $i of $loops"
        echo "Collecting jstack dump $i of $loops"
        jstack -l $pid > "$V_PATH/jstack_dump_$i.txt" 2>> "$LOG_FILE"
        top -b -H -n 1 -p $pid >> "$V_PATH/jstack_top_output_$i.txt" 2>> "$LOG_FILE"
        show_progress 3
    done
    log "Completed jstack dump"
    echo "jstack Dump Finish"
}

# Function to perform jcmd dump
jcmd_dump() {
    local pid=$1
    local loops=$2
    log "Starting jcmd dump for PID $pid, $loops iterations"
    echo "jcmd Dump Start"
    for i in $(seq 1 $loops); do
        log "Collecting jcmd dump $i of $loops"
        echo "Collecting jcmd dump $i of $loops"
        jcmd $pid Thread.print > "$V_PATH/jcmd_thread_dump_$i.txt" 2>> "$LOG_FILE"
        top -b -H -n 1 -p $pid >> "$V_PATH/jcmd_top_output_$i.txt" 2>> "$LOG_FILE"
        show_progress 3
    done
    log "Completed jcmd dump"
    echo "jcmd Dump Finish"
}

# Function to perform jmap dump
jmap_dump() {
    local pid=$1
    local loops=$2
    log "Starting jmap dump for PID $pid, $loops iterations"
    echo "jmap Dump Start"
    for i in $(seq 1 $loops); do
        log "Collecting heap dump $i of $loops"
        echo "Collecting heap dump $i of $loops"
        jmap -dump:file="$V_PATH/heap_dump_$i.hprof" $pid 2>> "$LOG_FILE"
        show_progress 10
    done
    log "Completed jmap dump"
    echo "jmap Dump Finish"
}

# Main script
echo "Java Dump Utility"
echo "================="

# Set up environment and logging
setup_environment
echo "Dumps will be saved in: $V_PATH"

# Validate required commands
validate_commands

log "Starting Java Dump Utility"

# Get PID from user
while true; do
    read -p "Please Enter PID: " V_PID
    if validate_pid $V_PID; then
        break
    fi
done

log "Java Program PID is $V_PID"
echo "Java Program PID is - 「 $V_PID 」"

# Get number of loops for jstack and jcmd from user
read -p "Enter the number of loops for jstack and jcmd dumps: " THREAD_LOOP_COUNT
log "Thread dump loop count: $THREAD_LOOP_COUNT"

# Get number of loops for jmap from user
read -p "Enter the number of loops for jmap dumps: " HEAP_LOOP_COUNT
log "Heap dump loop count: $HEAP_LOOP_COUNT"

# Menu for user to choose dump types
echo "Select the type of dump you want to perform:"
echo "1: jstack dump"
echo "2: jcmd dump"
echo "3: jmap dump"
echo "4: All dumps"
read -p "Enter your choice (1-4): " dump_choice
log "User selected dump type: $dump_choice"

case $dump_choice in
    1) jstack_dump $V_PID $THREAD_LOOP_COUNT ;;
    2) jcmd_dump $V_PID $THREAD_LOOP_COUNT ;;
    3) jmap_dump $V_PID $HEAP_LOOP_COUNT ;;
    4)
        jstack_dump $V_PID $THREAD_LOOP_COUNT
        jcmd_dump $V_PID $THREAD_LOOP_COUNT
        jmap_dump $V_PID $HEAP_LOOP_COUNT
        ;;
    *)
        log "Invalid choice. Exiting."
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

log "Dump process completed. Results are saved in $V_PATH"
echo "Dump process completed. Results are saved in $V_PATH"
echo "Press any key to exit..."
read -n 1 -s -r -p ""
log "Script execution finished"
exit 0
