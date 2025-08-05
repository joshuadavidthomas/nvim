local M = {}

M.hl = {}

-- Convert CSS HSL to RGB
local function hsl_to_rgb(h, s, l)
  h, s, l = tonumber(h), tonumber(s) / 100, tonumber(l) / 100

  local function hue_to_rgb(p, q, t)
    if t < 0 then
      t = t + 1
    end
    if t > 1 then
      t = t - 1
    end
    if t < 1 / 6 then
      return p + (q - p) * 6 * t
    end
    if t < 1 / 2 then
      return q
    end
    if t < 2 / 3 then
      return p + (q - p) * (2 / 3 - t) * 6
    end
    return p
  end

  local r, g, b
  if s == 0 then
    r, g, b = l, l, l
  else
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue_to_rgb(p, q, h / 360 + 1 / 3)
    g = hue_to_rgb(p, q, h / 360)
    b = hue_to_rgb(p, q, h / 360 - 1 / 3)
  end

  return { r = math.floor(r * 255), g = math.floor(g * 255), b = math.floor(b * 255) }
end

-- Define color format specifications
local color_formats = {
  hsl = {
    -- Pattern with empty captures to mark the content inside parens
    pattern = "hsl%(()%s*%d+%s*,%s*%d+%%%s*,%s*%d+%%%s*()%)",
    -- Pattern with captures for extraction
    extract = "hsl%(%s*(%d+)%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*%)",
    -- Convert captured values to color object
    process = function(h, s, l)
      return hsl_to_rgb(h, s, l)
    end,
  },
  hsla = {
    pattern = "hsla%(()%s*%d+%s*,%s*%d+%%%s*,%s*%d+%%%s*,%s*[%d%.]+%s*()%)",
    extract = "hsla%(%s*(%d+)%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*,",
    process = function(h, s, l)
      return hsl_to_rgb(h, s, l)
    end,
  },
  rgb = {
    pattern = "rgb%(()%s*%d+%s*,%s*%d+%s*,%s*%d+%s*()%)",
    extract = "rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)",
    process = function(r, g, b)
      return { r = tonumber(r), g = tonumber(g), b = tonumber(b) }
    end,
  },
  rgba = {
    pattern = "rgba%(()%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*[%d%.]+%s*()%)",
    extract = "rgba%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,",
    process = function(r, g, b)
      return { r = tonumber(r), g = tonumber(g), b = tonumber(b) }
    end,
  },
  okhsl = {
    pattern = "okhsl%(()%s*%d+%s+%d+%%%s+%d+%%%s*()%)",
    extract = "okhsl%(%s*(%d+)%s+(%d+)%%%s+(%d+)%%%s*%)",
    process = function(h, s, l)
      return { h = tonumber(h), s = tonumber(s), l = tonumber(l) }
    end,
  },
  oklch = {
    pattern = "oklch%(()%s*[%d%.]+%s+[%d%.]+%s+[%d%.]+%s*/?%s*[%d%.]*%%?%s*()%)",
    extract = "oklch%(%s*([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)",
    process = function(l, c, h)
      -- mini.colors expects l in [0,100] range
      return { l = tonumber(l) * 100, c = tonumber(c), h = tonumber(h) }
    end,
  },
}

-- Create highlighter from format specification
local function create_highlighter(format, opts)
  return {
    pattern = function()
      if not vim.tbl_contains(opts.css.ft, vim.bo.filetype) then
        return
      end
      return format.pattern
    end,
    group = function(_, _, data)
      local match = data.full_match
      local captures = { match:match(format.extract) }
      if not captures[1] then
        return
      end

      local color = format.process(unpack(captures))
      if not color then
        return
      end

      local hex = require("mini.colors").convert(color, "hex")
      if type(hex) == "string" then
        return MiniHipatterns.compute_hex_color_group(hex, "bg")
      end
    end,
    extmark_opts = { priority = 2000 },
  }
end

-- Highlight patterns in text.
return {
  "echasnovski/mini.hipatterns",
  event = "LazyFile",
  dependencies = {
    "echasnovski/mini.colors",
  },
  opts = function()
    local hi = require("mini.hipatterns")
    return {
      css = {
        ft = {
          "css",
          "scss",
          "sass",
          "less",
          "stylus",
          "html",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
          "svelte",
          "astro",
        },
      },
      tailwind = {
        ft = {
          "astro",
          "blade",
          "css",
          "heex",
          "html",
          "html-eex",
          "htmldjango",
          "javascript",
          "javascriptreact",
          "rust",
          "svelte",
          "typescript",
          "typescriptreact",
          "vue",
        },
        -- full: the whole css class will be highlighted
        -- compact: only the color will be highlighted
        style = "full",
      },
      highlighters = {
        hex_color = hi.gen_highlighter.hex_color({ priority = 2000 }),
        shorthand = {
          pattern = "()#%x%x%x()%f[^%x%w]",
          group = function(_, _, data)
            ---@type string
            local match = data.full_match
            local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
            local hex_color = "#" .. r .. r .. g .. g .. b .. b

            return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
          end,
          extmark_opts = { priority = 2000 },
        },
      },
    }
  end,
  config = function(_, opts)
    if type(opts.tailwind) == "table" then
      -- reset hl groups when colorscheme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          M.hl = {}
        end,
      })
      opts.highlighters.tailwind = {
        pattern = function()
          if not vim.tbl_contains(opts.tailwind.ft, vim.bo.filetype) then
            return
          end
          if opts.tailwind.style == "full" then
            return "%f[%w:-]()[%w:-]+%-[a-z%-]+%-%d+()%f[^%w:-]"
          elseif opts.tailwind.style == "compact" then
            return "%f[%w:-][%w:-]+%-()[a-z%-]+%-%d+()%f[^%w:-]"
          end
        end,
        group = function(_, _, m)
          local tw = require("lang.tailwind")
          ---@type string
          local match = m.full_match
          ---@type string, number
          local color, shade = match:match("[%w-]+%-([a-z%-]+)%-(%d+)")
          shade = tonumber(shade)
          local bg = vim.tbl_get(tw.colors, color, shade)
          if bg then
            local hl = "MiniHipatternsTailwind" .. color .. shade
            if not M.hl[hl] then
              M.hl[hl] = true
              local bg_shade = shade == 500 and 950 or shade < 500 and 900 or 100
              local fg = vim.tbl_get(tw.colors, color, bg_shade)
              vim.api.nvim_set_hl(0, hl, { bg = "#" .. bg, fg = "#" .. fg })
            end
            return hl
          end
        end,
        extmark_opts = { priority = 2000 },
      }
    end

    -- Add CSS color highlighters if css config is present
    if type(opts.css) == "table" then
      for name, format in pairs(color_formats) do
        opts.highlighters[name] = create_highlighter(format, opts)
      end
    end

    require("mini.hipatterns").setup(opts)
  end,
}
