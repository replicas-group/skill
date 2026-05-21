# Replicas Onboarding Wizard

This document covers the wizard UI mechanics only — the per-step capability playbooks live in `ENVIRONMENT.md` (env vars, files, skills, MCPs, warm hook, configuration) and `ORG-CONFIG.md` (integrations, automations). The agent's behavior is identical in onboarding and any other workspace; the wizard is just a stepper around the same playbooks.

## How the wizard works

In onboarding workspaces (`workspace.is_onboarding === true`), a 6-step accordion sits between the chat stream and the composer. Each step's **Walk me through this step** button fires a fixed prompt (see table below). Respond as you would to the same prompt typed in any other workspace — Adapt to state (`ORG-CONFIG.md`) handles the difference between fresh and existing users.

## Step order

| ID | Prompt | Playbook |
| --- | --- | --- |
| `integrations` | *"Help me connect Slack, Linear, or Sentry."* | `ORG-CONFIG.md` → Integrations |
| `variables` | *"Help me add env vars."* | `ENVIRONMENT.md` → Variables |
| `skills-mcps` | *"Recommend skills and MCPs for me."* | `ENVIRONMENT.md` → Skills & MCPs |
| `automations` | *"Show me automation templates."* | `ORG-CONFIG.md` → Automations |
| `warm-hook` | *"Help me set up a warm hook."* | `ENVIRONMENT.md` → Warm hook |
| `configuration` | *"Walk me through tuning my environment configuration."* | `ENVIRONMENT.md` → Configuration |

`integrations` and `variables` are required. The rest are optional.

Environment creation is never a wizard step — the onboarding workspace's env is already set, and the default-to-workspace-env rule from `ORG-CONFIG.md` covers everything else.

## Pacing rules

1. **Auto-advance is the default.** Every step has a corresponding inline block (`:::secure-input`, `:::connect-integration`, `:::add-skills-mcps`, `:::automation-templates`, `:::edit-warm-hook`, `:::edit-configuration`). When the block resolves (saved, skipped, approved, connected), the wizard advances client-side automatically — emit the block and trust the resolution path.

2. **Don't immediately orient the next step.** Let the user click **Walk me through this step** to pace through the wizard. Each step closes with the standard two-line footer (rule 12 in `ORG-CONFIG.md`) — that's the only follow-up.

3. **Skipping.** The user clicks **Skip** in the accordion (optional steps only). The wizard handles advancement; you don't need to emit anything.

## Welcome card

The onboarding workspace shows a "Welcome to Replicas onboarding" card in its empty state. The user has seen it before they reach chat — don't restate the framing. Go directly into the first step's playbook when `Walk me through this step` fires on `integrations`.
