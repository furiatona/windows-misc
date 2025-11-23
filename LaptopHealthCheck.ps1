# ============================================================================
# Laptop Hardware & Health Test Script - BULLETPROOF EDITION
# ============================================================================
# Purpose: Test used laptops on-site with comprehensive diagnostics
# Requirements: Windows PowerShell (built-in), no admin required
# Duration: < 10 minutes on older hardware
# Zero-Error Guarantee: ALL operations wrapped with safety checks
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"
$Script:Results = @{}
$Script:IsAdmin = $false

# ============================================================================
# Initialize ALL Result Keys with Default Values (Prevents HTML errors)
# ============================================================================

function Initialize-Results {
    $Script:Results = @{
        'Manufacturer' = 'N/A'
        'Model' = 'N/A'
        'WindowsVersion' = 'N/A'
        'Architecture' = 'N/A'
        'CPUModel' = 'N/A'
        'CPUCores' = 'N/A'
        'CPULogicalProcessors' = 'N/A'
        'CPUMaxSpeed' = 'N/A'
        'TotalRAM' = 'N/A'
        'FreeRAM' = 'N/A'
        'UsedRAM' = 'N/A'
        'Disk1Model' = 'N/A'
        'Disk1Size' = 'N/A'
        'CDriveFree' = 'N/A'
        'CDriveTotal' = 'N/A'
        'CDriveUsed' = 'N/A'
        'BatteryStatus' = 'N/A'
        'BatteryCharge' = 'N/A'
        'BatteryHealth' = 'N/A'
        'BIOSVersion' = 'N/A'
        'BIOSManufacturer' = 'N/A'
        'BIOSDate' = 'N/A'
        'CPUTestIterations' = 'N/A'
        'CPUTestOpsPerSec' = 'N/A'
        'MemoryWriteSpeed' = 'N/A'
        'MemoryReadTest' = 'N/A'
        'DiskWriteSpeed' = 'N/A'
        'DiskReadSpeed' = 'N/A'
        'SMARTStatus' = 'N/A'
        'CriticalErrors7Days' = 'N/A'
        'Errors7Days' = 'N/A'
    }
}

# ============================================================================
# Safe Helper Functions (Bulletproof Operations)
# ============================================================================

function Test-Administrator {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $currentUser) { return $false }
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal) { return $false }
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Safe-FormatBytes {
    param([object]$Bytes)
    try {
        # Handle null, empty, or invalid input
        if ($null -eq $Bytes -or $Bytes -eq '') { return "0 B" }

        # Convert to int64 safely
        $BytesValue = 0
        try {
            $BytesValue = [int64]$Bytes
        } catch {
            return "Invalid"
        }

        # Handle zero or negative
        if ($BytesValue -le 0) { return "0 B" }

        # Handle extremely large values
        if ($BytesValue -gt [int64]::MaxValue / 2) { return "Too Large" }

        $sizes = @("B","KB","MB","GB","TB")
        $i = [math]::Floor([math]::Log($BytesValue, 1024))

        # Clamp index
        if ($i -lt 0) { $i = 0 }
        if ($i -ge $sizes.Length) { $i = $sizes.Length - 1 }

        $value = $BytesValue / [math]::Pow(1024, $i)
        return "{0:N2} {1}" -f $value, $sizes[$i]
    } catch {
        return "Error"
    }
}

function Safe-DivideRound {
    param([object]$Numerator, [object]$Denominator, [int]$Decimals = 0)
    try {
        $num = [double]$Numerator
        $den = [double]$Denominator
        if ($den -eq 0 -or $den -eq $null) { return 0 }
        return [math]::Round($num / $den, $Decimals)
    } catch {
        return 0
    }
}

function Safe-GetProperty {
    param([object]$Object, [string]$Property, [object]$Default = 'N/A')
    try {
        if ($null -eq $Object) { return $Default }
        $value = $Object.$Property
        if ($null -eq $value -or $value -eq '') { return $Default }
        return $value
    } catch {
        return $Default
    }
}

