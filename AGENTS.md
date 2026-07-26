# AGENTS.md — chatbot skills pointer

This workspace ships two agent skills. Prefer loading them as skills:

- `skills/chatbot-builder/SKILL.md` — create a bot, write its prompt, load data, pick tools, test,
  launch. Its `references/` folder holds the prompt blueprint, per-industry ask-sets, the data model,
  and connector/tool-mode details.
- `skills/chatbot-ops/SKILL.md` — run a live bot: channels, conversations, leads, orders, follow-up,
  campaigns, analytics, and diagnosing a chat that went wrong.

Install them so Codex discovers them automatically:

```bash
./install.sh codex             # ~/.agents/skills   (user-wide)
./install.sh codex --project   # ./.agents/skills   (this workspace)
```

One-time MCP wiring in `~/.codex/config.toml`:

```toml
[mcp_servers.chatbot]
url = "https://YOUR-API-BASE/api/mcp-server"
http_headers = { Authorization = "Bearer YOUR_MCP_TOKEN" }
```

Values come from the dashboard → Settings → AI Connect. Restart Codex, then say “build my chatbot”.

If this Codex build has no skill support, read `skills/chatbot-builder/SKILL.md` (and its references as
needed) as your operating instructions for chatbot work, and `skills/chatbot-ops/SKILL.md` for
operating a bot that is already live. Do not act on chatbot requests without the MCP tools attached.
