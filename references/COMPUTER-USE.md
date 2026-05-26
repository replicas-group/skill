# Computer use (Linux desktop control)

Every Replicas workspace boots with a full Linux desktop stack — Xvfb (1920×1080), openbox, tint2, x11vnc, noVNC, ffmpeg, and Google Chrome. You drive it through the `replicas computer` CLI.

Use this for anything the user can't reasonably do via an API — clicking around web apps, filling forms, testing UI changes, dragging files between desktop apps, recording a walkthrough.

## When to use it

- **Prefer real APIs first.** If a task has a CLI or HTTP API (GitHub, Linear, Slack, Replicas itself), use that. Driving a UI is slower, flakier, and less auditable.
- **Use it when there's no API**: testing a frontend you just changed, navigating a vendor portal, demonstrating a flow on video.
- **Use it when the user wants to watch.** `replicas computer start` exposes a live `Desktop` tab in the dashboard — they can watch you work in real time.

## Never use raw `xdotool` / `scrot` / `ffmpeg` directly

The CLI is the canonical surface. Chat transcripts that show `DISPLAY=:99 xdotool key Return` are noisy and break when the underlying stack changes. Always call the CLI:

```bash
# DO
replicas computer key Return
replicas computer screenshot /tmp/state.png

# DON'T
DISPLAY=:99 xdotool key Return
scrot /tmp/state.png
```

## Quickstart

```bash
# 1) Make the desktop visible to the user (creates an authenticated noVNC
#    preview on port 6080, prints the viewer URL, adds a "Desktop" tab to the
#    dashboard).
replicas computer start

# 2) Launch a browser on the workspace display.
replicas computer launch chrome

# 3) Take a screenshot so you can see what's there.
replicas computer screenshot /tmp/state.png
# (Read the PNG yourself before deciding where to click.)

# 4) Drive the UI.
replicas computer key ctrl+l                       # focus address bar
replicas computer type "https://news.ycombinator.com"
replicas computer key Return
replicas computer click 521 700                    # click coordinates from the screenshot
replicas computer scroll down --amount 5

# 5) (Optional) Record a screencap to share back.
replicas computer record start /tmp/demo.mp4 --fps 60
# ... do stuff ...
replicas computer record stop
replicas media upload /tmp/demo.mp4

# 6) Tear down the live preview when done (services keep running for next time).
replicas computer stop
```

## Command reference

### `replicas computer start [--port N] [--display :N] [--size WxH]`
Ensures all desktop services are running and creates an authenticated noVNC preview. Prints the viewer URL (`https://<port>-<hash>.tryreplicas.com/vnc.html?autoconnect=1&resize=scale`). The Replicas dashboard automatically shows a `Desktop` tab while this preview is live — point the user at it instead of pasting the URL.

Idempotent — safe to call repeatedly. Use it as the first computer-use command in any session.

### `replicas computer stop [--port N]`
Tears down the noVNC preview (the `Desktop` tab disappears). The underlying Xvfb / openbox / x11vnc / browser keep running so the next `start` is instant.

### `replicas computer status`
Prints which desktop services are running and the active preview URL (if any). Useful for debugging when a tool call seems to be doing nothing.

### `replicas computer screenshot <path>`
Captures the current desktop to a PNG at the given path. Read the file (e.g. with your Read tool) to see what's on screen — coordinates from the screenshot drive subsequent `click` / `move` / `drag` calls.

### `replicas computer click <x> <y> [--button N] [--double] [--modifiers ctrl+shift]`
Move to (x, y) and click. Default is left-click (button 1); pass `--button 3` for right-click. `--modifiers` holds keys during the click (e.g. ctrl-click a link to open in a new tab).

### `replicas computer move <x> <y>`
Move the mouse without clicking. Useful for hovering tooltips.

### `replicas computer type <text> [--delay MS]`
Type a literal string into the focused field. Default per-character delay is 12ms (~80 wpm) — feels human and avoids breaking apps that debounce input. Bump `--delay 30` for stricter apps.

For key combos (not literal text), use `key`. `type "ctrl+l"` will literally type the seven characters `c t r l + l`.

### `replicas computer key <combo>`
Press a single key or combo. Examples: `Return`, `Escape`, `Tab`, `ctrl+l`, `ctrl+shift+t`, `alt+Left`, `Page_Down`, `Home`. Syntax matches `xdotool key`.

