@echo off
chcp 65001 >nul
title Inventory Wizart
color 1F
REM  Inventory Wizart - portable IT asset and upgrade toolkit
REM  Copyright (C) 2026 ktrotek
REM  Licensed under the GNU General Public License v3.0 (see LICENSE file).
REM  This program comes with ABSOLUTELY NO WARRANTY.
REM ============================================================
REM  Inventory Wizart - one file, three collectors, one menu.
REM  Double-click to run. Move with the arrow keys, Enter to run
REM  the highlighted collector. Every collector saves its CSV
REM  files next to this file and returns to the menu when it is
REM  done, so one visit to a PC can produce all three sets.
REM
REM   [1] PC & Monitors
REM         <HOSTNAME>_Specs.csv     - one row: system / BIOS / OS info
REM         <HOSTNAME>_Monitors.csv  - one row per connected monitor
REM       The two files share the ComputerName column, so you can
REM       match monitors back to their PC. Re-running on the same
REM       PC just refreshes its own files.
REM
REM   [2] Printers
REM         Company_Printers.csv     - one row per PHYSICAL printer
REM       Shared across the whole site: the first run creates it,
REM       every run after that merges into the same file instead
REM       of adding duplicate rows. Ten PCs sharing three printers
REM       end up as three rows, not thirty.
REM
REM   [3] RAM & HDD Upgrates
REM         <HOSTNAME>_Upgrate.csv   - one row: what this PC can take
REM       Answers "what can we upgrade in this box?" without
REM       opening the case: memory slots and headroom, drive bays
REM       and disk health, and Windows 11 readiness.
REM
REM  Tip: if Excel shows everything in one column (Greek locale
REM  uses ';' as separator), use Data > From Text/CSV to import.
REM  Numbers are always written with '.' as the decimal mark
REM  (invariant culture), never ',', so files from Greek and
REM  English PCs merge into one clean inventory.
REM ============================================================
setlocal EnableDelayedExpansion

REM  Inside a "call :label" subroutine %0 is the label, not this file, so the
REM  path to self has to be captured out here where %~f0 still means the file.
set "SELF=%~f0"
set "SPECS=%~dp0%COMPUTERNAME%_Specs.csv"
set "MONITORS=%~dp0%COMPUTERNAME%_Monitors.csv"
set "PRINTERS=%~dp0Company_Printers.csv"
set "UPGRATE=%~dp0%COMPUTERNAME%_Upgrate.csv"

REM  cmd cannot read an arrow key, so the menu is drawn and driven by the
REM  PowerShell payload below and hands its answer back through this file.
set "PICKFILE=%TEMP%\InventoryWizart_pick_%RANDOM%%RANDOM%.tmp"

:menu
cls
set "PICK="
call :run 0
if exist "%PICKFILE%" set /p PICK=<"%PICKFILE%"
del "%PICKFILE%" >nul 2>&1

REM  No answer means the console could not give PowerShell a raw key reader
REM  (a redirected or remote shell does this). Fall back to typing a number
REM  rather than dropping the user out of the tool.
if not defined PICK (
  echo.
  echo   Arrow keys are not available in this console - type a number instead.
  echo.
  echo     [1]  PC ^& Monitors
  echo     [2]  Printers
  echo     [3]  RAM ^& HDD Upgrates
  echo     [4]  Exit
  echo.
  set /p "PICK=  Select an option [1-4]: "
)

if "!PICK!"=="1" goto :opt1
if "!PICK!"=="2" goto :opt2
if "!PICK!"=="3" goto :opt3
goto :quit

REM ------------------------------------------------------------ option 1 ---
:opt1
cls
call :run 1
goto :back

REM ------------------------------------------------------------ option 2 ---
:opt2
cls
call :run 2
goto :back

REM ------------------------------------------------------------ option 3 ---
:opt3
cls
call :run 3
goto :back

REM --------------------------------------------------------------- shared ---
:back
echo.
echo   Done. Press Enter to return to the menu...
pause >nul
goto :menu

:run
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%SELF%'; $t=[IO.File]::ReadAllText($f); $s='#::PS'+'%~1'+'CODE::#'; $e='#::END'+'CODE::#'; $a=$t.IndexOf($s); if($a -lt 0){Write-Host '  ERROR: this file is damaged - payload %~1 is missing. Copy a fresh InventoryWizart.bat.' -ForegroundColor Red; exit 1}; $a+=$s.Length; $b=$t.IndexOf($e,$a); if($b -lt 0){$b=$t.Length}; Invoke-Expression $t.Substring($a,$b-$a)"
exit /b

:quit
cls
echo.
echo   Bye.
echo.
del "%PICKFILE%" >nul 2>&1
endlocal
exit /b 0

#::PS0CODE::#

# ===================== menu =========================================
# Everything below runs as PowerShell. The batch part above extracts
# it from this same file, so there is still only one file to copy.
#
# cmd has no way to read an arrow key, so the menu lives here. The
# whole screen is painted once, then only the five option lines are
# repainted on each keypress - repainting the lot would flicker.
# The chosen option goes back to the launcher through PICKFILE:
# an exit code cannot survive Invoke-Expression reliably, and a file
# is one thing that certainly does.

$ErrorActionPreference = 'SilentlyContinue'

$options = @(
    @{ Code = '1'; Name = 'PC & Monitors';       Blurb = 'system, BIOS, OS, network, monitors' }
    @{ Code = '2'; Name = 'Printers';            Blurb = 'every online printer, merged site-wide' }
    @{ Code = '3'; Name = 'RAM & HDD Upgrates';  Blurb = 'memory, drive bays, Windows 11 readiness' }
    @{ Code = '4'; Name = 'Exit';                Blurb = '' }
)

$ui = $Host.UI.RawUI

function Write-Options {
    param($Index, $Anchor, $Width)

    $ui.CursorPosition = $Anchor
    for ($i = 0; $i -lt $options.Count; $i++) {
        $o    = $options[$i]
        $box  = $(if ($i -eq $Index) { '[x]' } else { '[ ]' })
        $line = '     {0}  {1}  {2}' -f $box, $o.Name.PadRight(20), $o.Blurb

        # Pad to just short of the buffer width: it wipes whatever the previous
        # frame left on the line, and stopping one short of the edge keeps the
        # console from wrapping and scrolling the anchor out from under us.
        if ($line.Length -gt $Width) { $line = $line.Substring(0, $Width) }
        $line = $line.PadRight($Width)

        if ($i -eq $Index) { Write-Host $line -ForegroundColor Yellow }
        else               { Write-Host $line -ForegroundColor Gray }

        # A gap above Exit, so it does not read as a fourth collector.
        if ($i -eq $options.Count - 2) { Write-Host ''.PadRight($Width) }
    }
}

$cursorWas = $true
try {
    # A blinking caret parked under the list looks like a prompt that wants
    # typing. Restored in finally so an error cannot leave it switched off.
    $cursorWas = [Console]::CursorVisible
    [Console]::CursorVisible = $false

    Clear-Host
    $width = $ui.BufferSize.Width - 1

    # The option block is repainted at a fixed row, so the whole screen has to
    # fit without scrolling or the anchor slides out from under the redraw.
    # Banner 10 rows + header 3 + options 5 + footer 2 + 1 = 21; a window
    # shorter than that drops the banner instead of tearing the menu.
    if ($ui.WindowSize.Height -ge 21) {
        Write-Host ''
        Write-Host '  ▓▒░ ────── -─-──────-───-──-── --───────────────────────────[ ktrotek ]─┐'
        Write-Host ''
        Write-Host '▪   ▐ ▄  ▌ ▐·▄▄▄ . ▐ ▄ ▄▄▄▄▄      ▄▄▄   ▄· ▄▌▄▄▌ ▐ ▄▌▪  ·▄▄▄▄• ▄▄▄· ▄▄▄  ▄▄▄▄▄'
        Write-Host '██ •█▌▐█▪█·█▌▀▄.▀·•█▌▐█•██  ▪     ▀▄ █·▐█▪██▌██· █▌▐███ ▪▀·.█▌▐█ ▀█ ▀▄ █·•██'
        Write-Host '▐█·▐█▐▐▌▐█▐█•▐▀▀▪▄▐█▐▐▌ ▐█.▪ ▄█▀▄ ▐▀▀▄ ▐█▌▐█▪██▪▐█▐▐▌▐█·▄█▀▀▀•▄█▀▀█ ▐▀▀▄  ▐█.▪'
        Write-Host '▐█▌██▐█▌ ███ ▐█▄▄▌██▐█▌ ▐█▌·▐█▌.▐▌▐█•█▌ ▐█▀·.▐█▌██▐█▌▐█▌█▌▪▄█▀▐█ ▪▐▌▐█•█▌ ▐█▌·'
        Write-Host '▀▀▀▀▀ █▪. ▀   ▀▀▀ ▀▀ █▪ ▀▀▀  ▀█▄▀▪.▀  ▀  ▀ •  ▀▀▀▀ ▀▪▀▀▀·▀▀▀ • ▀  ▀ .▀  ▀ ▀▀▀'
        Write-Host ''
        Write-Host '  └─░▒▓ portable it asset toolkit ▓▒░ ───────--	  ---──────────────────█'
    }

    Write-Host ''
    Write-Host ("  Running on {0}.  Files are saved next to this one." -f $env:COMPUTERNAME) -ForegroundColor Gray
    Write-Host ''

    # Where the option block starts. Captured after the banner is on screen so
    # the repaint lands in the right place whatever the banner did.
    $anchor = $ui.CursorPosition

    $sel  = 0
    $done = $false
    while (-not $done) {
        Write-Options -Index $sel -Anchor $anchor -Width $width

        Write-Host ''
        Write-Host '  ─────────────────────────────────────────────────────────────────────────' -ForegroundColor DarkGray

        $key = $ui.ReadKey('NoEcho,IncludeKeyDown')
        switch ($key.VirtualKeyCode) {
            38 { $sel = ($sel - 1 + $options.Count) % $options.Count }   # up
            40 { $sel = ($sel + 1) % $options.Count }                    # down
            36 { $sel = 0 }                                              # home
            35 { $sel = $options.Count - 1 }                             # end
            13 { $done = $true }                                         # enter
            27 { $sel = $options.Count - 1; $done = $true }              # esc
            default {
                $ch = "$($key.Character)"
                if ($ch -match '^[1-4]$')    { $sel = [int]$ch - 1; $done = $true }
                elseif ($ch -match '^[qxQX]$') { $sel = $options.Count - 1; $done = $true }
            }
        }

        # The footer was written below the options, so rewind to the anchor and
        # let the next pass paint over it rather than letting it march down.
        if (-not $done) { $ui.CursorPosition = $anchor }
    }

    Write-Host ''
    if ($env:PICKFILE) {
        Set-Content -LiteralPath $env:PICKFILE -Value $options[$sel].Code -Encoding ASCII -ErrorAction Stop
    }
}
catch {
    # No raw key reader in this console, or the file could not be written.
    # Writing nothing is the signal for the launcher to prompt for a number.
    Write-Host ''
    Write-Host ('  Menu could not run here: ' + $_.Exception.Message) -ForegroundColor DarkYellow
}
finally {
    try { [Console]::CursorVisible = $cursorWas } catch { }
}

#::ENDCODE::#

#::PS1CODE::#

# ===================== pc + monitor collector =======================
# Everything below runs as PowerShell. The batch part above extracts
# it from this same file, so there is still only one file to copy.

$ErrorActionPreference = 'SilentlyContinue'

