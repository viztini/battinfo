#!/bin/bash

# ANSI color codes
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
NC="\e[0m" # No Color

# Find the first battery available
BATTERY_NAME=$(ls /sys/class/power_supply/ | grep -E '^BAT[0-9]+$' | head -n 1)
BATTERY_PATH="/sys/class/power_supply/$BATTERY_NAME"

# Check if battery exists
if [ -z "$BATTERY_NAME" ] || [ ! -d "$BATTERY_PATH" ]; then
    echo -e "${RED}Error:${NC} No battery (e.g., BAT0, BAT1) found in /sys/class/power_supply/." >&2
    echo -e "${RED}Please ensure you have a battery or specify its path if it's named differently.${NC}" >&2
    exit 1
fi

# Function to read battery info
get_battery_info() {
    local file="$1"
    cat "$BATTERY_PATH/$file" 2>/dev/null
}

# Read raw values
CAPACITY=$(get_battery_info "capacity")
STATUS=$(get_battery_info "status")
MANUFACTURER=$(get_battery_info "manufacturer")
MODEL_NAME=$(get_battery_info "model_name")
TECHNOLOGY=$(get_battery_info "technology")
VOLTAGE_NOW=$(get_battery_info "voltage_now")
CURRENT_NOW=$(get_battery_info "current_now")
POWER_NOW=$(get_battery_info "power_now")
CYCLE_COUNT=$(get_battery_info "cycle_count")
PRESENT_RATE=$(get_battery_info "present_rate")
TEMP=$(get_battery_info "temp")

# Try energy values first, then charge values
DESIGN_CAP=$(get_battery_info "energy_full_design")
FULL_CHARGE_CAP=$(get_battery_info "energy_full")
UNIT="Wh"

if [ -z "$DESIGN_CAP" ] || [ -z "$FULL_CHARGE_CAP" ]; then
    DESIGN_CAP=$(get_battery_info "charge_full_design")
    FULL_CHARGE_CAP=$(get_battery_info "charge_full")
    UNIT="Ah"
fi

# Convert values to more readable units if available
if [ -n "$VOLTAGE_NOW" ] && [ "$VOLTAGE_NOW" -gt 0 ]; then
    VOLTAGE_NOW=$(echo "scale=2; $VOLTAGE_NOW / 1000000" | bc) # uV to V
fi
if [ -n "$CURRENT_NOW" ] && [ "$CURRENT_NOW" -gt 0 ]; then
    CURRENT_NOW=$(echo "scale=2; $CURRENT_NOW / 1000000" | bc) # uA to A
fi
if [ -n "$POWER_NOW" ] && [ "$POWER_NOW" -gt 0 ]; then
    POWER_NOW=$(echo "scale=2; $POWER_NOW / 1000000" | bc) # uW to W
fi
if [ -n "$PRESENT_RATE" ] && [ "$PRESENT_RATE" -gt 0 ]; then
    PRESENT_RATE=$(echo "scale=2; $PRESENT_RATE / 1000000" | bc) # uW to W or uA to A
fi
if [ -n "$TEMP" ] && [ "$TEMP" -gt 0 ]; then
    TEMP=$(echo "scale=1; $TEMP / 1000" | bc) # mC to C
fi

# Calculate degradation
DEGRADATION_PERCENT="N/A"
if (( $(echo "$DESIGN_CAP > 0" | bc -l) )) && (( $(echo "$FULL_CHARGE_CAP > 0" | bc -l) )); then
    DEGRADATION_PERCENT=$(echo "scale=2; (1 - ($FULL_CHARGE_CAP / $DESIGN_CAP)) * 100" | bc)
fi

# Determine degradation color
DEGRADATION_COLOR="$WHITE"
if (( $(echo "$DEGRADATION_PERCENT != \"N/A\" && $DEGRADATION_PERCENT >= 0" | bc -l) )); then
    DEGRADATION_COLOR="$GREEN"
    if (( $(echo "$DEGRADATION_PERCENT >= 20" | bc -l) )); then
        DEGRADATION_COLOR="$YELLOW"
    fi
    if (( $(echo "$DEGRADATION_PERCENT >= 40" | bc -l) )); then
        DEGRADATION_COLOR="$RED"
    fi
fi

# Generate ASCII battery graph
GRAPH_LENGTH=20
FILLED_BARS=$(( CAPACITY * GRAPH_LENGTH / 100 ))
EMPTY_BARS=$(( GRAPH_LENGTH - FILLED_BARS ))

BATTERY_GRAPH="${CYAN}["
for (( i=0; i<FILLED_BARS; i++ )); do BATTERY_GRAPH+="#"; done
for (( i=0; i<EMPTY_BARS; i++ )); do BATTERY_GRAPH+="-"; done
BATTERY_GRAPH+="]${NC}"

# Output information with colors and improved formatting
echo -e "${BLUE}┌───────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC} ${YELLOW}Battery Information (${BATTERY_NAME}):${NC}             ${BLUE}│${NC}"
echo -e "${BLUE}├───────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Manufacturer:${NC} ${WHITE}${MANUFACTURER:-N/A}${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Model:       ${NC} ${WHITE}${MODEL_NAME:-N/A}${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Technology:  ${NC} ${WHITE}${TECHNOLOGY:-N/A}${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Status:      ${NC} ${WHITE}${STATUS:-N/A}${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Capacity:    ${NC} ${WHITE}${CAPACITY:-N/A}%${NC} ${BATTERY_GRAPH}"
echo -e "${BLUE}│${NC}   ${GREEN}Voltage:     ${NC} ${WHITE}${VOLTAGE_NOW:-N/A} V${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Current:     ${NC} ${WHITE}${CURRENT_NOW:-N/A} A${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Power:       ${NC} ${WHITE}${POWER_NOW:-N/A} W${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Rate:        ${NC} ${WHITE}${PRESENT_RATE:-N/A} W/A${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Temperature: ${NC} ${WHITE}${TEMP:-N/A} °C${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Design Cap:  ${NC} ${WHITE}${DESIGN_CAP:-N/A} ${UNIT}${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Full Charge: ${NC} ${WHITE}${FULL_CHARGE_CAP:-N/A} ${UNIT}${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Cycle Count: ${NC} ${WHITE}${CYCLE_COUNT:-N/A}${NC}"
echo -e "${BLUE}│${NC}   ${GREEN}Degradation: ${DEGRADATION_COLOR}${DEGRADATION_PERCENT:-N/A}%${NC}"
echo -e "${BLUE}└───────────────────────────────────────────────────┘${NC}"
