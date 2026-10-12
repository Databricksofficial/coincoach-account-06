$ErrorActionPreference = "Stop"

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command is not installed or not on PATH: $Name"
    }
}

Require-Command "gh"
Require-Command "npx"

$token = $null
try {
    gh auth status | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub CLI authentication check failed. Run: gh auth login"
    }

    $token = (gh auth token).Trim()
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "gh auth token returned an empty value. Run: gh auth login"
    }

    Write-Host "Uploading GitHub CLI token to the Account 06 Worker secret store..." -ForegroundColor Cyan
    $token | & npx wrangler@latest secret put GITHUB_TOKEN --name "coincoach-square-scheduler-account06"
    if ($LASTEXITCODE -ne 0) {
        throw "Wrangler secret upload failed with exit code $LASTEXITCODE."
    }

    Write-Host "GITHUB_TOKEN secret upload completed for coincoach-square-scheduler-account06." -ForegroundColor Green
}
finally {
    $token = $null
    [GC]::Collect()
}
