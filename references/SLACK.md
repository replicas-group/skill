# Slack Integration

Use `@replicas/sdk`; never read or send a Slack token directly. The SDK calls Replicas, which selects only this workspace's organization connection.

## Check access

```ts
import { replicas } from '@replicas/sdk';

const { native } = await replicas.integrations.list();
if (!native.slack) throw new Error('Connect Slack in Replicas organization integrations first.');
```

## Read a thread

For a link such as `https://team.slack.com/archives/C0123ABC/p1234567890123456`, the channel is `C0123ABC` and the timestamp is `1234567890.123456`.

```ts
const thread = await replicas.slack.call('conversations.replies', {
  channel: 'C0123ABC',
  ts: '1234567890.123456',
  limit: 200,
});
```

## Send a message

Write like a teammate, not a report. Lead with the outcome, keep routine updates to one to three sentences, and remove repetition, filler, step-by-step narration, and details the recipient can get from a linked artifact. Preserve every fact needed to understand the result, blocker, or next action.

Plain text is appropriate for a short conversational reply. Use [Block Kit](https://docs.slack.dev/block-kit/) whenever structure or an action would make the message faster to scan or use. You have broad leeway to combine supported blocks and elements, including:

- `section` with `mrkdwn` for the main update and `fields` for compact status, owner, date, or metric pairs
- `actions` with buttons for pull requests, dashboards, approvals, downloads, or clear next steps
- `context` for brief secondary metadata such as environment, timestamp, or source
- `header` and `divider` for longer announcements with genuinely distinct sections
- images, accessory buttons, selects, date pickers, and other interactive elements when they directly support the task

Do not force blocks into a simple reply, turn prose into decorative UI, or repeat the same content across blocks. Keep `text` as a concise, complete fallback for notifications and accessibility even when `blocks` are present.

```ts
await replicas.slack.call('chat.postMessage', {
  channel: 'C0123ABC',
  thread_ts: '1234567890.123456',
  text: 'The change is ready for review: https://github.com/owner/repo/pull/123',
  blocks: [
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: 'The change is ready for review: <https://github.com/owner/repo/pull/123|PR #123>',
      },
    },
    {
      type: 'actions',
      elements: [
        {
          type: 'button',
          style: 'primary',
          text: { type: 'plain_text', text: 'View PR' },
          url: 'https://github.com/owner/repo/pull/123',
          action_id: 'view_pr',
        },
      ],
    },
  ],
});
```

Only the message that first shares a pull request or merge request gets the button. Follow-ups keep the link in `text` and omit the button. Use "View MR" for GitLab. With several links, give each button a unique `action_id` and name its repository in the label.

## Start a conversation

Attach every new top-level conversation so future replies route to this workspace. For a reply in another thread, attach its root `thread_ts`, not the reply timestamp. Do not attach the originating thread again.

```ts
const message = await replicas.slack.call<{ channel: string; ts: string }>('chat.postMessage', {
  channel: 'C0123ABC',
  text: 'Update from Replicas',
});
await replicas.slack.attachThread({ channel: message.channel, threadTs: message.ts });
```

## Search and batch

```ts
const [messages, users] = await Promise.all([
  replicas.slack.call('search.messages', { query: 'launch status' }),
  replicas.slack.call('users.list', { limit: 200 }),
]);
```

Supported methods cover conversations, messages, search, users, reactions, and Slack's external file-upload flow. An unsupported method is rejected by Replicas before Slack is called.

## Download a file

Pass a Slack file object's `url_private_download` to the authenticated download helper. Provider credentials stay behind the workspace gateway.

```ts
const response = await replicas.slack.download(file.url_private_download);
await Bun.write('/tmp/recording.mov', response);
```

For screenshots, recordings, diagrams, or other media, read `references/MEDIA.md` before posting.

## Older workspaces without the SDK

If `@replicas/sdk` cannot be imported, use the gateway with workspace authentication. Send JSON containing `method` and `arguments` on stdin:

```bash
curl -sS --fail-with-body -X POST "${REPLICAS_MONOLITH_URL:-$MONOLITH_URL}/v1/engine/slack/api" \
  -H "Authorization: Bearer $REPLICAS_ENGINE_SECRET" \
  -H "X-Workspace-Id: ${REPLICAS_WORKSPACE_ID:-$WORKSPACE_ID}" \
  -H "Content-Type: application/json" \
  --data-binary @-
```