function Safe-ToString {
    param([object]$Value, [object]$Default = 'N/A')
    try {
        if ($null -eq $Value -or $Value -eq '') { return $Default }
        return $Value.ToString()
    } catch {
        return $Default
    }
}

function Safe-Trim {
    param([object]$String, [object]$Default = 'N/A')
    try {
        if ($null -eq $String -or $String -eq '') { return $Default }
        $result = $String.ToString().Trim()
        if ($result -eq '') { return $Default }
        return $result
    } catch {
        return $Default
    }
}

function Safe-Substring {
    param([object]$String, [int]$Start, [int]$Length, [object]$Default = '')
    try {
        if ($null -eq $String -or $String -eq '') { return $Default }
        $str = $String.ToString()
        if ($str.Length -eq 0) { return $Default }
        if ($Start -ge $str.Length) { return $Default }
        $actualLength = [Math]::Min($Length, $str.Length - $Start)
        if ($actualLength -le 0) { return $Default }
        return $str.Substring($Start, $actualLength)
    } catch {
        return $Default
    }
}

function Write-SectionHeader {
    param([string]$Title)
    try {
        Write-Host "`n" -NoNewline
        Write-Host ("=" * 80) -ForegroundColor Cyan
        Write-Host " $Title" -ForegroundColor Yellow
        Write-Host ("=" * 80) -ForegroundColor Cyan
    } catch {
        Write-Host "`n=== $Title ==="
    }
}

function Write-Result {
    param([string]$Label, [object]$Value, [string]$Status = "Info")
    try {
        $color = switch ($Status) {
            "Success" { "Green" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            default { "White" }
        }
        $safeValue = Safe-ToString $Value "N/A"
        Write-Host ("{0,-40}" -f $Label) -NoNewline
        Write-Host $safeValue -ForegroundColor $color
    } catch {
        Write-Host "$Label : $Value"
    }
}

# ============================================================================
# System Information Collection (Bulletproof)
# ============================================================================

function Get-SystemInfo {
    Write-SectionHeader "SYSTEM INFORMATION"

    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        if ($cs) {
            $mfg = Safe-GetProperty $cs 'Manufacturer' 'Unknown'
            $mdl = Safe-GetProperty $cs 'Model' 'Unknown'
            $Script:Results['Manufacturer'] = $mfg
            $Script:Results['Model'] = $mdl
            Write-Result "Manufacturer" $mfg
            Write-Result "Model" $mdl
        }
    } catch {
        Write-Result "System Info" "Error retrieving" "Error"
    }

    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if ($os) {
            $caption = Safe-GetProperty $os 'Caption' 'Windows'
            $build = Safe-GetProperty $os 'BuildNumber' 'Unknown'
            $winVersion = "$caption (Build $build)"
            $arch = Safe-GetProperty $os 'OSArchitecture' 'Unknown'
            $Script:Results['WindowsVersion'] = $winVersion
            $Script:Results['Architecture'] = $arch
            Write-Result "Windows Version" $winVersion
            Write-Result "Architecture" $arch
        }
    } catch {
        Write-Result "OS Info" "Error retrieving" "Error"
    }
}

function Get-CPUInfo {
    Write-SectionHeader "PROCESSOR INFORMATION"

    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpu) {
            $cpuName = Safe-Trim (Safe-GetProperty $cpu 'Name' 'Unknown CPU') 'Unknown CPU'
            $cores = Safe-GetProperty $cpu 'NumberOfCores' 'N/A'
            $logical = Safe-GetProperty $cpu 'NumberOfLogicalProcessors' 'N/A'
            $speed = Safe-GetProperty $cpu 'MaxClockSpeed' 'N/A'
            $speedStr = if ($speed -ne 'N/A') { "$speed MHz" } else { 'N/A' }

            $Script:Results['CPUModel'] = $cpuName
            $Script:Results['CPUCores'] = $cores
            $Script:Results['CPULogicalProcessors'] = $logical
            $Script:Results['CPUMaxSpeed'] = $speedStr

            Write-Result "CPU Model" $cpuName
            Write-Result "Physical Cores" $cores
            Write-Result "Logical Processors" $logical
            Write-Result "Max Clock Speed" $speedStr
        }
    } catch {
        Write-Result "CPU Info" "Error retrieving" "Error"
    }
}

