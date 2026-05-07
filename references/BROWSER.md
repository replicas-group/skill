# Browser

> **This file is not the `agent-browser` reference.** It only covers Replicas-specific guidance: when to reach for the browser vs. the desktop, and how browser artifacts get shared with the user. For command syntax, options, sessions, providers, selectors, and everything else about driving the browser itself, **read the `agent-browser` skill** (installed alongside this one) or run `agent-browser --help` / `agent-browser skills get core`.

`agent-browser` is the canonical way to drive a real Chromium browser from inside a Replicas workspace. It is a fast native CLI with a persistent daemon. Use it for any task that involves interacting with a web app — testing flows, scraping, screenshots of pages, login flows, etc.

## When to use this vs. the Desktop skill

| Goal | Use |
|---|---|
| Headless browser automation (tests, login flows, navigation, scraping) | **`agent-browser`** directly |
| Browser-only screenshots, PDFs, accessibility snapshots | **`agent-browser`** directly |
| "Send the user proof of CLI + browser working side-by-side" | **Desktop** skill (`replicas desktop start`), then run `agent-browser --headed` against `DISPLAY=:99` |
| User wants to watch you live drive the browser | **Desktop** skill |

Default to `agent-browser` alone. Only escalate to the Desktop skill when you need terminal output AND browser visible together, or when the user explicitly asks for a live view.

## Sharing browser artifacts

Any artifact you produce that the user should see goes through the **Media** skill. After taking a screenshot, PDF, or recording with `agent-browser`, upload it:

```bash
replicas media upload /tmp/proof.png
# Paste the returned ![…](url) line verbatim into your reply.
```

Do not rely on the raw file path being viewable by the user — files in the workspace disappear when the workspace is deleted.

## Headed mode (with the desktop)

By default `agent-browser` is headless. For cases where you want the browser visible — to be recorded by the desktop or watched live — use the desktop helper:

```bash
replicas desktop browser https://example.com
```

That auto-starts the desktop and launches a headed Chromium on it. Prefer this over launching `agent-browser open --headed` yourself.

`DISPLAY=:99` is set globally in the workspace, so if you do invoke `agent-browser` directly, you do not need to prefix `DISPLAY=:99` — just pass `--headed`. For headless workflows (the default), do not pass `--headed`. The desktop is not required for headless work.

## What you do NOT need to do

- **Do not** install Chrome, Chromium, Playwright, or Puppeteer yourself — `agent-browser` bundles its own Chromium and the workspace image already has the runtime libs.
- **Do not** run `agent-browser install` yourself — the workspace image runs it at build time.
- **Do not** spin up the desktop just to take a screenshot — `agent-browser screenshot` does it without a display.
- **Do not** reach for `xdotool` to click in the browser — `agent-browser click @e1` is reliable, fast, and CDP-backed.
- **Do not** look here for command syntax — the `agent-browser` skill is the source of truth.