# Numbers always use '.' as the decimal mark, so files from Greek and
# English machines merge into one clean inventory.
[Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

# The launcher sets these. Falling back to the working directory is a last
# resort only: started from a UNC path, cmd drops us in C:\Windows.
$specsOut = $env:SPECS
$monOut   = $env:MONITORS
if (-not $specsOut) { $specsOut = Join-Path (Get-Location).Path "$($env:COMPUTERNAME)_Specs.csv" }
if (-not $monOut)   { $monOut   = Join-Path (Get-Location).Path "$($env:COMPUTERNAME)_Monitors.csv" }

Write-Host ''
Write-Host '  [#-----] 1/6  Reading system and BIOS info...' -ForegroundColor Cyan
$pc   = $env:COMPUTERNAME
$now  = Get-Date -Format 'yyyy-MM-dd HH:mm K'
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS

Write-Host '  [##----] 2/6  Reading operating system and CPU...' -ForegroundColor Cyan
$os  = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

Write-Host '  [###---] 3/6  Reading network configuration...' -ForegroundColor Cyan
$nets = @(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True')
$net  = $nets | Where-Object { $_.DefaultIPGateway } | Select-Object -First 1
if (-not $net) { $net = $nets | Select-Object -First 1 }
$ip  = ''
$mac = ''
if ($net) {
    $ip  = (@($net.IPAddress) | Where-Object { $_ -match '\.' }) -join ', '
    $mac = $net.MACAddress
}

Write-Host '  [####--] 4/6  Reading disks and memory...' -ForegroundColor Cyan
$disk = Get-CimInstance Win32_DiskDrive | Where-Object { $_.InterfaceType -ne 'USB' }
$ramBytes = (Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue |
    Measure-Object -Property Capacity -Sum).Sum
if (-not $ramBytes) { $ramBytes = $cs.TotalPhysicalMemory }

# Snap to the real installed size so a 16 GB PC reads 16 and not 15.9, but
# only when the raw figure is close enough that the snap is not a guess.
$ramRaw = $ramBytes / 1GB
$ramGB  = [int][math]::Round($ramRaw)
$tol    = [math]::Max(0.5, $ramRaw * 0.06)
foreach ($s in 1, 2, 3, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96, 128, 192, 256, 384, 512, 768, 1024) {
    if ($s -ge $ramRaw -and ($s - $ramRaw) -le $tol) { $ramGB = $s; break }
}

$storGB = [int][math]::Round((($disk | Measure-Object -Property Size -Sum).Sum) / 1GB, 0)

$user = $cs.UserName
if (-not $user) { $user = "$env:USERDOMAIN\$env:USERNAME" }

Write-Host '  [#####-] 5/6  Detecting monitors...' -ForegroundColor Cyan
# EDID strings arrive as null-padded UInt16 arrays, one code point per cell.
$mon = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue |
    ForEach-Object {
        [PSCustomObject]@{
            Manufacturer = (-join [char[]]($_.ManufacturerName  | Where-Object { $_ -ne 0 })).Trim()
            Model        = (-join [char[]]($_.UserFriendlyName  | Where-Object { $_ -ne 0 })).Trim()
            Serial       = (-join [char[]]($_.SerialNumberID    | Where-Object { $_ -ne 0 })).Trim()
            Year         = $_.YearOfManufacture
        }
    })

$sys = [PSCustomObject]@{
    ComputerName    = $pc
    Manufacturer    = $cs.Manufacturer
    Model           = $cs.Model
    SerialNumber    = $bios.SerialNumber
    AssignedTo      = $user
    IPAddress       = $ip
    MACAddress      = $mac
    OperatingSystem = $os.Caption
    OSVersion       = $os.Version
    CPU             = ($cpu.Name).Trim()
    'RAM(GB)'       = $ramGB
    'Storage(GB)'   = $storGB
    MonitorCount    = $mon.Count
    CollectedOn     = $now
}

$monRows = @(for ($i = 0; $i -lt $mon.Count; $i++) {
    [PSCustomObject]@{
        ComputerName  = $pc
        AssignedTo    = $user
        MonitorNumber = $i + 1
        Manufacturer  = $mon[$i].Manufacturer
        Model         = $mon[$i].Model
        Serial        = $mon[$i].Serial
        Year          = $mon[$i].Year
        CollectedOn   = $now
    }
})

# A PC with no readable monitor still gets a row, so the file always has the
# same shape and a blank is visibly a blank rather than a missing machine.
if ($monRows.Count -eq 0) {
    $monRows = @([PSCustomObject]@{
        ComputerName = $pc; AssignedTo = $user; MonitorNumber = 0
        Manufacturer = ''; Model = ''; Serial = ''; Year = ''; CollectedOn = $now
    })
}

Write-Host ''
Write-Host '===== SYSTEM =====' -ForegroundColor Cyan
Write-Host (($sys | Format-List | Out-String).Trim())
Write-Host ''
Write-Host '===== MONITORS =====' -ForegroundColor Cyan
if ($mon.Count) {
    Write-Host (($mon | Format-Table -AutoSize | Out-String).Trim())
} else {
    Write-Host 'No monitor data available on this machine.' -ForegroundColor Yellow
}
Write-Host ''
Write-Host '  [######] 6/6  Saving CSV files...' -ForegroundColor Cyan
try {
    $sys     | Export-Csv -Path $specsOut -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $monRows | Export-Csv -Path $monOut   -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    Write-Host ('Saved specs:    ' + $specsOut) -ForegroundColor Green
    Write-Host ('Saved monitors: ' + $monOut)   -ForegroundColor Green
}
catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'If a CSV file is open in Excel, close it and run this again.' -ForegroundColor Yellow
}


#::ENDCODE::#

#::PS2CODE::#

# ===================== printer collector ============================
# Everything below runs as PowerShell. The batch part above extracts
# it from this same file, so there is still only one file to copy.

$ErrorActionPreference = 'SilentlyContinue'

$pc   = $env:COMPUTERNAME
$now  = Get-Date -Format 'yyyy-MM-dd HH:mm K'
# The launcher sets this. Falling back to the working directory is a last
# resort only: started from a UNC path, cmd drops us in C:\Windows.
$out  = $env:PRINTERS
if (-not $out) { $out = Join-Path (Get-Location).Path 'Company_Printers.csv' }
$cs   = Get-CimInstance Win32_ComputerSystem
$user = $cs.UserName
if (-not $user) { $user = "$env:USERDOMAIN\$env:USERNAME" }

# --------------------------------------------------------------------
# SNMP v2c GET, implemented over a raw UDP socket. Windows has no SNMP
# cmdlet, and this is the only way to reach a printer's serial number,
# MAC address and toner levels.
# --------------------------------------------------------------------

function BLen([int]$n) {
    if ($n -lt 128) { return ,[byte]$n }
    $b = @(); $v = $n
    while ($v -gt 0) { $b = @([byte]($v -band 0xFF)) + $b; $v = $v -shr 8 }
    return @([byte](0x80 -bor $b.Count)) + $b
}

function BTlv([byte]$tag, [byte[]]$val) {
    if ($null -eq $val) { $val = @() }
    return @($tag) + (BLen $val.Length) + $val
}

function BInt([int]$n) {
    $b = [BitConverter]::GetBytes([int32]$n)
    [array]::Reverse($b)
    $i = 0
    # Drop redundant leading bytes without flipping the sign bit.
    while ($i -lt 3 -and $b[$i] -eq 0 -and ($b[$i + 1] -band 0x80) -eq 0) { $i++ }
    return BTlv 0x02 ([byte[]]$b[$i..3])
}

function BOid([string]$oid) {
    $a = @($oid.Split('.') | Where-Object { $_ -ne '' } | ForEach-Object { [uint32]$_ })
    $r = New-Object System.Collections.Generic.List[byte]
    $r.Add([byte](40 * $a[0] + $a[1]))          # first two arcs share one byte
    if ($a.Count -gt 2) {
        foreach ($x in $a[2..($a.Count - 1)]) {
            if ($x -lt 128) { $r.Add([byte]$x); continue }
            $s = New-Object System.Collections.Generic.List[byte]
            $v = $x
            while ($v -gt 0) { $s.Insert(0, [byte]($v -band 0x7F)); $v = $v -shr 7 }
            for ($i = 0; $i -lt $s.Count - 1; $i++) { $r.Add([byte]($s[$i] -bor 0x80)) }
            $r.Add($s[$s.Count - 1])
        }
    }
    return BTlv 0x06 $r.ToArray()
}

function BRead([byte[]]$buf, [ref]$i) {
    if ($i.Value -ge $buf.Length) { return $null }
    $tag = $buf[$i.Value]; $i.Value++
    $len = $buf[$i.Value]; $i.Value++
    if ($len -band 0x80) {
        $n = $len -band 0x7F; $len = 0
        for ($k = 0; $k -lt $n; $k++) { $len = ($len -shl 8) -bor $buf[$i.Value]; $i.Value++ }
    }
    $val = if ($len -gt 0) { [byte[]]$buf[$i.Value..($i.Value + $len - 1)] } else { [byte[]]@() }
    $i.Value += $len
    return [PSCustomObject]@{ Tag = $tag; Value = $val }
}

function BOidStr([byte[]]$b) {
    if ($b.Length -eq 0) { return '' }
    $a = @([int][math]::Floor($b[0] / 40), [int]($b[0] % 40))
    $acc = 0
    for ($i = 1; $i -lt $b.Length; $i++) {
        $acc = ($acc -shl 7) -bor ($b[$i] -band 0x7F)
        if (-not ($b[$i] -band 0x80)) { $a += $acc; $acc = 0 }
    }
    return ($a -join '.')
}

# Returns an array of {Oid, Value, Raw} in reply order. Empty on any failure.
# $pduTag 0xA0 = GET, 0xA1 = GETNEXT (the walk uses the latter).
function SnmpReq($ip, $community, $oids, $ver = 1, $timeoutMs = 1200, $pduTag = 0xA0) {
    $vbs = @()
    foreach ($o in $oids) { $vbs += BTlv 0x30 ((BOid $o) + (BTlv 0x05 @())) }

    $pdu = BTlv $pduTag ((BInt (Get-Random -Minimum 1 -Maximum 2147483647)) +
                      (BInt 0) + (BInt 0) + (BTlv 0x30 $vbs))
    $pkt = [byte[]](BTlv 0x30 ((BInt $ver) +
                    (BTlv 0x04 ([Text.Encoding]::ASCII.GetBytes($community))) + $pdu))

    $u = $null
    try {
        $u = New-Object System.Net.Sockets.UdpClient
        $u.Client.ReceiveTimeout = $timeoutMs
        $u.Connect($ip, 161)
        [void]$u.Send($pkt, $pkt.Length)
        $ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $resp = $u.Receive([ref]$ep)
    }
    catch { return @() }
    finally { if ($u) { $u.Close() } }

    # SEQUENCE { version, community, PDU { id, err, idx, varbinds } }
    $i = [ref]0
    $outer = BRead $resp $i
    if ($null -eq $outer -or $outer.Tag -ne 0x30) { return @() }

    $j = [ref]0
    [void](BRead $outer.Value $j)          # version
    [void](BRead $outer.Value $j)          # community
    $pduT = BRead $outer.Value $j
    if ($null -eq $pduT) { return @() }

    $k = [ref]0
    [void](BRead $pduT.Value $k)           # request id
    [void](BRead $pduT.Value $k)           # error status
    [void](BRead $pduT.Value $k)           # error index
    $vbl = BRead $pduT.Value $k
    if ($null -eq $vbl) { return @() }

    $res = @()
    $m = [ref]0
    while ($m.Value -lt $vbl.Value.Length) {
        $e = BRead $vbl.Value $m
        if ($null -eq $e) { break }
        $n = [ref]0
        $oT = BRead $e.Value $n
        $vT = BRead $e.Value $n
        if ($null -eq $oT -or $null -eq $vT) { break }
        # 0x80/0x81/0x82 are v2c's "no such object/instance" markers.
        if ($vT.Tag -eq 0x05 -or $vT.Tag -eq 0x80 -or $vT.Tag -eq 0x81 -or $vT.Tag -eq 0x82) { continue }

        $val = switch ($vT.Tag) {
            0x04    { ([Text.Encoding]::UTF8.GetString($vT.Value) -replace '[\x00-\x1F]', '').Trim() }
            0x06    { BOidStr $vT.Value }
            default { $t = 0; foreach ($b in $vT.Value) { $t = $t * 256 + $b }; $t }
        }
        $res += [PSCustomObject]@{ Oid = (BOidStr $oT.Value); Value = $val; Raw = $vT.Value }
    }
    return $res
}

# Convenience wrapper: hashtable of OID -> {Value, Raw}. Empty on any failure.
function SnmpGet($ip, $community, $oids, $ver = 1, $timeoutMs = 1200) {
    $h = @{}
    foreach ($v in (SnmpReq $ip $community $oids $ver $timeoutMs 0xA0)) { $h[$v.Oid] = $v }
    return $h
}

# SNMPv1 has no per-varbind error: one unsupported OID in a request and the
# agent returns nothing at all for the other eleven. On a v1 device we have to
# ask one question at a time.
function SnmpGetMany($ip, $community, $oids, $ver = 1, $timeoutMs = 1200) {
    if ($ver -ne 0) { return SnmpGet $ip $community $oids $ver $timeoutMs }
    $h = @{}
    foreach ($o in $oids) {
        foreach ($v in (SnmpReq $ip $community @($o) $ver $timeoutMs 0xA0)) { $h[$v.Oid] = $v }
    }
    return $h
}

