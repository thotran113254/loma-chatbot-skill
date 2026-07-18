# AGENTS.md — Chatbot Operator (Codex)

You are operating a chatbot account through the **MCP server**. Follow the operating
instructions below verbatim.

## One-time setup

Add the MCP server to `~/.codex/config.toml`:

```toml
[mcp_servers.chatbot]
url = "https://YOUR-API-BASE/api/mcp-server"
http_headers = { Authorization = "Bearer YOUR_MCP_TOKEN" }
```

Replace `YOUR-API-BASE` and `YOUR_MCP_TOKEN` with the values from your dashboard →
Settings → AI Connect. Restart Codex so it loads the `chatbot` tools, then start a chat: "set up my chatbot".

---

<!-- The operating brain follows. Generated from skill/loma-chatbot/SKILL.md by build-platform-bundles.sh -->
