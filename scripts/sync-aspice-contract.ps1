[CmdletBinding()]
param()

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot 'references\aspice-document-contract.md'
$targets = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'skills') -Directory |
    Where-Object { $_.Name -like 'aspice-*' } |
    ForEach-Object { Join-Path $_.FullName 'references\document-contract.md' } |
    Where-Object { Test-Path -LiteralPath $_ }

if (-not (Test-Path -LiteralPath $source)) {
    throw "缺少 ASPICE 契约源文件：$source"
}

foreach ($target in $targets) {
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Host "已同步 $target"
}
