# Media (Screenshots, Recordings, Audio)

This guide covers how to share screenshots, screen recordings, generated diagrams, and audio clips with the user inline in the Replicas chat.

## Prerequisites

The `replicas` CLI is pre-installed and authenticated in your workspace. No additional setup is needed.

## When to use

Whenever you produce media that the user should see (UI verification screenshot, browser automation recording, generated diagram, audio sample, etc.), upload it to Replicas first. This is **mandatory** — even if you're also sending the file elsewhere (Slack, Linear, GitHub).

## Uploading

```bash
replicas media upload <path-to-file>
```

The CLI prints two lines:

1. A markdown image line: `![filename](<url>)`
2. A "View in Replicas" link to the workspace media tab.

## How to use the output

### In your Replicas chat reply

Include line 1 **verbatim** where you want the media to render inline. The chat substitutes it with an embedded image, video, or audio player. Multiple uploads can be embedded in a single reply.

### On external platforms (Slack, Linear, GitHub)

Also upload the raw bytes via that platform's own upload API (e.g. Slack `files.upload`, Linear attachments) so the recipient sees the media without needing Replicas access. **AND** include line 2 (the dashboard link) in the message so they can find the file in the Replicas media tab.

The Replicas upload is mandatory; the external upload is in addition to it, not instead of it.

## Recording defaults

When you record video (browser automation, screen capture, etc.):

- **Aspect ratio:** 16:9 (1920×1080 or 1280×720)
- **Frame rate:** 60 FPS or whatever the user specifies

Tools like Playwright default to a low frame rate that produces choppy playback — explicitly configure recording dimensions and FPS:

```ts
// Playwright example
const context = await browser.newContext({
  recordVideo: { dir: './videos', size: { width: 1280, height: 720 } },
});
```

For `ffmpeg` screen captures, pass `-r 30` (or `-r 60`) to set the frame rate.

## Supported formats

Auto-detected from the filename extension:

| Extension | Kind |
|---|---|
| `png`, `jpg`, `jpeg`, `webp` | image |
| `mp4`, `webm` | video |
| `mp3`, `wav` | audio |

For other extensions, pass `--kind image|video|audio` explicitly:

```bash
replicas media upload diagram.svg --kind image
```

## Options

- `--kind <image|video|audio>` — override auto-detection
- `--session-id <id>` — associate the upload with a specific session
