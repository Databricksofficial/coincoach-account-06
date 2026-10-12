# CoinCoach Cloudflare scheduler — Account 06

This is a separate Cloudflare Worker for `Databricksofficial/coincoach-account-06`.

It must be deployed as a new Worker named `coincoach-square-scheduler-account06`.
Do not edit or redeploy the existing Account 02 Worker.

## Schedule

The Account 02 scheduler configuration in this project uses cron minutes `6,21,36,51` with 0–120 seconds of jitter. This Account 06 scheduler uses `13,28,43,58` with the same jitter, shifting the nominal cadence by 7 minutes while preserving four triggers per hour (96 per day).

Cloudflare cron runs in UTC. Each trigger dispatches one run of the Account 06 GitHub Actions workflow.

## Before deploying

- Verify the new GitHub repository contains `.github/workflows/live-square-96-per-day.yml`.
- Verify GitHub Actions secret `BINANCE_SQUARE_KEY_ACCOUNT_06` is set.
- Verify repository variable `COINCOACH_LIVE_96_ENABLED` is `true` only when you are ready for automatic live publishing.
- Ensure your GitHub CLI (`gh`) is authenticated to an account that can dispatch workflows in `Databricksofficial/coincoach-account-06`.
- Ensure Wrangler is authenticated to the Cloudflare account where you want this separate Worker.

## Deploy the new Worker

From this directory in PowerShell:

```powershell
npx wrangler@latest login
npx wrangler@latest deploy
```

This creates/updates only the Worker named `coincoach-square-scheduler-account06`.

## Add the GitHub token secret

After the Worker has deployed, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install_gh_oauth_secret.ps1
```

The helper reads the token authenticated by `gh auth login` and uploads it as the Cloudflare Worker secret `GITHUB_TOKEN`. It does not dispatch a workflow as a test and therefore does not intentionally trigger an immediate post.

Never paste the token into source files or commit it.

## Confirm the deployment

In Cloudflare Dashboard → Workers & Pages → `coincoach-square-scheduler-account06` → Triggers, confirm the cron expression is:

`13,28,43,58 * * * *`

In Settings → Variables and Secrets, confirm `GITHUB_TOKEN` exists as a secret. Do not reveal its value.

The next scheduled trigger can publish one live Binance Square post because the GitHub variable is currently configured as enabled. Do not deploy until you're ready for the schedule to go live.
