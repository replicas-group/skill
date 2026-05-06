---
name: replicas-agent
description: Guide for background coding agents running inside Replicas cloud workspaces
---

# Replicas Agent

You are a background coding agent running inside a Replicas cloud workspace (a remote VM). This skill covers capabilities and best practices specific to this environment.

## Capabilities

This skill provides detailed guides for the following capabilities. **Read the relevant reference file before performing any of these actions.**

### Previews
Expose locally running services (web apps, APIs, databases) as public preview URLs so humans can interact with them directly.

**Reference:** `references/PREVIEWS.md`

Use this when:
- You need to start a service that a human should view or interact with
- The task involves UI work that benefits from human review
- You are verifying frontend/backend integrations visually

### Slack
Send messages, read threads, search conversations, and upload files via the Slack Web API.

**Reference:** `references/SLACK.md`

Use this when:
- You need to send a message to a Slack channel or thread
- You need to read or fetch a Slack conversation
- You encounter a Slack message link and need to retrieve its content
- The task asks you to notify, update, or communicate via Slack

### Linear
Fetch issues, update state, add comments, and search via the Linear GraphQL API.

**Reference:** `references/LINEAR.md`

Use this when:
- You encounter a Linear issue link and need to understand the task
- You need to update an issue's state (e.g. mark as done)
- You need to comment on or search for Linear issues

### GitHub
Use the pre-authenticated `gh` CLI for pull requests, issues, actions, and API calls.

**Reference:** `references/GITHUB.md`

Use this when:
- You need to create, review, or manage pull requests
- You need to interact with GitHub issues or actions
- You need to use the GitHub API for advanced operations
- You need to include images in PR descriptions

### Docker
Start and use the Docker daemon in Replicas workspaces. Docker is pre-installed but the daemon does not auto-start.

**Reference:** `references/DOCKER.md`

Use this when:
- You need to run `docker` or `docker compose` commands
- You need to build or run Docker containers
- Your task involves containerized services or Docker-based workflows

### Media
Share screenshots, screen recordings, generated diagrams, and audio clips inline in the Replicas chat (and as references in external messages).

**Reference:** `references/MEDIA.md`

Use this when:
- You produce a screenshot, recording, generated image, or audio clip the user should see
- You record video output (browser automation, screen capture) — including the recommended aspect ratio and FPS
- You need to embed media in a Slack/Linear/GitHub message AND keep a referenceable copy in the Replicas dashboard

### Browser
Drive a real Chromium browser from the workspace using `agent-browser` for navigation, screenshots, snapshots, login flows, scraping, and other web-side automation.

**Reference:** `references/BROWSER.md`

Use this when:
- You need to interact with a web app (test a flow, log in, take a screenshot of a page, scrape content)
- You need browser-side data (snapshots, page text, accessibility tree, network activity)
- The work is browser-only and does not need a visible terminal alongside

For browser + terminal visible together, see the **Desktop** skill below.

### Desktop
Spin up a virtual desktop so you can take full-screen screenshots, record screen videos, or hand the user a live "watch over your shoulder" URL — useful for showing CLI + browser side-by-side.

**Reference:** `references/DESKTOP.md`

Use this when:
- The user asks for a screen recording, video, or screenshot of "what you see"
- The user asks for proof — login flow, UI state, end-to-end demo
- The user wants to watch you work on a UI live
