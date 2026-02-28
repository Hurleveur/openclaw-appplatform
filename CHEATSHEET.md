# ZeroClaw CLI Cheat Sheet

## The `zeroclaw` Command

**IMPORTANT:** In console sessions, always use the `zeroclaw` wrapper command.

The `zeroclaw` wrapper script (in `/usr/local/bin/`) runs commands as the correct user with proper environment. Without it, you'll get permission errors when running as root.

```bash
# ✅ Correct - use the wrapper
zeroclaw status

# ❌ Wrong - running the binary directly as root won't work correctly
/usr/local/bin/zeroclaw status
```

---

## Console Access

```bash
doctl apps list                              # List apps, get app ID
doctl apps console <app-id> zeroclaw          # Open console session
motd                                         # Show system info (MOTD)
```

---

## Gateway Status

```bash
zeroclaw status                                          # Check gateway status
zeroclaw --version                                       # Show version
curl -s http://127.0.0.1:42617/health                    # HTTP health check
```

---

## Configuration

```bash
cat /data/.zeroclaw/config.toml                          # View full config
grep -A5 '\[gateway\]' /data/.zeroclaw/config.toml      # Gateway section
grep 'default_provider' /data/.zeroclaw/config.toml      # Current provider
grep 'default_model' /data/.zeroclaw/config.toml         # Current model
```

---

## Service Management (s6-overlay)

```bash
/command/s6-svc -r /run/service/zeroclaw           # Restart zeroclaw
/command/s6-svc -r /run/service/ngrok             # Restart ngrok
/command/s6-svc -r /run/service/tailscale         # Restart tailscale
/command/s6-svc -d /run/service/zeroclaw           # Stop zeroclaw
/command/s6-svc -u /run/service/zeroclaw           # Start zeroclaw

ls /run/service/                                  # List all services
/command/s6-svstat /run/service/zeroclaw           # Service status details
```

---

## Environment & API Key

```bash
cat /run/s6/container_environment/API_KEY          # Current API key
env | grep ZEROCLAW                                # All ZeroClaw env vars
env | grep ENABLE                                  # Feature flags
```

---

## ngrok (when ENABLE_NGROK=true)

```bash
curl -s http://127.0.0.1:4040/api/tunnels | jq .  # Get ngrok tunnel info
curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url'
```

---

## Quick Diagnostics

```bash
# Show system info (MOTD)
motd

# Full system check
zeroclaw status && \
echo "--- Config ---" && \
cat /data/.zeroclaw/config.toml

# Check what's running
ps aux | grep -E "(zeroclaw|ngrok|tailscale)"

# Disk usage
df -h /data
```

---

## Backup & Restore (Restic)

```bash
# View snapshots
restic snapshots

# View latest snapshot for a specific path
restic snapshots --path /data/.zeroclaw --latest 1

# Manually trigger backup
/usr/local/bin/restic-backup

# Manually restore a path
restic restore latest --target / --include /data/.zeroclaw

# Check repository status
restic check

# View repository stats
restic stats

# Prune old snapshots (done automatically hourly)
/usr/local/bin/restic-prune
```

---

## Troubleshooting

```bash
# Restart zeroclaw
/command/s6-svc -r /run/service/zeroclaw

# Check if gateway port is listening
ss -tlnp | grep 42617

# Test gateway HTTP
curl -I http://127.0.0.1:42617

# Re-run config generation
/etc/cont-init.d/20-setup-zeroclaw

# Check service dependencies
ls /etc/services.d/*/dependencies.d/
```

---

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| "API key not configured" | Check `grep api_key /data/.zeroclaw/config.toml` |
| ngrok tunnel not accessible | `curl http://127.0.0.1:4040/api/tunnels` then restart |
| Command not found (as root) | Use `zeroclaw` wrapper instead of direct binary |
| Backup not running | Check: `ps aux \| grep restic-backup` and logs in `/proc/1/fd/1` |
| Data lost after restart | Verify `ENABLE_SPACES=true` and check `restic snapshots` |
