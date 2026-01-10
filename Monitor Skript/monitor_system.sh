#!/usr/bin/env bash

set -u
set -o pipefail

# Daten Auslesen

CPU_CORES=$(grep -h . /sys/devices/system/cpu/cpu*/topology/core_id \
  | cut -d: -f2 \
  | sort -u \
  | wc -l)

# Zustände bestimmen

LOAD_WARN=$(awk "BEGIN {printf \"%.2f\", $CPU_CORES * 0.7}")
LOAD_CRIT=$(awk "BEGIN {printf \"%.2f\", $CPU_CORES * 1.0}")

LOAD_15=$(awk '{print $3}' /proc/loadavg)

# Zustände prüfen

LOAD_STATUS="OK"
if awk "BEGIN {exit !($LOAD_15 >= $LOAD_CRIT)}"; then
  LOAD_STATUS="CRIT"
elif awk "BEGIN {exit !($LOAD_15 >= $LOAD_WARN)}"; then
  LOAD_STATUS="WARN"
fi

DISK_USAGE_RAW=$(df -P / | awk 'NR==2 {print $5}')
DISK_USAGE=${DISK_USAGE_RAW%\%}
DISK_WARN=80
DISK_CRIT=90


DISK_STATUS="OK"
if [ "$DISK_USAGE" -ge $DISK_WARN ]; then
  DISK_STATUS="CRIT"
elif [ "$DISK_USAGE" -ge $DISK_CRIT ]; then
  DISK_STATUS="WARN"
fi

# Ausgabe

echo "System Health Check"
echo "==================="
echo "CPU Cores        : $CPU_CORES"
echo "Load (15 min)    : $LOAD_15 (WARN >= $LOAD_WARN | CRIT >= $LOAD_CRIT) => $LOAD_STATUS"
echo "Disk Usage (/)   : $DISK_USAGE% => $DISK_STATUS"

# Exit-Code bestimmen

EXIT_CODE=0

if [ "$DISK_STATUS" = "CRIT" ]; then
  EXIT_CODE=2
elif [ "$DISK_STATUS" = "WARN" ]; then
  EXIT_CODE=1
fi

if [ "$LOAD_STATUS" = "CRIT" ]; then
  EXIT_CODE=2
elif [ "$LOAD_STATUS" = "WARN" ] && [ "$EXIT_CODE" -lt 2 ]; then
  EXIT_CODE=1
fi

echo "Exit-Code: $EXIT_CODE"
exit "$EXIT_CODE"
