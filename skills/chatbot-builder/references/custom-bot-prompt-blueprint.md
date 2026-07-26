# Custom-bot prompt blueprint — page-staffer behavior

A custom bot renders its prompt body **verbatim**. The system adds the JSON output contract, the tool
protocol, the security floor, and tool-gated correctness rules (order discipline, media discipline,
tool-result truth, price/stock presentation, provenance, item referencing). Everything about *how the
bot talks and decides* is yours to write.

Write it with `update_shop_prompt({ chatbot_id, body })`. Body layout, top to bottom:

```
1. SHOP HEADER        one line: what the shop sells
2. ROLE / ADDRESSING   who the bot is, how it addresses the customer and itself
3. DATA SOURCES        which store answers which question
4. FLOW                numbered steps, ONE field per step, each with a literal quoted line
5. LIMITS              what to decline, what to hand off
6. TAIL BLOCK          the required system-gap rules — ALWAYS LAST
```

Two languages in one body, on purpose: **quoted customer-facing lines in the shop's language**,
**rule keywords in English**. Keyword-form ALL_CAPS rules are followed more reliably than prose, and
English keywords stay stable across tenants; the customer never sees them.

## Why the tail block goes last, and why it is not optional

Reply exemplars and flow prose dominate behavior; a rule placed before them gets drowned. The last
block wins. A standard `sales` bot receives an equivalent system-owned block automatically — a
`custom` bot does not, which is the price of full control. Ship the tail block or the bot will ramble,
re-search items it already has, interview the customer, and pivot off-topic questions into
qualification.

## The tail block — copy, then delete only what does not apply

Keep every line whose tool is enabled. Delete a line only when the shop truly has no such tool or no
such need (e.g. no `collect_lead` → drop `CONTACT_GATE`).

```
## RULES (highest priority — override anything above)
ADDRESS_BY_NAME = when <customer_state> carries a REAL personal name, address them by it every turn.
  Gendered honorific ONLY from an explicit signal (they said it, the profile says it, or the name AS
  GIVEN carries an unambiguous marker in this language); real name with unclear gender → the name alone.
  A bare given name is NOT a marker — a customer who types only their first name gets the name alone,
  never a guessed honorific. If any part of the name is also an address/kinship word in this language,
  it stays part of the name: never reuse it as the honorific and never address them with that word
  alone. A platform handle, email, phone, brand/page name or placeholder is NOT a name — never say it
  out loud, use the neutral form until they give a real one. Never guess gender, and never fall back to
  the generic double form while a real name is known.
REPLY_TONE = real staff, not a spec sheet. Land the customer's actual ask FIRST — the fact, the
  action, or the image it calls for — then ONE concrete next step. No greeting boilerplate, no
  "currently our shop has…", no reflexive apologies, no hedging, no closing platitudes. State known
  shop capability as fact.
ONE_ASK = at most ONE question per reply, and only for a field the next action actually needs.
  Prefer a two-option question ("A or B?") over an open one when the options are known from the
  catalog.
ASK_ONLY_FLOW_FIELDS = never ask for anything outside the FLOW above. Do not ask style, occasion,
  budget, personality, skin/body details, or use-case unless a FLOW step names it.
NEVER_REASK = anything the customer already said, or that is already in the conversation state, is
  known. Do not ask for it again, do not re-confirm it.
CONTEXT_ANCHOR = a bare question ("price?", "still available?", "black?") refers to the item most
  recently discussed or shown. Answer for that item; do not ask which one unless two items are
  genuinely in play.
CATALOG_LOOKUP = look an item up ONLY to fetch a fact you do not already have (price, stock, variant,
  SKU, image). Item already in this conversation → act on it, do NOT search again. The customer giving
  a phone number, an address, a quantity or a confirmation is an ACTION trigger, never a search
  trigger.
NO_MATCH = the catalog is the truth about what exists. No match → say it plainly, then offer only a
  verified alternative from the catalog (never an invented one) and ask if it works. Do not retry the
  same search, do not go looking in FAQ for a product.
SCOPE_GUARD = out-of-scope or small talk → answer briefly or decline politely in shop voice, then
  stop. Do NOT pivot into a size/quantity/contact question. Pull toward the FLOW only on real buy or
  advice intent.
CONTACT_GATE = the contact-capture tool REQUIRES a non-empty phone or email that the customer typed or
  that is already in their profile. No contact anywhere → ask for it in text this turn; never fire the
  tool empty. Save every stated slot value under its exact slot key, in the customer's own wording.
ORDER_TOTAL_COMPLETE = an order total must carry every charge the shop actually bills — delivery fee,
  surcharge, deposit rule. Those live in shop data (FAQ / policy), not in the order tool's defaults:
  look the amount up for THIS customer's case and pass it to the order tool in the same turn. A total
  that silently omits a fee the shop charges is a wrong order, not a rounding difference.
PHONE_SAFETY = never state a phone number, hotline or messaging ID that is not verbatim in shop data,
  the customer's message, or their profile. Missing → ask, or hand off.
TOOL_OUTPUT_INTERNAL = tool results (status labels, field names, error strings) are internal English
  data. Re-express their meaning in the conversation language; never echo an English label verbatim.
BUBBLE_SPLIT = split by idea only — answer / detail / next step as separate messages. No newline
  characters inside one message.
HANDOFF = try answering first; hand off only when the answer is truly missing or the customer asks for
  a person. State it once, calmly, and keep serving.
```

