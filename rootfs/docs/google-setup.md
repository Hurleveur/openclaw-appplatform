# Google Services Integration

This guide explains how to connect zeroclaw to Google Drive, Calendar, and Gmail.

## Prerequisites

You need a Google Cloud Platform (GCP) project with OAuth 2.0 credentials.

## Setup Steps

### 1. Create a GCP Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your project ID

### 2. Enable APIs

Enable these APIs for your project:
- **Google Drive API**: https://console.cloud.google.com/apis/library/drive.googleapis.com
- **Google Calendar API**: https://console.cloud.google.com/apis/library/calendar-json.googleapis.com
- **Gmail API**: https://console.cloud.google.com/apis/library/gmail.googleapis.com

### 3. Create OAuth 2.0 Credentials

1. Go to [Credentials page](https://console.cloud.google.com/apis/credentials)
2. Click **Create Credentials** → **OAuth client ID**
3. Configure the OAuth consent screen:
   - User Type: **External** (unless you have a Google Workspace)
   - App name: `ZeroClaw Gateway`
   - Add your email as test user
4. Create OAuth Client ID:
   - Application type: **Desktop app** (for CLI access)
   - Name: `zeroclaw-gateway`
5. Download the credentials JSON file

### 4. Upload Credentials to Container

**Option A: Via environment variable (recommended for App Platform)**

Base64 encode your credentials file:
```bash
cat credentials.json | base64 -w 0
```

Add to `app.yaml`:
```yaml
envs:
  - key: GOOGLE_CREDENTIALS_BASE64
    type: SECRET
    # Paste the base64 string in DO dashboard
```

**Option B: Direct file upload (for local testing)**

Copy the downloaded JSON to the container:
```bash
# Using doctl console
doctl apps console <app-id> openclaw

# In the container
cat > /data/.openclaw/google-credentials.json << 'EOF'
{
  "installed": {
    "client_id": "your-client-id.apps.googleusercontent.com",
    "project_id": "your-project-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_secret": "your-client-secret",
    "redirect_uris": ["http://localhost"]
  }
}
EOF
```

### 5. Authenticate with Google

Run the OAuth flow to authorize zeroclaw:

```bash
# In the container console
openclaw plugins auth google-drive
openclaw plugins auth google-calendar
openclaw plugins auth gmail
```

Each command will:
1. Display an authorization URL
2. Ask you to visit the URL in your browser
3. Prompt you to paste the authorization code
4. Store the refresh token in `/data/.openclaw/`

### 6. Verify Setup

```bash
# Check plugin status
openclaw plugins status

# Test Drive access
openclaw plugins test google-drive

# Test Calendar access
openclaw plugins test google-calendar

# Test Gmail access
openclaw plugins test gmail
```

## Configuration

The plugins are configured in `/data/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "google-drive": {
        "enabled": true,
        "credentials": "/data/.openclaw/google-credentials.json",
        "scopes": [
          "https://www.googleapis.com/auth/drive.file",
          "https://www.googleapis.com/auth/drive.readonly"
        ]
      },
      "google-calendar": {
        "enabled": true,
        "credentials": "/data/.openclaw/google-credentials.json",
        "scopes": [
          "https://www.googleapis.com/auth/calendar",
          "https://www.googleapis.com/auth/calendar.events"
        ]
      },
      "gmail": {
        "enabled": true,
        "credentials": "/data/.openclaw/google-credentials.json",
        "scopes": [
          "https://www.googleapis.com/auth/gmail.send",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.compose"
        ]
      }
    }
  }
}
```

## Persistence

When `ENABLE_SPACES=true`, the following are automatically backed up:
- Google credentials file
- OAuth refresh tokens
- Plugin configuration

This means your Google authentication persists across container restarts.

## Scopes Explained

### Google Drive
- `drive.file` - Create and access files created by the app
- `drive.readonly` - Read all files (optional, can be removed if not needed)

### Google Calendar
- `calendar` - Full calendar access
- `calendar.events` - Read/write calendar events

### Gmail
- `gmail.send` - Send emails
- `gmail.readonly` - Read emails
- `gmail.compose` - Create drafts

## Troubleshooting

### "Credentials file not found"
Ensure `/data/.openclaw/google-credentials.json` exists with proper JSON format.

### "Invalid grant" or "Token expired"
Re-run the authentication flow:
```bash
openclaw plugins auth google-drive
```

### "Access not configured"
Make sure the API is enabled in GCP console for your project.

### Check logs
```bash
tail -f /data/.openclaw/logs/gateway.log | grep -i google
```

## Security Notes

1. **Never commit credentials** to version control
2. Use **SECRET** type in `app.yaml` for sensitive values
3. **Limit OAuth scopes** to only what you need
4. Use a **dedicated GCP project** for zeroclaw
5. **Enable backup encryption** with `RESTIC_PASSWORD` to protect stored tokens

## Usage Examples

Once set up, you can use natural language commands:

```
"Check my calendar for tomorrow"
"Send an email to john@example.com about the meeting"
"Save this conversation to a Google Doc"
"What files are in my Drive?"
"Add a reminder to my calendar for next Monday at 2pm"
```

The zeroclaw agent will automatically use the appropriate Google plugin to fulfill these requests.
