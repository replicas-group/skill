# Media (Screenshots, Recordings, Audio)

This guide covers how to share screenshots, screen recordings, generated diagrams, and audio clips with the user inline in the Replicas chat.

## Prerequisites

The `replicas` CLI is pre-installed and authenticated in your workspace. No additional setup is needed.

## When to use

**Always** upload to Replicas every single time you produce media — screenshots, screen recordings, generated diagrams, audio samples, anything the user might want to see. No exceptions. Upload before doing anything else with the file (analyzing, deleting, sending elsewhere). This applies even when you're also sending the file to Slack, Linear, GitHub, or any other destination.

## Uploading

```bash
replicas media upload <path-to-file> [<path-to-file> ...]
```

Pass one or more file paths. Uploading several files in a single invocation is preferred over running the command repeatedly — it's faster and keeps the output grouped.

For each file, the CLI prints a markdown embed line: `![filename](<url>)`. After all files are uploaded, it prints a single "View in Replicas" link to the workspace media tab.

## How to use the output

### In your Replicas chat reply

Include each markdown embed line **verbatim** where you want that file to render inline. The chat substitutes each one with an embedded image, video, or audio player. Multiple embeds can appear in a single reply.

Also tell the user they can find the files in the **media tab** of the workspace, and include the "View in Replicas" link so they can open it directly. Do this for every batch of uploads, even when the media is already embedded inline.

### On external platforms (Slack, Linear, GitHub)

Also upload the raw bytes via that platform's own upload API (e.g. Slack `files.upload`, Linear attachments) so the recipient sees the media without needing Replicas access. **AND** include the "View in Replicas" link in the message so they can find the files in the Replicas media tab.

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

For other extensions, pass `--kind image|video|audio` explicitly. The kind applies to every file in that invocation, so group files of the same kind together:

```bash
replicas media upload diagram.svg --kind image
replicas media upload chart-a.svg chart-b.svg --kind image
```

## Options

- `--kind <image|video|audio>` — override auto-detection
- `--session-id <id>` — associate the upload with a specific session
