# Chatbot Skills

Two **agent skills** that teach any skill-capable AI assistant how to build and run your chatbot
through the platform's MCP connector — no code, no dashboard hunting.

| Skill | Use it for |
|---|---|
| **`chatbot-builder`** | scope what the bot should answer, create it, write its prompt, load products/FAQ/images, pick tools, test against the real runtime, launch on a channel |
| **`chatbot-ops`** | the bot is live: conversations, leads, orders, channels, follow-up, campaigns, analytics, diagnosing a chat that went wrong |

They are split on purpose: one assistant loading both jobs at once reads the wrong half and does the
wrong thing. Install both — the assistant picks the right one per request.

Built on the [Agent Skills open standard](https://agentskills.io), so the same folders work in Claude
(Code / desktop / web), ChatGPT, and Codex.

---

## 1. Get your connection details (once)

Dashboard → **Settings → AI Connect**:

| Value | Example |
|-------|---------|
| `MCP_API_BASE` | `https://app.your-domain.com` |
| `MCP_TOKEN` | `<your token>` — keep it secret |

The MCP endpoint is always `MCP_API_BASE` + `/api/mcp-server`, header
`Authorization: Bearer <MCP_TOKEN>`.

> Never paste the token into a chat message or commit it. Put it in connector settings only.

**Key modes.** New keys default to **toolbox mode**: the assistant loads tools on demand
(`search_tools` → `get_tool_schemas` → `invoke_tool` / `invoke_read_tool`) instead of seeing all ~170 at once — cheaper and
normal. Mint the key with the **`full`** scope if you want every tool exposed directly. Both skills
handle either mode automatically.

## 2. Install

```bash
git clone https://github.com/thotran113254/loma-chatbot-skill.git
cd loma-chatbot-skill
```

### Claude Code

```bash
./install.sh claude-code            # this project (./.claude/skills)
./install.sh claude-code --global   # all projects (~/.claude/skills)
```

Add the MCP server: copy `.mcp.json` into your project root (or merge it), then

```bash
export MCP_API_BASE="https://app.your-domain.com"
export MCP_TOKEN="<your token>"
```

Start Claude Code and say **“build my chatbot”**.

### Claude desktop / web (claude.ai)

```bash
./build-release-bundles.sh          # writes release/chatbot-builder.zip + release/chatbot-ops.zip
```

Settings → **Capabilities / Skills → Upload skill** → upload each zip. Then Settings → **Connectors →
Add custom connector** → URL `https://YOUR-API-BASE/api/mcp-server`, header
`Authorization: Bearer YOUR_MCP_TOKEN`. New chat → “build my chatbot”.

### ChatGPT

ChatGPT supports skills natively (Business / Enterprise / Edu workspaces; a workspace admin can enable
them). Upload `release/chatbot-builder.zip` and `release/chatbot-ops.zip` as skills, then attach the MCP
connector for the same URL and token.

`skills/*/agents/openai.yaml` already declares the MCP dependency — edit the `url:` line in each file to
your own `MCP_API_BASE` before uploading and the connector wiring is offered for you.

> The old Custom-GPT instruction bundle is gone. Skills replace it: same content, real progressive
> disclosure, and one copy shared with Claude and Codex.

### Codex

```bash
./install.sh codex                  # ~/.agents/skills  (user-wide)
./install.sh codex --project        # ./.agents/skills   (this workspace only)
```

Add the MCP server to `~/.codex/config.toml`:

```toml
[mcp_servers.chatbot]
url = "https://YOUR-API-BASE/api/mcp-server"
http_headers = { Authorization = "Bearer YOUR_MCP_TOKEN" }
```

Restart Codex, then: “build my chatbot”.

### Any other MCP client

Use `.mcp.json` as the connector template and load `skills/chatbot-builder/SKILL.md` (plus its
`references/`) as instruction context. Anything that speaks MCP over HTTP works.

## 3. What a first run looks like

Say what you want; the skill drives the tools in order:

pick which customer questions the bot should answer (it shows you a numbered menu — you reply with
numbers) → confirm the chat outcome, escalation route, and one grounded sample dialog → create or reuse
the bot → pick its tools → load products / FAQ / images → compile the Shop Prompt V2 body → validate →
preview the assembled prompt → **test through the real runtime** → bind a channel to go live → hand over
to ops for monitoring.

A page bot is most effective when it owns the 15–25 questions customers actually repeat; anything else it
files as a ticket for you, and once you answer, the bot learns it for next time.

A bot is live or silent purely through its **channel binding** — there is no separate on/off switch on
the bot, so nothing goes out to customers until you connect a channel.

Testing uses isolated `is_test` traffic through the same runtime pipeline, so a passing test is strong
evidence without contacting a real customer. Credits and test-side writes, including test orders, can
still be real; get explicit confirmation before starting any test session.

## Repository layout

```
skills/
  chatbot-builder/
    SKILL.md                                       ← build & prompt a bot
    agents/openai.yaml                             ← ChatGPT/Codex metadata + MCP dependency
    references/
      shop-intake-case-menu-and-coverage.md        ← what to ask the OWNER: case menu + coverage
      custom-bot-prompt-blueprint.md               ← how to write the bot's brain
      vertical-ask-sets.md                         ← what the bot may ask the CUSTOMER, per industry
      catalog-media-and-config-data-model.md       ← products, stock, images, lead slots, knobs
      connection-and-tool-modes.md                 ← connector, direct vs toolbox mode
  chatbot-ops/
    SKILL.md                                       ← run a live bot
    agents/openai.yaml
    references/
      conversation-diagnosis-playbook.md           ← symptom → the layer that actually fixes it
      connection-and-tool-modes.md
.mcp.json                                          ← MCP connector template
install.sh                                         ← claude-code | codex installer
build-release-bundles.sh                           ← zips for Claude.ai / ChatGPT upload
AGENTS.md                                          ← pointer for Codex setups without skill support
skill/loma-open-platform-integrator/SKILL.md       ← external REST/webhook integration playbook
```

Maintainers: the `SKILL.md` files are the source of truth. Keep each under 300 lines, keep each
reference under 300 lines, and never duplicate content between a SKILL.md and its references.
The repository also ships `skill/loma-open-platform-integrator/SKILL.md`, a developer-facing
playbook for external REST, webhook, proactive-message, conversation-label, and HTTP-tool
integrations. It is separate from the customer chatbot Builder/Ops skills and is not included in
the two chatbot upload bundles.

## Scope & privacy

These skills operate one chatbot account through MCP tools. They do **not** manage server hosting,
infrastructure, billing, or any other tenant, and they refuse credential-extraction and out-of-scope
requests. Your token scopes every action to your own account. Outreach, campaigns and customer-visible
messages require your explicit confirmation first.
