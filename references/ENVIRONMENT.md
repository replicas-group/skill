# Environments

This guide covers everything about Replicas **environments** — the org-scoped blueprints that workspaces are built from. Includes concepts, CLI commands, agent-behavior playbooks, block protocols for env actions, dashboard URLs, and edge cases.

For shared agent rules (hard rules about block emission, tone, state-adaptation, permissions), see `ORG-CONFIG.md`. For the CLI primer and non-env commands, see `REPLICAS.md`.

## Prerequisites

The `replicas` CLI is pre-installed and authenticated in your workspace. Run `replicas whoami` once silently if you want to verify before acting. `REPLICAS.md` has the auth details.

## When to use

Reach for this guide when the user asks to:

- Create, edit, or delete environments
- Add, edit, or delete environment variables
- Upload, edit, or delete environment files
- Enable/disable/resize a warm pool
- Set up a warm hook
- Add skills or MCPs
- Tune environment configuration (system prompt, repo binding, name)

Anything that's scoped to a single environment lives here. Cross-cutting actions (integrations, automations) live in `ORG-CONFIG.md`.

## What an environment is

An environment is the blueprint workspaces boot from. It bundles everything an agent needs to do a specific kind of work:

- **Repo** — codebase the workspace clones
- **Agent** — Claude, Codex, or Bedrock
- **System prompt** — instructions tuned for this env's job
- **Env vars / files** — secrets and config
- **Skills & MCPs** — extra capabilities you give the agent
- **Warm hook & pool** — setup script + hot-workspace queue for fast starts

Teams set up **focused envs per task** (`<repo>-debugging`, `<repo>-on-call`, `<repo>-content`) so each agent has tight context. Common config lives in the **Global** env and inherits everywhere.

**Forbidden example names.** Do not suggest `staging`, `prod`, `dev`, or any deploy-stage label as an env name. Those imply prod parity, not task-focused specialization. Use task-shaped names: `debugging`, `on-call`, `content`, `automations`, `code-review`.

## Discovering state

Before any capability playbook, run the relevant read-only commands silently so you know what exists:

```bash
replicas environment list                 # all envs in the org
replicas environment vars list <env>      # variables on one env
replicas environment files list <env>     # files on one env
replicas environment warm-pool get <env>  # warm pool status
```

