# Pi Agent Neovim Plugin — Plan

## What We Have

- **UI** (`lua/pi/ui/`): Floating chat window with raw Neovim APIs (no nui.nvim — we tried it, fought it, dropped it). Two floating windows: display + input. Auto-resizing input, mode-aware chrome (border color + label from tokyonight palette), scroll overflow indicators.
- **Colors** (`lua/pi/colors.lua`): Highlight groups derived from tokyonight palette, auto-refresh on ColorScheme change. `PiBorder`, `PiTitle`, `PiModeBorder_*`, `PiModeTitle_*`.
- **Context** (`lua/pi/context.lua`): Tree-sitter context gathering — nearest function/class/variable, visual selection, line fallback. Produces structured `pi.Context` with type, name, text, filepath, range, description.
- **Agent** (`lua/pi/agent.lua`): Stub that echoes back messages.
- **Plugin spec** (`lua/plugins/pi.lua`): Zero dependencies. Keymaps: `<leader>pp` toggle, `<leader>pa` ask with context. Commands: `:Pi`, `:PiAsk`.

## Agent Communication: RPC Mode

Spawn `pi --mode rpc` as a subprocess, communicate via JSON lines over stdin/stdout. Sessions are enabled by default — pi manages conversation history, compaction, and persistence automatically. This gives us:

- **Streaming**: `message_update` events with `text_delta` for token-by-token display
- **Tool visibility**: `tool_execution_start/update/end` events so we can show what pi is doing
- **Full control**: `abort`, `steer`, `follow_up` for interrupting/guiding the agent
- **Session management**: can add persistence later
- **No Node.js dependency** in the plugin — just subprocess + JSON parsing

RPC is preferred over the SDK for non-Node integrations. See pi docs: `docs/rpc.md` and `docs/sdk.md`.

## Steps

### Step 1: `agent.lua` — RPC client
- Spawn `pi --mode rpc` via `vim.system` or `vim.fn.jobstart`
- JSONL framing: write commands to stdin, read events from stdout line by line
- Expose: `send(message, callbacks)` where callbacks = `{ on_delta, on_tool_start, on_tool_end, on_done, on_error }`

### Step 2: Streaming display
- `append_message` becomes `start_message` / `append_delta` / `end_message`
- Text streams in token by token, auto-scrolling
- Show a spinner or indicator while agent is working

### Step 3: Tool execution display
- Show `[reading file.lua]`, `[running: ls -la]` etc. in the chat as the agent works
- Use the `tool_execution_start/end` events

### Step 4: Context payload
- Actually send the code from `context.lua` with the prompt
- Format: include filepath, range, and code block in the message
- The `ask` flow currently only sends the description, not the source text

### Step 5: Abort/interrupt
- `<C-c>` during streaming sends `abort` command instead of closing
- Maybe `steer` support for redirecting mid-stream

### Step 6: Display rendering
- Markdown rendering in the chat display (we have `render-markdown.nvim` in the config)
- Syntax-highlighted code blocks in responses
- Visual separation between messages (extmarks, highlights, virtual text)

### Step 7: Conversation history
- Pi handles conversation history via sessions (enabled by default)
- Preserve display buffer across toggle open/close (currently destroyed on close)
- On open, hydrate display from `get_messages` if resuming a session
- How much context (file contents, tree-sitter info) gets sent with each message?

### Step 8: Session management
- New session command (`:PiNew`)
- Switch/list sessions (pi RPC has `new_session`, `switch_session`, `get_fork_messages`)
- Session name display in the chat title

### Step 9: In-buffer UI (v2)
- Cursor-relative floating window for quick answers (`relative = "cursor"` in `nvim_open_win`)
- Inline virtual text for short responses
- Ask about a specific variable/function without opening the full chat

## Lessons Learned

- **nui.nvim**: Layout component flashes on update (unmount/remount cycle). Input component auto-closes after submit (designed for one-shot prompts). Ended up fighting it more than it helped. Raw `nvim_open_win` is simpler for a persistent chat UI.
- **ModeChanged autocmd**: Doesn't fire for visual mode entry in floating windows. Lualine solves this the same way — a polling timer on `vim.fn.mode()`. 100ms interval works fine.
- **Window geometry**: Percentage-based sizing causes rounding gaps (e.g., 85% + 15% of 30 = 29, not 30). Use `grow` patterns or fixed sizes.
- **Statusline on floats**: Even `style = "minimal"` floats can show statusline bars. Set `statusline = ""` or use `winhighlight` to hide them.
