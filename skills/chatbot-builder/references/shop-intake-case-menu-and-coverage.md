# Intake — scope the bot with a case menu, never an interview

A page bot earns its keep by answering the **15–25 questions customers actually repeat**, and by getting
everything else to a human fast. Coverage of the repeats beats cleverness on the rare ones.

So the job is not "understand this business". It is: **pick the cases this shop wants answered, collect
only the data those cases consume, and wire the rest to escalation.**

Scope note: this file is what *you* ask the **shop owner**. What the finished **bot** may ask the
**customer** is capped separately — see `vertical-ask-sets.md`.

## The method — 3 rounds, no free-form interrogation

**Round 1 — one question.** What does the shop sell, and what should a chat end with: an order, a
booking/contact, or an answer? (Everything else follows from these two facts.)

**Round 2 — show the menu, let them tick.** Present the case list for that industry as a numbered
checklist and ask them to reply with numbers. Three buckets, in one message:

```
Chọn giúp em những câu khách hay hỏi mà BOT nên tự trả lời (trả lời bằng số, ví dụ: 1,2,3,5,8):
 1. Giá bao nhiêu?              6. Bao lâu thì nhận được hàng?
 2. Còn hàng / còn size-màu?    7. Có bảo hành / đổi trả không?
 3. Cho xem thêm ảnh            8. Thanh toán kiểu gì?
 4. Phí ship bao nhiêu?         9. Shop ở đâu / mở lúc nào?
 5. Muốn đặt hàng              10. Đơn của em tới đâu rồi?
Câu nào KHÔNG muốn bot tự trả lời (để chuyển cho anh/chị)? →
Câu nào khách hỏi nhiều mà chưa có trong danh sách? →
```

A shop owner who cannot write a brief can always tick numbers. This is the single biggest reason a bot
gets built in one sitting instead of three.

**Round 3 — ask only for the data the ticked cases need.** Use the mapping table below; for each ticked
case ask the one missing fact, in one batch, and never ask for anything no ticked case consumes.
"Bot không tự trả lời" cases need no data at all — they need an escalation route.

Then build, and say plainly which cases are covered and which go to a human.

## Case → where the answer lives (this is the whole design)

Universal set — true in every industry:

| # | Customer case | Answer comes from | What to ask the owner |
|---|---|---|---|
| 1 | price | product/variant price in the catalog | price per buyable variant |
| 2 | availability, size/colour | variant `option_values` + stock | the real option list + whether they track stock |
| 3 | more photos | variant `image_url` / media catalog | photos per item (or accept "no photo" honestly) |
| 4 | shipping fee | FAQ + shipping config | fee, free-ship threshold, areas served |
| 5 | wants to order | order flow + `create_order` | which fields they need on an order |
| 6 | delivery time / lead time | FAQ | realistic days, pre-order rules |
| 7 | warranty / return | FAQ | the actual policy, in their words |
| 8 | payment methods | payment config + FAQ | COD? transfer? deposit required? |
| 9 | location / opening hours | FAQ | address, hours |
| 10 | order status | `lookup_order` (enable it) or escalation | nothing — decide bot vs human |
| 11 | promo / voucher | promotion + `check_promotions` | running promos, codes |
| 12 | bargaining | FAQ line or escalation | is negotiation allowed at all? |
| 13 | complaint | escalation (`transfer_to_agent`) | who handles it |
| 14 | off-topic / chit-chat | `SCOPE_GUARD` in the prompt | nothing |
| 15 | asks for a human | `transfer_to_agent` | nothing |
| 16 | spam / abuse | `mute_bot` | nothing |
| 17 | item out of stock | flow step: state it once + offer a verified alternative | which items are the usual substitutes |
| 18 | product detail / spec | `page_description` + `custom_fields` | the 2–3 specs customers actually ask about |
| 19 | delivery area | FAQ | areas in/out |
| 20 | **anything else** | `search_faq` → `search_resolved_knowledge` → `escalate_question` → ticket | nothing — this is the safety net |

Industry deltas — add these rows to the menu for that industry, drop the ones that make no sense:

- **Fashion / accessories:** size chart & "tôi cao X nặng Y thì size nào" (needs a real chart in FAQ, else
  escalate), material/care, "mặc có nóng không".
