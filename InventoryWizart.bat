@echo off
chcp 65001 >nul
title Portable PC ^& Monitor Asset Collector
color 1F
REM  Portable PC & Monitor Asset Collector
REM  Copyright (C) 2026 ktrotek
REM  Licensed under the GNU General Public License v3.0 (see LICENSE file).
REM  This program comes with ABSOLUTELY NO WARRANTY.
REM ============================================================
REM  Inventory Wizart - PC + monitor inventory collector
REM  Double-click to run. Saves TWO CSV files next to this file,
REM  named after the PC:
REM    <HOSTNAME>_Specs.csv     - one row: system / BIOS / OS info
REM    <HOSTNAME>_Monitors.csv  - one row per connected monitor
REM  The two files share the ComputerName column, so you can
REM  match monitors back to their PC.
REM  Re-running on the same PC just refreshes its own files.
REM  Tip: if Excel shows everything in one column (Greek locale
REM  uses ';' as separator), use Data > From Text/CSV to import,
REM  or add -UseCulture to the Export-Csv lines below.
REM ============================================================
setlocal
set "SPECS=%~dp0%COMPUTERNAME%_Specs.csv"
set "MONITORS=%~dp0%COMPUTERNAME%_Monitors.csv"

echo.
echo  ▓▒░ ──────────────────────────────────────────────────[ ktrotek ]─┐
echo.
echo ▪   ▐ ▄  ▌ ▐·▄▄▄ . ▐ ▄ ▄▄▄▄▄      ▄▄▄   ▄· ▄▌▄▄▌ ▐ ▄▌▪  ·▄▄▄▄• ▄▄▄· ▄▄▄  ▄▄▄▄▄
echo ██ •█▌▐█▪█·█▌▀▄.▀·•█▌▐█•██  ▪     ▀▄ █·▐█▪██▌██· █▌▐███ ▪▀·.█▌▐█ ▀█ ▀▄ █·•██
echo ▐█·▐█▐▐▌▐█▐█•▐▀▀▪▄▐█▐▐▌ ▐█.▪ ▄█▀▄ ▐▀▀▄ ▐█▌▐█▪██▪▐█▐▐▌▐█·▄█▀▀▀•▄█▀▀█ ▐▀▀▄  ▐█.▪
echo ▐█▌██▐█▌ ███ ▐█▄▄▌██▐█▌ ▐█▌·▐█▌.▐▌▐█•█▌ ▐█▀·.▐█▌██▐█▌▐█▌█▌▪▄█▀▐█ ▪▐▌▐█•█▌ ▐█▌·
echo ▀▀▀▀▀ █▪. ▀   ▀▀▀ ▀▀ █▪ ▀▀▀  ▀█▄▀▪.▀  ▀  ▀ •  ▀▀▀▀ ▀▪▀▀▀·▀▀▀ • ▀  ▀ .▀  ▀ ▀▀▀
echo.
echo  └─░▒▓ pc + monitor asset collector ▓▒░ ───────────────────────────█

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Write-Host '';" ^
  "Write-Host '  [#-----] 1/6  Reading system and BIOS info...' -ForegroundColor Cyan;" ^
  "$pc=$env:COMPUTERNAME;" ^
  "$now=Get-Date -Format 'yyyy-MM-dd HH:mm';" ^
  "$cs=Get-CimInstance Win32_ComputerSystem;" ^
  "$bios=Get-CimInstance Win32_BIOS;" ^
  "Write-Host '  [##----] 2/6  Reading operating system and CPU...' -ForegroundColor Cyan;" ^
  "$os=Get-CimInstance Win32_OperatingSystem;" ^
  "$cpu=Get-CimInstance Win32_Processor | Select-Object -First 1;" ^
  "Write-Host '  [###---] 3/6  Reading network configuration...' -ForegroundColor Cyan;" ^
  "$nets=@(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True');" ^
  "$net=$nets | Where-Object {$_.DefaultIPGateway} | Select-Object -First 1;" ^
  "if(-not $net){$net=$nets | Select-Object -First 1};" ^
  "$ip=''; $mac=''; if($net){ $ip=(@($net.IPAddress) | Where-Object {$_ -match '\.'}) -join ', '; $mac=$net.MACAddress };" ^
  "Write-Host '  [####--] 4/6  Reading disks and memory...' -ForegroundColor Cyan;" ^
  "$disk=Get-CimInstance Win32_DiskDrive | Where-Object {$_.InterfaceType -ne 'USB'};" ^
  "$ramGB=[math]::Round($cs.TotalPhysicalMemory/1GB,1);" ^
  "$storGB=[math]::Round((($disk | Measure-Object -Property Size -Sum).Sum)/1GB,0);" ^
  "$user=$cs.UserName; if(-not $user){$user=$env:USERDOMAIN+'\'+$env:USERNAME};" ^
  "Write-Host '  [#####-] 5/6  Detecting monitors...' -ForegroundColor Cyan;" ^
  "$mon=@(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue | ForEach-Object {" ^
    "[PSCustomObject]@{" ^
      "Manufacturer=(-join [char[]]($_.ManufacturerName | Where-Object {$_ -ne 0})).Trim();" ^
      "Model=(-join [char[]]($_.UserFriendlyName | Where-Object {$_ -ne 0})).Trim();" ^
      "Serial=(-join [char[]]($_.SerialNumberID | Where-Object {$_ -ne 0})).Trim();" ^
      "Year=$_.YearOfManufacture" ^
    "}" ^
  "});" ^
  "$sys=[PSCustomObject]@{" ^
    "ComputerName=$pc;" ^
    "Manufacturer=$cs.Manufacturer;" ^
    "Model=$cs.Model;" ^
    "SerialNumber=$bios.SerialNumber;" ^
    "AssignedTo=$user;" ^
    "IPAddress=$ip;" ^
    "MACAddress=$mac;" ^
    "OperatingSystem=$os.Caption;" ^
    "OSVersion=$os.Version;" ^
    "CPU=($cpu.Name).Trim();" ^
    "'RAM(GB)'=$ramGB;" ^
    "'Storage(GB)'=$storGB;" ^
    "MonitorCount=$mon.Count;" ^
    "CollectedOn=$now" ^
  "};" ^
  "$monOut=@(for($i=0;$i -lt $mon.Count;$i++){" ^
    "[PSCustomObject]@{" ^
      "ComputerName=$pc;" ^
      "AssignedTo=$user;" ^
      "MonitorNumber=$i+1;" ^
      "Manufacturer=$mon[$i].Manufacturer;" ^
      "Model=$mon[$i].Model;" ^
      "Serial=$mon[$i].Serial;" ^
      "Year=$mon[$i].Year;" ^
      "CollectedOn=$now" ^
    "}" ^
  "});" ^
  "if($monOut.Count -eq 0){ $monOut=@([PSCustomObject]@{ComputerName=$pc;AssignedTo=$user;MonitorNumber=0;Manufacturer='';Model='';Serial='';Year='';CollectedOn=$now}) };" ^
  "Write-Host '';" ^
  "Write-Host '===== SYSTEM =====' -ForegroundColor Cyan;" ^
  "$sys | Format-List | Out-String | Write-Host;" ^
  "Write-Host '===== MONITORS =====' -ForegroundColor Cyan;" ^
  "if($mon.Count){ $mon | Format-Table -AutoSize | Out-String | Write-Host } else { Write-Host 'No monitor data available on this machine.' -ForegroundColor Yellow };" ^
  "Write-Host '  [######] 6/6  Saving CSV files...' -ForegroundColor Cyan;" ^
  "try{" ^
    "$sys | Export-Csv -Path $env:SPECS -NoTypeInformation -Encoding UTF8 -ErrorAction Stop;" ^
    "$monOut | Export-Csv -Path $env:MONITORS -NoTypeInformation -Encoding UTF8 -ErrorAction Stop;" ^
    "Write-Host ('Saved specs:    '+$env:SPECS) -ForegroundColor Green;" ^
    "Write-Host ('Saved monitors: '+$env:MONITORS) -ForegroundColor Green" ^
  "} catch {" ^
    "Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red;" ^
    "Write-Host 'If a CSV file is open in Excel, close it and run this again.' -ForegroundColor Yellow" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host '  Done.' -ForegroundColor Green"

echo.
pause
endlocal
