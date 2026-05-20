# Replicas Onboarding Wizard

This document is **about the wizard UI**, not about how to handle org config. For the capability playbooks (what to say about each concept, which block to emit, dashboard URLs, CLI verbs) see `ORG-CONFIG.md`. The same playbooks apply to onboarding and to every other workspace — the agent's behavior is driven by user state (what's set up, what isn't), not by which workspace it's in.

The only thing onboarding adds is the wizard mechanics described below.

## What the wizard is

In onboarding workspaces (`workspace.is_onboarding === true`), a 6-step accordion sits between the chat stream and the composer. Each step has a `Walk me through this step` button that fires a synthetic prompt (e.g. *"Help me connect Slack, Linear, or Sentry."*). The step also has an `:::onboarding-advance` mechanism for skipping or finishing prose-only steps.

When that synthetic ask fires, run the corresponding capability playbook from `ORG-CONFIG.md`. Nothing about your behavior changes because of the wizard — you respond exactly as you would if the user typed the same prompt in any other workspace. The state-adaptation rule from `ORG-CONFIG.md` ("Adapt to state") takes care of the difference: in onboarding the user has nothing set up, so you orient fully; in a regular workspace they have things set up, so you act tersely.

## Wizard step order

| ID | Synthetic ask | `ORG-CONFIG.md` playbook |
| --- | --- | --- |
| `integrations` | *"Help me connect Slack, Linear, or Sentry."* | Integrations |
| `variables` | *"Help me add env vars."* | Variables |
| `skills-mcps` | *"Recommend skills and MCPs for me."* | Skills & MCPs |
| `automations` | *"Show me automation templates."* | Automations |
| `warm-hook` | *"Help me set up a warm hook."* | Warm hook |
| `configuration` | *"Walk me through tuning my environment configuration."* | Configuration |

**Integrations comes first on purpose.** Retention triples once a user connects Slack or Linear and gets the "ping the agent in Slack, get a PR back" magic moment.

**Warm hooks are not a wizard step right now.** They confuse new users. If they explicitly ask about warm hooks, fall back to the warm-hook playbook in `ORG-CONFIG.md`.

**Environment creation is not a wizard step.** The onboarding workspace's env is already set; the universal "default to workspace env" rule from `ORG-CONFIG.md` covers this.

## Wizard rules

These are about the wizard UI's pacing and lifecycle, not about how to handle capabilities.

1. **Pacing.** When a step resolves (block lands, automation created, prose orientation delivered), acknowledge in one short sentence and close with the rule-9 CTA **Click `Walk me through this step` below**. Do NOT immediately orient the next step — the user paces this.

   ```
   Result: Saved `CLAUDE_API_KEY` to `replicas-dev`. [View](https://tryreplicas.com/dashboard/environment/<id>?tab=variables)

   **Click `Walk me through this step` below when you're ready for skills & MCPs.**
   ```

2. **Step completion is automatic for capability-driven steps.** A confirm-action approval, a secure-input save, a connect-integration connect, an automation-template create, an add-skills-mcps save — all of these advance the wizard when their corresponding block resolves. The wizard infra reads the message stream and moves itself.

3. **For prose-only capabilities (e.g. `configuration`), close with `:::onboarding-advance`.** Otherwise the wizard has no signal to move on. Without this, the user is stuck on a step that has no resolving block.

4. **Skipping optional steps.** If the user explicitly says "skip" on an optional step, emit `:::onboarding-advance` (and nothing else in the message body). All steps except `integrations` and `variables` are optional.

## `:::onboarding-advance`

```
:::onboarding-advance
from: <current step id>
to: <next step id>
:::
```

Valid step ids: `integrations`, `variables`, `skills-mcps`, `automations`, `warm-hook`, `configuration`, `done`. Use `to: done` after `configuration` (the last step) to flip the wizard to its all-set state.

The block must be the entire message body when emitted as a skip. For prose-only capability completions, emit it as the closing line of the orientation reply.

**Only valid in onboarding workspaces.** In any other workspace, `:::onboarding-advance` is silently dropped by the parser — don't emit it.

## Welcome card

The onboarding workspace's empty-state shows a "Welcome to Replicas onboarding" card. The user has already seen it before they got to chat. Don't restate that framing — go straight into the first step's playbook when `Walk me through this step` fires on `integrations`.
