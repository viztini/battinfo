#!/bin/bash

# ANSI color codes
G="\e[1;32m"; Y="\e[1;33m"; R="\e[1;31m"; B="\e[1;34m"
C="\e[1;36m"; W="\e[1;37m"; NC="\e[0m"

# Find battery
BAT_NAME=$(ls /sys/class/power_supply/ | grep -E '^BAT[0-9]+$' | head -n 1)
BAT_PATH="/sys/class/power_supply/$BAT_NAME"

if [ -z "$BAT_NAME" ]; then
    echo -e "${R}Error:${NC} No battery found." >&2
    exit 1
fi

# Helper to read sysfs files safely
read_val() {
    [[ -f "$BAT_PATH/$1" ]] && cat "$BAT_PATH/$1" || echo ""
}

# Helper for micro-unit conversion (uV/uA/uW to V/A/W)
conv() {
    local val=$1
    [[ -z "$val" || "$val" -eq 0 ]] && echo "N/A" && return
    printf "%.2f" "$(echo "scale=2; $val / 1000000" | bc -l 2>/dev/null || echo "0")"
}

# Data Retrieval
CAPACITY=$(read_val "capacity")
STATUS=$(read_val "status")
MANU=$(read_val "manufacturer")
MODEL=$(read_val "model_name")
VOLT=$(conv $(read_val "voltage_now"))
POWER=$(conv $(read_val "power_now"))
TEMP_RAW=$(read_val "temp")
TEMP=$( [[ -n "$TEMP_RAW" ]] && echo "scale=1; $TEMP_RAW / 10" | bc -l || echo "N/A" )
CYCLES=$(read_val "cycle_count")

# Capacity/Degradation Logic
DESIGN=$(read_val "energy_full_design")
FULL=$(read_val "energy_full")
UNIT="Wh"

if [[ -z "$DESIGN" ]]; then
    DESIGN=$(read_val "charge_full_design")
    FULL=$(read_val "charge_full")
    UNIT="Ah"
fi

# Convert Design/Full to readable units
DESIGN_READABLE=$(conv "$DESIGN")
FULL_READABLE=$(conv "$FULL")

# Calculate Health/Degradation
HEALTH="N/A"; HEALTH_COLOR=$W
if [[ -n "$DESIGN" && "$DESIGN" -gt 0 && -n "$FULL" ]]; then
    HEALTH=$(echo "scale=1; ($FULL / $DESIGN) * 100" | bc -l)
    DEGRADATION=$(echo "100 - $HEALTH" | bc -l)
    
    if (( $(echo "$HEALTH > 80" | bc -l) )); then HEALTH_COLOR=$G
    elif (( $(echo "$HEALTH > 50" | bc -l) )); then HEALTH_COLOR=$Y
    else HEALTH_COLOR=$R; fi
fi

# Visual Progress Bar
BAR_WIDTH=20
FILLED=$(( CAPACITY * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))
BAR="${C}[${G}$(printf '%*s' "$FILLED" '' | tr ' ' '#')${W}$(printf '%*s' "$EMPTY" '' | tr ' ' '-')${C}]${NC}"

# Output Formatting
clear
echo -e "${B}┌───────────────────────────────────────────────────┐${NC}"
echo -e "${B}│${NC}  ${Y}BATTERY REPORT: ${W}$BAT_NAME${NC} $(printf '%*s' $((27 - ${#BAT_NAME})) '')${B}│${NC}"
echo -e "${B}├───────────────────────────────────────────────────┤${NC}"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Manufacturer:" "${MANU:-Unknown}"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Model:" "${MODEL:-Unknown}"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Status:" "${STATUS:-Unknown}"
printf "${B}│${NC}  ${G}%-15s${NC} %-5s %-26s ${B}│${NC}\n" "Charge:" "${CAPACITY}%" "$BAR"
echo -e "${B}├───────────────────────────────────────────────────┤${NC}"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Voltage:" "${VOLT} V"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Draw/Power:" "${POWER} W"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Temperature:" "${TEMP}°C"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Cycles:" "${CYCLES:-0}"
echo -e "${B}├───────────────────────────────────────────────────┤${NC}"
printf "${B}│${NC}  ${G}%-15s${NC} %-32s ${B}│${NC}\n" "Design Cap:" "$DESIGN_READABLE $UNIT"
printf "${B}│${NC}  ${G}%-15s${NC} ${HEALTH_COLOR}%-32s${NC} ${B}│${NC}\n" "Health:" "${HEALTH}% (of design)"
echo -e "${B}└───────────────────────────────────────────────────┘${NC}"
