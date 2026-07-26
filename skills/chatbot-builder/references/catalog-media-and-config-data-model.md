# Data model — catalog, media, lead slots, config knobs

Everything the bot states as fact must come from one of these stores. Prose in the prompt is the wrong
place for a fact that changes.

## Products — `add_products` / `update_product`

One `variants[]` entry per **buyable SKU**. The variant list is what the bot treats as the complete set
of choosable options, so an option that is not modelled here cannot be offered — and will not be asked
about either.

| Field | Why it matters |
|---|---|
| `variants[].option_values` | `{ "Size":"M", "Màu":"Đỏ" }` — this is how "còn màu đen không?" gets a real answer |
| `variants[].name` | distinct per SKU; used when re-mentioning the item to the customer |
| `variants[].price`, `compare_at_price`, `currency` | `compare_at_price` renders a strike-through; currency defaults to the shop's |
| `track_inventory` / `quantity` / `allow_oversell` | **decides sellability** — see below |
| `variants[].image_url` | no image → the bot honestly says it has no photo; it never fabricates a link |
| `unit` | "kg", "ly", "phần" — keeps quantities sane |
| `page_description` | markdown detail the bot can consult when advising |
| `custom_fields` | filterable attributes; keys must exist as field definitions first |

**Stock is the number-one launch bug.** A physical variant defaults to `track_inventory:true` with no
quantity → reads OUT OF STOCK → order creation is blocked and the bot politely refuses to sell.
- shop does not track per-unit stock → `track_inventory:false` (unlimited)
- shop tracks stock → real `quantity > 0`
- pre-order → `allow_oversell:true` keeps it sellable at 0
- fixing an existing item → `update_product` the variant with a `quantity`

**Pricing modes:** `fixed` (variant price) · `range` (display-only `price_display_text`, no order can be
created) · `rule` (`pricing_rule_code` + a pricing rule). In `range` mode the bot presents the text
verbatim and will not derive a number — that is correct behavior, not a bug.

**Filterable attributes:** `manage_field_definition` once per key (e.g. `roast_level` select,
`is_spicy` boolean, with `is_filterable`), then set matching `custom_fields` on the products. Field
definitions are **shop-wide, shared across all bots in the account**. A filter only appears at runtime
once a linked product actually carries the key — define *and* populate.

## FAQ, promotions, pricing

- `add_faqs` — policies, shipping, warranty, payment, hours. Answers become available once the FAQ
  corpus syncs; immediately after adding, expect a generic answer for a short while.
- `create_promotion` — discounts auto-apply at checkout, but the bot can only *mention* one if
  `check_promotions` (and `apply_voucher` for codes) are enabled. Without the tool it answers "no
  discount information", which is correct grounding.
- `create_pricing_rule` — parameterised pricing; the bot quotes through the pricing tool, never by
  arithmetic. Alternative for markdown-table pricing: `configure_chatbot`
  `price_estimation_enabled` + `price_estimation_pricing_table` + `price_estimation_instructions`.

## Images the bot may send — the media catalog

Two steps, and never raw URLs in the prompt:

1. `upload_chatbot_image({ chatbot_id, image_base64, description })` → returns a hosted `image_url`.
2. `update_chatbot_config({ config_patch:{ shop_media:{ enabled:true, items:[ …COMPLETE array… ] } } })`
   — the array **replaces**, it does not append. Send every item you want to keep.

Item shape: `{ id, url, label, description, use_when?, tags?, is_active? }` — `description` is required
for catalog membership, `use_when` tells the bot when it is the right image. Max 20 active items.

The runtime injects a media block listing each item as an opaque handle and resolves the real URL
server-side. In the prompt body reference the item by **name or handle**, never by URL. A handle is
sent once, then follow-ups on the same item are text-only unless the customer asks again.

Product photos are separate and usually better for a sales bot: put `image_url` on the variant. Use the
media catalog for things that are not one product (size charts, shop front, price lists, certificates).

## Lead slots — `lead_fields`

Set via `configure_chatbot` or `update_chatbot_config`. Shape: `{ name, label, required, type
(text|phone|number|email|select|date), options?, description? }`. The **`name`** is the slot key the
runtime injects and the model must save under, verbatim.

Works on **any** bot whose tool set includes the contact-capture tool — not only lead-generation bots.
Nothing in the platform creates leads behind the model: no capture means the prompt or the tool set is
wrong, not the database.

## Config knobs that change behavior

`configure_chatbot` (verified parameters — anything not listed here does not exist on this tool):
`chatbot_type` · `message_delay_seconds` (2–30) · `default_language` · `country_code` · `timezone` ·
`image_processing_enabled` · `image_disabled_messages` · `admin_pause_enabled` /
`admin_pause_duration_minutes` / `admin_pause_skip_first_message` · `max_search_results` (1–10,
**default 1**) · `show_out_of_stock` · `product_cards_enabled` / `product_cards_show_price` ·
`label_mode` · `lead_fields` · `negotiation_enabled` · `price_estimation_*`.

- **`max_search_results` default 1** is why a bot sometimes shows one item when the customer asked to
  browse. Raise it to 3–5 for a browsing page bot.
- **Language unset = system default**: the frame is neutral and the bot mirrors the customer's
  language. Only pin `default_language` when the shop wants one fixed language. Do not write these keys
  "just in case".
- `show_out_of_stock:true` is what lets the bot offer a sold-out item as "back soon" instead of
  pretending it does not exist. Pair it with a flow step for the out-of-stock case.

`update_chatbot_config` `config_patch` (for what `configure_chatbot` does not cover):
- `shop_media` — the media catalog (above).
- `media.auto_image_send` — `off` / `auto` (default: the model illustrates when it fits) / `force`
  (always attach the top result's photo).
- `payment.default_method` + `payment.available_methods`, `shipping.default_method` +
  `shipping.available_methods` — injected only when the order tool is enabled. One method → applied
  silently, the customer is never asked to choose. Several → the default applies unless a choice is
  genuinely needed. Configuring these removes a whole class of pointless questions.
  **These name the method, not the amount.** The delivery *fee* is a number the order tool takes as an
  argument; with no argument it falls back to a platform default that is not this shop's price. So put
  the shop's fee table (per area, free-ship threshold, surcharges) in the FAQ, and write the flow so the
  closing step looks it up for the customer's address and passes it when the order is created —
  otherwise the order code is right and the total is quietly short. Verify on a real test order, not by
  reading the reply text.
- `custom_context_modules` (custom bots) — `recent_turns`, `promotions`, `media_log`, `media_policy`.
  All default ON; switch one off only with a reason, and never `customer_state`.
- `tool_loop_max_iterations` — per-bot ceiling on the tool loop.
- `admin_pause`, `mute_bot.triggers`, `transfer_to_agent.triggers` — the last two replace the default
  handoff wording with the shop's own trigger description.
- `custom_tool_descriptions` — prefer the dedicated `set_tool_descriptions` tool.
- **Blocked here:** `system_prompt`, `custom_system_prompt`, `mcp`, `mcp_servers`. They are silently
  dropped and reported in `ignored_fields`. Prompt text goes through `update_shop_prompt` /
  `build_shop_prompt` / `refine_shop_prompt` only.

## Reading what a shop already has

`get_chatbot_config` · `get_enabled_tools` · `list_products` · `list_faqs` · `list_promotions` ·
`list_pricing_rules` · `list_field_definitions` · `get_shop_prompt` · `get_runtime_preview`.
Read before you write: most "the bot is broken" reports are a missing resource, not a prompt problem.
