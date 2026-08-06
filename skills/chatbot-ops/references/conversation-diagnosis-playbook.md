# Diagnosing a real conversation → fixing the right layer

Read the evidence first (`read_conversation` → `get_runtime_preview` → `get_conversation_state`), then
match the symptom. Fixing the wrong layer is the most common waste: a prompt rewrite cannot cure a
missing product, and a product edit cannot cure a rambling flow.

## Decision table

| What actually happened | Root layer | Fix |
|---|---|---|
| Bot never replied at all | prompt store | `get_shop_prompt` — an empty active body makes the runtime drop the reply permanently. Write a body (→ chatbot-builder) |
| Replied generically, ignored the catalog | tools / data | catalog tool not enabled, no products, or the body never names the catalog as the source |
| Wrong product picked | data modelling | raise `max_search_results` (default 1); model the distinguishing attribute via `manage_field_definition` + `custom_fields`; add the missing variant |
| Said "out of stock" for something in stock | product data | tracked variant with 0 quantity → `update_product` a real `quantity`, or `track_inventory:false` |
| "No discount" though a promotion runs | tools | enable `check_promotions` (+ `apply_voucher`). It refuses to invent offers by design |
| Did not send a photo | data + flow | product has no `image_url`, or the item is not in the media catalog, or the flow step never shows sending it |
| Asked questions the shop can't act on / interviewed the customer | prompt flow | narrow to the vertical ask-set; one field per step (→ chatbot-builder) |
| Re-asked something the customer already said | prompt flow | add the confirmed no-repeat requirement and an approved sample line, then compile a fresh body |
| Answered off-topic then pivoted into qualifying questions | prompt limits | add the shop's confirmed off-topic limit and re-test it |
| Echoed English status text into a local-language reply | runtime addendum/loadout | inspect the runtime preview and enabled tools; this system-owned rule is not a body or tool-description fix |
| Called the wrong tool, or too eagerly | tool descriptions | `set_tool_descriptions` for that tool — not the prompt |
| Order not created though everything was given | tools / stock | order tool missing from the tool set, or the variant is unsellable; check the transcript for a tool error |
| Contact was given but no lead appears | tools / prompt | contact-capture tool not enabled, or the body never asks for contact. Nothing creates leads behind the model |
| Too many / too few follow-up messages | follow-up config | `update_followup_settings` (quiet hours), scenario edits, `toggle_session_followup` for one customer |
| Repeated question the bot cannot answer | knowledge loop | `list_tickets` → `resolve_ticket` → approve the learned answer → promote to `add_faqs` |
| Bot kept talking after a human joined | pause config | `admin_pause` enabled/duration; `pause_session` for the live case |
| Customer says the bot forgot everything mid-chat | session state | `get_conversation_state`; a session wipe happens when the upstream conversation is deleted — identity, leads and orders survive |

## Rules of the loop

1. **One change, then re-test the same scenario** with `start_test_conversation`. Two changes at once
   and you learn nothing.
2. **Prefer data over prose.** If the answer could live in the catalog, FAQ or a config knob, put it
   there — prose in the prompt goes stale and no one audits it.
3. **Prefer tool descriptions over prompt text** for anything about *when* a tool should fire.
4. **Change quoted lines before abstract rules.** The runtime imitates the literal customer-facing
   lines in the flow far more strongly than it follows a rule about them.
5. **Confirm the fix in production shape**, not in theory: isolated `is_test` traffic runs the same
   pipeline without contacting a real customer, so a passing test is strong evidence. Every test
   consumes credits and test-side writes can still be real; get explicit confirmation before starting
   the session. `validate_chatbot_config` passing is not enough.
6. **Undo cleanly:** `get_shop_prompt_history` → `rollback_shop_prompt` restores the previous body.

## Escalating honestly

If the evidence shows a platform-side fault (a tool erroring on valid input, a channel not delivering,
a webhook never firing), stop trying to patch it in the prompt. State what the evidence shows, which
tool returned what, and that it needs the provider — do not invent a workaround that hides a real bug.