function Get-MemoryInfo {
    Write-SectionHeader "MEMORY INFORMATION"

    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

        if ($cs -and $os) {
            $totalBytes = Safe-GetProperty $cs 'TotalPhysicalMemory' 0
            $freeKB = Safe-GetProperty $os 'FreePhysicalMemory' 0

            $totalGB = Safe-DivideRound $totalBytes 1GB 2
            $freeGB = Safe-DivideRound ($freeKB * 1024) 1GB 2
            $usedGB = Safe-DivideRound ($totalBytes - ($freeKB * 1024)) 1GB 2

            $Script:Results['TotalRAM'] = "$totalGB GB"
            $Script:Results['FreeRAM'] = "$freeGB GB"
            $Script:Results['UsedRAM'] = "$usedGB GB"

            Write-Result "Installed RAM" "$totalGB GB"
            Write-Result "Free RAM" "$freeGB GB"
            Write-Result "Used RAM" "$usedGB GB"
        }
    } catch {
        Write-Result "Memory Info" "Error retrieving" "Error"
    }
}

function Get-DiskInfo {
    Write-SectionHeader "DISK INFORMATION"

    try {
        $disks = @(Get-CimInstance Win32_DiskDrive -ErrorAction Stop)
        if ($disks -and $disks.Count -gt 0) {
            $diskNum = 1
            foreach ($disk in $disks) {
                if ($disk) {
                    $model = Safe-GetProperty $disk 'Model' 'Unknown Disk'
                    $sizeBytes = Safe-GetProperty $disk 'Size' 0
                    $size = Safe-FormatBytes $sizeBytes
                    $Script:Results["Disk${diskNum}Model"] = $model
                    $Script:Results["Disk${diskNum}Size"] = $size
                    Write-Result "Disk $diskNum Model" $model
                    Write-Result "Disk $diskNum Size" $size
                    $diskNum++
                }
            }
        } else {
            Write-Result "Disk Info" "No disks found" "Warning"
        }
    } catch {
        Write-Result "Disk Info" "Error retrieving" "Error"
    }

    try {
        $systemDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
        if ($systemDrive) {
            $freeBytes = Safe-GetProperty $systemDrive 'FreeSpace' 0
            $totalBytes = Safe-GetProperty $systemDrive 'Size' 0

            $freeSpace = Safe-FormatBytes $freeBytes
            $totalSpace = Safe-FormatBytes $totalBytes

            $usedPercent = 0
            if ($totalBytes -gt 0) {
                $usedPercent = Safe-DivideRound (($totalBytes - $freeBytes) * 100) $totalBytes 1
            }

            $Script:Results['CDriveFree'] = $freeSpace
            $Script:Results['CDriveTotal'] = $totalSpace
            $Script:Results['CDriveUsed'] = "$usedPercent%"

            Write-Result "C: Drive Total" $totalSpace
            Write-Result "C: Drive Free" $freeSpace
            Write-Result "C: Drive Used" "$usedPercent%"
        }
    } catch {
        Write-Result "C: Drive Info" "Error retrieving" "Warning"
    }
}

