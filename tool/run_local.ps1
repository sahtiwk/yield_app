param(
    [string]$Device = 'chrome',
    [string]$ApiUrl = '',
    [int]$Port = 8082,
    [switch]$Usb,
    [switch]$NoResident,
    [Alias('Demo')][switch]$Offline
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $flutter = Join-Path $projectRoot '.tools\flutter\bin\flutter.bat'
    if (-not (Test-Path -LiteralPath $flutter)) { $flutter = 'flutter' }
    $arguments = @('run', '-d', $Device)
    if ($NoResident) { $arguments += '--no-resident' }
    if ($Device -in @('chrome','edge','web-server')) {
        $arguments += @('--web-hostname=127.0.0.1', "--web-port=$Port")
    }
    if (-not $Offline) {
        $rawStatus = & npx.cmd supabase status -o json
        if ($LASTEXITCODE -ne 0) { throw 'Start local Supabase with npx.cmd supabase start first.' }
        $status = $rawStatus | ConvertFrom-Json
        $publicKey = $status.PUBLISHABLE_KEY
        if (-not $publicKey) { $publicKey = $status.ANON_KEY }
        if (-not $publicKey) { throw 'Supabase did not return a public client key.' }
        if (-not $ApiUrl) { $ApiUrl = $status.API_URL }
        if ($Usb) {
            if ($Device -in @('chrome','edge','web-server','windows','linux','macos')) {
                throw '-Usb requires the Android device ID from adb devices.'
            }
            $endpoint = [Uri]$ApiUrl
            if ($endpoint.Host -notin @('127.0.0.1','localhost')) {
                throw '-Usb expects a local loopback Supabase API URL.'
            }
            $adb = Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe'
            if (-not (Test-Path -LiteralPath $adb)) { $adb = 'adb' }
            & $adb -s $Device reverse "tcp:$($endpoint.Port)" "tcp:$($endpoint.Port)"
            if ($LASTEXITCODE -ne 0) { throw 'Could not forward local Supabase to the Android device. Check USB debugging.' }
        }
        $arguments += @("--dart-define=SUPABASE_URL=$ApiUrl", "--dart-define=SUPABASE_PUBLISHABLE_KEY=$publicKey")
    }
    & $flutter @arguments
    exit $LASTEXITCODE
} finally { Pop-Location }
