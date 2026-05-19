# Media (Screenshots, Recordings, Audio)

This guide covers how to share screenshots, screen recordings, generated diagrams, and audio clips with the user inline in the Replicas chat.

## Prerequisites

The `replicas` CLI is pre-installed and authenticated in your workspace. No additional setup is needed.

## When to upload

Upload to Replicas in these cases — and **only** these cases:

1. **Media you produce.** Any screenshot, screen recording, generated diagram, or audio clip you create that the user might want to see. Upload before doing anything else with the file (analyzing, deleting, sending elsewhere). This applies even when you're also sending the file to Slack, Linear, GitHub, etc.
2. **Files the user explicitly asks you to upload.** If the user sends or points at a file (image, video, audio) and asks you to upload it, run `replicas media upload`. Otherwise leave it alone — files in the workspace the user did not ask about should not be auto-uploaded as media.
3. **Anything you plan to share externally (Slack, Linear, GitHub, etc.).** Upload to Replicas *in addition to* the platform's native upload. Never as a replacement.

If none of these apply, don't upload.

## Uploading

```bash
replicas media upload <path-to-file> [<path-to-file> ...]
```

Pass one or more file paths. Uploading several files in a single invocation is preferred over running the command repeatedly — it's faster and keeps the output grouped.

For each file, the CLI prints a markdown embed line: `![filename](<api-url>)`. After all files are uploaded, it prints a "View in Replicas" line with the workspace media tab URL.

## How to use the output

### CRITICAL: the markdown embed URL is for Replicas chat only

The URL inside `![filename](...)` points at `api.tryreplicas.com/v1/media/<id>`. This is **not a public URL** — it requires the Replicas chat's authenticated session, which resolves it to a presigned download. Anywhere else (Slack, Linear, GitHub, a browser tab the user opens directly, a customer copy-pasting from chat), it returns `{"error":"Missing authorization token"}` and renders as a broken image.

**Never paste this URL outside your Replicas chat reply.** Not in Slack messages, not in Linear comments, not in PR descriptions or commit messages, not in external docs — nowhere a non-Replicas surface will render it.

### Always render the workspace link as `[View in Replicas](<url>)`

Whenever you share the workspace media tab URL — in chat or anywhere else — format it as a markdown hyperlink labeled **View in Replicas**:

```markdown
[View in Replicas](https://tryreplicas.com/workspaces/<workspace-id>?mode=media)
```

Never paste the raw URL. Raw URLs look unpolished.

### In your Replicas chat reply

Include each markdown embed line **verbatim** where you want that file to render inline. The chat substitutes each one with an embedded image, video, or audio player. Multiple embeds can appear in a single reply.

Also tell the user they can find the files in the **media tab** of the workspace, and include a `[View in Replicas](...)` hyperlink (using the URL the CLI printed) so they can open it directly. Do this for every batch of uploads, even when the media is already embedded inline.

### On external platforms (Slack, Linear, GitHub, etc.)

Do **both** of these — neither alone is sufficient:

1. Upload the raw bytes via that platform's own upload API (Slack `files.upload`, Linear attachments, Imgur for GitHub PR/issue images, etc.) so the recipient actually sees the media.
2. Include a `[View in Replicas](https://tryreplicas.com/workspaces/<workspace-id>?mode=media)` hyperlink so they can also find it in Replicas.

Do **not** include the `![filename](https://api.tryreplicas.com/...)` markdown embed in external messages. It will render as a broken image / 401 for the recipient.

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