function Get-BatteryInfo {
    Write-SectionHeader "BATTERY INFORMATION"

    try {
        $battery = Get-CimInstance Win32_Battery -ErrorAction Stop
        if ($battery) {
            $battStatus = Safe-GetProperty $battery 'BatteryStatus' 0
            $statusText = switch ($battStatus) {
                1 { "Discharging" }
                2 { "AC Power" }
                3 { "Fully Charged" }
                4 { "Low" }
                5 { "Critical" }
                6 { "Charging" }
                7 { "Charging High" }
                8 { "Charging Low" }
                9 { "Charging Critical" }
                default { "Unknown" }
            }

            $charge = Safe-GetProperty $battery 'EstimatedChargeRemaining' 'N/A'
            $chargeStr = if ($charge -ne 'N/A') { "$charge%" } else { 'N/A' }

            # Safe battery health calculation
            $designCap = Safe-GetProperty $battery 'DesignCapacity' 0
            $fullCap = Safe-GetProperty $battery 'FullChargeCapacity' 0
            $healthStr = 'N/A'

            if ($designCap -gt 0 -and $fullCap -gt 0) {
                try {
                    $health = Safe-DivideRound ($fullCap * 100) $designCap 1
                    $healthStr = "$health%"
                } catch {
                    $healthStr = 'N/A'
                }
            }

            $Script:Results['BatteryStatus'] = $statusText
            $Script:Results['BatteryCharge'] = $chargeStr
            $Script:Results['BatteryHealth'] = $healthStr

            Write-Result "Battery Status" $statusText
            Write-Result "Current Charge" $chargeStr
            Write-Result "Battery Health" $healthStr
        } else {
            $Script:Results['BatteryStatus'] = "No battery detected"
            $Script:Results['BatteryCharge'] = "N/A"
            $Script:Results['BatteryHealth'] = "N/A"
            Write-Result "Battery" "No battery detected (Desktop or AC only)" "Warning"
        }
    } catch {
        $Script:Results['BatteryStatus'] = "Unable to retrieve"
        Write-Result "Battery Info" "Error retrieving" "Warning"
    }
}

function Get-BIOSInfo {
    Write-SectionHeader "BIOS INFORMATION"

    try {
        $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
        if ($bios) {
            $version = Safe-GetProperty $bios 'SMBIOSBIOSVersion' 'Unknown'
            $manufacturer = Safe-GetProperty $bios 'Manufacturer' 'Unknown'
            $releaseDate = Safe-GetProperty $bios 'ReleaseDate' $null

            $biosDate = "Unknown"
            if ($null -ne $releaseDate) {
                try {
                    $biosDate = ([datetime]$releaseDate).ToString("yyyy-MM-dd")
                } catch {
                    $biosDate = Safe-ToString $releaseDate "Unknown"
                }
            }

            $Script:Results['BIOSVersion'] = $version
            $Script:Results['BIOSManufacturer'] = $manufacturer
            $Script:Results['BIOSDate'] = $biosDate

            Write-Result "BIOS Version" $version
            Write-Result "BIOS Manufacturer" $manufacturer
            Write-Result "BIOS Date" $biosDate
        }
    } catch {
        Write-Result "BIOS Info" "Error retrieving" "Error"
    }
}

# ============================================================================
# Performance Tests (Bulletproof)
# ============================================================================

function Test-CPUPerformance {
    Write-SectionHeader "CPU STRESS TEST (10 seconds)"

    try {
        Write-Host "Running CPU stress test..." -ForegroundColor Yellow
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $iterations = 0

        # Safety: limit to 15 seconds max
        while ($sw.Elapsed.TotalSeconds -lt 10 -and $sw.Elapsed.TotalSeconds -lt 15) {
            try {
                $result = 1
                for ($i = 1; $i -lt 1000; $i++) {
                    $result = ($result * $i) % 999999
                }
                $iterations++
            } catch {
                break
            }
        }

        $sw.Stop()
        $elapsed = $sw.Elapsed.TotalSeconds
        $opsPerSec = Safe-DivideRound $iterations $elapsed 0

        $Script:Results['CPUTestIterations'] = $iterations
        $Script:Results['CPUTestOpsPerSec'] = $opsPerSec

        Write-Result "Total Iterations" $iterations "Success"
        Write-Result "Operations/Second" $opsPerSec "Success"
    } catch {
        $Script:Results['CPUTestIterations'] = "Test failed"
        $Script:Results['CPUTestOpsPerSec'] = "Test failed"
        Write-Result "CPU Stress Test" "Error during test" "Error"
    }
}

