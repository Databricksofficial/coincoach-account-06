param(
    [string]$Repository = "HarshitPatidarOfficial/coincoach-signal-cloud",
    [string]$Workflow = "live-square-96-per-day.yml",
    [string]$Ref = "main",
    [string]$WorkerName = "coincoach-square-scheduler"
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command is not installed or not on PATH: $Name"
    }
}

Require-Command "gh"
Require-Command "npx"

$token = $null
$body = $null
$previousGhToken = $env:GH_TOKEN

try {
    gh auth status | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "gh authentication check failed. Run: gh auth login"
    }

    $token = (gh auth token).Trim()
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "gh auth token returned an empty value. Run: gh auth login"
    }

    $body = @{
        ref = $Ref
        inputs = @{
            trigger_source = "cloudflare"
            confirmation   = "CLOUDFLARE_SLOT"
        }
    } | ConvertTo-Json -Depth 5 -Compress

    # Force gh api to use the exact same token that will be uploaded to Cloudflare.
    $env:GH_TOKEN = $token

    Write-Host "Testing GitHub workflow dispatch with the authenticated gh token..." -ForegroundColor Cyan
    $body | gh api `
        --method POST `
        -H "Accept: application/vnd.github+json" `
        -H "X-GitHub-Api-Version: 2022-11-28" `
        "repos/$Repository/actions/workflows/$Workflow/dispatches" `
        --input -

    if ($LASTEXITCODE -ne 0) {
        throw "GitHub dispatch test failed. The Cloudflare secret was not changed."
    }

    Write-Host "GitHub dispatch accepted: HTTP 204" -ForegroundColor Green
    Write-Host "Uploading the same tested token to Cloudflare Worker secret storage..." -ForegroundColor Cyan

    $token | & npx wrangler@latest secret put GITHUB_TOKEN --name $WorkerName
    if ($LASTEXITCODE -ne 0) {
        throw "Wrangler secret upload failed with exit code $LASTEXITCODE."
    }

    Write-Host "Free scheduler credential installed successfully." -ForegroundColor Green
    Write-Host "Keep COINCOACH_LIVE_96_ENABLED=false until one automatic Cloudflare dispatch appears." -ForegroundColor Yellow
}
finally {
    if ($null -eq $previousGhToken) {
        Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
    }
    else {
        $env:GH_TOKEN = $previousGhToken
    }

    $token = $null
    $body = $null
    $previousGhToken = $null
    [GC]::Collect()
}