Then **adapt to state** (per `ORG-CONFIG.md`'s state-adaptation rule):

- **Nothing set up yet** → orient the user fully with the jot-note framing below. Define the concept, surface the why, then act.
- **Already set up** → acknowledge what's there in one line, then act on the user's specific ask. Don't re-orient.
- **Default the env.** If the workspace is bound to an env (`workspace.environment_id`), every action defaults to that env. Don't ask the user to pick or create one unless they raise it.

## Capability playbooks

### Environments

Use the orientation block above as the framing. Then branch by what `replicas environment list` and `replicas repos list` returned:

- **No repos** → "Connect a repo at [the GitHub page](https://tryreplicas.com/dashboard/github), then tell me when you're back." Stop.
- **Default env exists for the only repo, user keeps it** → no action needed; acknowledge and close with rule-9 CTA from `ORG-CONFIG.md`.
- **No env yet, or user wants a new one** → propose `<name>` (auto-derived from repo: `acme/api` → `acme-api`, lowercase, no spaces). Emit `:::confirm-action` with `kind: create_environment`, `summary: Create environment \`<name>\` bound to \`<owner>/<repo>\``, `command: replicas environment create <name> --repository <owner>/<repo>`.

After approval, acknowledge per rule 9 (link to `https://tryreplicas.com/dashboard/environment/<id>?tab=configuration`).

**Edge cases**
- Name collision → suggest a suffix and emit a new confirm-action.
- No agent credential → "Connect Claude or Codex at [the agents page](https://tryreplicas.com/dashboard/agents) first (admin-only)." Stop.

### Variables

Run `replicas environment vars list <env>` silently. One short line stating what's there (or "nothing yet"), then emit one `:::secure-input` with `action: "set-env-var"` and a `hint` describing the target env. The form has multi-row support; the user adds as many KEY/Value pairs as they want and submits together.

Do NOT suggest key names. Only the user knows which keys they need. Omit `suggested_name` unless the user named a specific key in chat ("I need CLAUDE_API_KEY and S3_API_KEY"). When they do, emit one block with `suggested_name` for one of the keys.

Synthetic save reply: `Saved <keys> to <env>.` or `Saved N variables (k1, k2, …) to <env>.`. Acknowledge per rule 9, link to `?tab=variables`.

**Edge cases**
- User pastes a secret in chat → don't echo it. "Use the form below." Emit a fresh `:::secure-input`.
- File credential (service-account JSON, AWS creds) that should appear as an env var → `action: "upload-file-to-var"`. The form gives a textarea for content so the user can paste it; the value is stored as a regular env var.

### Files

Env files are written into every workspace at a configured path. Use this for config files (`.env.production`), credential JSON, or any content too big for an env var. Encrypted at rest, never in chat.

Run `replicas environment files list <env>` silently. One short line, then emit `:::secure-input` with `action: "set-env-file"` and a `hint`. The form has a file picker that supports multi-upload — the user picks one or more files from disk and the form auto-fills the path from each filename (editable). Submit writes them all.

Synthetic save reply: `Wrote file <path> to <env>.` or `Wrote N files (<paths>) to <env>.`. Acknowledge per rule 9, link to `?tab=files`.

### Warm pool

A warm pool keeps a handful of pre-provisioned workspaces hot in the background so the next one your agent boots starts in seconds instead of a minute.

> A **warm pool** keeps a few fully-provisioned workspaces hot. The next workspace your agent boots starts in seconds.
>
> - **Pool size** — user-settable, 0 to 20 workspaces. 0 disables the pool.
> - **Most useful when** — automations fire often (PR triggers, on-call debugging, daily crons)
> - **Cost** — workspaces in the pool count against your usage even when idle

Branches:

- **Enable / disable / resize** → emit `:::confirm-action` with `kind: toggle_warm_pool`, `command: replicas environment warm-pool enable <env>` (or `disable <env>`, or `set <env> --size <N>` for explicit size).
- **Pointer-only request** ("just explain it") → orient + link to `?tab=warm-hooks` (the warm-pool config lives on the warm-hooks tab in the dashboard, labeled "Warm Hooks & Pools").

After approval, acknowledge per rule 9 (link to `?tab=warm-hooks`).

### Warm hook

Two-tier hierarchy:

> A **warm hook** is a bash script that runs once when a workspace provisions. Two tiers:
>
> - **Global warm hook** — runs in every workspace across every environment. Good for shared setup that applies everywhere.
> - **Per-environment warm hook** — runs *after* the global one, in workspaces bound to a specific environment. Good for more specialized setup (a build cache for one repo, a specific registry login, etc.).
>
> Common uses:
>
> - **Installing deps** — `bun install`, `pnpm install`, `pip install -r requirements.txt`
> - **Priming caches** — warm a build cache or download model weights
> - **Private-registry login** — `gh auth login --with-token < ~/.token`
> - **Pre-pulling images** — `docker pull <internal-image>`

If the user's request is shared infrastructure (deps everyone needs, common cache), default to the **global** warm hook so it applies everywhere; if it's specific to one repo or workflow, default to the **per-environment** warm hook.

Branches:

- **Set up a script** → emit `:::edit-warm-hook` with `environment_id`, `environment_name`, and a `script: |` body. The UI shows an editable textarea, a **Test** button that runs the script in a sandbox, and a **Save** that's only enabled after a passing test. The script body must come strictly from what the user said in chat (or one of the example uses above, if they picked one); if they're vague, ask one short clarifier first. Synthetic save reply: `Saved warm hook for <env>.`.
- **Just browse / iterate manually** → point them at the dashboard tabs. Both URLs:
  - Global: `https://tryreplicas.com/dashboard/environment/global?tab=warm-hooks`
  - Per-env: `https://tryreplicas.com/dashboard/environment/<env-id>?tab=warm-hooks`

**When a test fails**, you'll get a synthetic chat reply of the form `Warm hook test failed (exit N) on <env>.` (or `timed out`) with a fenced sandbox-output code block and the line `What should I change in the script?`. Read the output, diagnose, and **emit a new `:::edit-warm-hook` block** with a fixed script. Brief one-line lead-in is fine (e.g. *"Looks like there's no `package.json` in the repo — dropping the `bun install` line."*); don't propose changes in prose without re-emitting the block.

After save, acknowledge per rule 9 with the warm-hooks tab URL and a one-line hierarchy reminder ("Global runs first, then this env's hook layers on top").

For per-repo warm-hook commands (an extra tier that runs after the env-level hook, in the repo's cwd) see the `replicas.json` section in `REPLICAS.md`.

### Skills & MCPs

Both extend what an agent can do, per-environment.

> - **Skills** — pre-packaged playbooks the agent can load on demand (a "PR review skill", a "Linear triage skill"). One-click add from the recommended catalog.
> - **MCPs** — external tools the agent can call (Postgres, Notion, Atlassian). Need provider secrets, so configured in the dashboard.

Emit `:::add-skills-mcps` with `environment_id` + `environment_name`. The UI fetches the recommended skills catalog server-side and shows the top picks with checkboxes; MCPs render as cards linking to the dashboard's MCPs tab (since they need secrets). The user picks skills + clicks Add.

Synthetic save reply: `Added skill <name> to <env>.` or `Added N skills (<names>) to <env>.`. Acknowledge per rule 9 (link to `?tab=skills`).

If the user wants MCPs configured for them (rare — they'd have to volunteer the secrets), guide them to the dashboard tab. Do not collect MCP secrets via secure-input — that flow only saves to env vars, not MCP config.

### Configuration

The configuration tab is where the user tunes an env's settings: system prompt, repo binding, name, description. Most edits are one-off and easier to do with the dashboard form. **Don't try to walk them through editing the system prompt in chat — link them to the tab.**

> An environment's **configuration** is the tunable layer on top of the basics — the system prompt, repo binding, name, description. The dashboard tab has a form for all of it.

Point them at `https://tryreplicas.com/dashboard/environment/<env-id>?tab=configuration`.

If they want a one-shot mutation like "rename the env" or "bind it to a different repo", you can emit `:::confirm-action edit_environment` with the relevant flags. Anything richer (system-prompt iteration, etc.) — just link.

## Block protocols (env-specific)

For the cross-cutting blocks (`:::confirm-action`, `:::connect-integration`, `:::automation-templates`, `:::onboarding-advance`), see `ORG-CONFIG.md`.

### `:::secure-input`

```
:::secure-input
action: set-env-var | upload-file-to-var | set-env-file
hint: "What this is for, e.g. 'Keys for replicas-dev'"
suggested_name: "OPENAI_API_KEY"   (optional — only when user named a specific key)
:::
```

The form has an env dropdown including **+ Create new environment**, so you don't need to create the env first. The agent never sees values. `set-env-file` uses a multi-file picker that auto-fills the path from each filename.

### `:::add-skills-mcps`

```
:::add-skills-mcps
environment_id: <env-uuid>
environment_name: <env-name>
hint: One short line of context (optional)
:::
```

The UI fetches the recommended skills catalog from the server and renders multi-select checkboxes. MCPs render as separate cards linking to the dashboard's MCPs tab (they need secrets). Save adds the picked skills via the existing skill API.

### `:::edit-warm-hook`

```
:::edit-warm-hook
id: wh_<8-char-random>
environment_id: <env-uuid>
environment_name: <env-name>
hint: One short line of context (optional)
script: |
  <bash body — derive strictly from chat, no invented defaults>
:::
```

The UI shows an editable textarea pre-filled with `script`, a **Test** button that runs the script in an isolated sandbox and streams the output, and a **Save** that's only enabled after a passing test. On save the UI POSTs to `/v1/environments/<id>/warm-hooks/save` and sends back the synthetic reply `Saved warm hook for <env-name>.`. On test failure, the UI sends back a `Warm hook test failed (exit N) on <env>.` reply with the sandbox output in a fenced code block — re-emit a new `:::edit-warm-hook` with a fixed script in response.

## CLI reference

### Environments

```bash
replicas environment list
replicas environment get <id-or-name>          # use "global" for the Global env
replicas environment create <name> --repository <repo>
replicas environment edit <id-or-name> [--name "..."] [--repository <repo>]
replicas environment delete <id-or-name> [--force]
```

Notes:
- Environments resolve by name or UUID. `global` is an alias for the org's Global env.
- Non-global envs need a repo (or repo set) to back a workspace.
- `edit` on the Global env is rejected — manage its contents (vars/files) instead.

### Env vars

```bash
replicas environment vars list <env>
replicas environment vars set <env> <KEY> <VALUE>          # forbidden in chat — use :::secure-input
replicas environment vars delete <env> <KEY|ID> [--force]
```

`vars set` is upsert. Secrets must not pass through chat or confirm-action — always use `:::secure-input`.

### Env files

```bash
replicas environment files list <env>
replicas environment files set <env> <path> --content "..."
replicas environment files set <env> <path> --file <local-path> [--name "Friendly name"]
replicas environment files delete <env> <path-or-id> [--force]
```

Each file is capped at 64KB. `set` is upsert (matched by destination path).

### Warm hooks (CLI)

```bash
replicas environment warm-hook get <env>
replicas environment warm-hook set <env> --script <path>     # or --script - / --inline "..."
replicas environment warm-hook test <env> --script <path>    # or --use-current; streams sandbox output
```

The inline `:::edit-warm-hook` block is the recommended path for in-chat editing (Test + Save with a passing-test gate). The CLI verbs are for scripting, one-shot edits from a known-good file on disk, or replaying a previously-saved hook into a dry-run via `--use-current`.

### Warm pools

```bash
replicas environment warm-pool get <env>
replicas environment warm-pool enable <env>
replicas environment warm-pool disable <env>
replicas environment warm-pool set <env> --size <N>     # 0 disables, 1-20 enables with that size
```

## Dashboard URLs

**Acknowledgment links must be tab-precise** — land the user on the exact tab that shows the change they just made.

| Change | URL |
| --- | --- |
| Env created or edited | `https://tryreplicas.com/dashboard/environment/<id>?tab=configuration` |
| Variable created/edited/deleted | `https://tryreplicas.com/dashboard/environment/<id>?tab=variables` |
| Env file created/edited/deleted | `https://tryreplicas.com/dashboard/environment/<id>?tab=files` |
| Skill added | `https://tryreplicas.com/dashboard/environment/<id>?tab=skills` |
| MCP added | `https://tryreplicas.com/dashboard/environment/<id>?tab=mcps` |
| Warm hook (per-env) | `https://tryreplicas.com/dashboard/environment/<env-id>?tab=warm-hooks` |
| Warm hook (global) | `https://tryreplicas.com/dashboard/environment/global?tab=warm-hooks` |
| Warm pool toggled | `https://tryreplicas.com/dashboard/environment/<env-id>?tab=warm-hooks` (same tab — labeled "Warm Hooks & Pools") |

Other env-related pages:

- Environments list: `https://tryreplicas.com/dashboard/environment`

## Common errors

- `An environment with this name already exists` → use `replicas environment edit` or pick a different name.
- `Cannot delete the global environment` → exactly one Global env per org, permanent. Manage its *contents* instead.
