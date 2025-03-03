# Migrating to Native Neovim LSP

This document provides a step-by-step plan to migrate from `nvim-lspconfig` to Neovim 0.11's built-in `vim.lsp.config` API.

## Why Migrate?

1. **Simplified Architecture**: Remove an abstraction layer (nvim-lspconfig)
2. **Future-proof**: Use Neovim's official API that will receive ongoing improvements
3. **Better Performance**: Fewer dependencies means faster startup and less overhead
4. **Better Integration**: Direct access to Neovim's latest LSP features

## Base Directory Structure

Current organization:
```
~/.config/nvim.new/
  ├── lua/
      ├── plugins/
      │   └── lang/           (Language-specific plugin settings)
      │       └── python.lua  (Contains formatter and LSP settings)
      │       └── django.lua
      │
      └── lsp/               (Current LSP modules)
          └── init.lua
          └── keymaps.lua
          └── ...
```

Target organization after migration:
```
~/.config/nvim.new/
  ├── lua/
      ├── plugins/
      │   └── lang/           (Will contain only non-LSP settings)
      │       └── python.lua
      │       └── django.lua
      │
      ├── lsp/               (Current LSP modules - transitional)
      │   └── init.lua
      │   └── ...
      │
      └── config/            (New centralized config)
          └── lsp.lua        (Main LSP setup)
```

## Migration Checklist

- [ ] Step 1: Create the language-based LSP configuration files
- [ ] Step 2: Create central LSP configuration module
- [ ] Step 3: Set up global LSP settings
- [ ] Step 4: Configure LSP event handlers
- [ ] Step 5: Update Mason integration
- [ ] Step 6: Update plugin configurations to disable nvim-lspconfig
- [ ] Step 7: Test and refine
- [ ] Step 8: Remove nvim-lspconfig entirely

## Detailed Migration Steps

### Step 1: Create the language-based LSP configuration files

First, we'll create modular LSP configuration files that work with Neovim 0.11's auto-discovery feature.

**Action 1.1: Create a directory for language server configurations**

```bash
mkdir -p ~/.config/nvim.new/lsp
```

**Action 1.2: Create a Python language configuration file**

Based on your current Python configuration:

```lua
-- File: ~/.config/nvim.new/lua/lsp/python.lua
return {
  -- Server configurations for Python
  basedpyright = {
    -- Your basedpyright settings (currently empty in your config)
  },
  ruff = {
    cmd_env = { RUFF_TRACE = "messages" },
    init_options = {
      settings = {
        logLevel = "error",
      },
    },
  },
}
```

**Action 1.3: Create configuration files for other languages**

Repeat the process for each language in your setup. For example, for Lua:

```lua
-- File: ~/.config/nvim.new/lua/lsp/lua.lua
return {
  lua_ls = {
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
        },
        codeLens = {
          enable = true,
        },
        completion = {
          callSnippet = "Replace",
        },
        doc = {
          privateName = { "^_" },
        },
        hint = {
          enable = true,
          setType = false,
          paramType = true,
          paramName = "Disable",
          semicolon = "Disable",
          arrayIndex = "Disable",
        },
      },
    },
  },
}
```

### Step 2: Create central LSP configuration module

**Action 2.1: Create the main LSP configuration file**

```lua
-- File: ~/.config/nvim.new/lua/config/lsp.lua
local M = {}

-- Capabilities helper function
function M.get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  
  -- Add blink capabilities
  local has_blink, blink = pcall(require, "blink.cmp")
  if has_blink then
    capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
  end
  
  return capabilities
}

function M.setup()
  -- Will be filled out in subsequent steps
end

return M
```

### Step 3: Set up global LSP settings

**Action 3.1: Configure global defaults and diagnostics**

Add to the `M.setup()` function:

```lua
function M.setup()
  -- Set global defaults for all servers
  vim.lsp.config["*"] = {
    capabilities = M.get_capabilities(),
    -- Any other global settings you want
  }
  
  -- Configure diagnostics
  vim.diagnostic.config({
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = require("utils.icons").diagnostics.Error,
        [vim.diagnostic.severity.WARN] = require("utils.icons").diagnostics.Warn,
        [vim.diagnostic.severity.HINT] = require("utils.icons").diagnostics.Hint,
        [vim.diagnostic.severity.INFO] = require("utils.icons").diagnostics.Info,
      },
    },
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
  })
end
```

