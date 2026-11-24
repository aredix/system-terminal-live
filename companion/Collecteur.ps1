param([switch]$Once,[Parameter(Mandatory=$true)][string]$OutputDirectory)
$OutputDirectory=(Resolve-Path -LiteralPath $OutputDirectory).Path
if (-not (Test-Path -LiteralPath (Join-Path $OutputDirectory 'terminal-live.marker'))) { throw 'Invalid wallpaper folder' }
$hasher=[Security.Cryptography.SHA256]::Create()
$folderId=[BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($OutputDirectory.ToLowerInvariant()))).Replace('-','')
$hasher.Dispose()
$ErrorActionPreference = 'Stop'
$mutex = New-Object System.Threading.Mutex($false, ('Local\SystemTerminalLive_'+$folderId))
if (-not $mutex.WaitOne(0)) { $mutex.Dispose(); exit }
try {
    $cpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
    $board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
    $ramInfo = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1
    $gpuCommand = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    $gpuPath = if ($gpuCommand) { $gpuCommand.Source } else { $null }
    $cachedOs = $null; $nextOs = [datetime]::MinValue
    $cachedProcesses = @(); $nextProcesses = [datetime]::MinValue
    $cachedDisks = @(); $nextDisks = [datetime]::MinValue
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $script:acquisitionSeconds = 5
    $script:refreshSeconds = 5
    function Read-Settings {
        try {
            $settingsFile = Get-Item -LiteralPath (Join-Path $PSScriptRoot 'settings.json')
            $version = $settingsFile.LastWriteTimeUtc.Ticks.ToString() + ':' + $settingsFile.Length
            if ($version -eq $script:settingsVersion) { return }
            $settings = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'settings.json') | ConvertFrom-Json
            foreach ($key in @('acquisitionSeconds','refreshSeconds')) {
                $value = 0
                if ([int]::TryParse([string]$settings.$key,[ref]$value) -and $value -ge 1 -and $value -le 60) { Set-Variable -Name $key -Value $value -Scope Script }
            }
            $payload = @{acquisitionSeconds=$script:acquisitionSeconds;refreshSeconds=$script:refreshSeconds} | ConvertTo-Json -Compress
            if ($payload -ne $script:lastSettingsPayload) {
                $targetSettings = Join-Path $OutputDirectory 'settings.js'
                $tempSettings = Join-Path $OutputDirectory 'settings-script.tmp'
                [IO.File]::WriteAllText($tempSettings,"window.receiveSettings($payload);",$encoding)
                if (Test-Path -LiteralPath $targetSettings) { [IO.File]::Replace($tempSettings,$targetSettings,(Join-Path $OutputDirectory 'settings-script.previous')) } else { [IO.File]::Move($tempSettings,$targetSettings) }
                $script:lastSettingsPayload = $payload
            }
            $script:settingsVersion = $version
        } catch {}
    }
    function Read-Number($value) {
        $result = 0.0
        if ([double]::TryParse([string]$value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$result)) { return $result }
        return $null
    }
    do {
        Read-Settings
        $cycle = [Diagnostics.Stopwatch]::StartNew()
        try {
            if ((Get-Date) -ge $nextOs) {
                $cachedOs = Get-CimInstance Win32_OperatingSystem -Property Caption,Version,TotalVisibleMemorySize,FreePhysicalMemory,LastBootUpTime
                $nextOs = (Get-Date).AddSeconds(2)
            }
            $os = $cachedOs
            $cpu = $null
            $threads = @()
            try {
                $counters = @(Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Property Name,PercentProcessorTime)
                $cpu = ($counters | Where-Object Name -eq '_Total').PercentProcessorTime
                $threads = @($counters | Where-Object Name -ne '_Total' | Sort-Object { [int]$_.Name } | ForEach-Object { @{id=[int]$_.Name;load=$_.PercentProcessorTime} })
            } catch {}
            if ((Get-Date) -ge $nextProcesses) {
            $cachedProcesses = @()
            try { $cachedProcesses = @(Get-CimInstance Win32_PerfFormattedData_PerfProc_Process -Property Name,IDProcess,PercentProcessorTime,WorkingSetPrivate | Where-Object { $_.IDProcess -gt 0 -and $_.Name -ne '_Total' } | Sort-Object PercentProcessorTime -Descending | Select-Object -First 5 | ForEach-Object { @{name=$_.Name;pid=$_.IDProcess;cpu=[Math]::Min(100.0,([double]$_.PercentProcessorTime / $cpuInfo.NumberOfLogicalProcessors));memory=$_.WorkingSetPrivate / 1MB} }) } catch {}
            $nextProcesses = (Get-Date).AddSeconds(3)
            }
            $processes = $cachedProcesses
            $diskActivity = @()
            try { $diskActivity = @(Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Property Name,DiskReadBytesPersec,DiskWriteBytesPersec,CurrentDiskQueueLength | Where-Object Name -ne '_Total' | Sort-Object Name | ForEach-Object { @{name=$_.Name;read=$_.DiskReadBytesPersec / 1MB;write=$_.DiskWriteBytesPersec / 1MB;queue=$_.CurrentDiskQueueLength} }) } catch {}
            $gpu = $null
            if ($gpuPath) {
                $p = New-Object Diagnostics.Process
                $p.StartInfo = New-Object Diagnostics.ProcessStartInfo
                $p.StartInfo.FileName = $gpuPath
                $p.StartInfo.Arguments = '--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw,driver_version,clocks.current.graphics,clocks.current.memory,fan.speed,pstate --format=csv,noheader,nounits'
                $p.StartInfo.UseShellExecute = $false
                $p.StartInfo.CreateNoWindow = $true
                $p.StartInfo.RedirectStandardOutput = $true
                try {
                    [void]$p.Start()
                    if ($p.WaitForExit(2500)) {
                        $line = ($p.StandardOutput.ReadToEnd() -split "`n")[0]
                        $parts = $line -split ',\s*'
                        if ($p.ExitCode -eq 0 -and $parts.Count -ge 11) { $gpu = @{name=$parts[0];temperature=(Read-Number $parts[1]);load=(Read-Number $parts[2]);memoryUsed=(Read-Number $parts[3]);memoryTotal=(Read-Number $parts[4]);power=(Read-Number $parts[5]);driver=$parts[6].Trim();clock=(Read-Number $parts[7]);memoryClock=(Read-Number $parts[8]);fan=(Read-Number $parts[9]);state=$parts[10].Trim()} }
                    } else { $p.Kill() }
                } catch {} finally { $p.Dispose() }
            }
            if ((Get-Date) -ge $nextDisks) {
            $cachedDisks = @()
            try { $cachedDisks = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -Property DeviceID,Size,FreeSpace | Where-Object Size -gt 0 | ForEach-Object { @{name=$_.DeviceID;total=$_.Size/1GB;free=$_.FreeSpace/1GB} }) } catch {}
            $nextDisks = (Get-Date).AddSeconds(30)
            }
            $disks = $cachedDisks
            $network = $null
            try { $nic = Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface -Property Name,BytesTotalPersec,BytesReceivedPersec,BytesSentPersec | Where-Object { $_.Name -notmatch 'Loopback|isatap|Teredo' } | Sort-Object BytesTotalPersec -Descending | Select-Object -First 1
                if ($nic) { $network=@{name=$nic.Name;rx=$nic.BytesReceivedPersec;tx=$nic.BytesSentPersec} }
            } catch {}
            $data = @{ timestamp=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds();os=($os.Caption+' · '+$os.Version);cpuName=$cpuInfo.Name.Trim();board=$board.Product;ramSpeed=$ramInfo.ConfiguredClockSpeed;cpu=$cpu;gpu=$gpu;ramTotal=$os.TotalVisibleMemorySize/1MB;ramUsed=($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/1MB;ram=100*(1-$os.FreePhysicalMemory/$os.TotalVisibleMemorySize);uptime=((Get-Date)-$os.LastBootUpTime).TotalSeconds;disks=$disks;network=$network }
            $data.os = $os.Caption + ' / ' + $os.Version
            $data.threads = $threads
            $data.processes = $processes
            $data.diskActivity = $diskActivity
            $data.acquisitionSeconds = $script:acquisitionSeconds
            $data.refreshSeconds = $script:refreshSeconds
            $data.collectionMilliseconds = $cycle.ElapsedMilliseconds
            $json = $data | ConvertTo-Json -Depth 6 -Compress
            $target = Join-Path $OutputDirectory 'telemetry.js'
            $temp = Join-Path $OutputDirectory 'telemetry.tmp'
            [IO.File]::WriteAllText($temp, "window.receiveTelemetry($json);", $encoding)
            if (Test-Path -LiteralPath $target) { [IO.File]::Replace($temp,$target,(Join-Path $OutputDirectory 'telemetry.previous')) } else { [IO.File]::Move($temp,$target) }
        } catch { [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'collecteur-error.log'), ((Get-Date).ToString('s')+' '+$_.Exception.Message), $encoding); if ($Once) { throw } }
        if (-not $Once) {
            while ($cycle.Elapsed.TotalSeconds -lt $script:acquisitionSeconds) {
                Start-Sleep -Milliseconds ([Math]::Max(1,[Math]::Min(250,[int](1000*$script:acquisitionSeconds-$cycle.ElapsedMilliseconds))))
                Read-Settings
            }
        }
    } while (-not $Once)
} finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