- **Cosmetics / skincare:** skin type or concern (one narrowing question), ingredients list,
  authenticity/genuine-product proof, "dùng bao lâu thì hết". Never diagnose.
- **F&B / bakery:** pre-order lead time, delivery window/slot, allergy or ingredient note, box/portion size,
  "đặt số lượng lớn cho tiệc".
- **Appointment services (spa, dental, repair, salon):** available slots, service duration, price range vs
  exact price, cancel/reschedule, "có cần đặt trước không". Booking itself = capture contact, human confirms.
- **Configurable pricing (print, furniture, signage):** which spec parameters, MOQ, sample/mockup request,
  production lead time, file/artwork requirements.
- **High-consideration (property, education, courses, B2B):** financing/instalments, legal or accreditation
  docs, viewing/demo appointment, "có hỗ trợ trả góp không". Most end in a contact, not an order.

## The escalation contract — make the other 80% land somewhere

A bot that guesses on case 20 is worse than a bot that hands it over. Wire the full ladder every time:

- `search_faq` — answers the cases the owner ticked.
- `search_resolved_knowledge` — answers what admins already resolved once before.
- `escalate_question` — silently files a ticket when the answer genuinely is not in the shop's data;
  the bot says it will check and keeps the conversation alive. **Enable this on every bot.** Without it the
  bot's only options are inventing something or dead-ending.
- `transfer_to_agent` — customer asks for a person, or the case is one the owner ticked as "not for the bot".
- `mute_bot` — abuse/spam only.

Tell the owner in plain words: *"Bot trả lời N câu này. Câu nào ngoài đó nó sẽ ghi phiếu cho anh/chị trả
lời, và khi anh/chị trả lời xong thì bot học luôn câu đó cho lần sau."* That last part is real: tickets →
`resolve_ticket` → `approve_resolved_knowledge` → promote to `add_faqs` (in the **chatbot-ops** skill). Coverage
grows from actual misses, which is far better targeting than guessing more cases up front.

## Seeding the FAQ with real customer phrasing

Owners write policy language ("Chính sách vận chuyển"); customers type "ship bao nhiêu tiền v" and
"mấy ngày tới hà nội". For each ticked case, ask the owner for **2–3 real phrasings** — or offer your own and
have them correct you. Put the customer phrasing in the FAQ topic and the owner's answer in the body.
This one habit is the difference between a FAQ that fires and a FAQ that never matches.

## Worked example — fashion shop, one sitting

```
Round 1  → "Bán túi da handmade, muốn chốt đơn ngay trên page."
Round 2  → ticks 1,2,3,4,5,6,7,8,17 ; "không cho bot mặc cả" (12 → transfer) ; adds "bảo quản da"
Round 3  → asks only: giá theo từng màu/size · màu-size thật · ảnh từng màu · phí ship + ngưỡng freeship
           · policy bảo hành/đổi · thời gian giao · COD hay CK · mẫu thay thế khi hết hàng
Build    → products(variants+stock+ảnh) · FAQ(ship/đổi trả/giao/thanh toán/bảo quản)
           · flow: giá→màu/size→SL→SĐT→địa chỉ→lên đơn · step hết hàng→mẫu tương đương
           · tools: search_products, get_product_info, send_media, create_order, collect_lead,
             search_faq, escalate_question, transfer_to_agent, mute_bot
Say      → "Bot tự trả lời 9 nhóm câu này; mặc cả và khiếu nại chuyển anh/chị; câu lạ nó ghi phiếu."
```

## Anti-patterns that cost a whole session

- Asking the owner to "describe your business" and getting three paragraphs of marketing copy → no
  operational facts. Use the menu.
- Asking for data no ticked case consumes (brand story, competitor list, target audience) → wasted turns
  and it never reaches the bot.
- Ticking 40 cases "để chắc" → the flow bloats, the prompt bloats, and the bot still misses. Start with the
  repeats; let tickets add the rest.
- Shipping a bot with no `escalate_question` → every unknown becomes either an invention or a dead end.
- Writing the ticked cases into the prompt as prose instead of into FAQ/catalog → the prompt rots and the
  data never gets reused.