### Step 4: Configure LSP event handlers

**Action 4.1: Add keymap and feature handlers**

Add to the `M.setup()` function:

```lua
function M.setup()
  -- Previous code from Step 3...
  
  -- Set up keymaps
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then return end
      
      -- Copy your existing keymap logic
      -- For now, you can even reuse your existing module:
      require("lsp.keymaps").on_attach(client, buffer)
    end,
  })
  
  -- Special server customizations (like your ruff setup)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "ruff" then
        client.server_capabilities.hoverProvider = false
      end
    end,
  })
  
  -- Set up inlay hints (for Neovim 0.10+)
  if vim.fn.has("nvim-0.10") == 1 then
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local buffer = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        
        if client and client.server_capabilities.inlayHintProvider then
          -- Get excluded filetypes from your current config
          local excluded_filetypes = {} -- Update this from your current config
          if not vim.tbl_contains(excluded_filetypes, vim.bo[buffer].filetype) then
            vim.lsp.inlay_hint.enable(buffer, true)
          end
        end
      end,
    })
  end
  
  -- Enable the servers
  vim.lsp.enable({
    "basedpyright", 
    "ruff", 
    "lua_ls",
    -- Add all your other servers here
  })
end
```

### Step 5: Update Mason integration

**Action 5.1: Update your Mason plugin configuration**

```lua
-- In lua/plugins/mason.lua or wherever your Mason setup is
return {
  "williamboman/mason.nvim",
  -- other Mason settings...
  opts = function(_, opts)
    opts = opts or {}
    opts.ensure_installed = opts.ensure_installed or {}
    
    -- Get server names from all language-specific LSP configs
    local lsp_servers = {
      "basedpyright", 
      "ruff", 
      "lua_ls",
      -- Add all your other servers here
    }
    
    -- Convert LSP server names to Mason package names if needed
    -- For most servers, the names are the same
    local mason_packages = {}
    for _, server in ipairs(lsp_servers) do
      -- Handle special cases
      if server == "lua_ls" then
        table.insert(mason_packages, "lua-language-server")
      else
        table.insert(mason_packages, server)
      end
    end
    
    -- Extend the ensure_installed list
    vim.list_extend(opts.ensure_installed, mason_packages)
    
    return opts
  end,
  -- other Mason setup...
}
```

### Step 6: Update plugin configurations to disable nvim-lspconfig

**Action 6.1: Update language-specific plugin files**

For each file in `lua/plugins/lang/`, remove the LSP configuration portions. For example:

```lua
-- Original lua/plugins/lang/python.lua
return {
  {
    "stevearc/conform.nvim",
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
    },
  },
  -- REMOVE THIS PART
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = {
  --     servers = {
  --       basedpyright = {},
  --       ruff = {
  --         -- settings...
  --       },
  --     },
  --     setup = {
  --       -- setup functions...
  --     },
  --   },
  -- },
}
```

**Action 6.2: Disable nvim-lspconfig**

Create or update your `lua/plugins/lspconfig.lua` file to disable the plugin:

```lua
return {
  "neovim/nvim-lspconfig",
  enabled = false, -- Disable the plugin
}
```

### Step A: Initialize Your New LSP Configuration

**Action A.1: Add to init.lua**

```lua
-- In your init.lua or a file that's loaded during startup
require("config.lsp").setup()
```

### Step 7: Test and refine

**Action 7.1: Test your configuration**

1. Start Neovim
2. Open a file for each language you've configured
3. Verify that:
   - The language server attaches correctly
   - Diagnostics appear
   - Keymaps work
   - Features like inlay hints work

**Action 7.2: Debug if needed**

If something isn't working:

```lua
-- Check which servers are enabled
:lua print(vim.inspect(vim.lsp.get_clients()))

-- Check server capabilities
:lua print(vim.inspect(vim.lsp.get_clients()[1].server_capabilities))

-- Manually try enabling a server
:lua vim.lsp.enable({"lua_ls"})
```

### Step 8: Remove nvim-lspconfig entirely

Once everything is working:

