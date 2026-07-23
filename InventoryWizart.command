#!/bin/bash
#
#  Portable PC & Monitor Asset Collector
#  Copyright (C) 2026 ktrotek
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version. See the LICENSE file for details.
#
# ============================================================
#  Inventory Wizart - PC + monitor inventory collector (macOS)
#  Double-click to run (opens Terminal). Saves TWO CSV files
#  next to this file, named after the Mac:
#    <HOSTNAME>_Specs.csv     - one row: system / OS info
#    <HOSTNAME>_Monitors.csv  - one row per connected monitor
#  Same column layout as the Windows InventoryWizart.bat, so
#  both platforms feed one combined inventory.
#
#  KNOWN LIMITATION (platform, not script): macOS often does
#  NOT expose external monitor serial numbers / manufacture
#  year, especially on Apple Silicon. Model name is reliable;
#  Serial/Year may be blank. Built-in laptop displays have no
#  separate serial.
#
#  First run: if macOS blocks it ("unidentified developer"),
#  right-click the file > Open > Open. Only needed once.
# ============================================================

# Work next to this script (the USB stick), not the home folder
DIR="$(cd "$(dirname "$0")" && pwd)"

PC="$(hostname -s | tr '[:lower:]' '[:upper:]')"
SPECS="$DIR/${PC}_Specs.csv"
MONITORS="$DIR/${PC}_Monitors.csv"
NOW="$(date '+%Y-%m-%d %H:%M')"

# Quote a value for CSV (match PowerShell Export-Csv: quote everything,
# double any embedded quotes)
q() { printf '"%s"' "$(printf '%s' "$1" | sed 's/"/""/g')"; }

cat <<'BANNER'

 ▓▒░ ──────────────────────────────────────────────────[ ktrotek ]─┐

▪   ▐ ▄  ▌ ▐·▄▄▄ . ▐ ▄ ▄▄▄▄▄      ▄▄▄   ▄· ▄▌▄▄▌ ▐ ▄▌▪  ·▄▄▄▄• ▄▄▄· ▄▄▄  ▄▄▄▄▄
██ •█▌▐█▪█·█▌▀▄.▀·•█▌▐█•██  ▪     ▀▄ █·▐█▪██▌██· █▌▐███ ▪▀·.█▌▐█ ▀█ ▀▄ █·•██
▐█·▐█▐▐▌▐█▐█•▐▀▀▪▄▐█▐▐▌ ▐█.▪ ▄█▀▄ ▐▀▀▄ ▐█▌▐█▪██▪▐█▐▐▌▐█·▄█▀▀▀•▄█▀▀█ ▐▀▀▄  ▐█.▪
▐█▌██▐█▌ ███ ▐█▄▄▌██▐█▌ ▐█▌·▐█▌.▐▌▐█•█▌ ▐█▀·.▐█▌██▐█▌▐█▌█▌▪▄█▀▐█ ▪▐▌▐█•█▌ ▐█▌·
▀▀▀▀▀ █▪. ▀   ▀▀▀ ▀▀ █▪ ▀▀▀  ▀█▄▀▪.▀  ▀  ▀ •  ▀▀▀▀ ▀▪▀▀▀·▀▀▀ • ▀  ▀ .▀  ▀ ▀▀▀

 └─░▒▓ pc + monitor asset collector ▓▒░ ───────────────────────────█

BANNER

echo "  [#-----] 1/6  Reading system and serial info..."
HW="$(system_profiler SPHardwareDataType 2>/dev/null)"
MODEL_NAME="$(echo "$HW"  | awk -F": " '/Model Name/{print $2; exit}')"
MODEL_ID="$(echo "$HW"    | awk -F": " '/Model Identifier/{print $2; exit}')"
SERIAL="$(echo "$HW"      | awk -F": " '/Serial Number/{print $2; exit}')"
MODEL="$MODEL_NAME ($MODEL_ID)"
MANUFACTURER="Apple"
USER_NAME="$(whoami)"

echo "  [##----] 2/6  Reading operating system and CPU..."
OS_NAME="$(sw_vers -productName) $(sw_vers -productVersion)"
OS_BUILD="$(sw_vers -buildVersion)"
CPU="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
# Apple Silicon fallback (brand_string exists there too, but just in case)
[ -z "$CPU" ] && CPU="$(echo "$HW" | awk -F": " '/Chip|Processor Name/{print $2; exit}')"

echo "  [###---] 3/6  Reading network configuration..."
IFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
IP=""; MAC=""
if [ -n "$IFACE" ]; then
  IP="$(ipconfig getifaddr "$IFACE" 2>/dev/null)"
  MAC="$(ifconfig "$IFACE" 2>/dev/null | awk '/ether/{print $2; exit}')"
fi

echo "  [####--] 4/6  Reading disks and memory..."
RAM_GB="$(sysctl -n hw.memsize | awk '{printf "%.1f", $1/1073741824}')"
STOR_BYTES=0
while read -r dev; do
  b="$(diskutil info "$dev" 2>/dev/null | awk -F'[()]' '/Disk Size/{split($2,a," "); print a[1]; exit}')"
  case "$b" in ''|*[!0-9]*) ;; *) STOR_BYTES=$((STOR_BYTES + b));; esac
