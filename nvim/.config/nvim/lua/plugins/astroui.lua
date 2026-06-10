-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "astrodark",
    highlights = {
      -- Transparent background for all colorschemes. Function form + get_hlgroup
      -- keeps each group's other attributes (AstroUI replaces groups wholesale,
      -- so a bare `{ bg = "NONE" }` would wipe foregrounds).
      init = function()
        local get_hlgroup = require("astroui").get_hlgroup
        local function clear_bg(name)
          local hl = get_hlgroup(name)
          hl.bg, hl.ctermbg = "NONE", "NONE"
          return hl
        end
        return {
          Normal = clear_bg "Normal",
          NormalNC = clear_bg "NormalNC",
          NormalFloat = clear_bg "NormalFloat",
          FloatBorder = clear_bg "FloatBorder",
          NeoTreeNormal = clear_bg "NeoTreeNormal",
          NeoTreeNormalNC = clear_bg "NeoTreeNormalNC",
        }
      end,
    },
    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}
