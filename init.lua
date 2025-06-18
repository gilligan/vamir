-- Visuals
vim.opt.number = true -- show line numbers
vim.opt.cursorline = true -- highlight the line with the cursor
vim.opt.termguicolors = true -- enable 24-bit colors

-- Editing
vim.opt.commentstring = '# %s' -- default to '#' as a comment character

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Indentation
vim.opt.expandtab = true -- use spaces, not tabs, by default
vim.opt.smartindent = true -- automatically indent and dedent
vim.opt.shiftwidth = 2 -- shift left and right by 2
vim.opt.softtabstop = 2 -- insert 2 spaces when typing <Tab>
vim.opt.tabstop = 2 -- render tabs as 2 spaces

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*.go",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*.cs,*.py,*.rs",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.tabstop = 4
  end,
})

-- Search
vim.opt.ignorecase = true -- ignore case when searching
vim.opt.smartcase = true -- stop ignoring case when uppercase is used

-- Save and load
---- reload the file when re-entering the buffer
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
  pattern = "*",
  command = "checktime",
})

-- Leader
vim.g.mapleader = " " -- set the leader key to <Space>

-- Set up lazy.nvim, the plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Initialize plugins
local plugins = {
  { "catppuccin/nvim", -- pretty colors
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin-mocha"
    end
  },

  { "tpope/vim-repeat" }, -- better repeat (`.`) semantics
  { "tpope/vim-surround" }, -- add, remove, and modify surrounding characters
  { "tpope/vim-commentary" }, -- comment and uncomment lines
  { "christoomey/vim-tmux-navigator" },
  { "folke/which-key.nvim", -- show keybinding help as you type
    event = "VeryLazy",
    dependencies = {
      "echasnovski/mini.icons",
    },
    opts = {},
  },

  { "romgrk/barbar.nvim", -- a pretty tab line
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    init = function() vim.g.barbar_auto_setup = false end,
    config = true,
  },
  { "nvim-lualine/lualine.nvim", -- a useful status bar
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = true,
  },
  { "nvim-telescope/telescope.nvim", -- fuzzy search
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim", -- override the selection UI with Telescope
    },
  },
  { "nvim-neo-tree/neo-tree.nvim", -- file browsing
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    lazy = false, -- neo-tree will lazily load itself
    opts = {
      close_if_last_window = true,
    },
  },

  { "NeogitOrg/neogit", -- Git
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
    config = true,
  },

  { "nvim-treesitter/nvim-treesitter", -- syntax highlighting
    build = ":TSUpdate",
  },
  { "neovim/nvim-lspconfig" }, -- LSP helpers
	{
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim", -- multiple LSP diagnostics per line
		config = true,
	},

}
require("lazy").setup(plugins, {
  install = {
    colorscheme = { "tokyonight-night" },
    checker = { enabled = true }, -- automatically check for plugin updates
  },
})

-- Set up fuzzy search and the fancy selection UI
require("telescope").setup {
  defaults = {
    layout_strategy = "vertical", -- better for thinner windows
    file_ignore_patterns = {
      "^%.git/", -- explicitly filter out any files in the .git directory
    },
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--hidden",
    },
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown(),
    },
  },
}
require("telescope").load_extension("ui-select")

-- Set up syntax highlighting
require("nvim-treesitter.configs").setup {
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true,
  },
}

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false

-- Configure LSP servers
local lspconfig = require("lspconfig")
---- a little hack to get the environment from direnv before running
---- to do:
----   - add a command for "allow"
----   - add a command for "deny"
----   - handle errors nicely
----   - factor into a plugin
lspconfig.util.on_setup = lspconfig.util.add_hook_before(lspconfig.util.on_setup, function(config)
  config.cmd = { "direnv", "exec", ".", unpack(config.cmd) }
end)
lspconfig.hls.setup {
  filetypes = { "haskell", "lhaskell", "cabal" }, -- configure HLS to run on Cabal files too
}
lspconfig.omnisharp.setup {
  cmd = { "OmniSharp" },
}
lspconfig.pyright.setup {}
lspconfig.rust_analyzer.setup {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        features = "all",
      },
      check = {
        command = "clippy",
      },
      procMacro = {
        enable = true,
      },
    },
  },
}
lspconfig.terraformls.setup {}
lspconfig.ts_ls.setup {}

-- Reformat code on write, if LSP is initialized.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = event.buf,
        callback = function(event)
          vim.lsp.buf.format({
            bufnr = event.buf,
            id = client.id,
            async = false,
            timeout_ms = 250,
          })
        end,
      })
    end
  end
})