# Walks a whole column with GETNEXT. Needed because the printer MIB indexes
# rows by hrDeviceIndex, and plenty of devices do NOT number theirs .1 - a
# plain GET on prtGeneralSerialNumber.1 then comes back empty on a printer
# that does publish its serial.
function SnmpWalk($ip, $community, $root, $ver = 1, $max = 8, $timeoutMs = 1200) {
    $res = @(); $oid = $root
    for ($n = 0; $n -lt $max; $n++) {
        $r = @(SnmpReq $ip $community @($oid) $ver $timeoutMs 0xA1)
        if ($r.Count -eq 0) { break }
        $v = $r[0]
        if (-not $v.Oid -or -not $v.Oid.StartsWith("$root.")) { break }
        $res += $v
        $oid = $v.Oid
    }
    return $res
}

# --------------------------------------------------------------------

function TcpOpen($ip, $port, $timeoutMs = 800) {
    $c = $null
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $a = $c.BeginConnect($ip, $port, $null, $null)
        if (-not $a.AsyncWaitHandle.WaitOne($timeoutMs, $false)) { return $false }
        $c.EndConnect($a)
        return $true
    }
    catch { return $false }
    finally { if ($c) { $c.Close() } }
}

function ToIp($hostOrIp) {
    if (-not $hostOrIp) { return $null }
    $tmp = 0
    if ([System.Net.IPAddress]::TryParse($hostOrIp, [ref]$tmp)) { return $hostOrIp }
    try {
        $a = [System.Net.Dns]::GetHostAddresses($hostOrIp) |
             Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
        if ($a) { return $a.IPAddressToString }
    }
    catch { }
    return $null
}

# Accepts any separator (or none) and rejects the placeholder addresses a
# printer hands out when the interface is down.
function NormMac($m) {
    if (-not $m) { return '' }
    $h = ($m -replace '[^0-9A-Fa-f]', '').ToLower()
    if ($h.Length -ne 12) { return '' }
    if ($h -eq '000000000000' -or $h -eq 'ffffffffffff') { return '' }
    return ((0..5 | ForEach-Object { $h.Substring($_ * 2, 2) }) -join ':')
}

function FirstIp($text) {
    if (-not $text) { return $null }
    if ("$text" -notmatch '((?:\d{1,3}\.){3}\d{1,3})') { return $null }
    $ip = $matches[1]
    if ($ip -eq '0.0.0.0' -or $ip -like '127.*') { return $null }
    $tmp = 0
    if ([System.Net.IPAddress]::TryParse($ip, [ref]$tmp)) { return $ip }
    return $null
}

# ARP only resolves inside the local broadcast domain, and only for hosts the
# cache has already seen - so poke the printer first.
function ArpMac($ip) {
    [void](Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue)
    $n = Get-NetNeighbor -IPAddress $ip -ErrorAction SilentlyContinue |
         Where-Object { $_.LinkLayerAddress -and $_.State -ne 'Unreachable' -and $_.State -ne 'Incomplete' } |
         Select-Object -First 1
    if ($n) { return (NormMac $n.LinkLayerAddress) }
    $line = (arp.exe -a $ip 2>$null) | Where-Object { $_ -match [regex]::Escape($ip) } | Select-Object -First 1
    if ($line -and $line -match '([0-9a-fA-F]{2}(?:[-:][0-9a-fA-F]{2}){5})') { return (NormMac $matches[1]) }
    return ''
}

# --------------------------------------------------------------------
# Where a printer's address actually lives on a Windows box, in order of
# how much we trust it. Win32_TCPIPPrinterPort only knows about Standard
# TCP/IP ports, which is why so many queues came back with no IP: WSD,
# vendor-supplied monitors and hand-named ports are invisible to it.
# --------------------------------------------------------------------

# Every port monitor keeps its ports under its own registry key. Scan the
# values of each port for a host name or an address.
function ReadPortRegistry {
    $map = @{}
    $root = 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Monitors'
    Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem "$($_.PSPath)\Ports" -ErrorAction SilentlyContinue | ForEach-Object {
            $name = $_.PSChildName
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if (-not $p) { return }
            $ip = FirstIp $p.IPAddress
            if (-not $ip) { $ip = FirstIp $p.HostName }
            if (-not $ip) { $ip = FirstIp $p.'Printer Name' }
            $hostName = $null
            foreach ($v in $p.HostName, $p.'Host Address', $p.IPAddress) {
                if ($v -and -not (FirstIp $v)) { $hostName = "$v"; break }
            }
            if (-not $ip -and -not $hostName) {
                # Last chance: some monitors store the address under a name
                # of their own invention.
                foreach ($v in $p.PSObject.Properties) {
                    if ($v.Name -like 'PS*') { continue }
                    $ip = FirstIp $v.Value
                    if ($ip) { break }
                }
            }
            if ($ip -or $hostName) { $map[$name] = [PSCustomObject]@{ Ip = $ip; HostName = $hostName } }
        }
    }
    return $map
}

# Flattens every value under a registry key (and optionally its subkeys) to
# strings. Windows scatters a printer's address across keys that have no
# consistent value name, so it is cheaper to read them all and pattern-match.
function RegStrings($path, $depth = 1) {
    $out = @()
    $k = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if (-not $k) { return $out }
    foreach ($n in $k.GetValueNames()) {
        $v = $k.GetValue($n)
        if ($v -is [byte[]]) {
            # Device properties are often a UTF-16 string stored as REG_BINARY.
            # Skip the big blobs - driver caches hold no addresses, only bulk.
            if ($v.Length -gt 4096) { continue }
            $out += [Text.Encoding]::Unicode.GetString($v)
            $out += [Text.Encoding]::ASCII.GetString($v)
            continue
        }
        $out += "$v"
    }
    if ($depth -gt 0) {
        foreach ($sub in @(Get-ChildItem -LiteralPath $path -ErrorAction SilentlyContinue)) {
            $out += RegStrings $sub.PSPath ($depth - 1)
        }
    }
    return $out
}

# WSD ports carry no address in their name, only the device UUID. The UUID
# is also the key of the software-device record the WSD provider wrote, and
# that record holds the transport address the device was discovered at.
function ReadWsdDevices {
    $map = @{}
    foreach ($base in 'HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\DAFWSDProvider',
                      'HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\DAFPrinterProvider') {
        Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
            $id = $_.PSChildName
            if ($id -notmatch '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { return }
            $uuid = $matches[1].ToLower()
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            $ip = $null
            if ($p) {
                foreach ($v in $p.PSObject.Properties) {
                    if ($v.Name -like 'PS*') { continue }
                    $ip = FirstIp $v.Value
                    if ($ip) { break }
                }
            }
            $map[$uuid] = [PSCustomObject]@{ Ip = $ip; Uuid = $uuid }
        }
    }
    return $map
}

