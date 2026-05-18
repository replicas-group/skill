# Replicas (in-workspace CLI)

This guide covers how to take action *with* Replicas itself from inside a Replicas workspace — managing automations, environments (and their variables/files), repos, previews, and the user's `replicas.json` config — using the pre-installed `replicas` CLI.

When the user asks _about_ Replicas (concepts, pricing, how a feature works), check https://docs.replicas.dev first. When the user asks you to _do_ something in their Replicas org, this is the file to use.

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

If you get "Not logged in", the workspace is misconfigured — surface this to the user instead of trying to work around it.

In agent mode the CLI hides commands that don't make sense for in-workspace agents (`login`, `logout`, `codex-auth`, `claude-auth`, `org switch`, `config`, `interact`, `code`, replica/workspace top-level CRUD). What you have is:

| Command | What it does |
| --- | --- |
| `replicas whoami` | Print the workspace + org identity |
| `replicas init` | Create a `replicas.json` / `replicas.yaml` in the current directory |
| `replicas connect <name>` | SSH into another workspace (requires user creds — usually only useful when scripting locally) |
| `replicas repos` | List repos connected to the org |
| `replicas environment ...` | Manage environments, env vars, env files |
| `replicas automation ...` | Manage automations (cron + GitHub event triggers) |
| `replicas preview ...` | Register / list preview URLs (covered in `PREVIEWS.md`) |
| `replicas media ...` | Upload screenshots, videos, audio (covered in `MEDIA.md`) |

`replicas <command> --help` is always the source of truth for flags.

## Picking the right command for the user's request

| User says... | Run |
| --- | --- |
| "What environments do I have?" | `replicas environment list` |
| "Add API key X to my staging env" | `replicas environment vars set <env> <KEY> <VALUE>` |
| "Make me a `.env` file in the workspace with these vars" | `replicas environment files set <env> .env --content "..."` |
| "Create a new env for my `acme/web` repo" | `replicas environment create <name> -r acme/web` |
| "What automations do I have?" | `replicas automation list` |
| "Run my nightly automation now" | `replicas automation run <id>` |
| "Make an automation that runs every weekday at 9am" | `replicas automation create` (interactive) or `--trigger-cron "0 9 * * 1-5"` |
| "Make an automation that runs when a PR opens on `acme/web`" | `replicas automation create ... --trigger-github pull_request.opened --trigger-github-repos acme/web` |
| "What repos are connected?" | `replicas repos` |
| "Set up a `replicas.json` in this repo" | `replicas init` (`-y` for YAML) |

## Environments

Environments are the org-scoped *primitives* workspaces are built from. Each environment can bind to one repository (or repository set), carry environment variables, project files, enabled skills, and MCP servers. The `Global` environment is special — its vars/files/skills/MCPs apply to *every* workspace in the org, but it has no repo binding and can't back a workspace on its own.

### List / get / create / edit / delete

```bash
replicas environment list
replicas environment get <id-or-name>          # use "global" for the Global env
replicas environment create [name] \
  --description "..." \
  --repository <repo-name-or-id> \
  --system-prompt "..."
replicas environment edit <id-or-name> \
  --name "..." --description "..." \
  --repository <repo-name-or-id>          # pass empty string to unbind
replicas environment delete <id-or-name> [--force]
```

Notes:
- Environments resolve by **name or UUID**. `global` is an alias for the org's Global env.
- Non-global envs need a repo (or repo set) to back a workspace. If you `create` without `--repository`, the CLI prompts; in non-interactive contexts pass `-r`.
- `edit` on the Global env is rejected by the API — manage its contents through the `vars` / `files` subcommands instead.

### Environment variables

```bash
replicas environment vars list <env>
replicas environment vars set <env> <KEY> <VALUE>     # upsert (create or update)
replicas environment vars delete <env> <KEY|VARIABLE_ID> [--force]
```

`vars set` is upsert: if a variable with that key already exists, it's updated; otherwise created. The CLI accepts either the variable's `key` or its UUID for `delete`.

These variables are injected into every workspace built from this environment as actual `env` vars — perfect for API keys, feature flags, etc. Anything you want available to the agent's tools (Claude, codex, your code, etc.) goes here.

### Environment files

Files materialize on the workspace filesystem when a workspace starts, at the destination path you specify. Use this for things like `.env` files at the repo root, dotfiles in `~`, prompt files for agents, etc.

```bash
replicas environment files list <env>
replicas environment files set <env> <destination-path> --content "..."        # inline
replicas environment files set <env> <destination-path> --file <local-path>    # from local file
replicas environment files set <env> <destination-path> --file <local-path> --name "Friendly name"
replicas environment files delete <env> <destination-path|FILE_ID> [--force]
```