-- Set up key bindings
local neoTreeCommand = require("neo-tree.command")
local telescopeBuiltin = require("telescope.builtin")
local wk = require("which-key")

---- navigate soft-wraps according to the screen, not the file
vim.keymap.set("n", "j", "gj", { noremap = true })
vim.keymap.set("n", "k", "gk", { noremap = true })

wk.add({
  -- most keybindings are behind the Leader key
  { "<leader>a", vim.lsp.buf.code_action, desc = "action" },

  { "<leader>b", group = "buffers" },
  { "<leader>bb", telescopeBuiltin.buffers, desc = "all" },
  { "<leader>bd", group = "close buffers" },
  { "<leader>bdd", "<cmd>BufferClose<cr>", desc = "this" },
  { "<leader>bdo", "<cmd>BufferCloseAllButCurrent<cr>", desc = "others" },
  { "<leader>bdh", "<cmd>BufferCloseBuffersLeft<cr>", desc = "to the left" },
  { "<leader>bdl", "<cmd>BufferCloseBuffersRight<cr>", desc = "to the right" },
  { "<leader>bn", "<cmd>BufferNext<cr>", desc = "next" },
  { "<leader>bp", "<cmd>BufferPrevious<cr>", desc = "previous" },
  { "<leader>bN", "<cmd>BufferMoveNext<cr>", desc = "move next" },
  { "<leader>bP", "<cmd>BufferMovePrevious<cr>", desc = "move previous" },

  { "<leader>d", group = "diagnostics" },
  { "<leader>dd", telescopeBuiltin.diagnostics, desc = "all" },
  { "<leader>dn", vim.diagnostic.goto_next, desc = "go to next" },
  { "<leader>dp", vim.diagnostic.goto_prev, desc = "go to previous" },
  { "[d", vim.diagnostic.goto_next, desc = "go to next" },
  { "]d", vim.diagnostic.goto_prev, desc = "go to previous" },


  { "<leader>f", group = "files" },
  { "<leader>ff", function() telescopeBuiltin.find_files({ hidden = true }) end, desc = "all" },
  { "<leader>fr", telescopeBuiltin.oldfiles, desc = "recent" },
  { "<leader>fs", "<cmd>write<cr>", desc = "save" },
  { "<leader>ft", function() neoTreeCommand.execute({ reveal = true }) end, desc = "tree" },

  { "<leader>g", function() require("neogit").open({ kind = "split" }) end, desc = "git" },

  { "<leader>j", group = "jump to" },
  { "<leader>jD", vim.lsp.buf.declaration, desc = "declaration" },
  { "<leader>jd", telescopeBuiltin.lsp_definitions, desc = "definition" },
  { "<leader>ji", telescopeBuiltin.lsp_implementations, desc = "implementation" },
  { "<leader>jr", telescopeBuiltin.lsp_references, desc = "references" },
  { "<leader>jt", telescopeBuiltin.lsp_type_definitions, desc = "type definition" },

  { "<leader>r", group = "refactor" },
  { "<leader>rf", vim.lsp.buf.format, desc = "format" },
  { "<leader>rr", vim.lsp.buf.rename, desc = "rename" },

  { "<leader>s", name = "search" },
  { "<leader>sc", "<cmd>nohlsearch<cr>", desc = "clear highlight" },
  { "<leader>sr", telescopeBuiltin.resume, desc = "resume" },
  { "<leader>ss", function() telescopeBuiltin.live_grep({ hidden = true }) end, desc = "text" },
  { "<leader>sw", telescopeBuiltin.grep_string, desc = "current word" },

  -- but not everything
  { "K", vim.lsp.buf.hover, desc = "hover" },
  { "<C-h>", "<C-w><C-h>", desc = "Move focus to the left window" },
  { "<C-l>", "<C-w><C-l>", desc = "Move focus to the right window" },
  { "<C-j>", "<C-w><C-j>", desc = "Move focus to the lower window" },
  { "<C-k>", "<C-w><C-k>", desc = "Move focus to the upper window" },
  { "<C-Left>", "<cmd>BufferPrevious<cr>", desc = "previous buffer" },
  { "<C-Right>", "<cmd>BufferNext<cr>", desc = "next buffer" },
  { "<C-S-Left>", "<cmd>BufferMovePrevious<cr>", desc = "move buffer to previous" },
  { "<C-S-Right>", "<cmd>BufferMoveNext<cr>", desc = "move buffer to next" },
})