**Action 8.1: Remove the plugin completely**

Remove the entry from your plugins list entirely, or use your plugin manager's clean command.

## Using Neovim 0.11+ Configuration Files with Your Current Structure

Neovim 0.11 introduces a powerful new feature that allows modular LSP configuration through files in your runtimepath. Looking at your current language-specific setup in `lua/plugins/lang/`, this migration plan takes full advantage of this feature.

The key concept is:
- LSP server configurations will be stored in `lua/lsp/{language}.lua` files
- Each file will return a table with server configurations for that language
- Neovim will automatically discover and merge these configurations
- Your main setup just needs to enable the servers

This approach aligns with your current organization while leveraging Neovim 0.11's new capabilities.

## Additional Resources

- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [vim.lsp.config API documentation](https://neovim.io/doc/user/lsp.html#vim.lsp.config())

## Implementation Plan

### Approach 1: Server-per-File Organization

#### 1. Create LSP Configuration Files

Create a new directory structure for LSP-specific configurations:

```
~/.config/nvim.new/lsp/
                   └── basedpyright.lua
                   └── ruff.lua
                   └── lua_ls.lua
                   └── ... (one file per server)
```

For example, based on your python.lua file:

```lua
-- In ~/.config/nvim.new/lsp/basedpyright.lua
return {
  -- Your basedpyright settings or an empty table if using defaults
  -- This corresponds to the settings from plugins/lang/python.lua
}
```

```lua
-- In ~/.config/nvim.new/lsp/ruff.lua
return {
  cmd_env = { RUFF_TRACE = "messages" },
  init_options = {
    settings = {
      logLevel = "error",
    },
  },
}
```

#### 2. Update Your Language-Specific Plugin Files

Modify your existing language files to remove the LSP config parts:

```lua
-- In lua/plugins/lang/python.lua
return {
  {
    "stevearc/conform.nvim",
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
    },
  },
  -- Keep non-LSP related settings here
  -- But remove or disable LSP server configurations
}
```

#### 3. Add Custom Server Setup Logic

For special server setup like you have for ruff:

```lua
-- In lua/config/lsp.lua
function M.setup()
  -- Global defaults
  vim.lsp.config("*", {
    capabilities = M.get_capabilities(),
  })
  
  -- Special server setup - equivalent to your current setup functions
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "ruff" then
        client.server_capabilities.hoverProvider = false
      end
    end,
  })
  
  -- Enable all servers
  vim.lsp.enable({ "basedpyright", "ruff", "lua_ls" })
end
```

### Alternative: Language-Grouped Approach

Instead of one file per server, you could organize by language, which matches your current structure better:

```
~/.config/nvim.new/lsp/
                   └── python.lua  (contains both basedpyright and ruff)
                   └── lua.lua     (contains lua_ls)
```

With each file containing multiple server configurations:

```lua
-- In ~/.config/nvim.new/lsp/python.lua
return {
  -- Each key is a server name
  basedpyright = {},
  ruff = {
    cmd_env = { RUFF_TRACE = "messages" },
    init_options = {
      settings = {
        logLevel = "error",
      },
    },
  },
}
```

### Advantages of This Approach

1. **Maintains Your Organization**: Keeps your language-centric organization
2. **Separates Concerns**: LSP configs are separate from other language settings
3. **Leverages Neovim 0.11 Features**: Takes advantage of the native module system
4. **Easy Migration Path**: You can migrate one language at a time

### Implementation Strategy

I recommend the language-grouped approach since it aligns better with your current organization. The steps would be:

1. Start with one language (e.g., Python)
2. Create `lsp/python.lua` with your server configurations 
3. Remove the LSP server configs from `lua/plugins/lang/python.lua`
4. Update your LSP setup to use `vim.lsp.enable()`
5. Verify it works, then repeat for other languages

## Future Enhancements

Once migrated to the native API, you'll be able to take advantage of:

- Future Neovim LSP improvements without waiting for plugin updates
- Simplified configuration with less abstraction
- Better performance with fewer dependencies
- Direct access to new LSP features as they're added to Neovim
- Modular per-server configuration in Neovim 0.11+

## References

- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [vim.lsp.config API documentation](https://neovim.io/doc/user/lsp.html#vim.lsp.config())