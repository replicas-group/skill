# Desktop

A virtual desktop runs inside your workspace on a hidden X display. It exists so you can **show** humans what you are doing — the desktop is purely a stage for visual proof:

- A full-screen screenshot of your terminal and a browser together.
- A screen recording of you reproducing or demonstrating something.
- A live "watch over your shoulder" URL the human can open in their browser.

Humans can only **view**; they cannot click or type into the desktop. You are the only actor that drives it.

If the task is browser-only (no terminal in the frame), use `agent-browser` directly instead — it has its own screenshot/PDF without spinning up a desktop. The full desktop is for the **terminal + browser side-by-side** case.

## Commands

```bash
replicas desktop start                     # boot the desktop, returns view-only URL (idempotent)
replicas desktop browser <url>             # open a headed browser on the desktop. Auto-starts the desktop.
replicas desktop terminal [--cmd "..."]    # open a terminal window. Auto-starts the desktop.
replicas desktop screenshot [path]         # full-display PNG via maim
replicas desktop record start              # begin recording (capped at 10 min, 60fps, 1920x1080)
replicas desktop record stop               # end recording, returns the mp4 path
replicas desktop mousemove <x> <y>         # smoothly glide the visible cursor
replicas desktop status                    # current state
replicas desktop stop                      # explicit stop (rare — idle auto-stop handles this)
```

`start` is idempotent. After 20 minutes of no agent activity (no screenshots, recordings, or other desktop calls) the desktop auto-stops to free resources.

`DISPLAY=:99` is set globally in the workspace, so you do not need to prefix `DISPLAY=:99` on commands.

## Browser and terminal helpers

Prefer `replicas desktop browser <url>` and `replicas desktop terminal` over launching `agent-browser open --headed` or `xfce4-terminal` yourself. Both auto-start the desktop and pass the right flags.

**For terminal commands during recordings, strongly prefer `--cmd`:**

```bash
replicas desktop terminal --cmd 'echo "Replicas desktop"; date; uname -a'
```

xfce4-terminal uses VTE, which silently ignores `xdotool key --window`. Typing into a focused terminal is fragile — pre-bake the commands with `--cmd` so the terminal runs them itself. Only fall back to "click to focus, then `xdotool type`" if the commands need to be issued mid-recording based on something interactive.

## Cursor visibility — critical for recordings

**The cursor does not move automatically.** Neither `agent-browser` (CDP) nor `xdotool windowmove/windowsize/key/type` move the visible mouse cursor. A recording where you just run commands will show the page reacting and windows changing but the cursor sitting frozen in one corner — looks broken.

Before every interaction in a recording (click, scroll, switching windows, typing into a terminal) call `replicas desktop mousemove X Y` to glide the cursor to where the action will happen.

```bash
replicas desktop mousemove 1400 540          # before scrolling a browser at the right side
replicas desktop mousemove 1400 400          # before switching focus to a terminal on the right
replicas desktop mousemove 1100 600          # before typing into a terminal at that position
```

Default screen is 1920x1080. Coordinates are pixels.

Options: `--ms <duration>` (default 320), `--easing <linear|ease-in|ease-out|ease-in-out>` (default ease-out).

## Window positioning

Up to you — use `xdotool windowsize` and `xdotool windowmove` directly. There is no high-level layout helper. After launching browser/terminal, find the windows by class and place them:

```bash
TERM_ID=$(xdotool search --class "xfce4-terminal" | tail -1)
BROW_ID=$(xdotool search --class "Chrome" | tail -1)
xdotool windowsize $BROW_ID 1100 920 windowmove $BROW_ID 800 60
xdotool windowsize $TERM_ID 720 540 windowmove $TERM_ID 50 60
```

## Typical recording flow

```bash
# 1. Open the windows you want to demonstrate
replicas desktop browser https://replicas.dev
replicas desktop terminal --cmd 'sleep 3; echo Ready; date; uname -a; sleep 30'

# 2. Position them (optional, use xdotool)
TERM_ID=$(xdotool search --class "xfce4-terminal" | tail -1)
BROW_ID=$(xdotool search --class "Chrome" | tail -1)
xdotool windowsize $BROW_ID 1100 920 windowmove $BROW_ID 800 60
xdotool windowsize $TERM_ID 720 540 windowmove $TERM_ID 50 60

# 3. Start recording, drive cursor between actions
replicas desktop record start
replicas desktop mousemove 1300 500          # over the browser
agent-browser scroll down 500
replicas desktop mousemove 400 400           # over the terminal
sleep 3
replicas desktop record stop                 # → /home/ubuntu/.replicas/desktop/artifacts/recordings/<ts>.mp4

# 4. Share via the media skill
replicas media upload /home/ubuntu/.replicas/desktop/artifacts/recordings/<ts>.mp4
```

## Live view URL

`replicas desktop start` returns a preview URL. The URL is **view-only** for humans — they cannot interact, only watch. Share it when the user wants to watch you work in real time:

```
The desktop is up — watch live: https://desktop-<hash>.replicas.dev
```

The URL works for anyone in the org with workspace access. It stays valid until the desktop is stopped (or auto-stopped after 20 minutes of inactivity).

## Artifacts

Screenshots and recordings save under `~/.replicas/desktop/artifacts/`. They live with the workspace — when the workspace is deleted, the artifacts go with it. Always upload via `replicas media upload` before relying on the file existing for the user, since the upload returns a chat-embeddable URL backed by Replicas storage.

## What you do NOT need to do

- **Do not** start Xvfb, x11vnc, ffmpeg, or noVNC by hand — `replicas desktop start` handles the whole stack.
- **Do not** install a window manager, theme, browser, or any apt packages yourself — the workspace image already has them.
- **Do not** prefix `DISPLAY=:99` on commands — it is set globally.
- **Do not** type commands into a terminal via `xdotool key --window` — VTE silently ignores it. Use `replicas desktop terminal --cmd` instead.
- **Do not** call `replicas desktop stop` after a single screenshot — idle auto-stop handles cleanup after 20 minutes.
