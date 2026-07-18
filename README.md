# Loma Chatbot Skill

An AI **skill** that teaches Claude / ChatGPT / Codex how to build, configure, test, and operate a
**Loma** chatbot for you — end to end, without touching code. Attach the Loma MCP connector to your AI
client, load this skill, and say *"set up my chatbot"*.

- **What it is:** one portable instruction set (`skill/loma-chatbot/SKILL.md`) + ready-to-paste
  bundles for each AI platform + an MCP connector template.
- **What it controls:** your bot's prompt, tools, products, FAQ, promotions, pricing, channels
  (website / Zalo / TikTok), tests against the real runtime, and analytics — via ~170 Loma MCP tools.
- **Tenant-safe:** every action runs only inside the Loma account your token authenticates to.

---

## 1. Get your connection details (once)

From your **Loma dashboard → AI Control**, copy:

| Value | Example |
|-------|---------|
| `LOMA_API_BASE` | `https://app.your-loma-domain.com` |
| `LOMA_MCP_TOKEN` | `loma_mcp_xxxxxxxxxxxx` (keep secret) |

The MCP server URL is always `LOMA_API_BASE` + `/api/mcp-server`.

> Never paste your token into a chat message or commit it to git. Use the connector settings only.

**Tool modes (know this once):** newly-minted keys default to **toolbox mode** — token-efficient, the
AI loads tools on demand via `search_tools` / `get_tool_schemas` / `invoke_tool`. If you want the AI
to see all ~170 tools directly, create the key with the **`full`** scope on the AI Control page. The
skill handles both modes automatically; the only difference is how tools are called.

---

## 2. Install per platform

### Claude Code (terminal)

```bash
git clone https://github.com/thotran113254/loma-chatbot-skill.git
cd loma-chatbot-skill
./install-claude-code-skill.sh          # project-local  (or --global for all projects)
```

Then add the MCP server (copy `.mcp.json` into your project root) and export your values:

```bash
export LOMA_API_BASE="https://app.your-loma-domain.com"
export LOMA_MCP_TOKEN="loma_mcp_xxxxxxxxxxxx"
```

Start Claude Code and say: **"set up my Loma chatbot"**. The `loma-chatbot` skill auto-activates.

### Claude.ai (web / desktop)

1. Download `release/loma-chatbot-skill.zip` from this repo.
2. Claude.ai → **Settings → Capabilities/Skills → Upload skill** → pick the zip.
3. Add the Loma MCP connector: **Settings → Connectors → Add custom connector** →
   URL `https://YOUR-API-BASE/api/mcp-server`, header `Authorization: Bearer YOUR_LOMA_MCP_TOKEN`.
4. New chat → *"build my chatbot"*.

### ChatGPT (Custom GPT)

1. Open `platforms/chatgpt-custom-gpt-instructions.md`.
2. Copy everything below the `---` line into your Custom GPT → **Configure → Instructions**.
3. Attach the Loma MCP connector (or import the Loma OpenAPI as an Action) — see the file header.

### Codex

1. Copy `AGENTS.md` to the root of the workspace where you run Codex.
2. Add the Loma MCP server to `~/.codex/config.toml` (snippet is inside `AGENTS.md`).
3. Run Codex and say: *"set up my chatbot"*.

### Any other MCP client

Use `.mcp.json` as a template and load `skill/loma-chatbot/SKILL.md` as the system / instruction
context. Anything that speaks MCP over HTTP works.

---

## 3. First run — the golden path

Once connected, just describe what you want. The skill drives the right tools in order:

1. `create_chatbot` → 2. choose tools (`set_enabled_tools`) → 3. write the prompt
(`update_chatbot_config`, custom bot) → 4. add products / FAQ / promotions → 5. `validate_chatbot_config`
→ 6. `get_runtime_preview` → 7. **test like production** (`start_test_conversation`) → 8. connect a
channel → 9. monitor (`query_analytics`, `list_leads`, `list_orders`).

Testing uses the **same runtime as real customers**, so a passing test = real behavior. Test orders
are real and consume credits.

---

## Repository layout

```
loma-chatbot-skill/
├── README.md                                  ← you are here
├── skill/loma-chatbot/SKILL.md                ← canonical skill (source of truth)
├── AGENTS.md                                  ← Codex bundle (generated)
├── platforms/
│   ├── chatgpt-custom-gpt-instructions.md     ← ChatGPT paste bundle (generated)
│   ├── codex-header.md                        ← header used to build AGENTS.md
│   └── chatgpt-custom-gpt-header.md           ← header used to build the ChatGPT bundle
├── .mcp.json                                  ← MCP connector template
├── install-claude-code-skill.sh              ← Claude Code installer
├── build-platform-bundles.sh                 ← regenerate AGENTS.md + ChatGPT bundle from SKILL.md
└── release/loma-chatbot-skill.zip            ← upload to Claude.ai
```

Maintainers: edit **only** `skill/loma-chatbot/SKILL.md`, then run `./build-platform-bundles.sh` to
regenerate the Codex and ChatGPT bundles, and re-zip `release/`.

---

## Scope & privacy

This skill operates a Loma chatbot account through the Loma MCP tools. It does **not** manage Loma
server hosting, infrastructure, or other tenants' accounts, and will refuse credential-extraction or
out-of-scope requests. Your `LOMA_MCP_TOKEN` scopes all access to your own account.