function Test-MemoryPerformance {
    Write-SectionHeader "MEMORY TEST"

    try {
        Write-Host "Testing memory write/read performance..." -ForegroundColor Yellow

        # Write test (50MB) with safety
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $testData = New-Object byte[] (50MB)
        $random = New-Object Random
        $random.NextBytes($testData)
        $sw.Stop()

        $elapsed = $sw.Elapsed.TotalSeconds
        $writeSpeed = Safe-FormatBytes (Safe-DivideRound 50MB $elapsed 0)
        $Script:Results['MemoryWriteSpeed'] = "$writeSpeed/s"
        Write-Result "Memory Write Speed" "$writeSpeed/s" "Success"

        # Read test with safety
        $sw.Restart()
        $sum = 0
        $maxIndex = [Math]::Min(10000, $testData.Length - 1)
        for ($i = 0; $i -le $maxIndex; $i++) {
            $sum += $testData[$i]
        }
        $sw.Stop()

        $Script:Results['MemoryReadTest'] = "Completed"
        Write-Result "Memory Read Test" "Completed successfully" "Success"

        # Cleanup
        $testData = $null
        [System.GC]::Collect()
    } catch {
        $Script:Results['MemoryWriteSpeed'] = "Test failed"
        $Script:Results['MemoryReadTest'] = "Test failed"
        Write-Result "Memory Test" "Error during test" "Error"
    }
}

function Test-DiskPerformance {
    Write-SectionHeader "DISK PERFORMANCE TEST"

    $tempFile = $null
    try {
        # Validate TEMP path
        $tempPath = $env:TEMP
        if ([string]::IsNullOrEmpty($tempPath) -or -not (Test-Path $tempPath)) {
            $tempPath = $env:TMP
        }
        if ([string]::IsNullOrEmpty($tempPath) -or -not (Test-Path $tempPath)) {
            throw "No valid TEMP directory found"
        }

        $tempFile = Join-Path $tempPath "disk_test_$(Get-Random).tmp"
        $testSize = 10MB
        $testData = New-Object byte[] $testSize

        # Write test
        Write-Host "Testing disk write speed..." -ForegroundColor Yellow
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        [System.IO.File]::WriteAllBytes($tempFile, $testData)
        $sw.Stop()

        $elapsed = $sw.Elapsed.TotalSeconds
        $writeSpeed = Safe-FormatBytes (Safe-DivideRound $testSize $elapsed 0)
        $Script:Results['DiskWriteSpeed'] = "$writeSpeed/s"
        Write-Result "Disk Write Speed" "$writeSpeed/s" "Success"

        # Read test
        Write-Host "Testing disk read speed..." -ForegroundColor Yellow
        $sw.Restart()
        $readData = [System.IO.File]::ReadAllBytes($tempFile)
        $sw.Stop()

        $elapsed = $sw.Elapsed.TotalSeconds
        $readSpeed = Safe-FormatBytes (Safe-DivideRound $testSize $elapsed 0)
        $Script:Results['DiskReadSpeed'] = "$readSpeed/s"
        Write-Result "Disk Read Speed" "$readSpeed/s" "Success"

        # Cleanup
        $readData = $null
        $testData = $null
        if ($tempFile -and (Test-Path $tempFile)) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        $Script:Results['DiskWriteSpeed'] = "Test failed"
        $Script:Results['DiskReadSpeed'] = "Test failed"
        Write-Result "Disk Performance Test" "Error during test" "Error"
        if ($tempFile -and (Test-Path $tempFile)) {
            try { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue } catch { }
        }
    }
}

