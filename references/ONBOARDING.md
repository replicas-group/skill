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

2. **Don't immediately orient the next step.** Let the user click **Walk me through this step** to pace through the wizard.

3. **Close every step reply with the onboarding navigation footer.** Replaces rule-12's dashboard footer for onboarding workspaces. Two lines, after the block (or after the explanation if there's no block) — the first is the skip cue, the second is the continue cue. Both vary by step:

   ```
   (<navigation cue>, or skip this step in the onboarding panel below.)
   When you are done, please click **<button>** to continue.
   ```

   Per step:
   | Step | Footer |
   | --- | --- |
   | `integrations` | `(Connect one of the above, or skip this step in the onboarding panel below.)`<br>`When you are done, please click **Next** in the onboarding panel below to continue.` |
   | `variables` | `(Save the variables above, or skip this step in the onboarding panel below.)`<br>`When you are done, please click **Save** above to continue.` |
   | `skills-mcps` | `(Add the skills above, or skip this step in the onboarding panel below.)`<br>`When you are done, please click **Add skills** and **Got it** above to continue.` |
   | `automations` | `(Pick one or more starters above, or skip this step in the onboarding panel below.)`<br>`When you are done, please click **Add Automation** above to continue.` |
   | `warm-hook` | `(Save the warm hook above, or skip this step in the onboarding panel below.)`<br>`When you are done, please click **Save warm hook** above to continue.` |
   | `configuration` | `(Save the configuration above, or skip this step in the onboarding panel below.)`<br>`When you are done, please click **Save** above to continue.` |

   This is the one allowed exception to rule 9's "no prose after a block" — it's navigation, not a CTA paraphrase. The wizard's "All set" card surfaces the dashboard link once the whole wizard is done, so rule-12's dashboard footer isn't needed per step.

4. **Skipping.** The user clicks **Skip** in the accordion (optional steps only). The wizard handles advancement; you don't need to emit anything.

## Welcome card

The onboarding workspace shows a "Welcome to Replicas onboarding" card in its empty state. The user has seen it before they reach chat — don't restate the framing. Go directly into the first step's playbook when `Walk me through this step` fires on `integrations`.
