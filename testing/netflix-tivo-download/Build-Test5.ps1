param(
    [string]$InputApk,
    [string]$OutputApk = (Join-Path $PSScriptRoot 'Netflix-TiVo-test5.apk')
)
$ErrorActionPreference = 'Stop'
$temporary = $null
try {
    if (-not $InputApk) {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Title = 'Select your original Netflix-TiVo-test3.apk'
        $picker.Filter = 'Android APK (*.apk)|*.apk'
        try {
            if ($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                throw 'No APK selected.'
            }
            $InputApk = $picker.FileName
        } finally { $picker.Dispose() }
    }
    $InputApk = (Resolve-Path -LiteralPath $InputApk).Path
    $OutputApk = [System.IO.Path]::GetFullPath($OutputApk)
    if (Test-Path -LiteralPath $OutputApk) { throw 'The output already exists. Choose a new output filename.' }
    $manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'test5-update.json') -Raw | ConvertFrom-Json
    if ($manifest.format -ne 'netflix-tivo-copy-patch-v1') { throw 'Unsupported update format.' }
    Write-Host 'Checking your original test3 APK...'
    if ((Get-FileHash -LiteralPath $InputApk -Algorithm SHA256).Hash -ne $manifest.input_sha256) {
        throw 'This is not the exact original Netflix-TiVo-test3.apk. Your file was not changed.'
    }
    $payloadPath = Join-Path $PSScriptRoot 'test5-update.bin'
    if ((Get-FileHash -LiteralPath $payloadPath -Algorithm SHA256).Hash -ne $manifest.payload_sha256) {
        throw 'The update data is damaged. Download the kit again.'
    }
    $payload = [System.IO.File]::ReadAllBytes($payloadPath)
    $temporary = $OutputApk + '.partial-' + [Guid]::NewGuid().ToString('N')
    $source = [System.IO.File]::OpenRead($InputApk)
    try {
        if ($source.Length -ne [long]$manifest.input_size) { throw 'Unexpected input size.' }
        $target = [System.IO.File]::Open($temporary, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
        try {
            $buffer = New-Object byte[] 1048576
            foreach ($op in $manifest.operations) {
                $properties = @($op.PSObject.Properties.Name)
                if ($properties.Count -ne 1 -or $properties[0] -notin @('copy', 'data')) {
                    throw 'Invalid update operation.'
                }
                $kind = $properties[0]
                $range = $op.$kind
                if ($range.Count -ne 2) { throw 'Invalid update range.' }
                $offset = [long]$range[0]; $remaining = [long]$range[1]
                $limit = if ($kind -eq 'copy') { $source.Length } else { $payload.LongLength }
                if ($offset -lt 0 -or $remaining -lt 0 -or $offset -gt $limit -or $remaining -gt ($limit - $offset)) {
                    throw 'Update range is outside its source.'
                }
                if ($target.Position + $remaining -gt [long]$manifest.output_size) { throw 'Output size exceeds the expected APK.' }
                if ($kind -eq 'copy') {
                    [void]$source.Seek($offset, [System.IO.SeekOrigin]::Begin)
                    while ($remaining -gt 0) {
                        $count = [int][Math]::Min($remaining, $buffer.Length)
                        $read = $source.Read($buffer, 0, $count)
                        if ($read -eq 0) { throw 'Unexpected end of the original APK.' }
                        $target.Write($buffer, 0, $read)
                        $remaining -= $read
                    }
                } else { $target.Write($payload, [int]$offset, [int]$remaining) }
            }
            if ($target.Position -ne [long]$manifest.output_size) { throw 'Output APK has an unexpected size.' }
        } finally { $target.Dispose() }
    } finally { $source.Dispose() }
    if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ne $manifest.output_sha256) {
        throw 'The rebuilt APK failed checksum verification. Do not install it.'
    }
    [System.IO.File]::Move($temporary, $OutputApk)
    $temporary = $null
    Write-Host ('SUCCESS: ' + $OutputApk)
    Write-Host ('SHA-256: ' + $manifest.output_sha256)
    Write-Host 'This is the exact signed test5 APK. Your original test3 file is unchanged.'
} catch {
    if ($temporary -and (Test-Path -LiteralPath $temporary)) { Remove-Item -LiteralPath $temporary -Force }
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
