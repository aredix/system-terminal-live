Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object Windows.Forms.Form
$form.Text = 'Terminal Live - Vitesse des donnees'
$form.ClientSize = New-Object Drawing.Size(460,240)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$path = Join-Path $PSScriptRoot 'settings.json'
$settings = @{acquisitionSeconds=5;refreshSeconds=5}
try { $settings = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json } catch {}
$fields = @{}
$index = 0
foreach ($entry in @(@('acquisitionSeconds','Acquisition des capteurs (secondes)'),@('refreshSeconds','Rafraichissement visuel (secondes)'))) {
    $label = New-Object Windows.Forms.Label
    $label.Text = $entry[1]; $label.SetBounds(20,(25+$index*50),310,25)
    $input = New-Object Windows.Forms.NumericUpDown
    $input.Minimum=1; $input.Maximum=60
    $input.Value = [Math]::Max(1,[Math]::Min(60,[decimal]$settings.($entry[0])))
    $input.SetBounds(345,(22+$index*50),85,28)
    $fields[$entry[0]] = $input
    $form.Controls.Add($label); $form.Controls.Add($input)
    $index++
}
$help = New-Object Windows.Forms.Label
$help.Text = "1 s = plus reactif ; 10-60 s = moins de travail pour le PC.`r`nApplication automatique. L'horloge reste a 1 seconde."
$help.SetBounds(20,125,420,45); $form.Controls.Add($help)
$save = New-Object Windows.Forms.Button
$save.Text='Enregistrer'; $save.SetBounds(300,185,130,32)
$save.Add_Click({
    try {
        $json = @{acquisitionSeconds=[int]$fields.acquisitionSeconds.Value;refreshSeconds=[int]$fields.refreshSeconds.Value} | ConvertTo-Json
        $temp = Join-Path $PSScriptRoot 'settings.tmp'
        [IO.File]::WriteAllText($temp,$json,(New-Object Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $path) { [IO.File]::Replace($temp,$path,(Join-Path $PSScriptRoot 'settings.previous')) } else { [IO.File]::Move($temp,$path) }
        $form.Close()
    } catch { [void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'Enregistrement impossible') }
})
$form.Controls.Add($save); $form.AcceptButton=$save
[void]$form.ShowDialog()
$form.Dispose()