### `replicas computer scroll <up|down|left|right> [--amount N] [--x X --y Y]`
Scroll the wheel. Pass `--x` / `--y` to hover before scrolling (otherwise scrolls wherever the cursor currently is). Default amount is 3 wheel ticks.

### `replicas computer drag <fromX> <fromY> <toX> <toY>`
Press left mouse at (fromX, fromY), drag to (toX, toY), release. For things like dragging a file onto an upload zone.

### `replicas computer launch <app> [args...]`
Spawns an app on the workspace display. Built-in aliases:
- `chrome` — Google Chrome with a clean profile and sane flags
- `chromium` — Chromium variant
- `firefox` — Firefox
- `terminal` / `xterm` — xterm
Anything else gets `exec`'d verbatim, so `replicas computer launch xeyes` works if xeyes is installed.

### `replicas computer record start <path> [--fps N]`
Starts an ffmpeg screen recorder. Output is a fragmented MP4 (still playable if the workspace dies mid-record). Default 60fps; drop to 30 if the workspace is CPU-constrained.

Only one recording at a time. Re-running `start` while one is active fails — call `stop` first.

### `replicas computer record stop`
SIGINTs ffmpeg, waits for it to finalize the MP4, prints the output path. Upload it with `replicas media upload <path>` to share it.

## Patterns

### Action / screenshot loop
You are blind between tool calls. After any action that changes the screen, take a screenshot before deciding the next coordinate:

```bash
replicas computer click 521 700
sleep 2  # let the page settle
replicas computer screenshot /tmp/after-click.png
# read /tmp/after-click.png, decide next click
```

`sleep` is a regular shell sleep — there's no `replicas computer wait` command, but you can mix shell sleeps freely.

### Typing into an address bar
```bash
replicas computer key ctrl+l                    # focus address bar
replicas computer type "https://example.com"
replicas computer key Return
sleep 3                                          # wait for page load
replicas computer screenshot /tmp/loaded.png
```

### Coordinates from screenshots
The display is 1920×1080. Screenshot pixels map 1:1 to click coordinates — if your Read tool shows a button at pixel (520, 700), click `replicas computer click 520 700`. **No translation needed.** Modern image-reading models often imagine the screenshot is at a different resolution; trust the `xdpyinfo` value (`replicas computer status` shows the real size).

### Letting the user watch
Always start the desktop session with `replicas computer start` *before* doing anything visual, even if you don't need the URL yourself. The Desktop tab appears in their dashboard. They get to watch and intervene if needed.

### Recording a deliverable
For tasks the user wants proof of:
```bash
replicas computer start                                 # makes it visible live too
replicas computer record start /tmp/walkthrough.mp4
# ... your work ...
replicas computer record stop
replicas media upload /tmp/walkthrough.mp4
```
Then embed the printed `![…](…)` line in your chat reply. See `MEDIA.md`.

### Cleaning up
Call `replicas computer stop` when you're done with the visual demo so the live preview URL goes away. The services keep running so the next `start` is instant.

## Failure modes

- **"Desktop services script missing"**: workspace image is older than this skill. Tell the user — nothing you can do from the CLI side.
- **`xdotool ... failed: Can't open display`**: Xvfb didn't come up. `replicas computer status` will show which service is dead. Re-running any CLI command auto-attempts to start it.
- **Browser doesn't appear after `launch chrome`**: give it 1-2s, then screenshot. Chrome cold-start on the virtual display takes ~500ms but bigger pages take longer.
- **Live preview shows static / black screen**: the browser may have crashed. `replicas computer status` should show no Chrome process — re-launch.

## What gets baked in vs. lazy

| Component | Where |
|---|---|
| `xvfb`, `openbox`, `tint2`, `x11vnc`, `websockify`, `xdotool`, `scrot`, `ffmpeg`, `google-chrome` | Baked into the workspace image |
| Xvfb / openbox / tint2 / x11vnc / websockify processes | Started at workspace boot (`replicas-start-desktop-services`) |
| noVNC preview URL (port 6080) | **Lazy** — created by `replicas computer start` |
| Dashboard `Desktop` tab | Appears when the preview URL is live, disappears on `stop` |

You can call any of the input tools (`click`, `type`, `screenshot`, etc.) without first calling `start` — they'll work since the daemons are running. `start` is only needed when you want the user to see the live stream.
