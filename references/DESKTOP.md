# Desktop

A virtual desktop on a hidden X display, used to **show** the user what you are doing — live URL, screen recording, or full-screen screenshot. The user can only watch; you drive everything.

For browser-only work without a terminal in frame, use `agent-browser` directly. The desktop is for **terminal + browser side-by-side**.

## Always share the live URL up front

After `replicas desktop start` (or any command that auto-starts it), paste the URL it prints in your reply *before* doing real work, so the user can watch live. Recording is asynchronous; live URLs are synchronous and almost always more useful.

## Operating mode

Mechanical execution, not creative orchestration. Run commands sequentially, don't write recovery wrappers, don't plan extensively. On unrecoverable failures, report and stop.

If you can pick your model: prefer the **smaller / faster** one (Haiku, GPT-4o-mini). The work is mechanical; bigger models overthink it.

## Commands

```bash
replicas desktop start                     # boot, returns view-only URL (idempotent)
replicas desktop browser <url>             # headed browser. Auto-starts. Prints window ID.
replicas desktop terminal [--cmd "..."]    # terminal window. Auto-starts. Prints window ID.
replicas desktop screenshot [path]         # full-display PNG
replicas desktop record start              # begin recording. Auto-starts. Cap 10 min, 30fps.
replicas desktop record stop               # end recording, returns mp4 path
replicas desktop mousemove <x> <y>         # glide cursor (no click)
replicas desktop click <x> <y>             # glide + click at pixel coords
replicas desktop browser-click <ref>       # glide + click an agent-browser ref (@e1)
replicas desktop status                    # current state
replicas desktop stop                      # explicit stop (rare — idle handles it)
```

`DISPLAY=:99` is set globally. Don't prefix it. Idle auto-stops after 20 minutes.

## Window launching

`browser` and `terminal` print the new window's ID — capture it instead of running `xdotool search` (which can return stale IDs):

```bash
BROW_WID=$(replicas desktop browser https://example.com)
TERM_WID=$(replicas desktop terminal --cmd 'date; sleep 60')
xdotool windowsize $BROW_WID 1300 920 windowmove $BROW_WID 590 60
```

For terminals, **always** use `--cmd 'your command'` to pre-bake the work — xfce4-terminal uses VTE which silently ignores `xdotool key --window`. The terminal stays open after the command (`--hold` is automatic).

## Cursor — visible interactions

`agent-browser click` is invisible (CDP). For visible interactions:

| Situation | Command |
|---|---|
| Click a browser element, **not in a recording** | `replicas desktop browser-click @e3` (resolves ref + glides + clicks) |
| Click during a recording | `replicas desktop click X Y` with **pre-cached** pixel coords (no agent-browser calls during recording) |
| Click pixel coords in any window (terminal, etc.) | `replicas desktop click 400 600` |
| Drift cursor between actions | `replicas desktop mousemove 1400 540 --ms 800 --easing ease-in-out` |

To get pixel coords for a browser element before recording: `agent-browser get box @e3 --json` then take the center.

**Never use `agent-browser click`/`navigate`/`scroll` for visible interactions** — CDP doesn't move the system cursor.

## Don't crash Xorg

The X server is software-rendered. Under combined load (Chrome + ffmpeg + agent-browser introspection + cursor) it can lock up. Two rules:

1. **No agent-browser calls between `record start` and `record stop`** — not `snapshot`, not `get box`, not `click`, not `navigate`. CDP introspection competes with ffmpeg/Chrome and kills Xorg. Resolve everything you need (refs → pixel coords) *before* recording.

2. **Keep recordings short**, one terminal, one browser. Don't accumulate windows across takes.

### Recording a page change

The page transition must happen *between* `record start` and `record stop`. Clicking before recording starts or after it stops produces a video with no visible navigation, even if the navigation worked.

The shape of the flow:
1. Open the page and resolve any coords you'll need (snapshot, `get box`).
2. Start recording.
3. Click via `replicas desktop click X Y` (pure X server — safe during recording). Wait long enough for the destination page to render before stopping.
4. Stop recording.
5. Verify with `agent-browser eval` or a screenshot diff *after* recording stops.

If you need fresh refs after a navigation (refs reset), stop recording, snapshot, start a new one.

## Self-recovery — authorized

If something fails (`xdotool` "Can't open display", `desktop start` times out, defunct Xorg), run this cleanup yourself without asking:

```bash
sudo rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
sudo pkill -9 -f Xorg
sudo pkill -9 -f x11vnc
sudo pkill -9 -f websockify
sudo pkill -9 -f ffmpeg
rm -rf ~/.replicas/desktop/*.pid
```

Then `replicas desktop start`. This is the same thing `desktop stop` does on newer CLIs. The "don't pkill" rule is for in-session debugging only; clearing dead state from a previous crashed session is fine. One retry max — if it crashes again, stop and report.

## Don't

- Start Xorg / x11vnc / ffmpeg / noVNC by hand.
- Install desktop packages with apt — the image has them. Missing binary = report a bug, don't work around.
- Use `xdotool search --class chrome` to find windows you just launched — capture stdout from the launch command.
- Type into a terminal via `xdotool key --window` — VTE ignores it. Use `--cmd`.
- Call `agent-browser snapshot` during a recording (rule above).
- Call `agent-browser click` during a recording (cursor stays frozen).
