# Connection and tool modes

## Attach the connector (once per AI client)

Two values from the dashboard → **Settings → AI Connect**:

| Value | Meaning |
|---|---|
| `MCP_API_BASE` | your platform origin, e.g. `https://app.example.com` |
| `MCP_TOKEN` | the access token — secret, never pasted into a chat message or committed |

The MCP endpoint is always `MCP_API_BASE` + `/api/mcp-server`, authenticated with
`Authorization: Bearer <MCP_TOKEN>`. Per-client setup steps live in the repository `README.md`.

If no tools are available at all, the connector is not attached — stop and set it up. Never simulate a
tool call or claim work was done without one.

## Direct mode vs toolbox mode

Look at what `tools/list` exposes right after connecting.

**Direct mode** — the full catalog appears as named tools. Call them exactly as written in the skill.
This is what OAuth/desktop sessions, legacy keys, and keys minted with the `full` scope get.

**Toolbox mode** — only a handful of meta-tools appear. This is the **default for newly-minted keys**
and is token-efficient (~0.5k tokens on connect), not a fault:

1. `search_tools({ query })` — find tools by keyword (`"order"`, `"test conversation"`, `"promotion"`).
   Returns the top `limit` matches with summaries plus `total_matches`; an **empty query** lists every
   tool name (no summaries, no truncation).
2. `get_tool_schemas({ names:[...] })` — exact descriptions + input schemas, up to 8 tools per call.
3. `invoke_tool({ name, arguments })` — run the real tool. **Passthrough:** identical behavior,
   permissions, tenant isolation and side effects as a direct call (mutations mutate for real, test
   runs spend credits).
4. `invoke_read_tool({ name, arguments })` — same passthrough, restricted to read-only tools
   (`list_*`, `get_*`, `search_*`, `query_*`, `validate_*`); it refuses anything that can mutate.
   Prefer it for discovery, inspection and monitoring.

Everything else — tool names, order, semantics, guardrails — is identical in both modes. Wherever a
step says *call `X`*, in toolbox mode do `get_tool_schemas({ names:["X"] })` → `invoke_tool({ name:"X",
arguments:{ … } })`. Look a name up once and reuse the schema instead of re-searching.

**Symptom to recognise:** a tool named in the skill "does not exist" as a callable function → you are
almost certainly in toolbox mode. Invoke it through `invoke_tool`; do not conclude the tool was removed.

## Key scopes

Minted on the same AI Connect page; fixed at creation and not changeable from inside a chat.

- `full` — the whole catalog, direct mode.
- default — toolbox mode.
- capability groups (`setup`, `catalog`, `testing`, `sales_ops`, `channels`, `outreach`,
  `integrations`, `analytics`) — only those groups' tools, exposed directly.

A key narrowed to a group cannot reach tools outside it. If a documented tool is genuinely absent in
direct mode, the key is scoped — say so and name the scope the user needs, instead of working around it.

## Automated / headless runs (CI, cron, `codex exec`, agent scripts)

`invoke_tool` is annotated **destructive** on purpose — it can place orders, delete channels and spend
credits. Consequences to plan for, verified on Codex 0.145:

- A client that respects tool annotations asks for approval on **every** toolbox call, reads included.
  Use `invoke_read_tool` for reads so only real writes need a decision.
- A **headless** client with "never ask" approvals does not just skip the prompt, it **auto-denies**
  the call (Codex reports `user cancelled MCP tool call`). Nothing works until you either accept
  bypassed approvals deliberately for that run, or use a `full`-scope key where each tool carries its
  own honest annotation and only writes need approval.
- Say so plainly when this bites instead of reporting the build as done: a cancelled tool call is not
  a completed step.

Codex specifics: install the skill folders under `.agents/skills` (workspace) or `$HOME/.agents/skills`
(user), configure the MCP server in `~/.codex/config.toml`, and keep
`agents/openai.yaml → policy.allow_implicit_invocation: true` — with `false` the skill is never
injected and the assistant behaves as if it did not exist.

## Tenant isolation

Every tool acts only inside the one account the token authenticates to. There is no cross-account
parameter and no way to reach another tenant's data. Requests to do so are out of scope — decline.
