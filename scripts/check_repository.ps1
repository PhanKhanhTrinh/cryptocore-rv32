$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
    'README.md',
    'CryptoCore_RV32.srcs/sources_1/imports/rtl/riscv_crypto_soc.v',
    'CryptoCore_RV32.srcs/sources_1/imports/rtl/crypto_coprocessor_axi.v',
    'CryptoCore_RV32.srcs/sources_1/new/picorv32.v',
    'CryptoCore_RV32.srcs/sources_1/imports/firmware/boot_rom.hex',
    'CryptoCore_RV32.srcs/constrs_1/imports/constraints/pynq_z2.xdc',
    'scripts/create_project.tcl'
)

$missing = foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file))) { $file }
}

if ($missing) {
    throw "Missing required repository files:`n$($missing -join "`n")"
}

$textExtensions = @('.v', '.vh', '.sv', '.tcl', '.xdc', '.S', '.md', '.ps1')
$sourceFiles = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -File |
    Where-Object {
        $textExtensions -contains $_.Extension -and
        $_.FullName -notmatch '\\(build|artifacts|\.git)\\'
    })
$absolutePathHits = $sourceFiles |
    Select-String -Pattern '(?<![A-Za-z])[A-Za-z]:[\\/](?![\\/])' -SimpleMatch:$false

if ($absolutePathHits) {
    $absolutePathHits | ForEach-Object {
        Write-Error "Absolute path: $($_.Path):$($_.LineNumber): $($_.Line.Trim())"
    }
    throw 'Repository contains workstation-specific absolute paths.'
}

$missingLinks = @()
foreach ($markdownFile in ($sourceFiles | Where-Object { $_.Extension -eq '.md' })) {
    $content = Get-Content -LiteralPath $markdownFile.FullName -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($content, '!?\[[^\]]*\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value
        if ($target -match '^(https?://|mailto:|#)') { continue }

        $localTarget = [uri]::UnescapeDataString($target.Split('#')[0])
        $resolvedTarget = Join-Path $markdownFile.DirectoryName $localTarget
        if (-not (Test-Path -LiteralPath $resolvedTarget)) {
            $missingLinks += "$($markdownFile.Name): $target"
        }
    }
}

if ($missingLinks.Count -gt 0) {
    throw "Broken local Markdown links:`n$($missingLinks -join "`n")"
}

Write-Host 'Repository check passed.' -ForegroundColor Green
