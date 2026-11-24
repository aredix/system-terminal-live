param([switch]$CollecteurSeulement,[switch]$Configurer)
$ErrorActionPreference='Stop'
try {
    $configPath=Join-Path $PSScriptRoot 'companion.local.json'
    $wallpaperPath=$null
    if (Test-Path -LiteralPath $configPath) { $wallpaperPath=(Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json).wallpaperPath }
    if ($Configurer -or -not $wallpaperPath -or -not (Test-Path -LiteralPath (Join-Path $wallpaperPath 'terminal-live.marker'))) {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog=New-Object Windows.Forms.FolderBrowserDialog
        $dialog.Description='Selectionner le dossier du fond System Terminal Live (index.html et terminal-live.marker). Dans Wallpaper Engine : clic droit sur le fond > Ouvrir dans Explorateur.'
        if ($dialog.ShowDialog() -ne 'OK') { $dialog.Dispose(); exit }
        $wallpaperPath=$dialog.SelectedPath; $dialog.Dispose()
        if (-not (Test-Path -LiteralPath (Join-Path $wallpaperPath 'terminal-live.marker'))) { throw 'Ce dossier ne contient pas le fond System Terminal Live.' }
        $config=@{wallpaperPath=$wallpaperPath} | ConvertTo-Json
        [IO.File]::WriteAllText($configPath,$config,(New-Object Text.UTF8Encoding($false)))
    }
    & (Join-Path $PSScriptRoot 'Arreter.ps1')
    $script=Join-Path $PSScriptRoot 'Collecteur.ps1'
    Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -WindowStyle Hidden -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "'+$script+'" -OutputDirectory "'+$wallpaperPath+'"')
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'System Terminal Live')
    exit 1
}
