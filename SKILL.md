---
name: replicas-agent
description: Guide for background coding agents running inside Replicas cloud workspaces
---

# Replicas Agent

You are a background coding agent running inside a Replicas cloud workspace (a remote VM). This guide covers capabilities and best practices specific to this environment.

## Preview URLs

When you run services on ports — such as a web app, API server, or database — humans may want to interact with them directly. You can expose your locally running services as public preview URLs.

### Running Services for Preview

Services must run as detached background processes so they survive after your command session ends. Do not leave them attached to a foreground terminal.

Some potential methods:
```bash
# Start a detached service with logging
setsid -f bash -lc 'cd /path/to/app && exec yarn dev >> /tmp/app.log 2>&1'

# For daemons like Docker
nohup dockerd > /tmp/dockerd.log 2>&1 &
```

After starting a service:
1. Verify the process is running: `pgrep -af 'yarn dev'`
2. Check logs for readiness: `tail -f /tmp/app.log`
3. Confirm it's actually serving: `curl -s http://localhost:3000` (or appropriate health check)
4. Only create the preview after the service is healthy

If a prior detached process exists on the same port, stop it before restarting.

### Creating Previews

```bash
# Expose a local port as a public URL
replicas preview create <port>

# List all active preview URLs
replicas preview list
```

The `create` command prints the public URL. You can also read all active previews from `~/.replicas/preview-ports.json`.

### Cross-Service References

When you expose multiple services that reference each other, you must update their configuration so they use preview URLs instead of `localhost`.

**Example:** You run a React frontend on port 3000 that makes API calls to a backend on port 8585.

1. Create previews for both:
   ```bash
   replicas preview create 8585
   # Output: https://8585-<sandbox-id>.replicas.dev
   replicas preview create 3000
   # Output: https://3000-<sandbox-id>.replicas.dev
   ```

2. Update the frontend's environment so its API base URL points to the backend's **preview URL**, not `localhost:8585`. For example, set `REACT_APP_API_URL=https://8585-<sandbox-id>.replicas.dev` or update the relevant config file.

**Why?** The frontend works on `localhost` for you because both services run on the same machine. But a human viewing the preview is on a different machine — requests to `localhost:8585` from their browser will fail. They need the public preview URL instead.

### When to Create Previews

- After starting any service that a human should be able to view or interact with
- When verifying frontend/backend integrations visually
- When the task involves UI work that benefits from human review

It is your responsibility to make previews work for outsiders as well as they work for you on localhost. If at any time you need to see the public URLs that have been created, read `~/.replicas/preview-ports.json`.
