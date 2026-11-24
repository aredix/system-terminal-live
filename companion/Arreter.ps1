$target = Join-Path $PSScriptRoot 'Collecteur.ps1'
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -and $_.CommandLine.Contains('"'+$target+'"') } | ForEach-Object { Stop-Process -Id $_.ProcessId }
