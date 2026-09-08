# Slack Integration

This guide covers how to interact with Slack from within your Replicas workspace.

## Prerequisites

Check if the `SLACK_BOT_TOKEN` environment variable is set:

```bash
echo "${SLACK_BOT_TOKEN:+set}"
```

- If **set**: Your workspace has Slack access. You can use the Slack Web API as described below.
- If **not set**: Slack has not been configured for this workspace. The user needs to connect Slack in the [Replicas dashboard](https://replicas.dev) under their organization's integration settings. Let the user know and do not attempt Slack operations.

## Using the Slack API

All requests use the `$SLACK_BOT_TOKEN` for authentication via the Slack Web API.

### Fetching a Thread from a Slack Link

If you encounter a Slack message link (e.g. `https://team.slack.com/archives/C0123ABC/p1234567890123456`), extract the channel ID and thread timestamp:

- **Channel ID**: The segment after `/archives/` (e.g. `C0123ABC`)
- **Thread TS**: The `p` value with a dot inserted before the last 6 digits (e.g. `p1234567890123456` -> `1234567890.123456`)

```bash
curl -s "https://slack.com/api/conversations.replies?channel=CHANNEL_ID&ts=THREAD_TS" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN"
```

### Sending a Message

Write like a teammate, not a report. Lead with the outcome, keep routine updates to one to three sentences, and remove repetition, filler, step-by-step narration, and details the recipient can get from a linked artifact. Preserve every fact needed to understand the result, blocker, or next action.

Plain text is appropriate for a short conversational reply. Use [Block Kit](https://docs.slack.dev/block-kit/) whenever structure or an action would make the message faster to scan or use. You have broad leeway to combine supported blocks and elements, including:

- `section` with `mrkdwn` for the main update and `fields` for compact status, owner, date, or metric pairs
- `actions` with buttons for pull requests, dashboards, approvals, downloads, or clear next steps
- `context` for brief secondary metadata such as environment, timestamp, or source
- `header` and `divider` for longer announcements with genuinely distinct sections
- images, accessory buttons, selects, date pickers, and other interactive elements when they directly support the task

Do not force blocks into a simple reply, turn prose into decorative UI, or repeat the same content across blocks. Keep the top-level `text` as a concise, complete fallback for notifications and accessibility even when `blocks` are present.

```bash
curl -s -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "CHANNEL_ID",
    "text": "Your message here",
    "thread_ts": "OPTIONAL_THREAD_TS"
  }'
```

Omit `thread_ts` to post a new message to the channel. Include it to reply in a thread.

For a structured update with an action:

```bash
curl -s -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "CHANNEL_ID",
    "text": "The change is ready for review: https://github.com/owner/repo/pull/123",
    "thread_ts": "OPTIONAL_THREAD_TS",
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "The change is ready for review: <https://github.com/owner/repo/pull/123|PR #123>"
        }
      },
      {
        "type": "actions",
        "elements": [
          {
            "type": "button",
            "style": "primary",
            "text": { "type": "plain_text", "text": "View PR" },
            "url": "https://github.com/owner/repo/pull/123",
            "action_id": "view_pr"
          }
        ]
      }
    ]
  }'
```

### Searching Messages

```bash
curl -s "https://slack.com/api/search.messages?query=YOUR_SEARCH_QUERY" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN"
```

### Uploading Files

```bash
curl -s -X POST "https://slack.com/api/files.uploadV2" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -F "channel_id=CHANNEL_ID" \
  -F "file=@/path/to/file" \
  -F "title=File title"
```

### Other Operations

You can list channels, read channel history, add reactions, and perform any other operation supported by the Slack Web API using the same authentication pattern.

For full API documentation, see: https://docs.slack.dev/apis/web-api/
