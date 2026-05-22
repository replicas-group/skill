# Replicas (in-workspace CLI)

This is the umbrella for the `replicas` CLI, what it does, how it's authenticated, where to look for specific actions. For deep dives on specific action categories, see the topical references below.

When the user asks _about_ Replicas (concepts, pricing, how a feature works), check https://docs.tryreplicas.com first. When the user asks you to _do_ something in their Replicas org, this file and its siblings cover it.

## Topical references

| Topic | Reference |
| --- | --- |
| Environments + env vars + env files + warm pools + warm hooks + skills/MCPs + configuration | `ENVIRONMENT.md` |
| Automations, integrations (Slack/Linear/Sentry connect), shared agent rules + block protocols | `ORG-CONFIG.md` |
| Onboarding wizard mechanics | `ONBOARDING.md` |

Pick the right ref based on what the user is asking for. `ENVIRONMENT.md` is self-contained for env-related work; `ORG-CONFIG.md` covers everything cross-cutting plus non-env capabilities.

## Prerequisites

The CLI is pre-installed in every workspace and pre-authenticated using the workspace's engine secret. You do **not** need to log in or set an API key. Verify:

```bash
replicas whoami
```

Expected output (in agent mode):

```
Workspace identity:
  Workspace ID:    <uuid>
  Organization ID: <uuid>
```

If you get "Not logged in", the workspace is misconfigured, surface this to the user instead of trying to work around it.

In agent mode the CLI hides commands that don't make sense for in-workspace agents (`login`, `logout`, `codex-auth`, `claude-auth`, `org switch`, `config`, `interact`, `code`, replica/workspace top-level CRUD). What you have:

| Command | What it does | See |
| --- | --- | --- |
| `replicas whoami` | Print the workspace + org identity | here |
| `replicas init` | Create a `replicas.json` / `replicas.yaml` in the current directory | here |
| `replicas connect <name>` | SSH into another workspace (rarely needed) | here |
| `replicas repos` | List repos connected to the org | here |
| `replicas environment ...` | Manage environments, env vars, files, warm pools, skills, MCPs | `ENVIRONMENT.md` |
| `replicas automation ...` | Manage automations | `ORG-CONFIG.md` |
| `replicas preview ...` | Register / list preview URLs | `PREVIEWS.md` |
| `replicas media ...` | Upload screenshots, videos, audio | `MEDIA.md` |

`replicas <command> --help` is always the source of truth for flags.

## Repositories

Read-only listing of repos connected to the org. Use when the user asks "what repos can I use?", or to validate a `--repository` value before passing it to `environment create` / `automation create`:

```bash
replicas repos
```

Repos are connected via the GitHub integration in the dashboard, not from the CLI. If the user wants a repo connected, point them at the dashboard rather than trying to do it yourself: `https://tryreplicas.com/dashboard/github`.

## `replicas.json` / `replicas.yaml`

`replicas init` creates a starter config in the current directory. `-y` writes YAML, `-f` overwrites an existing file. This file is for **per-repo overrides** that live in the repo itself, not in the org's Replicas settings.

What it's actually required for:

- **GitHub triggers (automations).** The GitHub App reads automation mappings from the committed file, so triggers don't fire until `replicas.json` (or `.yaml`) is committed to the repo's default branch.
- **Per-repo warm hook commands.** If a repo declares a `warmHook` field, the engine runs those commands *after* the env-level warm hook in that repo's cwd. Optional override, most users don't need it. For env-level warm hooks, see `ENVIRONMENT.md`.
- **Per-repo start hook**, organization scoping, and a handful of other repo-local settings.

What it's **not** required for:

- **Env-level warm hooks**: edited via `:::edit-warm-hook` in chat or the dashboard. See `ENVIRONMENT.md`.
- **Warm pools**: pool size and toggle are managed via `replicas environment warm-pool` CLI. See `ENVIRONMENT.md`.
- **Environment variables, files, skills, MCPs**: all managed at the env level. See `ENVIRONMENT.md`.
- **Integrations**: managed at the org level (Slack/Linear/Sentry OAuth). See `ORG-CONFIG.md`.

When the user asks to "set up Replicas in this repo", run `replicas init` and then edit the generated file based on what they need. If they're asking about anything that lives at the env level (warm hooks, env vars, etc.), don't push them toward the repo file, use the right CLI verb or the dashboard.

## When NOT to use the CLI

- **Don't use the CLI to reach into other tools' state** (Linear, Slack, GitHub), those have dedicated skill references in this directory.
- **Don't try to install Replicas, log in, or switch orgs**: those flows are user-facing and aren't available in agent mode anyway.
- **Don't create workspaces** from inside an existing workspace just to run a command. You're already in one.

## Common errors

- `Missing Replicas-Org-Id header` → the workspace is hitting an older monolith that doesn't yet recognize agent auth on this endpoint. Surface this to the user; don't try to work around it by faking headers.
- `Workspace not found` → the workspace was deleted while you were running. Stop and tell the user.

For action-specific errors (e.g. "An environment with this name already exists"), see the topical reference for that action.
