# Desktop

A virtual desktop runs inside your workspace on a hidden X display. It exists so you can **show** humans what you are doing — the desktop is purely a stage for visual proof:

- Take a full-screen screenshot that includes both your terminal and a browser window.
- Record a screen video while you reproduce or demonstrate something.
- Hand the human a live "watch over your shoulder" URL.

Humans can only **view**; they cannot click or type into the desktop. You are the only actor that drives it.

## When to use

- The user asks for a screen recording, a video, or a screenshot of "what you see".
- The user asks for proof — login flow, UI state, end-to-end demo.
- The user wants to watch you work on a UI live.

If the task is purely browser automation with no need for visible terminal context, prefer `agent-browser` directly (it has its own dashboard at `agent-browser dashboard start`). The full desktop is for the **terminal + browser side-by-side** case.

## Commands

```bash
replicas desktop start             # boot the desktop, returns view URL (idempotent)
replicas desktop stop              # explicit stop (rare — idle handles this)
replicas desktop status            # current state
replicas desktop screenshot [path] # full-display PNG via maim
replicas desktop record start      # begin screen recording
replicas desktop record stop       # end recording, returns file path
```

`start` is idempotent — calling it twice is safe and cheap. After 20 minutes of no agent activity (no screenshots, recordings, or other desktop calls), the desktop auto-stops to free resources.

## Typical flow

```bash
# 1. Boot the desktop
replicas desktop start

# 2. Open whatever you want to show (browser via agent-browser, terminal commands, etc.)
DISPLAY=:99 agent-browser open --headed http://localhost:3000

# 3. Capture the result
replicas desktop screenshot /tmp/proof.png

# 4. Share via the media skill — this is mandatory for anything humans need to see
replicas media upload /tmp/proof.png
# Paste the returned ![…](url) line into your reply
```

## Recording

```bash
# Start
replicas desktop record start
# → { "recordingId": "...", "path": "/home/ubuntu/.replicas/desktop/artifacts/recordings/<ts>.mp4" }

# Do the thing you want to demonstrate
agent-browser open --headed http://localhost:3000
agent-browser click @e1
# ...

# Stop
replicas desktop record stop
# → { "path": "...", "durationMs": 47823 }

# Upload and share
replicas media upload /home/ubuntu/.replicas/desktop/artifacts/recordings/<ts>.mp4
```

**Recording cap:** 10 minutes maximum. The recording auto-stops at the cap and the file is finalized. If you need longer, do multiple recordings and link them.

**Frame rate:** 60 FPS, 1920×1080. Matches the recommended defaults in the Media skill.

## Browser on the desktop

The desktop is just an X display. Any GUI app you launch with `DISPLAY=:99` appears on it. For browser work, use `agent-browser` in headed mode:

```bash
DISPLAY=:99 agent-browser open --headed http://localhost:3000
```

Or set the env once for the session:

```bash
export DISPLAY=:99
agent-browser open --headed http://localhost:3000
```

agent-browser drives the browser via CDP (reliable, fast). The browser window lives on the desktop where humans can see it via the live URL or where it can be captured by a screenshot or recording.

## Live view URL

`replicas desktop start` returns a preview URL. The URL is **view-only** for humans — they cannot interact, only watch. Share it when the user wants to watch you work in real time:

```
The desktop is up — watch live: https://desktop-<hash>.replicas.dev
```

The URL works for anyone in the org with workspace access. It stays valid until the desktop is stopped (or auto-stopped after 20 minutes of inactivity).

## Artifacts

Screenshots and recordings save under `~/.replicas/desktop/artifacts/`. They live with the workspace — when the workspace is deleted, the artifacts go with it. **Always upload via `replicas media upload` before relying on the file existing for the user**, since the upload returns a chat-embeddable URL backed by Replicas storage.

## What you do NOT need to do

- **Do not** start Xvfb, x11vnc, ffmpeg, or noVNC by hand — `replicas desktop start` handles the whole stack.
- **Do not** install a window manager, theme, or browser yourself — the workspace image already has them.
- **Do not** symlink xdotool or wrap mouse moves — browser automation goes through `agent-browser`.
- **Do not** call `replicas desktop stop` after a single screenshot — idle auto-stop handles cleanup.
