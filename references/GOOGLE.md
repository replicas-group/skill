# Google Workspace (Docs, Sheets, Forms, Drive)

This guide covers how to create and edit Google Docs, Sheets, and Forms — plus do basic Drive file operations — from inside a Replicas workspace, using the monolith as a gateway to Google's APIs.

## Prerequisites

The integration is configured at the org or user level by the Replicas admin. From inside a workspace you don't have a Google access token directly; instead you call the monolith's `/v1/gdrive/*` endpoints, authenticated with your workspace's engine secret. The monolith refreshes the org's (or user's) Google access token and proxies the call.

Quick check that the integration is connected:

```bash
curl -s -X GET "$MONOLITH_URL/v1/gdrive/credentials" \
  -H "Authorization: Bearer $REPLICAS_ENGINE_SECRET" \
  -H "X-Workspace-Id: $WORKSPACE_ID"
```

- If `hasCredentials` is `true`: you're good to go.
- If `hasCredentials` is `false`: Google has not been connected for this org. Ask the user to go to **Settings → Integrations → Google** in the [Replicas dashboard](https://www.tryreplicas.com) and connect a Google account. Do not attempt Google operations until it's connected.

Standard auth headers used by every call below:

```
Authorization: Bearer $REPLICAS_ENGINE_SECRET
X-Workspace-Id: $WORKSPACE_ID
```

For brevity the examples below use a shell variable:

```bash
GDRIVE_AUTH=(-H "Authorization: Bearer $REPLICAS_ENGINE_SECRET" -H "X-Workspace-Id: $WORKSPACE_ID")
```

## Important constraint: drive.file scope

The integration uses the **sensitive-tier `drive.file` scope**. That means Replicas can only read and edit Google files **it created itself**. It **cannot**:

- Read or edit a user's pre-existing Google Docs, Sheets, or Forms — even ones that were shared with the connected Google account.
- List or search the user's broader Drive.
- Touch any file that was not created via these gateway endpoints.

If the user asks you to edit an existing doc that Replicas didn't create, tell them this constraint and offer to create a new doc that mirrors what they want.

## Google Docs

### Create a new doc

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/docs" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Meeting notes 2026-05-14"}'
```

Returns the full Doc object; grab `.documentId` for follow-up calls.

### Read a doc

```bash
curl -s "$MONOLITH_URL/v1/gdrive/docs/$DOC_ID" "${GDRIVE_AUTH[@]}"
```

Returns the full document structure — `body.content` is an ordered list of structural elements (paragraphs, tables, etc.) with character indexes you can target for edits.

### Edit a doc (batchUpdate)

The Docs API edits use a list of [structural requests](https://developers.google.com/workspace/docs/api/reference/rest/v1/documents/request). Insert text, then style it; or insert tables, images, page breaks, etc.

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/docs/$DOC_ID/batchUpdate" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{
    "requests": [
      { "insertText": { "location": { "index": 1 }, "text": "Hello, world!\n" } }
    ]
  }'
```

Common request types:

- `insertText` — insert plain text at a given index
- `deleteContentRange` — delete a range
- `replaceAllText` — find-and-replace
- `updateTextStyle` — bold/italic/colors/fonts/sizes for a range
- `updateParagraphStyle` — headings (`HEADING_1`..`HEADING_6`), alignment, spacing
- `createParagraphBullets` — turn paragraphs into bulleted/numbered lists
- `insertTable` — insert a table
- `insertInlineImage` — insert an image from a URL

Edits are verbose but powerful. Prefer batching many requests into a single `batchUpdate` call rather than making many round trips — it's faster and keeps the doc state consistent.

## Google Sheets

### Create a new spreadsheet

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/sheets" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q2 metrics"}'
```

Returns the full Spreadsheet object; grab `.spreadsheetId`.

### Read a range of cells

```bash
# Range is in A1 notation, e.g. "Sheet1!A1:C10"
curl -s "$MONOLITH_URL/v1/gdrive/sheets/$SHEET_ID/values/$(printf %s 'Sheet1!A1:C10' | jq -sRr @uri)" \
  "${GDRIVE_AUTH[@]}"
```

### Write a range of cells

```bash
curl -s -X PUT \
  "$MONOLITH_URL/v1/gdrive/sheets/$SHEET_ID/values/$(printf %s 'Sheet1!A1:B2' | jq -sRr @uri)?valueInputOption=USER_ENTERED" \
  "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{
    "range": "Sheet1!A1:B2",
    "majorDimension": "ROWS",
    "values": [
      ["Name", "Revenue"],
      ["Q1",   "=SUM(B3:B100)"]
    ]
  }'
