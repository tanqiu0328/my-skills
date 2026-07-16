[CmdletBinding()]
param()

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsRoot = Join-Path $repoRoot 'skills'
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$skillDirs = Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name
$skillNames = @($skillDirs.Name)

foreach ($dir in $skillDirs) {
    $skillFile = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile)) {
        $errors.Add("$($dir.Name)：缺少 SKILL.md")
        continue
    }

    $content = Get-Content -Raw -LiteralPath $skillFile
    $frontmatter = [regex]::Match($content, '(?s)^---\s*\r?\n(.*?)\r?\n---')
    if (-not $frontmatter.Success) {
        $errors.Add("$($dir.Name)：frontmatter 无效")
        continue
    }

    $nameMatch = [regex]::Match($frontmatter.Groups[1].Value, '(?m)^name:\s*([^\r\n]+)')
    $descriptionMatch = [regex]::Match($frontmatter.Groups[1].Value, '(?m)^description:\s*([^\r\n]+)')
    $declaredName = $nameMatch.Groups[1].Value.Trim().Trim('"')

    if (-not $nameMatch.Success -or $declaredName -ne $dir.Name) {
        $errors.Add("$($dir.Name)：name 与目录不一致")
    }
    if (-not $descriptionMatch.Success -or [string]::IsNullOrWhiteSpace($descriptionMatch.Groups[1].Value)) {
        $errors.Add("$($dir.Name)：缺少 description")
    }

    $agentFile = Join-Path $dir.FullName 'agents\openai.yaml'
    if (-not (Test-Path -LiteralPath $agentFile)) {
        $errors.Add("$($dir.Name)：缺少 agents/openai.yaml")
    }
    else {
        $agentContent = Get-Content -Raw -LiteralPath $agentFile
        if ($agentContent -notmatch '(?m)^\s*default_prompt:\s*"[^"]*\$' + [regex]::Escape($dir.Name)) {
            $errors.Add("$($dir.Name)：default_prompt 未显式引用 `$${declaredName}")
        }
        $shortDescription = [regex]::Match($agentContent, '(?m)^\s*short_description:\s*"([^"]+)"').Groups[1].Value
        if ($shortDescription.Length -lt 25 -or $shortDescription.Length -gt 64) {
            $errors.Add("$($dir.Name)：short_description 长度应为 25～64 字符，当前为 $($shortDescription.Length)")
        }
    }

    $invocations = [regex]::Matches($content, '`\$([a-z][a-z0-9-]+)`')
    foreach ($invocation in $invocations) {
        $targetName = $invocation.Groups[1].Value
        if ($skillNames -notcontains $targetName) {
            $errors.Add("$($dir.Name)：引用不存在的 skill $targetName")
        }
    }
}

$markdownFiles = Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.md' |
    Where-Object { $_.Name -ne 'CONTEXT-FORMAT.md' }

foreach ($file in $markdownFiles) {
    $content = Get-Content -Raw -LiteralPath $file.FullName
    $lineCount = ($content -split "`n").Count
    if ($file.Name -ne 'SKILL.md' -and $file.FullName.StartsWith($skillsRoot) -and
        $lineCount -gt 100 -and $content -notmatch '(?m)^## (导航|Contents|Table of Contents)') {
        $relativeFile = [System.IO.Path]::GetRelativePath($repoRoot, $file.FullName)
        $errors.Add("$relativeFile：超过 100 行但缺少导航目录")
    }
    $links = [regex]::Matches($content, '\[[^\]\r\n]+\]\(([^)\r\n]+)\)')
    foreach ($link in $links) {
        $target = $link.Groups[1].Value
        if ($target -match '^(https?://|mailto:|#)') {
            continue
        }
        $pathPart = $target.Split('#')[0]
        $resolved = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $pathPart))
        if (-not (Test-Path -LiteralPath $resolved)) {
            $relativeFile = [System.IO.Path]::GetRelativePath($repoRoot, $file.FullName)
            $errors.Add("$relativeFile：相对链接不存在 $target")
        }
    }
}

$canonicalContract = Join-Path $repoRoot 'references\aspice-document-contract.md'
if (Test-Path -LiteralPath $canonicalContract) {
    $canonicalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $canonicalContract).Hash
    $contracts = Get-ChildItem -LiteralPath $skillsRoot -Recurse -Filter 'document-contract.md'
    foreach ($contract in $contracts) {
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $contract.FullName).Hash
        if ($hash -ne $canonicalHash) {
            $relative = [System.IO.Path]::GetRelativePath($repoRoot, $contract.FullName)
            $errors.Add("$relative：与 ASPICE 契约源不一致")
        }
    }
}
else {
    $errors.Add('缺少 references/aspice-document-contract.md')
}

if ($warnings.Count -gt 0) {
    $warnings | ForEach-Object { Write-Warning $_ }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "验证通过：$($skillDirs.Count) 个 skills"