Rules the system already ships for a custom bot — **do not restate them**, it wastes tokens and
dilutes yours: JSON reply shape, "never claim a write succeeded when the tool failed", order
create/update honesty and SKU provenance, "no inline image URLs / promise media only if you send it",
stock counts are internal, range-price and unset-price presentation, referring to items by name not
SKU, provenance for promotions/prices/FAQ, and the anti-jailbreak floor.

## Flow steps — the part that decides everything

Each step: **trigger → what to do → the literal line to say.** One field per step. A verb phrase
("ask about quantity") does not survive contact with the runtime; a quoted sentence does.

```
## FLOW
1. Customer asks price / points at an item → look it up → say: "<literal line with the price>
   Mình lấy size nào ạ?"
2. Customer asks about a variant (colour/size) → check the variant list → say: "<literal line with
   the real options> Chị chọn <A> hay <B> nhé?"
3. Variant out of stock → say it once, then offer the closest verified alternative → say: "<literal
   line naming the alternative>"
4. Customer confirms the item → ask the one blocking fulfillment field → say: "Chị cho em xin số
   điện thoại để em lên đơn nhé?"
5. Address still missing → say: "Chị cho em địa chỉ nhận hàng giúp em ạ."
6. Item + quantity + phone + address known → place the order in this same turn → say: "<literal
   confirmation line; the order code and total come from the system at that moment>"
```

Terminal steps confirm or decline; they do not ask a new question. Never write a step that says "send
the link" followed by a URL — media delivery is the runtime's job, reference the catalog item by name.
Never write "save the contact now" as an imperative — that trains empty tool calls; the quoted line
must *ask* the customer.

## Voice, addressing, softeners

This is the one place tenant-language nuance belongs — the system frame is deliberately neutral.

- Fix the pair explicitly: how the bot refers to itself and how it addresses the customer, and make
  them two distinct words. Never let one word play both roles in a sentence.
- **USE THE CUSTOMER'S NAME when the runtime knows it.** The system injects the known profile in
  `<customer_state>`; a bot that keeps saying the generic double form ("anh/chị", "Sir/Madam") while a
  real name sits in state reads like a robot. Write the rule into the body:

  ```
  ADDRESS = <customer_state> has a REAL personal name → use it every turn (with the honorific below
    when the language needs one). Customer states their own name or preferred form → switch to it
    immediately and keep it for the rest of the chat.
  NOT_A_NAME = a profile value that is not a personal name — a platform handle ("fb user 8823",
    "user_12345"), an email, a phone number, a shop/brand/page name, or an obvious placeholder — is
    NOT a name. NEVER say it out loud. Use the shop's neutral address form until the customer gives a
    real name.
  HONORIFIC = pick the gendered form ONLY from an explicit signal: the customer said it, the profile
    carries it, or the name has an unambiguous marker in this language. Real name but gender unclear →
    the name alone, no gendered word.
  ```

  Both halves matter. The first stops the sterile "anh/chị mọi lượt"; the second stops the far worse
  failure of addressing someone as the wrong gender. In Vietnamese for example "Nguyễn Thị Lan" and
  "Trần Văn Hùng" carry explicit markers (→ "chị Lan", "anh Hùng"), while "Minh Anh", "Bảo", a shop
  page name or a nickname do not (→ "Minh Anh" alone, or the shop's neutral pair). Write the equivalent
  guidance for whatever language the shop sells in — the rule is language-specific, not translatable
  word for word.
- Register shift is allowed and useful: a more formal address form when asking for phone, address or
  payment; a warmer one while discussing the product.
- Politeness particles / softeners belong here, with a cap: **one per message.** Listing many
  particles produces a bot that stuffs every sentence with them.
- Ban the specific fillers this shop hates, by example, and keep the exemplars consistent with the
  ban — the model copies exemplars over rules. If you forbid an opener, no exemplar may use it.

## Exemplars — 0 to 2, and never with hard-coded facts

The runtime imitates exemplars more strongly than it follows rules. That cuts both ways:

- An exemplar containing a literal price ("250k") teaches the bot to say 250k for other items. In
  catalog mode, write the fact as a placeholder: `"<tên món> <giá từ catalog> ạ. Chị lấy <màu A> hay
  <màu B>?"`.
- An exemplar asserting stock ("còn hàng ạ") teaches unconditional yes. Show the *shape* of the reply,
  let the tool supply the value.
- Each exemplar: reactive, at most one question mark, at most one field requested, no raw URL, no SKU
  read aloud.
- Zero exemplars is a valid, often better choice: the FLOW's quoted lines already anchor the voice.

## Length

Aim for a body of ~1,200–2,500 characters plus the tail block. Longer bodies do not buy behavior —
they bury it. If a rule already lives in a FLOW step, do not repeat it as a bullet. ONE rule, ONE
place.

## After writing

`get_runtime_preview` (the body is there, tools loaded) → `validate_chatbot_config` → the 5-message
acceptance set in SKILL.md. When behavior is wrong, change the **quoted lines** first — they move
behavior more than abstract rules — then the tail block. `get_shop_prompt_history` +
`rollback_shop_prompt` undo a bad edit.
