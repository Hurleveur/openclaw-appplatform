# AI-Assisted ZeroClaw Setup

This guide enables AI coding assistants (Claude Code, Cursor, Codex, Gemini, etc.) to deploy and configure ZeroClaw on DigitalOcean App Platform.

## Overview

- Uses [do-app-sandbox](https://pypi.org/project/do-app-sandbox/) SDK for remote execution on app container console
- References [do-app-platform-skills](https://github.com/digitalocean-labs/do-app-platform-skills) for best practices
- Follows progressive deployment stages (CLI → ngrok → Tailscale)

## Prerequisites

Before asking your AI assistant to deploy ZeroClaw:

```bash
# 1. Install and configure doctl
brew install doctl
doctl auth init

# 2. Install do-app-sandbox
pip install do-app-sandbox
# or with uv:
uv pip install do-app-sandbox

# 3. Clone app-platform-skills (if not available)
git clone https://github.com/digitalocean-labs/do-app-platform-skills ~/.claude/skills/do-app-platform-skills
```

---

## Stage 1: Deploy CLI-Only ($5/mo)

The simplest deployment - gateway with CLI access only via `doctl apps console`.

### Prompt

```
Deploy ZeroClaw to DigitalOcean App Platform using the CLI-only configuration.

Use the app spec from https://github.com/zeroclaw-labs/zeroclaw-appplatform with:
- Instance size: basic-xxs (1 CPU, 512MB shared)
- All feature flags disabled (ENABLE_NGROK=false, TAILSCALE_ENABLE=false, ENABLE_SPACES=false)

After deployment:
1. Use do-app-sandbox to connect to the container
2. Run: zeroclaw status
3. Run: curl -s http://127.0.0.1:42617/health
4. Show me the API key from: cat /run/s6/container_environment/API_KEY

Reference the do-app-platform-skills for deployment best practices.
```

### Verification

```bash
# Connect to console
doctl apps console <app-id> zeroclaw

# In console, verify:
zeroclaw status
curl -s http://127.0.0.1:42617/health
```

---

## Stage 2: Add ngrok ($12/mo)

Public URL access to the gateway via ngrok tunnel.

### Prompt

```
Upgrade my ZeroClaw deployment to Stage 2 with ngrok for public access.

Update the app configuration:
- Instance size: basic-xs (1 CPU, 1GB shared)
- Set ENABLE_NGROK=true
- Add NGROK_AUTHTOKEN (I'll provide it: <your-token>)

After deployment:
1. Connect via do-app-sandbox
2. Get the ngrok URL: curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url'
3. Verify gateway is accessible

Use do-app-platform-skills for the update process.
```

### Getting ngrok Token

1. Sign up at https://dashboard.ngrok.com
2. Go to: Your Authtoken → Copy

### Verification

```bash
# Get ngrok URL
curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url'
```

---

## Stage 3: Production with Tailscale ($25/mo)

Private network access - most secure for production use.

### Prompt

```
Upgrade my ZeroClaw deployment to Stage 3 with Tailscale for private access.

Update the app configuration:
- Instance size: basic-s (1 CPU, 2GB shared)
- Set ENABLE_NGROK=false
- Set TAILSCALE_ENABLE=true
- Add TS_AUTHKEY (I'll provide it)
- Set STABLE_HOSTNAME=zeroclaw

After deployment:
1. Verify Tailscale is connected
2. Show me the Tailscale hostname
3. Verify I can access via https://zeroclaw.<my-tailnet>.ts.net

Reference do-app-platform-skills for Tailscale integration.
```

### Getting Tailscale Auth Key

1. Go to https://login.tailscale.com/admin/settings/keys
2. Generate new auth key (reusable recommended for App Platform)

### Verification

```bash
# In console
tailscale status

# Access via browser
https://zeroclaw.<your-tailnet>.ts.net
```

---

## Adding Persistence (Any Stage)

Add DO Spaces backup to preserve data across restarts.

### Prompt

```
Add persistence to my ZeroClaw deployment using DO Spaces.

I have a Spaces bucket ready:
- Bucket: <bucket-name>
- Endpoint: <region>.digitaloceanspaces.com
- Access Key: <key>
- Secret Key: <secret>

Update the configuration:
- Set ENABLE_SPACES=true
- Add all the Spaces environment variables
- Add RESTIC_PASSWORD for backup encryption

After deployment:
1. Verify backup service is running
2. Confirm data will persist across restarts

Use do-app-platform-skills for Spaces configuration.
```

---

## Deployment Modes

| Mode               | When to Use                            |
| ------------------ | -------------------------------------- |
| **Laptop (doctl)** | Development, testing, quick iterations |
| **GitHub Actions** | Production, CI/CD, team deployments    |

### Deploy from Laptop

```bash
# Validate spec
doctl apps spec validate app.yaml

# Create app
doctl apps create --spec app.yaml

# Or update existing
doctl apps update <app-id> --spec app.yaml
```

### Deploy from GitHub Actions

See `.github/workflows/deploy.yml` for automated deployment on push.

---

## Reference

### Key Files

| File                       | Purpose                              |
| -------------------------- | ------------------------------------ |
| `app.yaml`                 | App Platform spec with feature flags |
| `.do/deploy.template.yaml` | Template for Deploy to DO button     |
| `CHEATSHEET.md`            | CLI commands reference               |
| `.env.example`             | Environment variable template        |

### Important Commands

```bash
# Always use zeroclaw wrapper in console
zeroclaw <command>

# Service management
/command/s6-svc -r /run/service/zeroclaw    # Restart
/command/s6-svc -d /run/service/zeroclaw    # Stop
/command/s6-svc -u /run/service/zeroclaw    # Start

# View config
cat /data/.zeroclaw/config.toml

# View API key
cat /run/s6/container_environment/API_KEY
```

### Troubleshooting

| Issue                          | Solution                                                   |
| ------------------------------ | ---------------------------------------------------------- |
| "Command not found" in console | Use `zeroclaw` wrapper                                     |
| Gateway not starting           | Check: `/command/s6-svstat /run/service/zeroclaw`          |
| ngrok URL not working          | Restart ngrok: `/command/s6-svc -r /run/service/ngrok`     |

### External Resources

- [ZeroClaw GitHub](https://github.com/zeroclaw-labs/zeroclaw)
- [do-app-sandbox PyPI](https://pypi.org/project/do-app-sandbox/)
- [do-app-platform-skills](https://github.com/digitalocean-labs/do-app-platform-skills)
- [DigitalOcean App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
