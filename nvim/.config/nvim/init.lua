vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Core Editor Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to upper window" })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      require("gruvbox").setup({ contrast = "hard" })
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "ibhagwan/fzf-lua",
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({})
      vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", fzf.help_tags, { desc = "Help tags" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      local filetypes = { "bash", "go", "json", "lua", "markdown", "python", "rust", "toml", "typescript", "vim", "yaml" }
      local indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

      ts.install(filetypes)

      local function enable(bufnr, lang)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        vim.treesitter.start(bufnr, lang)
        vim.api.nvim_set_option_value("indentexpr", indentexpr, { buf = bufnr })
      end

      -- Highlight/indent once the parser is available; install on demand otherwise.
      vim.api.nvim_create_autocmd("FileType", {
        desc = "Enable Tree-sitter highlighting and indentation",
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
          if not lang then
            return
          end
          if vim.treesitter.get_parser(bufnr, lang, { error = false }) then
            enable(bufnr, lang)
          else
            ts.install({ lang }):await(function()
              enable(bufnr, lang)
            end)
          end
        end,
      })
    end,
  },
})
