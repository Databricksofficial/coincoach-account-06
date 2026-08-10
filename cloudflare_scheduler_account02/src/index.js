const sleep = (milliseconds) =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));

function requireValue(env, name) {
  const value = env[name];
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`Missing required Worker binding: ${name}`);
  }
  return value.trim();
}

function parseJitterSeconds(env) {
  const raw = env.JITTER_MAX_SECONDS ?? "120";
  const value = Number.parseInt(String(raw), 10);
  if (!Number.isInteger(value) || value < 0 || value > 120) {
    throw new Error("JITTER_MAX_SECONDS must be an integer from 0 to 120");
  }
  return value;
}

async function dispatchGitHubWorkflow(env) {
  const owner = requireValue(env, "GITHUB_OWNER");
  const repo = requireValue(env, "GITHUB_REPO");
  const workflow = requireValue(env, "GITHUB_WORKFLOW");
  const ref = requireValue(env, "GITHUB_REF");
  const token = requireValue(env, "GITHUB_TOKEN");

  const endpoint =
    `https://api.github.com/repos/${encodeURIComponent(owner)}/` +
    `${encodeURIComponent(repo)}/actions/workflows/` +
    `${encodeURIComponent(workflow)}/dispatches`;

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      "User-Agent": "CoinCoach-Cloudflare-Scheduler",
      "X-GitHub-Api-Version": "2022-11-28",
    },
    body: JSON.stringify({
      ref,
      inputs: {
        trigger_source: "cloudflare",
        confirmation: "CLOUDFLARE_SLOT",
      },
    }),
  });

  if (response.status !== 200 && response.status !== 204) {
    const body = await response.text();
    throw new Error(
      `GitHub workflow dispatch failed (${response.status}): ${body.slice(0, 500)}`,
    );
  }

  return { status: response.status, dispatchedAt: new Date().toISOString() };
}

export default {
  async scheduled(controller, env, ctx) {
    const jitterMaxSeconds = parseJitterSeconds(env);
    const jitterSeconds = Math.floor(Math.random() * (jitterMaxSeconds + 1));

    console.log(
      JSON.stringify({
        event: "coincoach_scheduler_started",
        cron: controller.cron,
        scheduledTime: new Date(controller.scheduledTime).toISOString(),
        jitterSeconds,
      }),
    );

    await sleep(jitterSeconds * 1000);
    const result = await dispatchGitHubWorkflow(env);
    console.log(JSON.stringify({ event: "coincoach_dispatch_complete", ...result }));
  },

  async fetch() {
    return Response.json({
      service: "coincoach-square-scheduler",
      status: "ready",
    });
  },
};