```

`valueInputOption=USER_ENTERED` makes formulas evaluate as if a human typed them. Use `RAW` to write literal strings.

### Bulk operations (formatting, charts, new tabs, etc.)

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/sheets/$SHEET_ID/batchUpdate" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{ "requests": [ { "addSheet": { "properties": { "title": "Raw data" } } } ] }'
```

`batchUpdate` accepts an array of [Sheets API requests](https://developers.google.com/workspace/sheets/api/reference/rest/v4/spreadsheets/request) — addSheet, updateSheetProperties, repeatCell, addChart, autoResizeDimensions, etc.

## Google Forms

### Create a new form

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/forms" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Customer feedback"}'
```

Returns the form. Grab `.formId`.

### Add questions / edit form structure

The Forms API uses its own `batchUpdate`:

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/forms/$FORM_ID/batchUpdate" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{
    "requests": [
      {
        "createItem": {
          "item": {
            "title": "How likely are you to recommend us?",
            "questionItem": {
              "question": {
                "required": true,
                "scaleQuestion": { "low": 0, "high": 10, "lowLabel": "Not at all", "highLabel": "Very likely" }
              }
            }
          },
          "location": { "index": 0 }
        }
      }
    ]
  }'
```

See the [Forms API Request reference](https://developers.google.com/workspace/forms/api/reference/rest/v1/forms/request) for all supported request types — text questions, multiple choice, checkboxes, scale, grid, date, time, file upload, section breaks, branching logic, quiz settings, etc.

### Read responses

```bash
curl -s "$MONOLITH_URL/v1/gdrive/forms/$FORM_ID/responses" "${GDRIVE_AUTH[@]}"
```

Pagination: pass `?pageToken=...&pageSize=...` to walk through responses.

## Drive operations (only on Replicas-created files)

### Share a file with a person

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/files/$FILE_ID/permissions" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "user",
    "role": "writer",
    "emailAddress": "alice@example.com",
    "sendNotificationEmail": true
  }'
```

Roles: `reader`, `commenter`, `writer`. Types: `user`, `group`, `domain`, `anyone`.

### Make a file viewable by anyone with the link

```bash
curl -s -X POST "$MONOLITH_URL/v1/gdrive/files/$FILE_ID/permissions" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{ "type": "anyone", "role": "reader" }'
```

### List existing permissions

```bash
curl -s "$MONOLITH_URL/v1/gdrive/files/$FILE_ID/permissions" "${GDRIVE_AUTH[@]}"
```

### Rename / move a file

```bash
curl -s -X PATCH "$MONOLITH_URL/v1/gdrive/files/$FILE_ID" "${GDRIVE_AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{"name":"Final report.docx"}'
```

To move into a folder, also pass `addParents` and `removeParents` as query parameters per [Drive API docs](https://developers.google.com/workspace/drive/api/reference/rest/v3/files/update).

### Get file metadata

```bash
curl -s "$MONOLITH_URL/v1/gdrive/files/$FILE_ID?fields=id,name,mimeType,webViewLink,parents,modifiedTime" \
  "${GDRIVE_AUTH[@]}"
```

`webViewLink` is the human-shareable URL that opens in Google Docs/Sheets/Forms.

### Delete a file

```bash
curl -s -X DELETE "$MONOLITH_URL/v1/gdrive/files/$FILE_ID" "${GDRIVE_AUTH[@]}"
```

### List Replicas-created files

```bash
curl -s "$MONOLITH_URL/v1/gdrive/files?pageSize=50" "${GDRIVE_AUTH[@]}"
```

Pass `?q=...` to filter using [Drive API search syntax](https://developers.google.com/workspace/drive/api/guides/search-files). Only files the app created or was granted access to will appear.

## Tips

- **Always return the `webViewLink`** to the user when you create or edit a file so they can open it. Get it from `/v1/gdrive/files/$FILE_ID?fields=webViewLink` or from `documents.documentId` → `https://docs.google.com/document/d/$ID/edit`.
- **Batch your edits.** A single `batchUpdate` with 20 requests beats 20 round-trips.
- **Watch error responses.** A 412 from the gateway means the org has no Google credentials connected — tell the user to connect Google in the dashboard. Other 4xx responses come straight from Google and usually explain the issue clearly.
