param(
    [string]$Godot = '',
    [ValidateSet('import','input','movement','combat','states','enemies','progression','boss','playthrough','all','smoke')]
    [string]$Suite = 'all'
)
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Godot)) {
    $godotCommand = Get-Command godot4, godot -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($godotCommand) {
        $Godot = $godotCommand.Source
    } else {
        $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        if ([string]::IsNullOrWhiteSpace($userProfile)) {
            $userProfile = $env:USERPROFILE
        }
        $downloads = Join-Path $userProfile 'Downloads'
        $godotDownload = Get-ChildItem -LiteralPath $downloads -Filter 'Godot*_console.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($godotDownload) {
            $Godot = $godotDownload.FullName
        } else {
            throw "Godot was not found on PATH or under Downloads. Pass -Godot 'C:\path\to\Godot_console.exe'."
        }
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'logs') | Out-Null
$suites = if ($Suite -eq 'all') { @('import','input','movement','combat','states','enemies','progression','boss','playthrough','smoke') } else { @($Suite) }
foreach ($testSuite in $suites) {
    $logPath = Join-Path $projectRoot "logs/$testSuite.log"
    $godotArguments = @('--headless','--path',$projectRoot,'--log-file',$logPath)
    if ($testSuite -eq 'import') {
        $godotArguments += @('--editor','--import')
    } elseif ($testSuite -eq 'smoke') {
        $godotArguments += @('--quit-after','300','--fixed-fps','60')
    } else {
        $godotArguments += @('--script',"res://tests/test_$testSuite.gd",'--fixed-fps','60','--quit-after','24000')
    }
    & $Godot @godotArguments
    if ($LASTEXITCODE -ne 0) { throw "$testSuite exited with code $LASTEXITCODE" }
    $logText = Get-Content -LiteralPath $logPath -Raw
    if ($logText -match '(SCRIPT ERROR:|ERROR:|WARNING:)') { throw "$testSuite reported errors or warnings; see $logPath" }
    $summaryPattern = $testSuite.ToUpper() + ': [0-9]+/[0-9]+ passed'
    if ($testSuite -notin @('import','smoke') -and $logText -notmatch $summaryPattern) { throw "$testSuite never completed" }
}
