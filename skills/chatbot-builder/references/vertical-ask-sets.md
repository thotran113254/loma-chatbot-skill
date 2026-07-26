# Vertical ask-sets — what the bot may ask, per industry

A page staffer closes with the fewest questions. The failure mode of a capable model is the opposite:
it interviews. Fix that per industry with an **ask-set**.

Scope note: this file governs what the **bot** may ask the **customer**. What *you* ask the **shop owner**
during setup is a different job — see `shop-intake-case-menu-and-coverage.md`.

## The rule that generates every ask-set

```
ASK-SET = (fields the target action requires) ∩ (fields the shop actually configured)
```

Outside that intersection → the bot does not ask. If the shop has no data to act on an answer, the
question is theatre: it costs a turn, invites a wrong promise, and lowers close rate. When the bot
lacks the data to advise, it looks it up or says it will check — it does not interview.

Industry chooses the **ask-set and the flow**. It must never change which tools are enabled by type
alone — tools are gated on the shop's resources and configuration, not on an industry label.

## Presets

Each row: the target action, the maximum questions, and the questions that are forbidden even though a
smart model wants to ask them.

### Fashion / accessories / footwear — target: order

- May ask: size · colour or model (from the real variant list) · quantity · phone · delivery address
- Never ask: style, aesthetic, occasion, outfit pairing, body type, budget, "what do you usually wear"
- Flow: price/photo answer → variant choice (two options when known) → quantity → phone → address →
  order this turn
- Out of stock: state it once, offer one verified similar item, ask if it works

### Cosmetics / skincare / supplements — target: order

- May ask: **one** need-narrowing question the catalog can filter on (skin type, or the concern) ·
  product or set choice · quantity · phone · address
- Never ask: full routine, age, hormones, medication, medical history, or anything diagnostic
- Advise from the product description and FAQ only. No claims about treating conditions.
- Flow: answer the question from product data → one narrowing question → recommend 1–2 items with the
  reason from the description → phone → address → order

### Food & beverage / bakery — target: order

- May ask: item · size or topping/option · quantity · time or address · phone
- Never ask: taste preference interviews, dietary profiling beyond a stated allergy note
- Flow: item + price → options → quantity → delivery time/address → phone → order

### Appointment services (spa, dental, clinic, repair, salon) — target: contact captured

- May ask: which service they are interested in · phone · preferred time window **only if the shop
  configured a time field** · plus any extra field the shop explicitly configured — nothing else
- Never ask: deep consultation questions, price negotiation, medical detail, or a field the shop did
  not configure
- Give a general answer from FAQ / service description, then capture the contact. The human confirms
  the booking.
- Flow: answer the service question → phone → confirm someone will call back within the stated window

### Configurable pricing (printing, furniture, signage, industrial) — target: quote then contact/order

- May ask: exactly the parameters the pricing rule needs (dimensions, material, quantity) · phone
- Never ask: any dimension the pricing rule does not contain — it cannot affect the number
- Below the minimum order → polite refusal, no recovery pitch unless the shop allows one
- Flow: identify the item → collect the rule's parameters one per step → quote from the pricing tool →
  phone → hand off or order

### High-consideration lead (property, education, courses, B2B) — target: qualified contact

- May ask: what they are looking for (one question) · phone · one qualifier the shop configured
  (budget band, area, intake) — only if configured
- Never ask: a battery of qualifiers, company details, or a decision timeline the shop never asked for
- Accept a volunteered contact immediately; never defer it behind more qualification
- Flow: answer from data → one qualifier → phone → confirm the callback

## Applying a preset

1. Read what the shop actually has: `list_products` (variants, options, stock), `list_faqs`,
   `list_pricing_rules`, `get_chatbot_config` (`lead_fields`), `list_field_definitions`.
2. Intersect with the preset. A field the shop has not configured drops out of the ask-set, even if the
   preset lists it.
3. Turn the surviving fields into FLOW steps — one field per step, each with a literal quoted line in
   the shop's language (see `custom-bot-prompt-blueprint.md`).
4. Write the forbidden questions into the tail block's `ASK_ONLY_FLOW_FIELDS` line only if the shop
   keeps seeing them; the FLOW plus that rule is normally enough.
5. Verify with acceptance case 5 (an off-brief consulting request must not start an interview).

## When the shop insists on more questions

Push back once with the arithmetic: each extra question is one more turn where the customer can leave,
and a question whose answer the shop cannot act on cannot improve the recommendation. If the shop still
wants it, add it as a **conditional** step ("when the customer mentions X → ask …"), never an
unconditional every-chat question.