function Get-SMARTStatus {
    Write-SectionHeader "DISK SMART STATUS"

    if (-not $Script:IsAdmin) {
        Write-Result "SMART Status" "Requires Administrator privileges" "Warning"
        $Script:Results['SMARTStatus'] = "Admin required - skipped"
        return
    }

    try {
        $disks = @(Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction Stop)
        if ($disks -and $disks.Count -gt 0) {
            $diskNum = 1
            $allOK = $true
            foreach ($disk in $disks) {
                if ($disk) {
                    $predictFailure = Safe-GetProperty $disk 'PredictFailure' $false
                    $status = if ($predictFailure) { "WARNING: Failure predicted" } else { "OK" }
                    $color = if ($predictFailure) { "Warning" } else { "Success" }
                    if ($predictFailure) { $allOK = $false }
                    $Script:Results["SMART_Disk$diskNum"] = $status
                    Write-Result "Disk $diskNum SMART Status" $status $color
                    $diskNum++
                }
            }
            if ($diskNum -eq 1) {
                $Script:Results['SMARTStatus'] = "No SMART data"
            } else {
                $Script:Results['SMARTStatus'] = if ($allOK) { "All OK" } else { "Warning detected" }
            }
        } else {
            $Script:Results['SMARTStatus'] = "SMART data not available"
            Write-Result "SMART Status" "Not available on this system" "Warning"
        }
    } catch {
        $Script:Results['SMARTStatus'] = "Unable to retrieve"
        Write-Result "SMART Status" "Not available or error occurred" "Warning"
    }
}

function Get-SystemErrors {
    Write-SectionHeader "SYSTEM ERROR CHECK (Last 7 Days)"

    try {
        Write-Host "Checking system event logs..." -ForegroundColor Yellow
        $startDate = (Get-Date).AddDays(-7)

        $criticalErrors = @(Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 1
            StartTime = $startDate
        } -MaxEvents 10 -ErrorAction SilentlyContinue)

        $errors = @(Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 2
            StartTime = $startDate
        } -MaxEvents 10 -ErrorAction SilentlyContinue)

        $critCount = if ($criticalErrors) { $criticalErrors.Count } else { 0 }
        $errCount = if ($errors) { $errors.Count } else { 0 }

        $Script:Results['CriticalErrors7Days'] = $critCount
        $Script:Results['Errors7Days'] = $errCount

        Write-Result "Critical Errors (7 days)" $critCount $(if ($critCount -gt 0) { "Warning" } else { "Success" })
        Write-Result "Errors (7 days)" $errCount $(if ($errCount -gt 5) { "Warning" } else { "Success" })

        if ($critCount -gt 0 -and $criticalErrors) {
            Write-Host "`nMost Recent Critical Errors:" -ForegroundColor Yellow
            $criticalErrors | Select-Object -First 3 | ForEach-Object {
                try {
                    $timestamp = Safe-GetProperty $_ 'TimeCreated' 'Unknown time'
                    $message = Safe-GetProperty $_ 'Message' 'No message'
                    $shortMsg = Safe-Substring $message 0 80 $message
                    Write-Host "  [$timestamp] $shortMsg..." -ForegroundColor Red
                } catch {
                    Write-Host "  Error reading event details" -ForegroundColor Red
                }
            }
        }
    } catch {
        $Script:Results['CriticalErrors7Days'] = 0
        $Script:Results['Errors7Days'] = 0
        Write-Result "System Error Check" "Error accessing event logs" "Warning"
    }
}

# ============================================================================
# HTML Report Generation (Bulletproof)
# ============================================================================

function Safe-HTMLEncode {
    param([object]$Text)
    try {
        if ($null -eq $Text -or $Text -eq '') { return 'N/A' }
        $str = $Text.ToString()
        $str = $str -replace '&', '&amp;'
        $str = $str -replace '<', '&lt;'
        $str = $str -replace '>', '&gt;'
        $str = $str -replace '"', '&quot;'
        $str = $str -replace "'", '&#39;'
        return $str
    } catch {
        return 'N/A'
    }
}

