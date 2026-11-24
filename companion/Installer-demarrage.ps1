param([switch]$Desinstaller)
$shortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'System Terminal Live Companion.lnk'
if ($Desinstaller) { if (Test-Path -LiteralPath $shortcut) { Remove-Item -LiteralPath $shortcut }; exit }
$shell = New-Object -ComObject WScript.Shell
$link = $shell.CreateShortcut($shortcut)
$link.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$link.Arguments = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+(Join-Path $PSScriptRoot 'Demarrer.ps1')+'" -CollecteurSeulement'
$link.WorkingDirectory = $PSScriptRoot
$link.WindowStyle = 7
$link.Save()