# A version-1 UUID ends in the generating machine's MAC. Printers mint their
# WSD UUID from the NIC, so this is a real address - but only when the
# version nibble says v1, otherwise the tail is 60 bits of random.
function UuidMac($uuid) {
    if (-not $uuid -or $uuid -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-([0-9a-f])[0-9a-f]{3}-[0-9a-f]{4}-([0-9a-f]{12})$') { return '' }
    if ($matches[1] -ne '1') { return '' }
    return (NormMac $matches[2])
}

$vendorRx = '(?i)\b(brother|hewlett[- ]?packard|hp|canon|epson|xerox|lexmark|ricoh|kyocera|' +
            'konica ?minolta|sharp|toshiba|oki(?:data)?|samsung|dell|zebra|dymo|pantum|panasonic)\b'
$mfpRx    = '(?i)(\bmfp\b|\bmfc\b|\bdcp\b|all[- ]?in[- ]?one|\baio\b|multi[- ]?function|workcentre|' +
            'imagerunner|imageclass|\bmf\d|bizhub|e-?studio|taskalfa|ecosys m|maxify|pixma|ecotank|' +
            'workforce|smart tank|officejet|envy)'

function CleanModel($text, $vendor) {
    if (-not $text) { return $null }
    $m = ($text -split "[\r\n;]")[0].Trim()
    if ($vendor) { $m = $m -replace "(?i)^\s*$([regex]::Escape($vendor))\s*", '' }
    $m = $m -replace $vendorRx, ''
    # The pattern MUST stay parenthesised: ',' binds tighter than '+', so an
    # unbracketed multi-line pattern swallows the replacement argument and
    # becomes an invalid regex that throws away the whole cleanup.
    $m = $m -replace ('(?i)\b(printer|print queue|series|class driver|driver|pcl\s*-?\s*[56]e?|' +
                      'pcl-?xl|postscript|ps\d?|xps|universal|bidi|copier|scanner|fax|v\d(\.\d+)*|' +
                      '\(v\d+(\.\d+)*\))\b'), ' '
    $m = ($m -replace '\s{2,}', ' ').Trim(' ', '-', ',', '(', ')', '.')
    if ($m) { return $m } else { return $null }
}

# Instance-ID tails and SNMP strings are full of things that are not serials.
function CleanSerial($s) {
    if (-not $s) { return '' }
    $s = ("$s" -replace '[\x00-\x1F]', '').Trim()
    if ($s -match '[&\\/]') { return '' }               # a bus path, not a serial
    if ($s.Length -lt 4 -or $s.Length -gt 40) { return '' }
    if ($s -match '^(?i)(0+|n/?a|none|null|unknown|serial ?(number|no)?|not set|x+|-+)$') { return '' }
    return $s
}

function Vendor($text) {
    if (-not $text) { return $null }
    if ($text -notmatch $vendorRx) { return $null }
    $v = $matches[1].ToLower()
    switch -regex ($v) {
        'hewlett|^hp$'    { return 'HP' }
        'konica'          { return 'Konica Minolta' }
        'okidata'         { return 'OKI' }
        default           { return (Get-Culture).TextInfo.ToTitleCase($v) }
    }
}

# Half the printers in the world are named after the model alone - "LBP233"
# says Canon to anyone in the trade but matches no brand word.
function VendorFromModel($m) {
    if (-not $m) { return $null }
    switch -regex ($m) {
        '(?i)^(lbp|mf\d|imageclass|imagerunner|ir-?adv|pixma|maxify|i-?sensys)' { return 'Canon' }
        '(?i)^(mfc|dcp|hl-|ql-|pt-|ads-)'                                       { return 'Brother' }
        '(?i)^(wf-|xp-|et-|l\d{3,}|sc-|lq-|fx-)'                                { return 'Epson' }
        '(?i)^(laserjet|officejet|deskjet|envy|designjet|pagewide|smart ?tank|neverstop)' { return 'HP' }
        '(?i)^(workcentre|versalink|altalink|phaser|colorqube)'                  { return 'Xerox' }
        '(?i)^(ecosys|taskalfa|fs-\d)'                                           { return 'Kyocera' }
        '(?i)^(bizhub)'                                                          { return 'Konica Minolta' }
        '(?i)^(aficio|sp \d|im c|mp c)'                                          { return 'Ricoh' }
        '(?i)^(e-?studio)'                                                       { return 'Toshiba' }
        '(?i)^(cx\d|mx\d|ms\d|ct\d)'                                             { return 'Lexmark' }
    }
    return $null
}

# ====================================================================

Write-Host ''
Write-Host '  [#-----] 1/6  Reading the print spooler...' -ForegroundColor Cyan

$queues = @(Get-CimInstance Win32_Printer)

$ports = @{}
Get-CimInstance Win32_TCPIPPrinterPort | ForEach-Object { $ports[$_.Name] = $_ }

$drivers = @{}
# Win32_PrinterDriver names look like "Brother MFC-J5955DW,3,Windows x64".
Get-CimInstance Win32_PrinterDriver | ForEach-Object { $drivers[($_.Name -split ',')[0]] = $_ }

Write-Host '  [##----] 2/6  Filtering out virtual and offline queues...' -ForegroundColor Cyan

$virtualRx = '(?i)(print to pdf|xps document writer|onenote|^fax$|shared fax|adobe pdf|cutepdf|' +
             'pdf24|foxit|bullzip|novapdf|primopdf|pdfcreator|snagit|\(redirected \d+\)|' +
             'remote desktop easy print|print to file|microsoft software printer)'
$virtualPortRx = '(?i)^(portprompt:|xpsport:|shrfax:|nul:?|file:|ts\d+$|onenote)'

$candidates = @()
foreach ($q in $queues) {
    if ($q.Name -match $virtualRx -or $q.DriverName -match $virtualRx -or $q.PortName -match $virtualPortRx) {
        Write-Host "         skipped (virtual):  $($q.Name)" -ForegroundColor DarkGray
        continue
    }
    if ($q.WorkOffline) {
        Write-Host "         skipped (offline):  $($q.Name)" -ForegroundColor DarkGray
        continue
    }
    $candidates += $q
}

Write-Host '  [###---] 3/6  Locating USB printers...' -ForegroundColor Cyan

# Map spooler port (USB001) -> PnP device, then walk up to the parent USB
# device whose instance ID ends with the real serial number.
$present = @{}
Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | ForEach-Object { $present[$_.InstanceId] = $true }
# On older Windows the PnpDevice module is absent. Without it we cannot prove
# a USB printer is unplugged, so we must not treat silence as "offline".
$havePnp = $present.Count -gt 0

# A composite device (printer + scanner + card reader in one box) hangs its
# functions off a shared container, and only the container's USB node carries
# the serial. Cache the USB tree once so we can look across it.
$usbNodes = @()
foreach ($d in @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
                 Where-Object { $_.InstanceId -like 'USB\VID_*' })) {
    $tail = CleanSerial ($d.InstanceId.Split('\')[-1])
    if (-not $tail) { continue }
    $cid = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_ContainerId' -ErrorAction SilentlyContinue).Data
    $usbNodes += [PSCustomObject]@{ InstanceId = $d.InstanceId; Serial = $tail; Container = "$cid" }
}

function UsbSerial($id, $childName) {
    # 1. the parent USB node - the normal case
    try {
        $parent = (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_Parent' -ErrorAction Stop).Data
        # Hub-enumerated devices use &-joined location strings, not serials.
        if ($parent) { $s = CleanSerial ($parent.Split('\')[-1]); if ($s) { return $s } }
    }
    catch { }
    # 2. a sibling function of the same physical device
    $cid = (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_ContainerId' -ErrorAction SilentlyContinue).Data
    if ($cid) {
        $hit = $usbNodes | Where-Object { $_.Container -eq "$cid" } | Select-Object -First 1
        if ($hit) { return $hit.Serial }
    }
    # 3. the USBPRINT key's own name, which on some drivers IS the serial
    return (CleanSerial $childName)
}

$usb = @{}
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBPRINT' -ErrorAction SilentlyContinue | ForEach-Object {
    $model = $_.PSChildName
    Get-ChildItem $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
        $port = (Get-ItemProperty "$($_.PSPath)\Device Parameters" -ErrorAction SilentlyContinue).PortName
        if (-not $port) { return }
        $id  = "USBPRINT\$model\$($_.PSChildName)"
        $usb[$port] = [PSCustomObject]@{
            Serial     = (UsbSerial $id $_.PSChildName)
            InstanceId = $id
            Online     = $present.ContainsKey($id)
        }
    }
}

# Address sources for everything that is not USB.
$portReg = ReadPortRegistry
$wsdDev  = ReadWsdDevices

# A port or queue name that happens to resolve in DNS is not proof we found
# the printer - some unrelated host can carry the same label, and querying it
# would hang a stranger's serial number on this asset. Only trust a guessed
# name if something is actually listening on a print port.
function VerifyPrinterIp($ip) {
    if (-not $ip) { return $null }
    foreach ($p in 9100, 631, 515) { if (TcpOpen $ip $p 600) { return $ip } }
    return $null
}

# The device record behind a print queue, and the address hiding in it. An
# IPP or WSD printer is installed as a software device, and the transport
# address is written to a sibling device in the same hardware container -
# never to the port, which is why Win32_TCPIPPrinterPort knows nothing.
function QueueDeviceIp($q) {
    $ids = @()
    $base = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers\$($q.Name)"
    foreach ($sub in "$base\PnPData", $base) {
        $p = Get-ItemProperty -LiteralPath $sub -ErrorAction SilentlyContinue
        if (-not $p) { continue }
        foreach ($n in 'DeviceInstanceId', 'DeviceInstanceID', 'PnPDeviceID') {
            if ($p.$n) { $ids += "$($p.$n)" }
        }
    }

    foreach ($id in ($ids | Select-Object -Unique)) {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Enum\$id"
        foreach ($s in (RegStrings $key 1)) {
            $ip = FirstIp $s
            if ($ip) { return $ip }
        }
        # Nothing on the queue's own device - try everything sharing its
        # container, which is where the WSD/IPP endpoint lives.
        $k = Get-Item -LiteralPath $key -ErrorAction SilentlyContinue
        if (-not $k) { continue }
        $cid = "$($k.GetValue('ContainerID'))"
        if (-not $cid) { continue }
        foreach ($prov in @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\SWD' -ErrorAction SilentlyContinue)) {
            foreach ($dev in @(Get-ChildItem -LiteralPath $prov.PSPath -ErrorAction SilentlyContinue)) {
                $dk = Get-Item -LiteralPath $dev.PSPath -ErrorAction SilentlyContinue
                if (-not $dk -or "$($dk.GetValue('ContainerID'))" -ne $cid) { continue }
                foreach ($s in (RegStrings $dev.PSPath 1)) {
                    $ip = FirstIp $s
                    if ($ip) { return $ip }
                }
            }
        }
    }
    return $null
}

# Returns {Ip, Mac} for a queue, trying every place Windows records one,
# most trustworthy first. Mac is only ever a hint from the WSD UUID; SNMP
# or ARP overrule it later.
function PrinterAddress($q, $port) {
    $ip = $null; $mac = ''
    $pn = "$($q.PortName)"

    # A queue served by another PC must never be probed here: the only
    # address we could find would be the print server's, and interrogating
    # that would file the server's details under the printer's name.
    if ($q.ServerName -or $pn -like '\\*') { return [PSCustomObject]@{ Ip = $null; Mac = '' } }

    if ($pn -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
        $mac = UuidMac $matches[1].ToLower()
    }

    if ($port) { $ip = ToIp $port.HostAddress }        # Standard TCP/IP port, via WMI
    if (-not $ip -and $portReg.ContainsKey($pn)) {     # any other port monitor, via registry
        $r = $portReg[$pn]
        if ($r.Ip) { $ip = $r.Ip } elseif ($r.HostName) { $ip = ToIp $r.HostName }
    }
    if (-not $ip) { $ip = FirstIp $pn }                # ports named after the address
    if (-not $ip) { $ip = FirstIp $q.Location }        # WSD writes its mex URL here
    if (-not $ip -and $pn -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
        $uuid = $matches[1].ToLower()
        if ($wsdDev.ContainsKey($uuid) -and $wsdDev[$uuid].Ip) { $ip = $wsdDev[$uuid].Ip }
    }
    if (-not $ip) {
        # The queue's own registry branch: DsSpooler, PnPData, port settings.
        foreach ($s in (RegStrings "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers\$($q.Name)" 2)) {
            $ip = FirstIp $s
            if ($ip) { break }
        }
    }
    if (-not $ip) { $ip = QueueDeviceIp $q }           # the IPP / WSD device record
    if (-not $ip) { $ip = FirstIp $q.Comment }
    if (-not $ip) {
        # A port named after the host: IP_printer01, printer01:9100, printer01_1
        $cand = ($pn -replace '(?i)^(ip|tcp|wsd|dnssd|http|socket)[_-]+', '') -replace '[:_].*$', ''
        if ($cand -and $cand -notmatch '[\\ ]' -and $cand.Length -ge 3) { $ip = VerifyPrinterIp (ToIp $cand) }
    }
    if (-not $ip -and $q.Name -notmatch '[\\ ]') { $ip = VerifyPrinterIp (ToIp $q.Name) }
    # Windows resolves an mDNS name for IPP printers installed by discovery.
    if (-not $ip -and $q.Name -notmatch '[\\]') {
        $ip = VerifyPrinterIp (ToIp (($q.Name -replace '\s+', '-') + '.local'))
    }
    return [PSCustomObject]@{ Ip = $ip; Mac = $mac }
}

$imaging = @(Get-CimInstance Win32_PnPEntity -Filter "PNPClass='Image'" | ForEach-Object { $_.Name })

Write-Host '  [####--] 4/6  Testing which printers are online...' -ForegroundColor Cyan

$rows = @()
foreach ($q in $candidates) {

    $port   = $ports[$q.PortName]
    $isUsb  = ($q.PortName -match '(?i)^(usb|dot4|lpt|com)\d*')
    $addr   = if ($isUsb) { [PSCustomObject]@{ Ip = $null; Mac = '' } } else { PrinterAddress $q $port }
    $ip     = $addr.Ip
    $online = $false
    $via    = ''

    if ($isUsb) {
        $u = $usb[$q.PortName]
        if ($u) {
            if ($u.Online -or -not $havePnp) { $online = $true; $via = 'USB device present' }
        }
        else {
            # No registry entry for this port - fall back to the spooler, which
            # already told us the queue is not marked offline.
            $online = $true; $via = 'USB port, spooler ready'
        }
    }
    elseif ($ip) {
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $online = $true; $via = 'ICMP'
        }
        else {
            # Plenty of printers drop ping but still answer on a print port.
            foreach ($p in 9100, 631, 515, 80) {
                if (TcpOpen $ip $p) { $online = $true; $via = "TCP/$p"; break }
            }
        }
    }
    elseif ($q.Network -and $q.ServerName) {
        $sip = ToIp ($q.ServerName -replace '^\\\\', '')
        if ($sip -and (TcpOpen $sip 445)) { $online = $true; $via = 'print server reachable' }
    }
    else {
        # WSD and other exotic ports expose no address to test. PrinterStatus
        # 3/4/5 = idle/printing/warmup, i.e. the spooler believes it is ready.
        if ($q.PrinterStatus -eq 3 -or $q.PrinterStatus -eq 4 -or $q.PrinterStatus -eq 5) {
            $online = $true; $via = 'spooler reports ready'
        }
    }

    if (-not $online) {
        Write-Host "         skipped (no answer): $($q.Name)" -ForegroundColor DarkGray
        continue
    }
    Write-Host "         online: $($q.Name)  [$via]" -ForegroundColor Green

    $rows += [PSCustomObject]@{ Q = $q; Ip = $ip; IsUsb = $isUsb; Via = $via; HintMac = $addr.Mac }
}

Write-Host '  [#####-] 5/6  Querying devices over SNMP...' -ForegroundColor Cyan

$assets = @()
foreach ($r in $rows) {
    $q = $r.Q

    $serial = ''; $mac = ''; $snmpModel = ''; $sysDescr = ''; $sysLoc = ''
    $colorants = 0; $pages = ''; $errBits = $null; $supplies = @()

    if ($r.IsUsb) {
        $u = $usb[$q.PortName]
        if ($u -and $u.Serial) { $serial = $u.Serial }
    }
    if ($r.Ip) {
        # Find a community and SNMP version that answer, using sysDescr.
        $comm = ''; $ver = 1
        foreach ($c in 'public', 'private') {
            foreach ($v in 1, 0) {
                $t = SnmpGet $r.Ip $c @('1.3.6.1.2.1.1.1.0') $v 900
                if ($t.Count -gt 0) { $comm = $c; $ver = $v; break }
            }
            if ($comm) { break }
        }

        if ($comm) {
            $g = SnmpGetMany $r.Ip $comm @(
                '1.3.6.1.2.1.1.1.0'             # sysDescr
                '1.3.6.1.2.1.1.6.0'             # sysLocation
                '1.3.6.1.2.1.43.5.1.1.17.1'     # prtGeneralSerialNumber
                '1.3.6.1.2.1.43.5.1.1.16.1'     # prtGeneralPrinterName
                '1.3.6.1.2.1.25.3.2.1.3.1'      # hrDeviceDescr
                '1.3.6.1.2.1.43.10.2.1.4.1.1'   # prtMarkerProcessColorants
                '1.3.6.1.2.1.43.10.2.1.7.1.1'   # prtMarkerLifeCount
                '1.3.6.1.2.1.25.3.5.1.2.1'      # hrPrinterDetectedErrorState
                '1.3.6.1.2.1.2.2.1.6.1'         # ifPhysAddress.1
                '1.3.6.1.2.1.2.2.1.6.2'         # ifPhysAddress.2
            ) $ver

            if ($g['1.3.6.1.2.1.1.1.0'])           { $sysDescr  = $g['1.3.6.1.2.1.1.1.0'].Value }
            if ($g['1.3.6.1.2.1.1.6.0'])           { $sysLoc    = $g['1.3.6.1.2.1.1.6.0'].Value }
            if ($g['1.3.6.1.2.1.43.5.1.1.17.1'])   { $serial    = CleanSerial $g['1.3.6.1.2.1.43.5.1.1.17.1'].Value }
            if ($g['1.3.6.1.2.1.43.5.1.1.16.1'])   { $snmpModel = $g['1.3.6.1.2.1.43.5.1.1.16.1'].Value }
            if (-not $snmpModel -and $g['1.3.6.1.2.1.25.3.2.1.3.1']) { $snmpModel = $g['1.3.6.1.2.1.25.3.2.1.3.1'].Value }
            if ($g['1.3.6.1.2.1.43.10.2.1.4.1.1']) { $colorants = [int]$g['1.3.6.1.2.1.43.10.2.1.4.1.1'].Value }
            if ($g['1.3.6.1.2.1.43.10.2.1.7.1.1']) { $pages     = $g['1.3.6.1.2.1.43.10.2.1.7.1.1'].Value }
            if ($g['1.3.6.1.2.1.25.3.5.1.2.1'])    { $errBits   = $g['1.3.6.1.2.1.25.3.5.1.2.1'].Raw }

            $snmpMac = ''
            foreach ($oid in '1.3.6.1.2.1.2.2.1.6.1', '1.3.6.1.2.1.2.2.1.6.2') {
                if ($snmpMac) { break }
                $v = $g[$oid]
                if ($v -and $v.Raw.Length -eq 6) {
                    $snmpMac = NormMac (($v.Raw | ForEach-Object { $_.ToString('x2') }) -join ':')
                }
            }
            # Interfaces are not always numbered 1 and 2 - loopback, USB gadget
            # and wireless entries push the real NIC further down the table.
            if (-not $snmpMac) {
                foreach ($v in (SnmpWalk $r.Ip $comm '1.3.6.1.2.1.2.2.1.6' $ver 8)) {
                    if ($v.Raw.Length -ne 6) { continue }
                    $snmpMac = NormMac (($v.Raw | ForEach-Object { $_.ToString('x2') }) -join ':')
                    if ($snmpMac) { break }
                }
            }
            if ($snmpMac) { $mac = $snmpMac }

            # Same story for the serial: the printer MIB is indexed by device,
            # and .1 is only a convention. Walk the column, then fall back to
            # the Entity MIB and finally to the vendor's private OID.
            if (-not $serial) {
                foreach ($root in '1.3.6.1.2.1.43.5.1.1.17', '1.3.6.1.2.1.47.1.1.1.1.11') {
                    foreach ($v in (SnmpWalk $r.Ip $comm $root $ver 6)) {
                        $serial = CleanSerial $v.Value
                        if ($serial) { break }
                    }
                    if ($serial) { break }
                }
            }
            if (-not $serial) {
                # Enterprise OIDs, tried oldest-and-most-common first. A device
                # that does not implement one simply answers "no such object".
                $vendorSerialOids = @(
                    '1.3.6.1.4.1.11.2.36.1.1.2.9.0'                  # HP
                    '1.3.6.1.4.1.11.2.4.3.1.7.0'                     # HP JetDirect
                    '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.1.0'           # Brother
                    '1.3.6.1.4.1.1602.1.2.1.4.0'                     # Canon
                    '1.3.6.1.4.1.1248.1.1.3.1.3.8.0'                 # Epson
                    '1.3.6.1.4.1.253.8.53.3.2.1.3.1'                 # Xerox
                    '1.3.6.1.4.1.641.2.1.2.1.6.1'                    # Lexmark
                    '1.3.6.1.4.1.1347.43.5.1.1.28.1'                 # Kyocera
                    '1.3.6.1.4.1.367.3.2.1.2.1.4.0'                  # Ricoh
                    '1.3.6.1.4.1.18334.1.1.1.5.5.1.1.3.1'            # Konica Minolta
                    '1.3.6.1.4.1.2001.1.1.1.1.11.1.10.45.0'          # OKI
                    '1.3.6.1.4.1.236.11.5.11.53.1.1.1.0'             # Samsung
                )
                $vs = SnmpGetMany $r.Ip $comm $vendorSerialOids $ver 1500
                foreach ($oid in $vendorSerialOids) {
                    if ($vs[$oid]) {
                        $serial = CleanSerial $vs[$oid].Value
                        if ($serial) { break }
                    }
                }
            }

            # Consumables: description / level / max share a row index.
            $s = SnmpGetMany $r.Ip $comm @(
                '1.3.6.1.2.1.43.11.1.1.6.1.1', '1.3.6.1.2.1.43.11.1.1.9.1.1', '1.3.6.1.2.1.43.11.1.1.8.1.1'
                '1.3.6.1.2.1.43.11.1.1.6.1.2', '1.3.6.1.2.1.43.11.1.1.9.1.2', '1.3.6.1.2.1.43.11.1.1.8.1.2'
                '1.3.6.1.2.1.43.11.1.1.6.1.3', '1.3.6.1.2.1.43.11.1.1.9.1.3', '1.3.6.1.2.1.43.11.1.1.8.1.3'
                '1.3.6.1.2.1.43.11.1.1.6.1.4', '1.3.6.1.2.1.43.11.1.1.9.1.4', '1.3.6.1.2.1.43.11.1.1.8.1.4'
            ) $ver
            foreach ($n in 1, 2, 3, 4) {
                $d = $s["1.3.6.1.2.1.43.11.1.1.6.1.$n"]
                $l = $s["1.3.6.1.2.1.43.11.1.1.9.1.$n"]
                $x = $s["1.3.6.1.2.1.43.11.1.1.8.1.$n"]
                if (-not $d -or -not $l -or -not $x) { continue }
                $lv = [int]$l.Value; $mx = [int]$x.Value
                # -1 unknown, -2 unsupported, -3 "some left"
                if ($mx -gt 0 -and $lv -ge 0) {
                    $supplies += [PSCustomObject]@{ Name = $d.Value; Pct = [math]::Round(100 * $lv / $mx) }
                }
            }
        }

        if (-not $mac) { $mac = ArpMac $r.Ip }
    }
    # Only if the device itself never told us: the WSD UUID's node field.
    if (-not $mac -and $r.HintMac) { $mac = $r.HintMac }

    # ---- derive the asset fields ------------------------------------

    $drv    = $drivers[$q.DriverName]

    # Windows increasingly installs printers on one of its own class drivers,
    # so DriverName says "Microsoft IPP Class Driver" for a Canon, an HP and a
    # Brother alike. When that happens the queue name is the better source -
    # Windows built it from the device's own advertised name.
    $genericDrvRx = '(?i)(ipp class driver|wsd print|class driver|mopria|universal print|' +
                    'generic ?/ ?text only|microsoft (enhanced point and print|shared))'
    $realDriver = ("$($q.DriverName)" -and "$($q.DriverName)" -notmatch $genericDrvRx)

    $vendor = Vendor $sysDescr
    if (-not $vendor) { $vendor = Vendor $snmpModel }
    if (-not $vendor -and $drv -and $realDriver) { $vendor = Vendor $drv.Manufacturer }
    if (-not $vendor -and $realDriver) { $vendor = Vendor $q.DriverName }
    if (-not $vendor) { $vendor = Vendor $q.Name }

    $model = CleanModel $snmpModel $vendor
    if (-not $model) { $model = CleanModel $sysDescr $vendor }
    if (-not $model -and $realDriver) { $model = CleanModel $q.DriverName $vendor }
    if (-not $model) { $model = CleanModel $q.Name $vendor }

    if (-not $vendor) { $vendor = VendorFromModel $model }

    # MFP if a scanner exists on this PC that looks like the same device,
    # or the model / SNMP description says so.
    $features = 'SFP'
    $needle = ($model -replace '[^A-Za-z0-9]', '')
    if ($needle.Length -ge 4 -and ($imaging | Where-Object { ($_ -replace '[^A-Za-z0-9]', '') -like "*$needle*" })) {
        $features = 'MFP'
    }
    elseif ("$model $sysDescr $($q.DriverName)" -match $mfpRx) { $features = 'MFP' }

    $colour = ''
    if ($colorants -gt 1) { $colour = 'Colour' }
    elseif ($colorants -eq 1) { $colour = 'B&W' }
    elseif ($supplies.Count -and (($supplies | ForEach-Object { $_.Name }) -join ' ') -match '(?i)cyan|magenta') { $colour = 'Colour' }
    elseif ($q.CapabilityDescriptions -match '(?i)color') { $colour = 'Colour' }
    elseif ($q.CapabilityDescriptions) { $colour = 'B&W' }

    # Condition is DERIVED - Windows has no such field. Faults outrank
    # consumables; a device we could not interrogate stays blank.
    $condition = ''; $note = ''
    $faults = @()
    if ($errBits -and $errBits.Length -ge 1) {
        $b = $errBits[0]
        if ($b -band 0x80) { $faults += 'low paper' }
        if ($b -band 0x40) { $faults += 'no paper' }
        if ($b -band 0x20) { $faults += 'low toner' }
        if ($b -band 0x10) { $faults += 'no toner' }
        if ($b -band 0x08) { $faults += 'door open' }
        if ($b -band 0x04) { $faults += 'jammed' }
        if ($b -band 0x02) { $faults += 'offline' }
        if ($b -band 0x01) { $faults += 'service requested' }
    }
    $hard = @($faults | Where-Object { $_ -match 'no toner|no paper|jam|door|service' })
    $low  = $null
    if ($supplies.Count) { $low = ($supplies | Measure-Object -Property Pct -Minimum).Minimum }

    if ($hard.Count)         { $condition = 'Poor'; $note = $hard -join ', ' }
    elseif ($faults.Count)   { $condition = 'Fair'; $note = $faults -join ', ' }
    elseif ($null -ne $low)  {
        if ($low -lt 10)     { $condition = 'Poor'; $note = "consumable at $low%" }
        elseif ($low -lt 25) { $condition = 'Fair'; $note = "consumable at $low%" }
        else                 { $condition = 'Good'; $note = "lowest consumable $low%" }
    }
    elseif ($sysDescr)       { $condition = 'Good'; $note = 'no faults reported' }

    $location = $q.Location
    if (-not $location) { $location = $sysLoc }

    # Asset tags are not a Windows concept. The only in-band source is an
    # admin who typed one into the printer's comment field.
    $tag = ''
    if ("$($q.Comment)" -match '(?i)\b(?:ID|AT|ASSET|TAG)[-_ ]?\d{2,8}\b') { $tag = $matches[0] }

    # Only a directly attached printer can be said to belong to this user.
    $assigned = ''
    if ($r.IsUsb) { $assigned = $user }

    $assets += [PSCustomObject]@{
        ComputerName = $pc
        Manufacturer = $vendor
        Model        = $model
        Features     = $features
        Colour       = $colour
        Condition    = $condition
        SerialNumber = $serial
        AssetTag     = $tag
        Location     = $location
        AssignedTo   = $assigned
        IPAddress    = $r.Ip
        MACAddress   = $mac
        PrinterName  = $q.Name
        Connection   = $(if ($r.IsUsb) { 'USB' }
                         elseif ($q.ServerName -or $q.PortName -like '\\*') { 'Shared' }
                         elseif ($r.Ip) { 'Network' } else { 'Other' })
        Port         = $q.PortName
        Driver       = $q.DriverName
        IsDefault    = [bool]$q.Default
        Shared       = [bool]$q.Shared
        PageCount    = $pages
        Supplies     = (@($supplies | ForEach-Object { "$($_.Name) $($_.Pct)%" }) -join '; ')
        ConditionNote= $note
        OnlineVia    = $r.Via
        CollectedOn  = $now
    }
}

Write-Host ''
Write-Host '===== PRINTERS =====' -ForegroundColor Cyan
if ($assets.Count) {
    Write-Host (($assets | Format-Table Manufacturer, Model, Features, Colour, Condition, SerialNumber,
                           AssetTag, Location, IPAddress, MACAddress -AutoSize -Wrap | Out-String).Trim())

    $gaps = $assets | Where-Object { -not $_.SerialNumber -or -not $_.MACAddress }
    foreach ($g in $gaps) {
        $miss = @()
        if (-not $g.SerialNumber) { $miss += 'serial' }
        if (-not $g.MACAddress)   { $miss += 'MAC' }
        $why = if ($g.Connection -eq 'USB')    { 'USB device publishes no serial anywhere in its PnP tree' }
               elseif ($g.Connection -eq 'Shared') { 'shared queue - run this on the print server' }
               elseif (-not $g.IPAddress) { 'no address to query - the port carries no host name or IP' }
               else { 'no SNMP reply (disabled, blocked, or non-default community)' }
        Write-Host "  no $($miss -join '/') for $($g.PrinterName) [port $($g.Port)] - $why" -ForegroundColor DarkYellow
    }
}
else {
    Write-Host 'No connected printers found on this machine.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '  [######] 6/6  Merging into the shared CSV file...' -ForegroundColor Cyan

# --------------------------------------------------------------------
# One file for the whole site. Ten PCs sharing three printers must end
# up as three rows, so every run reads what is already there, matches
# each printer against it, and only appends the ones nobody has seen.
# --------------------------------------------------------------------

$cols = @('ComputerName', 'Manufacturer', 'Model', 'Features', 'Colour', 'Condition',
          'SerialNumber', 'AssetTag', 'Location', 'AssignedTo', 'IPAddress', 'MACAddress',
          'PrinterName', 'Connection', 'Port', 'Driver', 'IsDefault', 'Shared',
          'PageCount', 'Supplies', 'ConditionNote', 'OnlineVia', 'CollectedOn')

# Values that describe the moment, not the device: a fresh reading wins.
# Everything else is only ever filled in when it was blank, so a PC that
# could not reach SNMP never wipes what another PC already found.
$volatile = @('Condition', 'ConditionNote', 'PageCount', 'Supplies', 'OnlineVia',
              'IPAddress', 'CollectedOn')

function ToRow($o) {
    $h = [ordered]@{}
    foreach ($c in $cols) {
        $v = $o.$c
        $h[$c] = if ($null -eq $v) { '' } else { "$v".Trim() }
    }
    return [PSCustomObject]$h
}

# The identities a row can be recognised by, best first. Any one of them
# matching an existing row means it is the same physical printer.
function AssetKeys($a) {
    $k = @()
    $sn = ("$($a.SerialNumber)" -replace '[^A-Za-z0-9]', '').ToUpper()
    if ($sn.Length -ge 4) { $k += "SN|$sn" }
    $mac = NormMac $a.MACAddress
    if ($mac) { $k += "MAC|$mac" }
    $mdl = ("$($a.Manufacturer)$($a.Model)" -replace '[^A-Za-z0-9]', '').ToUpper()
    if ($a.IPAddress) { $k += "IP|$($a.IPAddress)|$mdl" }
    if ("$($a.Connection)" -eq 'USB') {
        # A cable-attached printer that will not tell us its serial can only
        # be identified by the PC and port it hangs off - and the identical
        # model on the next desk is a different device, so keep them apart.
        foreach ($c in ("$($a.ComputerName)" -split ';')) {
            $c = $c.Trim().ToUpper()
            if ($c) { $k += "USB|$c|$($a.Port)|$mdl" }
        }
    }
    elseif ($mdl -or $a.PrinterName) {
        $k += "NM|$mdl|$("$($a.PrinterName)".ToUpper())"
    }
    return $k
}

function MergeInto($old, $new) {
    $h = [ordered]@{}
    foreach ($c in $cols) {
        $o = "$($old.$c)"; $n = "$($new.$c)"
        if ($c -eq 'ComputerName') {
            $seen = @($o -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            foreach ($x in ($n -split ';')) {
                $x = $x.Trim()
                if ($x -and ($seen -notcontains $x)) { $seen += $x }
            }
            $h[$c] = ($seen -join '; ')
        }
        elseif ($n -and ($volatile -contains $c -or -not $o)) { $h[$c] = $n }
        else { $h[$c] = $o }
    }
    return [PSCustomObject]$h
}

$added = 0; $matched = 0; $total = 0; $saved = $false; $lastErr = ''

if ($assets.Count -eq 0 -and (Test-Path -LiteralPath $out)) {
    Write-Host "Nothing to add - $out left untouched." -ForegroundColor Yellow
    $saved = $true
}

for ($try = 1; $try -le 5 -and -not $saved; $try++) {
    try {
        # Re-read on every attempt: another PC on the same share may have
        # appended a row while we were interrogating printers.
        $existing = @()
        if (Test-Path -LiteralPath $out) {
            $existing = @(Import-Csv -LiteralPath $out -Encoding UTF8 -ErrorAction Stop)
        }

        $merged = New-Object System.Collections.ArrayList
        $index  = @{}
        $added = 0; $matched = 0

        foreach ($e in $existing) {
            $row = ToRow $e
            $i = $merged.Add($row)
            foreach ($k in (AssetKeys $row)) { if (-not $index.ContainsKey($k)) { $index[$k] = $i } }
        }

        foreach ($a in $assets) {
            $row = ToRow $a
            $hit = -1
            foreach ($k in (AssetKeys $row)) {
                if ($index.ContainsKey($k)) { $hit = $index[$k]; break }
            }
            if ($hit -ge 0) {
                $merged[$hit] = MergeInto $merged[$hit] $row
                $matched++
            }
            else {
                $hit = $merged.Add($row)
                $added++
            }
            # New serial or MAC learned from this PC becomes a match key too.
            foreach ($k in (AssetKeys $merged[$hit])) { if (-not $index.ContainsKey($k)) { $index[$k] = $hit } }
        }

        $total = $merged.Count
        if ($total -gt 0) {
            $merged | Select-Object $cols | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        }
        else {
            # No printers anywhere yet - still leave a file with headers so the
            # next PC has something to merge into.
            Set-Content -Path $out -Value ('"' + ($cols -join '","') + '"') -Encoding UTF8 -ErrorAction Stop
        }
        $saved = $true
    }
    catch {
        $lastErr = $_.Exception.Message
        Start-Sleep -Milliseconds (300 * $try)
    }
}

if ($saved -and $assets.Count) {
    Write-Host ("Saved printers: $out") -ForegroundColor Green
    Write-Host ("  $added new, $matched already listed (merged), $total printers in the file.") -ForegroundColor Green
}
elseif (-not $saved) {
    Write-Host ('ERROR: ' + $lastErr) -ForegroundColor Red
    Write-Host 'If the CSV file is open in Excel or locked by another PC, close it and run this again.' -ForegroundColor Yellow
}


#::ENDCODE::#

#::PS3CODE::#

# ===================== upgrate wizart ===============================
# Everything below runs as PowerShell. The batch part above extracts
# it from this same file, so there is still only one file to copy.
#
# Answers "what can we upgrade in this box?" without opening the case:
#   - how many memory slots the board has, used, free, and the maximum
#     it reports it supports, plus what sits in each populated slot so
#     an added module can be matched
#
# One row, one file. The per-slot and per-drive detail is printed to the
# screen while you are standing at the machine, but the sheet stays one
# line per PC so a whole site collates into a single list.
#   - what drives are fitted, HDD or SSD, on what bus, how healthy they
#     are, and how much room is left for another one
#   - whether the machine can take Windows 11, so a box that is not
#     worth parts is visible before the parts are ordered
#
# This PC only. Firmware does not report empty drive bays or empty
# memory slot names, so those are derived - see the Notes column.

$ErrorActionPreference = 'SilentlyContinue'

# Same rule as the other collectors: numbers always use '.' as the
# decimal mark, so files from Greek and English machines merge cleanly.
[Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

# The launcher sets these. Falling back to the working directory is a last
# resort only: started from a UNC path, cmd drops us in C:\Windows.
$outFile = $env:UPGRATE
if (-not $outFile) { $outFile = Join-Path (Get-Location).Path "$($env:COMPUTERNAME)_Upgrate.csv" }

# ---------------------------------------------------------------- lookups ---

# SMBIOS 7.18.2 Memory Device - Type. Win32_PhysicalMemory.MemoryType is 0 on
# most modern boards, so SMBIOSMemoryType is the one worth reading.
$MemoryTypeMap = @{
    0 = 'Unknown'; 1 = 'Other'; 2 = 'Unknown'; 3 = 'DRAM'; 4 = 'EDRAM'
    5 = 'VRAM'; 6 = 'SRAM'; 7 = 'RAM'; 8 = 'ROM'; 9 = 'FLASH'; 10 = 'EEPROM'
    11 = 'FEPROM'; 12 = 'EPROM'; 13 = 'CDRAM'; 14 = '3DRAM'; 15 = 'SDRAM'
    16 = 'SGRAM'; 17 = 'RDRAM'; 18 = 'DDR'; 19 = 'DDR2'; 20 = 'DDR2 FB-DIMM'
    24 = 'DDR3'; 25 = 'FBD2'; 26 = 'DDR4'; 27 = 'LPDDR'; 28 = 'LPDDR2'
    29 = 'LPDDR3'; 30 = 'LPDDR4'; 31 = 'Logical non-volatile'; 32 = 'HBM'
    33 = 'HBM2'; 34 = 'DDR5'; 35 = 'LPDDR5'
}

$FormFactorMap = @{
    0 = 'Unknown'; 1 = 'Other'; 2 = 'SIP'; 3 = 'DIP'; 4 = 'ZIP'; 5 = 'SOJ'
    6 = 'Proprietary'; 7 = 'SIMM'; 8 = 'DIMM'; 9 = 'TSOP'; 10 = 'PGA'
    11 = 'RIMM'; 12 = 'SODIMM'; 13 = 'SRIMM'; 14 = 'SMD'; 15 = 'SSMP'
    16 = 'QFP'; 17 = 'TQFP'; 18 = 'SOIC'; 19 = 'LCC'; 20 = 'PLCC'; 21 = 'BGA'
    22 = 'FPBGA'; 23 = 'LGA'
}

# MSFT_PhysicalDisk numeric enums. The string properties are not present on
# every Windows build, so the numbers are what we read.
$MediaTypeMap = @{ 0 = 'Unspecified'; 3 = 'HDD'; 4 = 'SSD'; 5 = 'SCM' }
$BusTypeMap   = @{
    0 = 'Unknown'; 1 = 'SCSI'; 2 = 'ATAPI'; 3 = 'ATA'; 4 = '1394'; 5 = 'SSA'
    6 = 'Fibre Channel'; 7 = 'USB'; 8 = 'RAID'; 9 = 'iSCSI'; 10 = 'SAS'
    11 = 'SATA'; 12 = 'SD'; 13 = 'MMC'; 15 = 'File Backed Virtual'
    16 = 'Storage Spaces'; 17 = 'NVMe'
}
$HealthMap = @{ 0 = 'Healthy'; 1 = 'Warning'; 2 = 'Unhealthy'; 5 = 'Unknown' }

# Win32_SystemEnclosure.ChassisTypes values that mean "portable".
$LaptopChassis = @(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32)

# Typical internal 2.5"/3.5" bay count per chassis type. Firmware never
# reports bays, so this is the published norm for the form factor and is
# labelled an estimate everywhere it is used.
$ChassisBayMap = @{
    3 = 4; 4 = 2; 5 = 2; 6 = 4; 7 = 4; 13 = 2; 15 = 2; 16 = 2; 17 = 4
    23 = 4; 24 = 4; 8 = 1; 9 = 1; 10 = 1; 11 = 1; 12 = 1; 14 = 1; 18 = 1
    21 = 1; 30 = 1; 31 = 1; 32 = 1; 35 = 1
}
$ChassisNameMap = @{
    1 = 'Other'; 2 = 'Unknown'; 3 = 'Desktop'; 4 = 'Low Profile Desktop'
    5 = 'Pizza Box'; 6 = 'Mini Tower'; 7 = 'Tower'; 8 = 'Portable'
    9 = 'Laptop'; 10 = 'Notebook'; 11 = 'Hand Held'; 12 = 'Docking Station'
    13 = 'All in One'; 14 = 'Sub Notebook'; 15 = 'Space-saving'
    16 = 'Lunch Box'; 17 = 'Main System Chassis'; 18 = 'Expansion Chassis'
    21 = 'Peripheral Chassis'; 23 = 'Rack Mount Chassis'; 24 = 'Sealed-case PC'
    30 = 'Tablet'; 31 = 'Convertible'; 32 = 'Detachable'; 35 = 'Mini PC'
}

function Get-MapValue {
    param($Map, $Key, [string]$Fallback = 'Unknown')
    if ($null -ne $Key -and $Map.ContainsKey([int]$Key)) { return $Map[[int]$Key] }
    return $Fallback
}

# -------------------------------------------------------------- collection ---

$now = Get-Date -Format 'yyyy-MM-dd HH:mm K'
$notes = @()

Write-Host ''
Write-Host '  [#----] 1/5  Reading system, board and chassis...' -ForegroundColor Cyan

$cs    = Get-CimInstance Win32_ComputerSystem
$os    = Get-CimInstance Win32_OperatingSystem
$bios  = Get-CimInstance Win32_BIOS
$cpu   = Get-CimInstance Win32_Processor | Select-Object -First 1
$board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
$enc   = Get-CimInstance Win32_SystemEnclosure | Select-Object -First 1

$chassis     = ''
$chassisName = 'Unknown'
$isLaptop    = $false
$chassisCode = $null
if ($enc -and $enc.ChassisTypes) {
    $chassis     = (@($enc.ChassisTypes) -join ',')
    $chassisCode = @($enc.ChassisTypes)[0]
    $chassisName = Get-MapValue $ChassisNameMap $chassisCode
    $isLaptop    = @($enc.ChassisTypes | Where-Object { $_ -in $LaptopChassis }).Count -gt 0
}

# ------------------------------------------------------------------ memory ---

Write-Host '  [##---] 2/5  Reading memory slots...' -ForegroundColor Cyan

# Use = 3 is "System Memory"; video/flash arrays would skew the slot count.
$arrays = @(Get-CimInstance Win32_PhysicalMemoryArray)
$sysArrays = @($arrays | Where-Object { $_.Use -eq 3 })
if ($sysArrays.Count -gt 0) { $arrays = $sysArrays }

$slots = 0
$maxKB = [uint64]0
foreach ($a in $arrays) {
    if ($a.MemoryDevices) { $slots += [int]$a.MemoryDevices }
    # MaxCapacity is a UINT32 of KB and saturates at ~2 TB; MaxCapacityEx
    # (Win8/2012 and later) carries the real value when it does.
    if ($a.PSObject.Properties['MaxCapacityEx'] -and $a.MaxCapacityEx -gt 0) {
        $maxKB += [uint64]$a.MaxCapacityEx
    } elseif ($a.MaxCapacity -gt 0) {
        $maxKB += [uint64]$a.MaxCapacity
    }
}
$maxGB = [int][math]::Round($maxKB / 1MB, 0)

$mods = @(Get-CimInstance Win32_PhysicalMemory)
$installedBytes = ($mods | Measure-Object -Property Capacity -Sum).Sum
if (-not $installedBytes) { $installedBytes = $cs.TotalPhysicalMemory }
# Same snap as the inventory collector: Win32_ComputerSystem reports slightly
# less than the fitted total, and a 16 GB PC reading 15 in one file and 16 in
# the other is the kind of thing that costs an hour later.
$installedRaw = $installedBytes / 1GB
$installedGB  = [int][math]::Round($installedRaw)
$tolRam       = [math]::Max(0.5, $installedRaw * 0.06)
foreach ($sz in 1, 2, 3, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96, 128, 192, 256, 384, 512, 768, 1024) {
    if ($sz -ge $installedRaw -and ($sz - $installedRaw) -le $tolRam) { $installedGB = $sz; break }
}

$used = $mods.Count
if ($slots -lt $used) { $slots = $used }   # board under-reported its own slots
$free = $slots - $used

$types  = @($mods | ForEach-Object { Get-MapValue $MemoryTypeMap $_.SMBIOSMemoryType } | Select-Object -Unique)
$speeds = @($mods | Where-Object { $_.Speed } | ForEach-Object { [int]$_.Speed } | Select-Object -Unique)
$sizes  = @($mods | ForEach-Object { [int][math]::Round($_.Capacity / 1GB, 0) } | Select-Object -Unique)
$forms  = @($mods | ForEach-Object { Get-MapValue $FormFactorMap $_.FormFactor } | Select-Object -Unique)

$configured = @($mods |
    Where-Object { $_.PSObject.Properties['ConfiguredClockSpeed'] -and $_.ConfiguredClockSpeed } |
    ForEach-Object { [int]$_.ConfiguredClockSpeed } | Select-Object -Unique)

$mixed = ($types.Count -gt 1) -or ($speeds.Count -gt 1) -or ($sizes.Count -gt 1)

$perSlot = 0
if ($slots -gt 0 -and $maxGB -gt 0) { $perSlot = [int][math]::Floor($maxGB / $slots) }
$headroom = [math]::Max(0, $maxGB - $installedGB)

$typeLabel  = ($types -join '/')
$speedLabel = if ($speeds.Count) { ($speeds -join '/') } else { '?' }

if ($maxGB -le 0) {
    $ramPath = "Unknown - board reported no maximum; check vendor spec for $($cs.Model) / $($bios.SerialNumber)"
} elseif ($headroom -le 0) {
    $ramPath = "At maximum ($maxGB GB) - no upgrade possible"
} elseif ($free -gt 0) {
    $ramPath = "Add up to $headroom GB across $free free slot(s); match $typeLabel $speedLabel MT/s $($forms -join '/')"
} else {
    $ramPath = "All $slots slots full - replace modules; up to $perSlot GB per slot to reach $maxGB GB"
}

if ($maxGB -gt 0 -and $maxGB -le $installedGB -and $free -gt 0) {
    $notes += 'SMBIOS max capacity looks wrong (reports <= installed while slots are free) - verify against vendor spec'
}
if ($maxGB -le 0) {
    $notes += 'No maximum reported by SMBIOS'
}
if ($os.OSArchitecture -match '32') {
    $notes += '32-bit Windows - cannot address more than ~3.5 GB regardless of slots'
}
if ($os.Caption -match 'Home' -and $maxGB -gt 128) {
    $notes += 'Windows Home edition is capped at 128 GB'
}
if ($isLaptop -and $free -eq 0 -and $used -le 1) {
    $notes += 'Portable chassis with a single reported device - memory may be soldered; confirm before ordering'
}
if ($mixed) {
    $notes += 'Mixed modules installed (size/type/speed differ) - may be running below rated speed'
}
if ($configured.Count -and $speeds.Count -and ($configured | Measure-Object -Minimum).Minimum -lt ($speeds | Measure-Object -Maximum).Maximum) {
    $notes += 'Modules running below their rated speed'
}
if ($free -gt 0) {
    $notes += 'WMI reports only populated memory devices, so empty slot rows are counted, not named'
}

# ----------------------------------------------------------------- storage ---

Write-Host '  [###--] 3/5  Reading drives and bays...' -ForegroundColor Cyan

# Win32_DiskDrive is the one class present on every Windows we touch.
# MSFT_PhysicalDisk adds HDD-vs-SSD, bus type and health, and joins on
# DeviceId = Win32_DiskDrive.Index, so we read both and merge.
$physMap = @{}
foreach ($p in @(Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_PhysicalDisk)) {
    if ($null -ne $p.DeviceId) { $physMap["$($p.DeviceId)"] = $p }
}
# Without it (pre-Windows 8, or a locked-down box) HDD-vs-SSD and bus type are
# guesses off the model name, and a "No" in those columns is not a finding.
$storageNs = $physMap.Count -gt 0

# One SMART reading for the whole box: matching a failure-predict instance
# back to a specific disk is not reliable, but "something is predicting
# failure here" is worth carrying.
$smartRows    = @(Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus)
$smartRead    = $smartRows.Count -gt 0
$smartFailing = @($smartRows | Where-Object { $_.PredictFailure }).Count

$drives    = @(Get-CimInstance Win32_DiskDrive | Sort-Object Index)
$driveRows = @()
$internalCount = 0
$hasHDD  = $false
$hasNVMe = $false
$sysDiskGB = 0

foreach ($d in $drives) {
    $p = $physMap["$($d.Index)"]

    $media = 'Unknown'
    if ($p) { $media = Get-MapValue $MediaTypeMap $p.MediaType }
    # Pre-Win8 boxes have no MSFT_PhysicalDisk. A spindle speed of 0 on a
    # rotating-media class is the other honest hint that it is an SSD.
    if ($media -in @('Unknown', 'Unspecified')) {
        if ($p -and $p.PSObject.Properties['SpindleSpeed'] -and $p.SpindleSpeed -eq 0) { $media = 'SSD' }
        elseif ($d.Model -match 'SSD|NVMe|Solid.?State') { $media = 'SSD' }
    }

    $bus = if ($p) { Get-MapValue $BusTypeMap $p.BusType } else { "$($d.InterfaceType)" }
    if ($bus -in @('Unknown', '')) { $bus = "$($d.InterfaceType)" }

    $health = if ($p) { Get-MapValue $HealthMap $p.HealthStatus } else { '' }

    $isInternal = ($bus -ne 'USB') -and ($d.InterfaceType -ne 'USB') -and ($bus -ne 'SD') -and ($bus -ne 'MMC')
    if ($isInternal) {
        $internalCount++
        if ($media -eq 'HDD') { $hasHDD = $true }
        if ($bus -eq 'NVMe')  { $hasNVMe = $true }
    }

    $sizeGB = [int][math]::Round($d.Size / 1GB, 0)

    # Walk disk -> partition -> logical disk so the sheet shows which letters
    # live on which spindle and how much room is left on each.
    $vols = @()
    $isSystem = $false
    foreach ($part in @(Get-CimAssociatedInstance -InputObject $d -ResultClassName Win32_DiskPartition)) {
        if ($part.BootPartition) { $isSystem = $true }
        foreach ($ld in @(Get-CimAssociatedInstance -InputObject $part -ResultClassName Win32_LogicalDisk)) {
            $ldSize = [math]::Round($ld.Size / 1GB, 1)
            $ldFree = [math]::Round($ld.FreeSpace / 1GB, 1)
            $vols += "$($ld.DeviceID) $ldFree of $ldSize GB free"
            if ($ld.DeviceID -eq $env:SystemDrive) { $isSystem = $true }
        }
    }
    if ($isSystem -and $sizeGB -gt $sysDiskGB) { $sysDiskGB = $sizeGB }

    $driveRows += [PSCustomObject]@{
        ComputerName  = $cs.Name
        DiskNumber    = $d.Index
        Model         = ("$($d.Model)").Trim()
        'Size(GB)'    = $sizeGB
        MediaType     = $media
        BusType       = $bus
        Internal      = $(if ($isInternal) { 'Yes' } else { 'No' })
        SystemDisk    = $(if ($isSystem) { 'Yes' } else { 'No' })
        Health        = $health
        Partitions    = $d.Partitions
        Volumes       = ($vols -join '; ')
        SerialNumber  = ("$($d.SerialNumber)").Trim()
        FirmwareRev   = ("$($d.FirmwareRevision)").Trim()
        CollectedOn   = $now
    }
}

$optical = @(Get-CimInstance Win32_CDROMDrive | Where-Object { $_.Drive }).Count

# Firmware exposes no bay count, so this is the published norm for the
# chassis type minus what is already fitted. Always labelled an estimate.
$estBays = $null
if ($null -ne $chassisCode -and $ChassisBayMap.ContainsKey([int]$chassisCode)) {
    $estBays = [int]$ChassisBayMap[[int]$chassisCode]
}
if ($null -ne $estBays -and $estBays -lt $internalCount) { $estBays = $internalCount }

$estBaysLabel = ''
$freeBaysLabel = ''
if ($null -ne $estBays) {
    $estFree = [math]::Max(0, $estBays - $internalCount)
    $estBaysLabel  = "$estBays (typical for $chassisName)"
    $freeBaysLabel = "$estFree (estimate)"
} else {
    $estBaysLabel  = "Unknown ($chassisName chassis)"
    $freeBaysLabel = 'Unknown'
}

$storParts = @()
if ($null -ne $estBays) {
    $estFree = [math]::Max(0, $estBays - $internalCount)
    if ($estFree -gt 0) {
        $storParts += "About $estFree free drive bay(s) for a $chassisName - confirm by opening the case"
    } else {
        $storParts += "No spare bay expected in a $chassisName with $internalCount drive(s) fitted"
    }
} else {
    $storParts += "Bay count not reported by firmware for this chassis - confirm by opening the case"
}
if ($optical -gt 0) {
    $storParts += "$optical optical drive(s) fitted - that bay takes a caddy if a drive is needed"
}
if (-not $hasNVMe -and $storageNs) {
    $storParts += 'No NVMe drive fitted - check the board for a free M.2 slot'
}
if ($hasHDD) {
    $storParts += 'Spinning disk fitted - an SSD swap is the cheapest change available'
}
$storPath = ($storParts -join '; ')

$notes += 'Drive bays are not reported by firmware - the bay figures are estimated from the chassis type'
if (-not $storageNs) {
    $notes += 'Storage namespace unavailable - HDD/SSD and bus type are guessed from the model name'
}
if ($smartRead -and $smartFailing -gt 0) {
    $notes += "SMART is predicting failure on $smartFailing drive(s) - back up before doing anything else"
}
if (-not $smartRead) {
    $notes += 'SMART status could not be read (needs administrator) - the drive-failure column is not a clean bill of health'
}
if (@($driveRows | Where-Object { $_.Health -eq 'Unhealthy' -or $_.Health -eq 'Warning' }).Count -gt 0) {
    $notes += 'A drive reports less than healthy status'
}

# -------------------------------------------------------- windows 11 check ---

Write-Host '  [####-] 4/5  Checking Windows 11 readiness...' -ForegroundColor Cyan

$blockers = @()
$unknowns = @()

# TPM lives in its own namespace and needs an elevated read; a failure here
# is "we could not tell", not "there is no TPM".
$tpmVersion = 'Unknown'
$tpmReady   = $null
$tpm = Get-CimInstance -Namespace root\cimv2\Security\MicrosoftTpm -ClassName Win32_Tpm -ErrorAction SilentlyContinue | Select-Object -First 1
if ($tpm) {
    $tpmVersion = (("$($tpm.SpecVersion)") -split ',')[0].Trim()
    $enabled = $true
    if ($tpm.PSObject.Properties['IsEnabled_InitialValue'])   { $enabled = $enabled -and [bool]$tpm.IsEnabled_InitialValue }
    if ($tpm.PSObject.Properties['IsActivated_InitialValue']) { $enabled = $enabled -and [bool]$tpm.IsActivated_InitialValue }
    $tpmReady = ($tpmVersion -match '^2') -and $enabled
    if (-not $tpmReady) {
        if ($tpmVersion -match '^2') { $blockers += 'TPM 2.0 present but not enabled/activated in firmware' }
        else { $blockers += "TPM $tpmVersion - Windows 11 needs 2.0" }
    }
} else {
    $tpmVersion = 'Not detected'
    $unknowns  += 'TPM could not be read (run as administrator, or there is no TPM)'
}

# Windows only creates this key on UEFI firmware, so its absence is itself
# the answer for boot mode on older boxes.
$secureBoot = 'Unknown'
$sbState = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction SilentlyContinue
if ($sbState -and $null -ne $sbState.UEFISecureBootEnabled) {
    $secureBoot = $(if ($sbState.UEFISecureBootEnabled -eq 1) { 'On' } else { 'Off' })
}

$bootMode = "$env:firmware_type"
if (-not $bootMode -or $bootMode -eq 'Unknown') {
    $bootMode = $(if ($sbState) { 'UEFI' } else { 'Unknown' })
}
if ($bootMode -eq 'Legacy') { $blockers += 'Legacy BIOS boot - Windows 11 needs UEFI (disk would need MBR to GPT conversion)' }
elseif ($bootMode -ne 'UEFI') { $unknowns += 'Boot mode could not be determined' }

# On legacy firmware there is nothing to read rather than something we failed
# to read, and "could not tell" would drag Win11Ready down to Unknown for it.
if ($secureBoot -eq 'Unknown' -and $bootMode -eq 'Legacy') { $secureBoot = 'Not supported (legacy BIOS)' }

if ($secureBoot -eq 'Off') { $blockers += 'Secure Boot is off - supported by the firmware but needs enabling' }
elseif ($secureBoot -eq 'Unknown') { $unknowns += 'Secure Boot state could not be read' }

# GPT is required for a UEFI install; MBR means a conversion step, not a wall.
$partStyle = 'Unknown'
$sysDisk = Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_Disk |
    Where-Object { $_.IsSystem -or $_.IsBoot } | Select-Object -First 1
if ($sysDisk) {
    $partStyle = switch ([int]$sysDisk.PartitionStyle) { 1 { 'MBR' } 2 { 'GPT' } default { 'Unknown' } }
}
if ($partStyle -eq 'MBR') { $blockers += 'System disk is MBR - needs converting to GPT for a UEFI install' }

if ($installedGB -lt 4) { $blockers += "RAM is $installedGB GB - Windows 11 needs 4 GB" }
if ($sysDiskGB -gt 0 -and $sysDiskGB -lt 64) { $blockers += "System disk is $sysDiskGB GB - Windows 11 needs 64 GB" }

$cpuName  = ("$($cpu.Name)").Trim()
$cpuCores = $cpu.NumberOfCores
$cpuMHz   = $cpu.MaxClockSpeed
if ($cpuCores -and $cpuCores -lt 2) { $blockers += "CPU has $cpuCores core - Windows 11 needs 2" }
if ($cpuMHz -and $cpuMHz -lt 1000) { $blockers += "CPU is $cpuMHz MHz - Windows 11 needs 1 GHz" }
if ($os.OSArchitecture -match '32') { $blockers += '32-bit Windows - Windows 11 is 64-bit only' }

# Microsoft's supported-CPU list is thousands of entries long and changes.
# The generation cut is the part that decides almost every real machine, so
# that is what is checked, and it is reported as the estimate it is.
$cpuGen = 'Unknown'
if ($cpuName -match 'i[3579][- ](\d{4,5})([A-Z]*\d*)') {
    $num = $matches[1]
    $sfx = $matches[2]
    if ($num.Length -eq 5) {
        $gen = [int]$num.Substring(0, 2)          # 10210U, 12400 -> 10, 12
    } elseif ($sfx -match '^G\d') {
        $gen = 10                                 # Ice Lake: 1035G1 is 10th gen
    } else {
        $gen = [int]$num.Substring(0, 1)          # 8250, 4570 -> 8, 4
    }
    $cpuGen = $(if ($gen -ge 8) { 'Supported' } else { 'Too old' })
} elseif ($cpuName -match 'Ryzen \d+ (\d{4})') {
    $cpuGen = $(if ([int]$matches[1] -ge 2000) { 'Supported' } else { 'Too old' })
} elseif ($cpuName -match 'Ultra \d+ \d{3}') {
    $cpuGen = 'Supported'
}
if ($cpuGen -eq 'Too old') { $blockers += "$cpuName is below the Windows 11 generation cut (Intel 8th gen / AMD Ryzen 2000)" }
elseif ($cpuGen -eq 'Unknown') { $unknowns += "CPU model not recognised by the generation check - verify $cpuName against Microsoft's list" }

if ($blockers.Count -gt 0)      { $win11 = 'No' }
elseif ($unknowns.Count -gt 0)  { $win11 = 'Unknown' }
else                            { $win11 = 'Yes' }

if ($os.Caption -match 'Windows 11') { $win11 = 'Already on 11' }

$win11Notes = @($blockers + $unknowns) -join '; '

# ------------------------------------------------------------------ output ---

$boardMfr  = if ($board) { $board.Manufacturer } else { '' }
$boardProd = if ($board) { $board.Product } else { '' }
$configuredLabel = if ($configured.Count) { ($configured -join '/') } else { '' }

$summary = [PSCustomObject]@{
    ComputerName            = $cs.Name
    Manufacturer            = $cs.Manufacturer
    Model                   = $cs.Model
    SerialNumber            = $bios.SerialNumber
    BoardManufacturer       = $boardMfr
    BoardProduct            = $boardProd
    ChassisType             = $chassisName
    ChassisCodes            = $chassis
    OperatingSystem         = $os.Caption
    OSVersion               = $os.Version
    OSArchitecture          = $os.OSArchitecture
    CPU                     = $cpuName
    CPUCores                = $cpuCores
    MemorySlotsTotal        = $slots
    MemorySlotsUsed         = $used
    MemorySlotsFree         = $free
    'InstalledRAM(GB)'      = $installedGB
    'MaxSupportedRAM(GB)'   = $maxGB
    'Headroom(GB)'          = $headroom
    'MaxPerSlot(GB)'        = $perSlot
    MemoryType              = $typeLabel
    FormFactor              = ($forms -join '/')
    'RatedSpeed(MT/s)'      = $speedLabel
    'ConfiguredSpeed(MT/s)' = $configuredLabel
    MixedModules            = $mixed
    DrivesInternal          = $internalCount
    OpticalDrives           = $optical
    EstimatedDriveBays      = $estBaysLabel
    EstimatedFreeBays       = $freeBaysLabel
    HasHDD                  = $(if ($hasHDD) { 'Yes' } elseif ($storageNs) { 'No' } else { 'Unknown' })
    HasNVMe                 = $(if ($hasNVMe) { 'Yes' } elseif ($storageNs) { 'No' } else { 'Unknown' })
    'SystemDisk(GB)'        = $sysDiskGB
    SmartFailingDrives      = $(if ($smartRead) { $smartFailing } else { 'Not read' })
    StorageUpgradePath      = $storPath
    TPMVersion              = $tpmVersion
    SecureBoot              = $secureBoot
    BootMode                = $bootMode
    SystemDiskPartitionStyle = $partStyle
    CPUGenerationCheck      = $cpuGen
    Win11Ready              = $win11
    Win11Notes              = $win11Notes
    Notes                   = ($notes -join '; ')
    CollectedOn             = $now
}

$memRows = @()
$n = 0
foreach ($m in ($mods | Sort-Object DeviceLocator)) {
    $n++
    $modConfigured = if ($m.PSObject.Properties['ConfiguredClockSpeed']) { $m.ConfiguredClockSpeed } else { '' }
    $memRows += [PSCustomObject]@{
        ComputerName            = $cs.Name
        SlotNumber              = $n
        State                   = 'Populated'
        BankLabel               = $m.BankLabel
        DeviceLocator           = $m.DeviceLocator
        'Capacity(GB)'          = [int][math]::Round($m.Capacity / 1GB, 0)
        MemoryType              = (Get-MapValue $MemoryTypeMap $m.SMBIOSMemoryType)
        FormFactor              = (Get-MapValue $FormFactorMap $m.FormFactor)
        'RatedSpeed(MT/s)'      = $m.Speed
        'ConfiguredSpeed(MT/s)' = $modConfigured
        Manufacturer            = ("$($m.Manufacturer)").Trim()
        PartNumber              = ("$($m.PartNumber)").Trim()
        SerialNumber            = ("$($m.SerialNumber)").Trim()
        CollectedOn             = $now
    }
}

# WMI only reports populated devices, so empty slots are a count, not a
# locator. These placeholder rows make occupancy visible in the sheet.
for ($i = 0; $i -lt $free; $i++) {
    $n++
    $memRows += [PSCustomObject]@{
        ComputerName            = $cs.Name
        SlotNumber              = $n
        State                   = 'Empty'
        BankLabel               = ''
        DeviceLocator           = '(empty - locator not reported by WMI)'
        'Capacity(GB)'          = 0
        MemoryType              = ''
        FormFactor              = ''
        'RatedSpeed(MT/s)'      = ''
        'ConfiguredSpeed(MT/s)' = ''
        Manufacturer            = ''
        PartNumber              = ''
        SerialNumber            = ''
        CollectedOn             = $now
    }
}

Write-Host ''
Write-Host ("===== {0} =====" -f $cs.Name) -ForegroundColor Cyan
Write-Host (($summary | Select-Object Manufacturer, Model, SerialNumber, BoardProduct, ChassisType,
    MemorySlotsTotal, MemorySlotsUsed, MemorySlotsFree,
    'InstalledRAM(GB)', 'MaxSupportedRAM(GB)', 'Headroom(GB)', 'MaxPerSlot(GB)',
    MemoryType, FormFactor, 'RatedSpeed(MT/s)', 'ConfiguredSpeed(MT/s)' |
    Format-List | Out-String).Trim())
Write-Host ''
Write-Host '===== MEMORY SLOTS =====' -ForegroundColor Cyan
Write-Host (($memRows | Select-Object SlotNumber, State, DeviceLocator, 'Capacity(GB)', MemoryType,
    'RatedSpeed(MT/s)', Manufacturer, PartNumber |
    Format-Table -AutoSize | Out-String).Trim())
Write-Host ''
Write-Host '===== DRIVES =====' -ForegroundColor Cyan
if ($driveRows.Count) {
    Write-Host (($driveRows | Select-Object DiskNumber, Model, 'Size(GB)', MediaType, BusType,
        Internal, SystemDisk, Health |
        Format-Table -AutoSize | Out-String).Trim())
} else {
    Write-Host 'No drives reported on this machine.' -ForegroundColor Yellow
}
Write-Host ''
Write-Host ("  RAM:      {0}" -f $ramPath)  -ForegroundColor Green
Write-Host ("  STORAGE:  {0}" -f $storPath) -ForegroundColor Green
Write-Host ("  WIN 11:   {0}" -f $win11) -ForegroundColor $(if ($win11 -eq 'No') { 'Yellow' } else { 'Green' })
if ($win11Notes) { Write-Host ("            {0}" -f $win11Notes) -ForegroundColor Yellow }
if ($notes.Count) {
    Write-Host ''
    foreach ($nte in $notes) { Write-Host ("  NOTE:     {0}" -f $nte) -ForegroundColor Yellow }
}

Write-Host ''
Write-Host '  [#####] 5/5  Saving CSV file...' -ForegroundColor Cyan
try {
    @($summary) | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    Write-Host ('Saved: ' + $outFile) -ForegroundColor Green
}
catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'If a CSV file is open in Excel, close it and run this again.' -ForegroundColor Yellow
}


#::ENDCODE::#
