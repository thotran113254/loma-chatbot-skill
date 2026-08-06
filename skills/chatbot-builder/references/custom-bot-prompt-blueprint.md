# Shop Prompt V2 blueprint — Assistant Builder compatible

Use this as a quality standard for a Shop Prompt V2 body, not a template to copy. Two shops in the
same category should produce different bodies. A fixed section list, a generic tail block, or filler
for a decision the merchant never made creates a bot that sounds confident but is not grounded.

## Source of every line

Write from seven merchant decisions, in their own language:

1. **Outcome** — what a successful chat ends with.
2. **Answer sources** — catalog, policy answers, media, or approved Q&A.
3. **Flow** — the next customer detail needed to reach the outcome.
4. **Policies** — recurring questions the shop wants answered directly.
5. **Limits** — promises or topics the bot must decline.
6. **Escalation** — what happens when an answer is not in shop data.
7. **Voice** — address style and the shop's own natural wording.

Outcome and escalation cannot be missing. Do not fill the rest with industry assumptions. A vertical
reference can suggest questions to ask the merchant; it never supplies the answer or the flow.

## Preferred write path

1. Collect a merchant-approved multi-turn sample. Keep real customer wording, at least one catalog
   or policy answer, the intended flow, and an unknown-question handoff.
2. Build a short `brief` from the confirmed decisions and sample lines.
3. Call `build_shop_prompt({ chatbot_id, brief, bot_toolset, product_source })`.
4. Inspect the generated V2 body. Use `refine_shop_prompt` for one explicit correction; use
   `update_shop_prompt({ chatbot_id, body })` only when deliberately replacing the whole body.
5. Confirm with `get_runtime_preview`, then run the relevant isolated test conversation.

Never write prompt text through `update_chatbot_config`: `custom_system_prompt` and `system_prompt`
are blocked there. Never append an old body to a new one. Generate from the current confirmed facts,
then make the smallest needed refinement.

## When a manual body is necessary

Keep it short and specific. Include only the shop identity, required flow, named data sources,
confirmed limits, escalation route, voice, and the approved sample lines that demonstrate critical
behavior. For each flow step, state one needed customer detail and a literal line in the shop's
language; do not turn it into a loose interview.

- Do not paste product lists, prices, stock, phone numbers, SKUs, image URLs, or tool schemas. Put
  facts in catalog/FAQ/media; steer tool timing with `set_tool_descriptions`.
- Do not promise an image unless the item has a real uploaded image. Do not promise prices, stock,
  delivery, or policies the relevant data source does not support.
- Address a customer by a real known name only. Do not say platform handles, email addresses, or phone
  numbers aloud, and do not guess gender from an ambiguous name.
- Put any single behavior that must override earlier examples at the end, but do not paste a universal
  rule block. State the shop-specific requirement in plain language and verify it in a test.
- Keep customer-facing lines in the shop's language. Keep tool names and platform mechanics out of the
  body.

## Response discipline — required for every custom bot

A custom bot has no persona frame. Its V2 body MUST finish with a short section, in the shop's
language and no more than six one-line requirements, that covers all of these:

- Answer what the customer asked first, then take one next step.
- Ask at most one question in a reply.
- Speak as the shop's staff, without assistant filler or hedging.
- Never send an empty reply; acknowledge unclear input and repeat the current step.
- Decline off-topic requests briefly, without turning them into a qualification interview.
- Use a real name already known in the conversation naturally, without asking again.

This required section is different from system-owned tool correctness and safety rules. Keep it once,
at the end of the body, and write it naturally for the shop rather than copying these English words.

## Review before writing

- [ ] Every factual line traces to the merchant or a shop data source.
- [ ] The outcome, escalation route, and one-question flow are unambiguous.
- [ ] A custom body ends with the required response-discipline section.
- [ ] Examples reflect real shop wording; they do not contain fabricated facts.
- [ ] Data belongs in catalog/FAQ/media, and tool timing belongs in tool descriptions.
- [ ] The body has no setup transcript, placeholder, copied generic vertical, or stale accumulated text.
- [ ] `get_runtime_preview` shows the expected V2 body and tool loadout before a test or channel bind.
