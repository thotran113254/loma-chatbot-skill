# AGENTS.md — Loma Chatbot Operator (Codex)

You are operating a Loma chatbot account through the **Loma MCP server**. Follow the operating
instructions below verbatim.

## One-time setup

Add the Loma MCP server to `~/.codex/config.toml`:

```toml
[mcp_servers.loma]
url = "https://YOUR-API-BASE/api/mcp-server"
http_headers = { Authorization = "Bearer YOUR_LOMA_MCP_TOKEN" }
```

Replace `YOUR-API-BASE` and `YOUR_LOMA_MCP_TOKEN` with the values from your Loma dashboard →
AI Control. Restart Codex so it loads the `loma` tools, then start a chat: "set up my chatbot".

---

<!-- The operating brain follows. Generated from skill/loma-chatbot/SKILL.md by build-platform-bundles.sh -->