done < <(diskutil list physical internal 2>/dev/null | awk '/^\/dev\//{print $1}')
STOR_GB="$(echo "$STOR_BYTES" | awk '{printf "%.0f", $1/1073741824}')"

echo "  [#####-] 5/6  Detecting monitors..."
# Parse system_profiler display output: display names are indented lines
# ending in ':' after a 'Displays:' header; properties follow beneath.
MON_TMP="$(mktemp)"
system_profiler SPDisplaysDataType 2>/dev/null | awk '
  # a new GPU section (4-space indent) ends any Displays block
  /^    [^ ]/ { if (name != "") { print name "\t" serial "\t" year "\t" vendor; name="" }; indisp=0 }
  /^[[:space:]]+Displays:$/ { indisp=1; next }
  # display names: 8-space indent, ending in ":"
  indisp && /^        [^ ].*:$/ {
    if (name != "") print name "\t" serial "\t" year "\t" vendor
    name=$0; sub(/^[[:space:]]+/,"",name); sub(/:$/,"",name)
    serial=""; year=""; vendor=""
    next
  }
  # display properties: 10-space indent only (avoids GPU-level lines)
  indisp && /^          [^ ]/ && /Serial Number:/       { v=$0; sub(/.*Serial Number:[[:space:]]*/,"",v); serial=v }
  indisp && /^          [^ ]/ && /Year of Manufacture:/ { v=$0; sub(/.*Year of Manufacture:[[:space:]]*/,"",v); year=v }
  indisp && /^          [^ ]/ && /Vendor:/              { v=$0; sub(/.*Vendor:[[:space:]]*/,"",v); vendor=v }
  END { if (name != "") print name "\t" serial "\t" year "\t" vendor }
' > "$MON_TMP"
MON_COUNT="$(grep -c . "$MON_TMP" 2>/dev/null || echo 0)"

echo ""
echo "===== SYSTEM ====="
printf '%-18s %s\n' "ComputerName:"    "$PC"
printf '%-18s %s\n' "Manufacturer:"    "$MANUFACTURER"
printf '%-18s %s\n' "Model:"           "$MODEL"
printf '%-18s %s\n' "SerialNumber:"    "$SERIAL"
printf '%-18s %s\n' "AssignedTo:"      "$USER_NAME"
printf '%-18s %s\n' "IPAddress:"       "$IP"
printf '%-18s %s\n' "MACAddress:"      "$MAC"
printf '%-18s %s\n' "OperatingSystem:" "$OS_NAME"
printf '%-18s %s\n' "OSVersion:"       "$OS_BUILD"
printf '%-18s %s\n' "CPU:"             "$CPU"
printf '%-18s %s\n' "RAM(GB):"         "$RAM_GB"
printf '%-18s %s\n' "Storage(GB):"     "$STOR_GB"
printf '%-18s %s\n' "MonitorCount:"    "$MON_COUNT"
echo ""
echo "===== MONITORS ====="
if [ "$MON_COUNT" -gt 0 ]; then
  awk -F'\t' '{printf "  %d. %s   Serial: %s   Year: %s\n", NR, $1, ($2==""?"-":$2), ($3==""?"-":$3)}' "$MON_TMP"
else
  echo "No monitor data available on this machine."
fi
echo ""

echo "  [######] 6/6  Saving CSV files..."
{
  echo '"ComputerName","Manufacturer","Model","SerialNumber","AssignedTo","IPAddress","MACAddress","OperatingSystem","OSVersion","CPU","RAM(GB)","Storage(GB)","MonitorCount","CollectedOn"'
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$(q "$PC")" "$(q "$MANUFACTURER")" "$(q "$MODEL")" "$(q "$SERIAL")" \
    "$(q "$USER_NAME")" "$(q "$IP")" "$(q "$MAC")" "$(q "$OS_NAME")" \
    "$(q "$OS_BUILD")" "$(q "$CPU")" "$(q "$RAM_GB")" "$(q "$STOR_GB")" \
    "$(q "$MON_COUNT")" "$(q "$NOW")"
} > "$SPECS" || { echo "ERROR: could not write $SPECS (file open in Excel?)"; read -r -p "Press Enter to close..."; exit 1; }

{
  echo '"ComputerName","AssignedTo","MonitorNumber","Manufacturer","Model","Serial","Year","CollectedOn"'
  if [ "$MON_COUNT" -gt 0 ]; then
    n=0
    while IFS=$'\t' read -r mname mserial myear mvendor; do
      n=$((n+1))
      printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$(q "$PC")" "$(q "$USER_NAME")" "$(q "$n")" "$(q "$mvendor")" \
        "$(q "$mname")" "$(q "$mserial")" "$(q "$myear")" "$(q "$NOW")"
    done < "$MON_TMP"
  else
    printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$(q "$PC")" "$(q "$USER_NAME")" '"0"' '""' '""' '""' '""' "$(q "$NOW")"
  fi
} > "$MONITORS" || { echo "ERROR: could not write $MONITORS (file open in Excel?)"; rm -f "$MON_TMP"; read -r -p "Press Enter to close..."; exit 1; }

rm -f "$MON_TMP"
echo "Saved specs:    $SPECS"
echo "Saved monitors: $MONITORS"
echo ""
echo "  Done. You can close this window."
