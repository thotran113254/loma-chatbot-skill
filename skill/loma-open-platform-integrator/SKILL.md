---
name: loma-open-platform-integrator
description: >-
  Build an EXTERNAL integration/automation on top of the chatbot platform's open
  surfaces — mint API keys, call the public REST API v1, subscribe outbound webhooks
  (incl. conversation_started + message_received) with HMAC verification, send proactive
  messages and assign labels back into conversations, let the bot call your API
  mid-conversation via HTTP tools, and drive production-real test traffic through the
  web-widget public API. Use when you (or your customer) want your own code to react to
  conversations, sync leads/orders to a CRM, or build custom follow-up automations
  OUTSIDE the platform. Tenant-neutral: use YOUR dashboard domain as {base}. Every step
  verified end-to-end against a live deployment.
---

# Open Platform Integrator

Playbook for external systems plugging into the platform. Pairs with the
`loma-chatbot` operator skill (that one configures bots via MCP; this one builds
YOUR code around the platform).

## 1. Provision an API key (once, operator context)

- Dashboard → Developer Portal / Settings → API Keys → create a key with the
  scopes you need. **The one-time full key is returned in the `key` field**
  (`ak_…`). Store it immediately; it is never shown again.
- Scopes are granular (`chatbots`, `leads:read`, `orders:write`, `campaigns:*`,
  `labels:*`, `follow-up:*`, `http-tools:*`, `analytics:read`,
  `conversations:write`…). `chatbots` also covers `/api/v1/webhooks` +
  `/api/v1/channels` + `/api/v1/field-definitions`.
- 60 req/min per key; back off on 429 `Retry-After`.

## 2. Call the REST API

- Base `{base}/api/v1`, header `X-API-Key`, envelope `{success, data|error}`.
- OpenAPI: `GET {base}/api/v1/docs-json` (spec) / `{base}/api/v1/docs` (UI).
  Typed client: `npx openapi-typescript {base}/api/v1/docs-json -o types.ts`.
- AI-agent index: `GET {base}/llms.txt` — point any coding agent here first.

## 3. React to events — webhooks

- Discover: `GET /api/v1/webhooks/events` (registry-driven; includes
  `conversation_started` and `message_received`).
- Subscribe: `POST /api/v1/webhooks`
  `{chatbot_id, name, url, events: [...], generate_secret: true}` — the HMAC
  secret is returned ONCE in the create response.
- **Receiver requirements (enforced):** HTTPS only (localhost/private IPs
  rejected), and the URL is probed with a `HEAD` request that must return
  < 400. For local dev, front your receiver with an HTTPS tunnel (e.g.
  `cloudflared tunnel --url http://127.0.0.1:<port>`; on hosts without IPv6
  egress add `--edge-ip-version 4 --protocol http2`, and VERIFY the tunnel
  serves before subscribing — quick tunnels can register DNS yet answer 530).
- Verify every delivery: `X-Webhook-Signature: sha256=HMAC_SHA256(secret, rawBody)`
  (constant-time compare). Retries: exponential backoff 1m→16m; logs at
  `GET /api/v1/webhooks/:id/logs`; repeated failures auto-disable the webhook.
- Delivery is **at-least-once** → dedupe on your side:
  `message_received` → `data.message_id`; `lead_captured` → `lead_id` + `is_returning`.

### Event semantics that matter for automation design

- `conversation_started` — once per new conversation session; envelope carries
  full `contact` info + `session_id` + `chatbot_id`.
- `message_received` — HIGH VOLUME, one per INCOMING customer message
  (`data`: message_id, content, attachments[], conversation_id). It NEVER fires
  for outgoing bot/agent/API-sent messages — your automation can safely send
  replies without creating feedback loops. Fires even when the AI won't reply.
- `lead_captured` — check `data.field_sources`: `customer_typed` = customer
  actually typed the contact info; `contact_meta` = channel-supplied hint. Only
  auto-dial/auto-message `customer_typed` phones.
- `label_assigned` — drive tag-based workflows; subscriptions can filter by
  `label_ids`.

## 4. Act back — proactive send + labels (scope `conversations:write`)

Every webhook payload carries `session_id` — address conversations with it:

- **Send a message:** `POST /api/v1/conversations/:session_id/messages`
  body `{content?, image_url?}` (at least one; `image_sent:false` in the
  response means the image failed even though the text delivered). Optional
  `Idempotency-Key` header dedupes retries. Recorded as the agent bot; never
  re-triggers `message_received`. Errors: `402 PLAN_LIMIT_EXCEEDED` (plan
  monthly quota, unlimited by default), `404` unknown session,
  `410 CONVERSATION_GONE`, `422 CHANNEL_REJECTED`.
- **Attach/detach a tag:** `POST /api/v1/conversations/:session_id/labels`
  `{label_id}` / `DELETE …/labels/:label_id`. Assignment syncs the label to the
  channel conversation, fires `label_assigned`, and starts the label's
  follow-up scenario when one is active (stop-labels cancel all follow-ups).
- MCP twins for AI-agent builders: `send_conversation_message`,
  `add_session_label`, `remove_session_label`.

## 5. Let the bot call YOUR API mid-conversation — HTTP tools

`POST /api/v1/http-tools` (scope `http-tools:write`) with
`{chatbot_id, name, description, url, input_schema}` — the agent calls your
HTTPS endpoint as a function tool when conversation context matches the
description. Free-form object params: OMIT `properties` entirely (an empty
`properties: {}` forbids the model from filling anything).

## 6. Generate production-real test traffic (no admin tokens needed)

Shareable test links create test sessions — webhooks are SUPPRESSED for those
by design. To test your automation end-to-end, create REAL traffic through the
web-widget public API (what any website visitor uses):

1. Operator: create a Website channel in the dashboard → copy the widget
   `website_token`; activate your bot on that inbox.
2. Visitor bootstrap: `GET {chatwoot}/widget?website_token=X` → extract
   `authToken = '…'` from the HTML (a fresh visitor JWT).
3. `POST {chatwoot}/api/v1/widget/conversations?website_token=X`
   header `X-Auth-Token`, body `{message:{content}}` → real conversation;
   follow-ups via `POST …/widget/messages`; read the thread (bot replies have
   `message_type === 1`) via `GET …/widget/messages`.

## 7. The proven automation loop

```
webhook (conversation_started / message_received / lead_captured / label_assigned)
  → your logic (CRM sync, scoring, routing, scheduling)
  → act back via REST: send message, assign label (label follow-up runs
    platform-side), campaigns, orders/leads updates, HTTP tools
```

## Pitfalls checklist (all hit + resolved during live verification)

- [ ] Key field is `key` (top-level) in the create response.
- [ ] Webhook URL: HTTPS + publicly reachable + answers `HEAD` < 400.
- [ ] Store the webhook `secret` from the create response — shown once.
- [ ] Dedupe deliveries (at-least-once) by event-specific ids.
- [ ] Don't test webhooks through test links / dashboard test chat (test-session
      suppression) — use the widget public API or a real channel.
- [ ] Keep your receiver up — repeated delivery failures auto-disable the
      subscription (repoint the URL via `PUT /api/v1/webhooks/:id` after moving).
- [ ] Respect 60 req/min per key; back off on 429 `Retry-After`.