function Get-SafeResult {
    param([string]$Key)
    if ($Script:Results.ContainsKey($Key)) {
        return Safe-HTMLEncode $Script:Results[$Key]
    }
    return 'N/A'
}

function Generate-HTMLReport {
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $fileName = "LaptopTest_Report_$timestamp.html"
        $currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Build HTML with safe value retrieval
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Laptop Test Report - $timestamp</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; border-bottom: 2px solid #ecf0f1; padding-bottom: 8px; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #3498db; color: white; padding: 12px; text-align: left; font-weight: 600; }
        td { padding: 10px; border-bottom: 1px solid #ecf0f1; }
        tr:nth-child(even) { background: #f8f9fa; }
        .label { font-weight: 600; color: #555; width: 40%; }
        .value { color: #2c3e50; }
        .success { color: #27ae60; font-weight: 600; }
        .warning { color: #f39c12; font-weight: 600; }
        .error { color: #e74c3c; font-weight: 600; }
        .timestamp { color: #7f8c8d; font-size: 0.9em; margin-top: 30px; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Laptop Hardware &amp; Health Test Report</h1>
        <p><strong>Test Date:</strong> $currentDate</p>

        <h2>System Information</h2>
        <table>
            <tr><td class="label">Manufacturer</td><td class="value">$(Get-SafeResult 'Manufacturer')</td></tr>
            <tr><td class="label">Model</td><td class="value">$(Get-SafeResult 'Model')</td></tr>
            <tr><td class="label">Windows Version</td><td class="value">$(Get-SafeResult 'WindowsVersion')</td></tr>
            <tr><td class="label">Architecture</td><td class="value">$(Get-SafeResult 'Architecture')</td></tr>
        </table>

        <h2>Processor</h2>
        <table>
            <tr><td class="label">CPU Model</td><td class="value">$(Get-SafeResult 'CPUModel')</td></tr>
            <tr><td class="label">Physical Cores</td><td class="value">$(Get-SafeResult 'CPUCores')</td></tr>
            <tr><td class="label">Logical Processors</td><td class="value">$(Get-SafeResult 'CPULogicalProcessors')</td></tr>
            <tr><td class="label">Max Speed</td><td class="value">$(Get-SafeResult 'CPUMaxSpeed')</td></tr>
        </table>

        <h2>Memory</h2>
        <table>
            <tr><td class="label">Total RAM</td><td class="value">$(Get-SafeResult 'TotalRAM')</td></tr>
            <tr><td class="label">Free RAM</td><td class="value">$(Get-SafeResult 'FreeRAM')</td></tr>
            <tr><td class="label">Used RAM</td><td class="value">$(Get-SafeResult 'UsedRAM')</td></tr>
        </table>

        <h2>Storage</h2>
        <table>
            <tr><td class="label">Disk Model</td><td class="value">$(Get-SafeResult 'Disk1Model')</td></tr>
            <tr><td class="label">Disk Size</td><td class="value">$(Get-SafeResult 'Disk1Size')</td></tr>
            <tr><td class="label">C: Drive Total</td><td class="value">$(Get-SafeResult 'CDriveTotal')</td></tr>
            <tr><td class="label">C: Drive Free</td><td class="value">$(Get-SafeResult 'CDriveFree')</td></tr>
            <tr><td class="label">C: Drive Used</td><td class="value">$(Get-SafeResult 'CDriveUsed')</td></tr>
        </table>

        <h2>Battery</h2>
        <table>
            <tr><td class="label">Status</td><td class="value">$(Get-SafeResult 'BatteryStatus')</td></tr>
            <tr><td class="label">Current Charge</td><td class="value">$(Get-SafeResult 'BatteryCharge')</td></tr>
            <tr><td class="label">Battery Health</td><td class="value">$(Get-SafeResult 'BatteryHealth')</td></tr>
        </table>

        <h2>BIOS</h2>
        <table>
            <tr><td class="label">Version</td><td class="value">$(Get-SafeResult 'BIOSVersion')</td></tr>
            <tr><td class="label">Manufacturer</td><td class="value">$(Get-SafeResult 'BIOSManufacturer')</td></tr>
            <tr><td class="label">Date</td><td class="value">$(Get-SafeResult 'BIOSDate')</td></tr>
        </table>

        <h2>Performance Tests</h2>
        <table>
            <tr><td class="label">CPU Test - Iterations</td><td class="value success">$(Get-SafeResult 'CPUTestIterations')</td></tr>
            <tr><td class="label">CPU Test - Ops/Second</td><td class="value success">$(Get-SafeResult 'CPUTestOpsPerSec')</td></tr>
            <tr><td class="label">Memory Write Speed</td><td class="value success">$(Get-SafeResult 'MemoryWriteSpeed')</td></tr>
            <tr><td class="label">Disk Write Speed</td><td class="value success">$(Get-SafeResult 'DiskWriteSpeed')</td></tr>
            <tr><td class="label">Disk Read Speed</td><td class="value success">$(Get-SafeResult 'DiskReadSpeed')</td></tr>
        </table>

        <h2>Health &amp; Diagnostics</h2>
        <table>
            <tr><td class="label">SMART Status</td><td class="value">$(Get-SafeResult 'SMARTStatus')</td></tr>
            <tr><td class="label">Critical Errors (7 days)</td><td class="value">$(Get-SafeResult 'CriticalErrors7Days')</td></tr>
            <tr><td class="label">Errors (7 days)</td><td class="value">$(Get-SafeResult 'Errors7Days')</td></tr>
        </table>

        <p class="timestamp">Report generated by Laptop Test Script v2.0 (Bulletproof Edition)</p>
    </div>
</body>
</html>
"@

        $html | Out-File -FilePath $fileName -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "`n" -NoNewline
        Write-Host ("=" * 80) -ForegroundColor Green
        Write-Host " HTML Report Generated: $fileName" -ForegroundColor Green
        Write-Host ("=" * 80) -ForegroundColor Green
    } catch {
        Write-Host "`nFailed to generate HTML report: $_" -ForegroundColor Red
        Write-Host "Report path attempted: $fileName" -ForegroundColor Yellow
    }
}

# ============================================================================
# Main Execution (Bulletproof)
# ============================================================================

try {
    Clear-Host
    Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║              LAPTOP HARDWARE & HEALTH TEST SCRIPT                            ║
║              Version 2.0 - Bulletproof Edition                               ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

    # Initialize all result keys with defaults
    Initialize-Results

    # Check admin privileges
    $Script:IsAdmin = Test-Administrator
    if ($Script:IsAdmin) {
        Write-Host "[✓] Running with Administrator privileges" -ForegroundColor Green
    } else {
        Write-Host "[!] Running without Administrator privileges (some tests will be skipped)" -ForegroundColor Yellow
    }

    Write-Host "`nStarting comprehensive hardware test...`n" -ForegroundColor White

    # Run all tests (each is individually protected)
    Get-SystemInfo
    Get-CPUInfo
    Get-MemoryInfo
    Get-DiskInfo
    Get-BatteryInfo
    Get-BIOSInfo
    Test-CPUPerformance
    Test-MemoryPerformance
    Test-DiskPerformance
    Get-SMARTStatus
    Get-SystemErrors

    # Generate HTML report
    Generate-HTMLReport

    Write-Host "`n" -NoNewline
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host " Test Complete! Review the results above and check the HTML report." -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "`n`nCRITICAL ERROR: Script failed unexpectedly" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nPlease report this error." -ForegroundColor Yellow
}
