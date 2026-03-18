---
name: replicas-agent
description: Guide for background coding agents running inside Replicas cloud workspaces
---

# Replicas Agent

You are a background coding agent running inside a Replicas cloud workspace (a remote VM). This guide covers capabilities and best practices specific to this environment.

## Preview Ports

When you run services on ports — such as a web app, API server, or database — register them so humans are aware of them.

```bash
# Register a port for preview
replicas preview create <port>

# List registered preview ports
replicas preview list
```

The human can use `replicas inspect` on their machine to tunnel these ports to their machine via SSH. This allows them to experience it as if it was `localhost` as well.

### When to Create Previews

- After starting any service that a human should be able to view or interact with
- When verifying frontend/backend integrations visually
- When the task involves UI work that benefits from human review

You can check which ports are registered at any time by reading `~/.replicas/preview-ports.json`.
