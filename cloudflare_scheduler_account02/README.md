# CoinCoach free cloud scheduler

This is the zero-cost cloud path:

`Cloudflare Cron Trigger -> GitHub workflow_dispatch -> GitHub Actions -> Binance Square`

It does not require Render, a paid VM, or a laptop left on.

## Safety

Keep the GitHub repository variable below set to `false` while testing:

`COINCOACH_LIVE_96_ENABLED=false`

A test dispatch will create a skipped GitHub Actions run and will not publish to Binance.

## Install the tested GitHub CLI OAuth token

From this directory in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\install_gh_oauth_secret.ps1
```

The helper:

1. Reads the token already authenticated by `gh auth login`.
2. Tests the exact GitHub workflow-dispatch endpoint.
3. Uploads that same tested token directly to the Worker secret without clipboard input.
4. Never writes the token into the repository.

## Deploy

```powershell
npx wrangler@latest deploy
```

The cron is `6,21,36,51 * * * *` with up to 120 seconds of delay.
