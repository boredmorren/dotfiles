call plug#begin()
Plug 'https://github.com/yorumicolors/yorumi.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': 'v0.2.0' }
Plug 'https://github.com/nvim-telescope/telescope-fzf-native.nvim', {'do': 'make'}
Plug 'https://github.com/nvim-telescope/telescope-live-grep-args.nvim'
Plug 'mason-org/mason.nvim'
Plug 'mason-org/mason-lspconfig.nvim'
Plug 'hrsh7th/nvim-cmp'          
Plug 'hrsh7th/cmp-nvim-lsp'     
Plug 'hrsh7th/cmp-buffer'      
Plug 'hrsh7th/cmp-path'       
Plug 'onsails/lspkind.nvim'      
Plug 'kdheepak/lazygit.nvim'
Plug 'nvim-tree/nvim-tree.lua'
call plug#end()

set number
set autoindent
set smarttab
set tabstop=4
set shiftwidth=4
set clipboard=unnamedplus
set mouse=a


syntax on
colorscheme yorumi


"Bindings
nnoremap .ff <cmd>Telescope find_files<cr>
nnoremap .fg <cmd>Telescope live_grep<cr>
nnoremap .gg :LazyGit<cr>

" Основная кодировка для Neovim
set encoding=utf-8

" Кодировка по умолчанию для новых файлов
set fileencoding=utf-8

" Автоматическое определение кодировки при открытии файлов
set fileencodings=utf-8,cp1251,koi8-r,cp866,iso-8859-1

lua <<EOF
-- Глобальная горячая клавиша для открытия/закрытия
vim.keymap.set('n', '.e', ':NvimTreeToggle<CR>', { silent = true })
EOF

lua <<EOF
-- Применяем настройку
vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    spacing = 4,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
EOF

lua <<EOF
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- empty setup using defaults
require("nvim-tree").setup()

-- OR setup with some options
require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})
EOF

lua <<EOF
local cmp = require('cmp')
-- Упрощенная конфигурация БЕЗ LuaSnip
cmp.setup({
  -- Убираем секцию snippet полностью
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },      -- Подсказки от gopls
    { name = 'buffer' },        -- Слова из текущего файла
    { name = 'path' },          -- Пути к файлам
  }),
  -- Упрощенное форматирование
  formatting = {
    format = function(entry, vim_item)
      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        buffer = "[Буфер]",
        path = "[Путь]",
      })[entry.source.name]
      return vim_item
    end
  }
})
EOF

lua <<EOF
-- Получаем возможности для автодополнения
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Функция on_attach с keymaps
local function on_attach(client, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'rn', vim.lsp.buf.rename, opts)
  
  print("gopls attached to buffer " .. bufnr)
end

-- Автоматически запускаем gopls для Go файлов
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function(args)
    -- Находим корень проекта (по go.mod или .git)
    local root_dir = vim.fs.dirname(vim.fs.find(
      { 'go.mod', '.git' },
      { upward = true }
    )[1] or vim.fn.getcwd())
    
    -- ЗАПУСКАЕМ gopls через НОВЫЙ API
    vim.lsp.start({
      name = 'gopls',                    -- Имя сервера
      cmd = { 'gopls' },                 -- Команда для запуска
      root_dir = root_dir,               -- Корень проекта
      capabilities = capabilities,       -- Возможности автодополнения
      on_attach = on_attach,             -- Наши keymaps
      settings = {                       -- Настройки gopls
        gopls = {
          analyses = {
            unusedparams = true,
            unusedwrite = true,
          },
          staticcheck = true,
          gofumpt = true,
          completeUnimported = true,
        }
      }
    })
  end
})

-- Автоформатирование при сохранении
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.go',
  callback = function()
    vim.lsp.buf.format({ async = false })
  end
})
EOF
