$ErrorActionPreference = 'Stop'
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$platformRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot '../pocket doctor'))
$snapshotRoot = Join-Path $workspaceRoot '.validation/platform'
$envFiles = @()
foreach ($directory in @($workspaceRoot, $platformRoot, (Join-Path $platformRoot 'services/api'), $snapshotRoot, (Join-Path $snapshotRoot 'services/api'))) {
    $envFiles += @(Get-ChildItem -LiteralPath $directory -Force -File | Where-Object { $_.Name -like '.env*' -and $_.Name -notlike '*.example*' } | ForEach-Object {
        [ordered]@{ path = $_.FullName; hasDatabaseSetting = [bool]([IO.File]::ReadAllText($_.FullName) -match '(?m)^\s*DATABASE_URL\s*=\s*\S+') }
    })
}
$configuration = [ordered]@{
    processDatabaseUrl = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable('DATABASE_URL', 'Process'))
    userDatabaseUrl = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable('DATABASE_URL', 'User'))
    machineDatabaseUrl = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable('DATABASE_URL', 'Machine'))
    environmentFiles = $envFiles
    databaseCreated = $false
}
$tracked = @(git -C $platformRoot ls-files -- apps/mobile apps/admin-console services/api)
$code = @($tracked | Where-Object { [IO.Path]::GetExtension($_) -in @('.dart', '.ts', '.prisma') })
$differences = @()
foreach ($relative in $code) {
    $original = Join-Path $platformRoot $relative
    $copy = Join-Path $snapshotRoot $relative
    if (!(Test-Path -LiteralPath $copy)) { $differences += $relative; continue }
    $left = [IO.File]::ReadAllText($original).Replace("`r`n", "`n")
    $right = [IO.File]::ReadAllText($copy).Replace("`r`n", "`n")
    if ($left -cne $right) { $differences += $relative }
}
$report = [ordered]@{
    configuration = $configuration
    platformCommit = (git -C $platformRoot rev-parse HEAD)
    sourceGitStatus = @(git -C $platformRoot status --porcelain)
    comparedCodeFiles = $code.Count
    comparison = 'Tracked Dart, TypeScript and Prisma source/test files; CRLF/LF normalized only'
    snapshotCodeDifferences = $differences
    platformSourceModifiedByClosure = $false
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'environment-source-audit.json') -Encoding utf8
$report | ConvertTo-Json -Depth 6