Constraints:
- Each file is capped at 64KB.
- `set` is upsert (matched by destination path).
- The display `--name` defaults to the basename of the destination path; override only if it would be unclear in the dashboard list.

## Automations

Automations are saved prompts with one or more triggers (cron schedules and/or GitHub events). When fired, they create a workspace using the configured environment and run the prompt with the user's coding agent.

### List / get / run / delete

```bash
replicas automation list
replicas automation get <id>
replicas automation run <id>          # cron-triggered automations only
replicas automation delete <id> [--force]
```

### Create

Either fully flag-driven or fully interactive — the CLI prompts for anything you don't pass.

```bash
# Cron trigger
replicas automation create "Nightly typecheck" \
  --prompt "Run \`bun typecheck\` and report any new errors" \
  --environment <env-name-or-id> \
  --trigger-cron "0 4 * * *" \
  --trigger-cron-timezone "America/New_York"

# GitHub trigger (filter to specific repos)
replicas automation create "Review my PRs" \
  --prompt "Leave a code review on this PR" \
  --environment <env-name-or-id> \
  --trigger-github pull_request.opened \
  --trigger-github-repos acme/web,acme/api

# Disable on creation
replicas automation create ... --disabled

# Workspace lifecycle
replicas automation create ... --lifecycle delete_when_done
replicas automation create ... --lifecycle delete_after_inactivity --auto-stop-minutes 30
```

When the user says "make me an automation that...", default to **picking the environment for them by listing the available envs** and asking only when the user hasn't already pinned one. Same for repos in GitHub triggers. Don't pepper the user with questions you can answer by reading the existing config.

### Edit

```bash
replicas automation edit <id> \
  --name "..." \
  --prompt "..." \
  --enabled true|false \
  --environment <env-name-or-id> \
  --trigger-cron "0 4 * * *"   # replaces existing triggers
```

`replicas automation edit <id>` with no flags drops into interactive mode.

## Repositories

Read-only listing of repos connected to the org. Use when the user asks "what repos can I use?", or to validate a `--repository` value before passing it to `environment create` / `automation create`:

```bash
replicas repos
```

Repos are connected via the GitHub integration in the dashboard — not from the CLI. If the user wants a repo connected, point them at the dashboard rather than trying to do it yourself.

## `replicas.json` / `replicas.yaml`

`replicas init` creates a starter config in the current directory. `-y` writes YAML, `-f` overwrites an existing file. This file is for **per-repo overrides** that live in the repo itself, not in the org's Replicas settings.

What it's actually required for:

- **GitHub triggers (automations).** The GitHub App reads automation mappings from the committed file, so triggers don't fire until `replicas.json` (or `.yaml`) is committed to the repo's default branch.
- **Per-repo warm hook commands.** If a repo declares a `warmHook` field, the engine runs those commands *after* the env-level warm hook in that repo's cwd. Optional override — most users don't need it.
- **Per-repo start hook**, organization scoping, and a handful of other repo-local settings.

What it's **not** required for:

- **Env-level warm hooks** — set via `replicas env warm-hook set` or the dashboard. Stored in the DB and run on every warm sandbox regardless of whether any repo has a `replicas.yaml`.
- **Warm pools** — the pool primes sandboxes using the env-level warm hook. No repo file needed.
- **Environment variables, files, skills, MCPs, integrations** — all managed at the org/env level, not in the repo.

When the user asks to "set up Replicas in this repo", run `replicas init` and then edit the generated file based on what they need. If they're asking about warm hooks, env vars, or anything else that lives at the env level, don't push them toward the repo file — use the right CLI verb instead.

## When NOT to use the CLI

- **Don't use the CLI to reach into other tools' state** (Linear, Slack, GitHub) — those have dedicated skill references in this directory.
- **Don't try to install Replicas, log in, or switch orgs** — those flows are user-facing and aren't available in agent mode anyway.
- **Don't create workspaces** from inside an existing workspace just to run a command. You're already in one.

## Common errors

- `Missing Replicas-Org-Id header` → the workspace is hitting an older monolith that doesn't yet recognize agent auth on this endpoint. Surface this to the user; don't try to work around it by faking headers.
- `Workspace not found` → the workspace was deleted while you were running. Stop and tell the user.
- `An environment with this name already exists` → use `environment edit` instead, or pick a different name.
- `Cannot delete the global environment` → there is exactly one Global env per org and it's permanent. Manage its *contents* (`vars`, `files`) instead.
