#!/bin/bash
# 一键安装配置 lazy.nvim 及主流插件（智能版本检测版）
set -e

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[36m'
NC='\033[0m'

# 检查依赖
check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}错误：请先安装 $1${NC}" >&2
    exit 1
  fi
}
check_dependency git
check_dependency tar
check_dependency curl
check_dependency jq

# 配置目录
NVIM_DIR="$HOME/.config/nvim"
PLUGINS_DIR="$NVIM_DIR/lua/plugins"
OPTIONS_DIR="$NVIM_DIR/lua/config"

# 智能版本检测
get_latest_version() {
  local api_url="https://api.github.com/repos/neovim/neovim/releases"
  local cache_file="/tmp/neovim_releases.json"
  local fallback_version="v0.10.4"

  # 带缓存的API请求
  if [ ! -f "$cache_file" ] || find "$cache_file" -mmin +60 | grep -q .; then
    if ! curl -sSH "Accept: application/vnd.github+json" "$api_url" -o "$cache_file"; then
      echo -e "${YELLOW}警告：无法获取最新版本，使用备用版本 $fallback_version${NC}" >&2
      echo "$fallback_version"
      return 1
    fi
  fi

  # 过滤并排序版本
  local versions=$(jq -r '.[] | select(.prerelease == false) | .tag_name' "$cache_file" 2>/dev/null)
  if [ -z "$versions" ]; then
    echo -e "${YELLOW}解析版本失败，使用备用版本 $fallback_version${NC}" >&2
    echo "$fallback_version"
    return 1
  fi

  echo "$versions" | sort -Vr | head -n1
}

# 改进的安装函数
install_neovim() {
  local LATEST_VERSION=$(get_latest_version || echo "v0.10.4")
  local CURRENT_VERSION=""
  local ARCH=""

  # 获取当前版本
  if command -v nvim &>/dev/null; then
    CURRENT_VERSION=$(nvim --version | awk 'NR==1{print $2}' | sed 's/^v//')
    CURRENT_VERSION="v${CURRENT_VERSION}"
  fi

  # 版本比较
  if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GREEN}Neovim 已经是最新版 ($LATEST_VERSION)，无需更新${NC}"
    return
  fi

  # 架构检测
  case $(uname -m) in
    x86_64) ARCH="linux64" ;;
    aarch64) ARCH="linux-arm64" ;;
    *) ARCH="linux-x86_64" ;;
  esac

  local URL="https://github.com/neovim/neovim/releases/download/$LATEST_VERSION/nvim-$ARCH.tar.gz"
  local TAR_FILE="$HOME/nvim.tar.gz"
  local INSTALL_PREFIX="$HOME/.local"

  echo -e "${BLUE}检测到新版本 ${LATEST_VERSION}（当前：${CURRENT_VERSION:-未安装}）${NC}"
  
  # 下载处理
  echo -e "${BLUE}正在下载 Neovim...${NC}"
  if ! curl -L "$URL" -o "$TAR_FILE"; then
    echo -e "${YELLOW}下载失败，尝试备用版本...${NC}"
    URL="https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz"
    curl -L "$URL" -o "$TAR_FILE" || {
      echo -e "${RED}严重错误：无法下载 Neovim${NC}" >&2
      exit 1
    }
  fi

  # 安装流程
  echo -e "${BLUE}正在安装到 $INSTALL_PREFIX...${NC}"
  mkdir -p "$INSTALL_PREFIX"
  tar -xzf "$TAR_FILE" -C "$INSTALL_PREFIX" --strip-components=1

  # 更新PATH
  if ! grep -q ".local/bin" "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  source "$HOME/.bashrc" >/dev/null 2>&1

  rm -f "$TAR_FILE"
  echo -e "${GREEN}Neovim 已成功更新到 $LATEST_VERSION${NC}"
}

# 检查系统环境 (P0改进)
check_system_environment() {
  echo -e "${BLUE}检查系统环境...${NC}"
  
  # 检查可用内存
  local available_mem=$(free -m | awk '/^Mem:/{print $7}')
  if [ "$available_mem" -lt 500 ]; then
    echo -e "${YELLOW}警告: 可用内存较低 (${available_mem}MB)，可能影响Neovim性能${NC}"
  fi
  
  # 检查磁盘空间
  local available_space=$(df -m "$HOME" | awk 'NR==2 {print $4}')
  if [ "$available_space" -lt 1000 ]; then
    echo -e "${YELLOW}警告: 磁盘空间不足 (${available_space}MB)，安装全部插件可能会遇到问题${NC}"
  fi
  
  # 检查Node.js (很多LSP依赖它)
  if ! command -v node &>/dev/null; then
    echo -e "${YELLOW}警告: 未检测到Node.js，某些LSP功能可能不可用${NC}"
  else
    local node_version=$(node --version)
    echo -e "${GREEN}检测到Node.js: $node_version${NC}"
  fi
  
  echo -e "${GREEN}系统环境检查完成${NC}"
}

# 备份配置
backup_config() {
  if [ -d "$NVIM_DIR" ]; then
    local timestamp=$(date +%s)
    local backup_dir="$NVIM_DIR.bak.$timestamp"
    while [ -d "$backup_dir" ]; do
      sleep 1
      timestamp=$(date +%s)
      backup_dir="$NVIM_DIR.bak.$timestamp"
    done
    mv "$NVIM_DIR" "$backup_dir"
    echo -e "${YELLOW}原有配置已备份至: $backup_dir${NC}"
  fi
}

# 生成配置
generate_plugin_config() {
  mkdir -p "$PLUGINS_DIR"
  mkdir -p "$OPTIONS_DIR"

  # 核心配置
  cat > "$NVIM_DIR/init.lua" << 'EOF'
-- init.lua - Neovim 主配置文件
-- 由安装脚本自动生成

-- 基础设置
vim.g.mapleader = " "  -- 设置空格键为Leader键
vim.g.maplocalleader = ","  -- 设置本地Leader键

-- 加载基础选项
require("config.options")
require("config.keymaps")

-- 初始化插件管理器(lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 加载插件
require("lazy").setup("plugins", {
  install = { colorscheme = { "tokyonight" } },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "zipPlugin", "netrwPlugin",
        "matchit", "matchparen"
      }
    }
  }
})
EOF

  # 基础选项配置
  cat > "$OPTIONS_DIR/options.lua" << 'EOF'
-- options.lua - Neovim 基础选项配置

local opt = vim.opt

-- UI配置
opt.number = true           -- 显示行号
opt.relativenumber = true   -- 显示相对行号
opt.termguicolors = true    -- 启用真彩色支持
opt.showmode = false        -- 不显示模式 (使用状态栏替代)
opt.signcolumn = "yes"      -- 总是显示标志列
opt.laststatus = 3          -- 全局状态栏
opt.cmdheight = 1           -- 命令栏高度
opt.scrolloff = 10          -- 光标距离顶部/底部的行数
opt.conceallevel = 0        -- 不隐藏标记

-- 编辑体验
opt.expandtab = true        -- 用空格代替制表符
opt.shiftwidth = 2          -- 缩进宽度
opt.tabstop = 2             -- 制表符宽度
opt.softtabstop = 2         -- 软制表符宽度
opt.smartindent = true      -- 智能缩进
opt.wrap = false            -- 不自动换行
opt.cursorline = true       -- 高亮当前行
opt.ignorecase = true       -- 搜索时忽略大小写
opt.smartcase = true        -- 搜索中有大写字母时不忽略大小写

-- 编辑行为
opt.undofile = true         -- 持久撤销
opt.swapfile = false        -- 不创建交换文件
opt.backup = false          -- 不创建备份文件
opt.hlsearch = true         -- 高亮搜索结果
opt.incsearch = true        -- 增量搜索
opt.clipboard = "unnamedplus" -- 使用系统剪贴板
opt.virtualedit = "block"   -- 允许在可视块模式中超出行尾
opt.mouse = "a"             -- 启用鼠标支持

-- 分割窗口
opt.splitbelow = true       -- 水平分割在下方
opt.splitright = true       -- 垂直分割在右侧

-- 性能优化
opt.updatetime = 300        -- 更新间隔
opt.timeoutlen = 500        -- 等待映射序列完成的时间
opt.completeopt = "menuone,noselect" -- 补全选项

-- 文件类型检测
vim.cmd [[filetype plugin indent on]]
EOF

  # 基础快捷键配置
  cat > "$OPTIONS_DIR/keymaps.lua" << 'EOF'
-- keymaps.lua - Neovim 基础快捷键配置

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader键已在init.lua中设置为空格

-- 窗口导航
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- 调整窗口大小
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- 更好的缩进
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- 移动文本块
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- 保存与退出
keymap("n", "<leader>w", ":w<CR>", { desc = "保存文件" })
keymap("n", "<leader>q", ":q<CR>", { desc = "退出" })
keymap("n", "<leader>Q", ":qa!<CR>", { desc = "强制退出所有" })

-- 更好的粘贴
keymap("v", "p", '"_dP', opts)

-- 清除搜索高亮
keymap("n", "<leader>h", ":nohlsearch<CR>", { desc = "清除搜索高亮" })

-- 快速命令
keymap("n", "<leader>;", ":", { desc = "命令模式" })

-- 缓冲区导航
keymap("n", "<S-l>", ":bnext<CR>", { desc = "下一个缓冲区" })
keymap("n", "<S-h>", ":bprevious<CR>", { desc = "上一个缓冲区" })
keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "删除当前缓冲区" })
keymap("n", "<leader>ba", ":ball<CR>", { desc = "显示所有缓冲区" })

-- 快速跳转
keymap("n", "<C-d>", "<C-d>zz", { desc = "向下滚动并居中" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "向上滚动并居中" })
keymap("n", "n", "nzzzv", { desc = "下一个搜索结果并居中" })
keymap("n", "N", "Nzzzv", { desc = "上一个搜索结果并居中" })

-- 禁用方向键（强制使用hjkl）
keymap({ "n", "i", "v" }, "<Up>", "<Nop>", opts)
keymap({ "n", "i", "v" }, "<Down>", "<Nop>", opts)
keymap({ "n", "i", "v" }, "<Left>", "<Nop>", opts)
keymap({ "n", "i", "v" }, "<Right>", "<Nop>", opts)
EOF

  # 主题插件配置
  cat > "$PLUGINS_DIR/01-colorscheme.lua" << 'EOF'
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- 确保最先加载
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "dark",
          floats = "dark",
        },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  
  -- 添加avante.nvim语法高亮引擎
  {
    "yetone/avante.nvim",
    event = { "BufReadPre", "BufNewFile" },
    priority = 1001, -- 优先级比主题略高
    config = function()
      require("avante").setup({
        -- 使用默认配置
        -- 保持开启大多数语言的支持
      })
      
      -- 如果需要手动启用/禁用语言，可以使用如下配置
      -- local avante = require("avante")
      -- avante.setup({
      --   client_kind = "llama", -- 可选: llama, tiny, full
      --   enable_all = false, -- 是否默认启用所有语言
      --   enable = {
      --     "lua",
      --     "python",
      --     "javascript",
      --     "typescript",
      --     "html",
      --     "css",
      --     "json",
      --   },
      --   disable = {
      --     -- "c",
      --     -- "rust",
      --   },
      -- })
    end,
  },
}
EOF

  # UI增强插件配置
  cat > "$PLUGINS_DIR/02-ui.lua" << 'EOF'
return {
  -- 漂亮的通知窗口
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        lsp = {
          -- 覆盖markdown渲染，使用Treesitter
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        presets = {
          bottom_search = true, -- 使用底部搜索命令行
          command_palette = true, -- 使用命令面板
          long_message_to_split = true, -- 长消息发送到分割窗口
          inc_rename = false, -- 增量重命名UI
          lsp_doc_border = false, -- 在LSP悬停窗口中添加边框
        },
      })
    end,
  },
  
  -- 美化通知
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      local notify = require("notify")
      notify.setup({
        background_colour = "#000000",
        top_down = true,
        render = "default",
        stages = "fade",
        timeout = 3000,
      })
      vim.notify = notify
    end,
  },
  
  -- 图标支持
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true
  },
  
  -- 顶部标签页
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          separator_style = "slant",
          always_show_bufferline = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          color_icons = true,
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(_, _, diag)
            local icons = {
              Error = " ",
              Warn = " ",
              Hint = " ",
              Info = " ",
            }
            local ret = {}
            for severity, icon in pairs(icons) do
              local n = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity[string.upper(severity)] })
              if n > 0 then
                table.insert(ret, icon .. n)
              end
            end
            return table.concat(ret, " ")
          end,
        },
      })
    end,
  },
  
  -- 底部状态栏
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = "tokyonight",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
          always_divide_middle = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { { "branch", icon = "" }, "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {}
        },
      })
    end,
  },
  
  -- 启动界面
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        [[  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗  ]],
        [[  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║  ]],
        [[  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║  ]],
        [[  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║  ]],
        [[  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║  ]],
        [[  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝  ]],
      }
      
      dashboard.section.buttons.val = {
        dashboard.button("f", "  查找文件", ":Telescope find_files <CR>"),
        dashboard.button("e", "  新建文件", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", "  最近文件", ":Telescope oldfiles <CR>"),
        dashboard.button("t", "  查找文本", ":Telescope live_grep <CR>"),
        dashboard.button("c", "  配置", ":e $MYVIMRC <CR>"),
        dashboard.button("q", "  退出", ":qa<CR>"),
      }
      
      dashboard.section.footer.val = "https://github.com/neovim/neovim"
      
      dashboard.section.footer.opts.hl = "Type"
      dashboard.section.header.opts.hl = "Include"
      dashboard.section.buttons.opts.hl = "Keyword"
      
      dashboard.opts.opts.noautocmd = true
      require("alpha").setup(dashboard.opts)
    end,
  },
  
  -- 缩进指示线
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = {
          char = "▏",
        },
        scope = { enabled = true },
      })
    end,
  },
  
  -- 光标下单词高亮
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        providers = { "lsp", "treesitter", "regex" },
        delay = 100,
        filetypes_denylist = {
          "alpha", "NvimTree", "TelescopePrompt",
        },
        min_count_to_highlight = 2,
      })
    end,
  },
}
EOF

  # 编辑体验增强插件配置
  cat > "$PLUGINS_DIR/03-editing.lua" << 'EOF'
return {
  -- 自动配对括号等
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true, -- 使用Treesitter检查
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
        },
        disable_filetype = { "TelescopePrompt", "vim" },
      })
      
      -- 将自动配对与cmp集成
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({}))
    end,
  },
  
  -- 更好的注释
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("Comment").setup({
        padding = true, -- 在注释分隔符后添加空格
        sticky = true, -- 注释光标行
        toggler = {
          line = "gcc", -- 切换行注释
          block = "gbc", -- 切换块注释
        },
        opleader = {
          line = "gc", -- 行注释操作符
          block = "gb", -- 块注释操作符
        },
        extra = {
          above = "gcO", -- 在上方添加注释行
          below = "gco", -- 在下方添加注释行
          eol = "gcA", -- 在行尾添加注释
        },
        mappings = {
          basic = true, -- 基本映射
          extra = true, -- 额外映射
          extended = false, -- 扩展映射
        },
      })
    end,
  },
  
  -- 快速环绕
  {
    "kylechui/nvim-surround",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-surround").setup({
        -- 默认配置足够好
      })
    end,
  },
  
  -- 突出显示和删除尾随空格
  {
    "ntpeters/vim-better-whitespace",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.g.better_whitespace_enabled = 1
      vim.g.strip_whitespace_on_save = 1
      vim.g.strip_whitespace_confirm = 0
      vim.g.better_whitespace_filetypes_blacklist = {
        "diff", "git", "gitcommit", "unite", "qf", "help", "fugitive",
      }
    end,
  },
  
  -- Treesitter支持
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "windwp/nvim-ts-autotag", -- 自动关闭HTML/JSX标签
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "bash", "markdown", "markdown_inline", "regex", "c", "python", "javascript", "typescript", "json", "html", "css" },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        -- 增强选择
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<CR>",
            node_incremental = "<CR>",
            scope_incremental = "<S-CR>",
            node_decremental = "<BS>",
          },
        },
        -- 文本对象
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["ai"] = "@conditional.outer",
              ["ii"] = "@conditional.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
            },
          },
          -- 移动到下一个/上一个文本对象
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.outer",
              ["]i"] = "@conditional.outer",
              ["]l"] = "@loop.outer",
              ["]b"] = "@block.outer",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
              ["]A"] = "@parameter.outer",
              ["]I"] = "@conditional.outer",
              ["]L"] = "@loop.outer",
              ["]B"] = "@block.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.outer",
              ["[i"] = "@conditional.outer",
              ["[l"] = "@loop.outer",
              ["[b"] = "@block.outer",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
              ["[A"] = "@parameter.outer",
              ["[I"] = "@conditional.outer",
              ["[L"] = "@loop.outer",
              ["[B"] = "@block.outer",
            },
          },
        },
        autotag = { enable = true },
      })
    end,
  },
}
EOF

  # 代码补全和LSP插件配置
  cat > "$PLUGINS_DIR/04-completion-lsp.lua" << 'EOF'
return {
  -- LSP配置
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- 自动安装LSP服务器
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      -- LSP UI增强
      "folke/neodev.nvim",
      "folke/trouble.nvim",
      "hrsh7th/cmp-nvim-lsp", -- LSP源
    },
    config = function()
      -- 设置LSP诊断图标和样式
      local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
      
      -- 诊断配置
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })
      
      -- LSP浮动窗口设置
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, { border = "rounded" }
      )
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, { border = "rounded" }
      )
      
      -- 配置Lua开发
      require("neodev").setup()
      
      -- LSP服务器设置
      local mason = require("mason")
      local mason_lspconfig = require("mason-lspconfig")
      
      -- Mason设置
      mason.setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
      
      -- LSP服务器自动安装
      mason_lspconfig.setup({
        ensure_installed = {
          "lua_ls", "pyright", "tsserver", "html", "cssls", "jsonls", "bashls"
        },
        automatic_installation = true,
      })
      
      -- Capabilities设置
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      
      -- LSP键位绑定
      local on_attach = function(client, bufnr)
        local keymap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = bufnr, desc = desc })
        end
        
        -- LSP导航
        keymap("n", "gD", vim.lsp.buf.declaration, "转到声明")
        keymap("n", "gd", vim.lsp.buf.definition, "转到定义")
        keymap("n", "K", vim.lsp.buf.hover, "显示文档")
        keymap("n", "gi", vim.lsp.buf.implementation, "转到实现")
        keymap("n", "gr", vim.lsp.buf.references, "查找引用")
        keymap("n", "<C-k>", vim.lsp.buf.signature_help, "显示签名帮助")
        
        -- 工作区
        keymap("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "添加工作区文件夹")
        keymap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "移除工作区文件夹")
        keymap("n", "<leader>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, "列出工作区文件夹")
        
        -- 重构
        keymap("n", "<leader>rn", vim.lsp.buf.rename, "重命名")
        keymap("n", "<leader>ca", vim.lsp.buf.code_action, "代码操作")
        
        -- 格式化
        if client.supports_method("textDocument/formatting") then
          keymap("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "格式化文档")
        end
        
        -- 诊断导航
        keymap("n", "[d", vim.diagnostic.goto_prev, "上一个诊断")
        keymap("n", "]d", vim.diagnostic.goto_next, "下一个诊断")
        keymap("n", "<leader>d", vim.diagnostic.open_float, "显示诊断")
        keymap("n", "<leader>q", vim.diagnostic.setloclist, "添加诊断到位置列表")
        
        -- 代码折叠
        if client.server_capabilities.documentSymbolProvider then
          require("nvim-navic").attach(client, bufnr)
        end
      end
      
      -- 配置所有安装的服务器
      mason_lspconfig.setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
        
        -- 特定服务器配置覆盖
        ["lua_ls"] = function()
          require("lspconfig").lua_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim" },
                },
                workspace = {
                  library = vim.api.nvim_get_runtime_file("", true),
                  checkThirdParty = false,
                },
                telemetry = { enable = false },
              },
            },
          })
        end,
      })
      
      -- 配置Trouble
      require("trouble").setup({
        position = "bottom",
        icons = true,
        mode = "workspace_diagnostics",
        fold_open = "",
        fold_closed = "",
        group = true,
        padding = true,
        action_keys = {
          close = "q",
          cancel = "<esc>",
          refresh = "r",
          jump = { "<cr>", "<tab>" },
          open_split = { "<c-x>" },
          open_vsplit = { "<c-v>" },
          open_tab = { "<c-t>" },
          toggle_mode = "m",
          toggle_preview = "P",
          hover = "K",
          preview = "p",
          close_folds = { "zM", "zm" },
          open_folds = { "zR", "zr" },
          toggle_fold = { "zA", "za" },
          previous = "k",
          next = "j"
        },
      })
      
      -- 键盘映射
      vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", { desc = "切换诊断列表" })
      vim.keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { desc = "切换工作区诊断" })
      vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", { desc = "切换文档诊断" })
      vim.keymap.set("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", { desc = "切换位置列表" })
      vim.keymap.set("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", { desc = "切换快速修复" })
    end,
  },
  
  -- 自动完成
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSP源
      "hrsh7th/cmp-buffer", -- 缓冲区源
      "hrsh7th/cmp-path", -- 路径源
      "hrsh7th/cmp-cmdline", -- 命令行源
      "saadparwaiz1/cmp_luasnip", -- LuaSnip源
      "L3MON4D3/LuaSnip", -- 代码片段引擎
      "rafamadriz/friendly-snippets", -- 代码片段集合
      "onsails/lspkind.nvim", -- 漂亮的图标
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      
      -- 加载代码片段
      require("luasnip.loaders.from_vscode").lazy_load()
      
      -- 代码片段设置
      luasnip.config.setup({
        history = true,
        updateevents = "TextChanged,TextChangedI",
      })
      
      -- 向前/向后导航片段
      vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { silent = true, desc = "下一个片段位置" })
      
      vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        end
      end, { silent = true, desc = "上一个片段位置" })
      
      -- 设置自动完成
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            menu = {
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            },
          }),
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        experimental = {
          ghost_text = { hl_group = "Comment" },
        },
      })
      
      -- 命令行自动完成
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
        }),
      })
      
      -- 搜索自动完成
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },
}
EOF

  # 文件导航和搜索插件配置
  cat > "$PLUGINS_DIR/05-navigation.lua" << 'EOF'
return {
  -- 文件树导航
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "文件浏览器" },
      { "<leader>o", "<cmd>NvimTreeFocus<CR>", desc = "聚焦文件浏览器" },
    },
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
          signcolumn = "yes",
        },
        renderer = {
          group_empty = true,
          icons = {
            glyphs = {
              default = "",
              symlink = "",
              bookmark = "󰆤",
              modified = "●",
              folder = {
                arrow_closed = "",
                arrow_open = "",
                default = "",
                open = "",
                empty = "",
                empty_open = "",
                symlink = "",
                symlink_open = "",
              },
              git = {
                unstaged = "✗",
                staged = "✓",
                unmerged = "",
                renamed = "➜",
                untracked = "★",
                deleted = "",
                ignored = "◌",
              },
            },
          },
        },
        filters = {
          dotfiles = false,
        },
        git = {
          enable = true,
          ignore = false,
        },
        actions = {
          open_file = {
            quit_on_open = false,
            window_picker = {
              enable = true,
              picker = "default",
              chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
              exclude = {
                filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
                buftype = { "nofile", "terminal", "help" },
              },
            },
          },
        },
      })
    end,
  },
  
  -- 模糊查找
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { 
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "查找文件" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "全局搜索" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "查找缓冲区" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "帮助标签" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "最近文件" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "命令" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "键位映射" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "文档符号" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "诊断" },
      { "<leader>fw", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "工作区符号" },
      { "<leader>fi", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "当前缓冲区搜索" },
      { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "项目" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      
      telescope.setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "smart" },
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-c>"] = actions.close,
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
              ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
            
            n = {
              ["<esc>"] = actions.close,
              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,
              ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["j"] = actions.move_selection_next,
              ["k"] = actions.move_selection_previous,
              ["H"] = actions.move_to_top,
              ["M"] = actions.move_to_middle,
              ["L"] = actions.move_to_bottom,
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
              ["gg"] = actions.move_to_top,
              ["G"] = actions.move_to_bottom,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
              ["?"] = actions.which_key,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = false,
            follow = true,
          },
          live_grep = {
            additional_args = function()
              return { "--hidden" }
            end,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      
      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
  },
  
  -- 导航标记
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local which_key = require("which-key")
      
      which_key.setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = {
            enabled = false,
            suggestions = 20,
          },
          presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
          },
        },
        operators = { gc = "Comments" },
        key_labels = {},
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },
        popup_mappings = {
          scroll_down = "<c-d>",
          scroll_up = "<c-u>",
        },
        window = {
          border = "single",
          position = "bottom",
          margin = { 1, 0, 1, 0 },
          padding = { 1, 2, 1, 2 },
          winblend = 0,
        },
        layout = {
          height = { min = 4, max = 25 },
          width = { min = 20, max = 50 },
          spacing = 3,
          align = "left",
        },
        ignore_missing = false,
        hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua " },
        show_help = true,
        show_keys = true,
        triggers = "auto",
        triggers_blacklist = {
          i = { "j", "k" },
          v = { "j", "k" },
        },
      })
      
      which_key.register({
        ["<leader>"] = {
          f = { name = "搜索/查找" },
          b = { name = "缓冲区" },
          w = { name = "工作区" },
          c = { name = "代码" },
          d = { name = "诊断/调试" },
          g = { name = "Git" },
          r = { name = "重构/重命名" },
          s = { name = "分割/会话" },
          t = { name = "终端/测试" },
          x = { name = "问题/诊断" },
        },
      })
    end,
  },
  
  -- 像VSCode一样的导航面包屑
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("nvim-navic").setup({
        icons = {
          File = " ",
          Module = " ",
          Namespace = " ",
          Package = " ",
          Class = " ",
          Method = " ",
          Property = " ",
          Field = " ",
          Constructor = " ",
          Enum = " ",
          Interface = " ",
          Function = " ",
          Variable = " ",
          Constant = " ",
          String = " ",
          Number = " ",
          Boolean = " ",
          Array = " ",
          Object = " ",
          Key = " ",
          Null = " ",
          EnumMember = " ",
          Struct = " ",
          Event = " ",
          Operator = " ",
          TypeParameter = " ",
        },
        highlight = true,
        separator = " > ",
        depth_limit = 0,
        depth_limit_indicator = "..",
      })
    end,
  },
}
EOF

  # Git集成插件配置
  cat > "$PLUGINS_DIR/06-git.lua" << 'EOF'
return {
  -- Git变更标识
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "契" },
          topdelete = { text = "契" },
          changedelete = { text = "▎" },
          untracked = { text = "▎" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          interval = 1000,
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 1000,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
        preview_config = {
          border = "single",
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
        yadm = {
          enable = false,
        },
        
        -- 键位映射
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          
          -- 导航
          map("n", "]c", function()
            if vim.wo.diff then return "]c" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "下一个变更" })
          
          map("n", "[c", function()
            if vim.wo.diff then return "[c" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "上一个变更" })
          
          -- 操作
          map("n", "<leader>gs", gs.stage_hunk, { desc = "暂存变更" })
          map("n", "<leader>gr", gs.reset_hunk, { desc = "重置变更" })
          map("v", "<leader>gs", function() gs.stage_hunk { vim.fn.line("."), vim.fn.line("v") } end, { desc = "暂存选中的变更" })
          map("v", "<leader>gr", function() gs.reset_hunk { vim.fn.line("."), vim.fn.line("v") } end, { desc = "重置选中的变更" })
          map("n", "<leader>gS", gs.stage_buffer, { desc = "暂存整个缓冲区" })
          map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "撤销暂存变更" })
          map("n", "<leader>gR", gs.reset_buffer, { desc = "重置整个缓冲区" })
          map("n", "<leader>gp", gs.preview_hunk, { desc = "预览变更" })
          map("n", "<leader>gb", function() gs.blame_line { full = true } end, { desc = "显示变更责任人" })
          map("n", "<leader>gtb", gs.toggle_current_line_blame, { desc = "切换行责任人显示" })
          map("n", "<leader>gd", gs.diffthis, { desc = "与索引中的状态比较" })
          map("n", "<leader>gD", function() gs.diffthis("~") end, { desc = "与上一个提交比较" })
          map("n", "<leader>gtd", gs.toggle_deleted, { desc = "切换已删除行显示" })
          
          -- 文本对象
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "选择变更块" })
        end,
      })
    end,
  },
  
  -- Git集成
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    cmd = { "Git", "Gstatus", "Gblame", "Gpush", "Gpull" },
    keys = {
      { "<leader>gg", "<cmd>Git<CR>", desc = "打开Git状态" },
      { "<leader>gl", "<cmd>Git log<CR>", desc = "Git日志" },
      { "<leader>gB", "<cmd>Git blame<CR>", desc = "Git责任人" },
      { "<leader>gP", "<cmd>Git push<CR>", desc = "Git推送" },
      { "<leader>gL", "<cmd>Git pull<CR>", desc = "Git拉取" },
    },
  },
  
  -- GitHub集成
  {
    "tpope/vim-rhubarb",
    dependencies = { "tpope/vim-fugitive" },
    event = "VeryLazy",
  },
}
EOF

  # 工具和终端插件配置
  cat > "$PLUGINS_DIR/07-tools.lua" << 'EOF'
return {
  -- 浮动终端
  {
    "akinsho/toggleterm.nvim",
    cmd = "ToggleTerm",
    keys = {
      { [[<C-\>]], "<cmd>ToggleTerm<CR>", desc = "切换终端" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "浮动终端" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "水平终端" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", desc = "垂直终端" },
    },
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        open_mapping = [[<C-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })
      
      function _G.set_terminal_keymaps()
        local opts = { noremap = true }
        vim.api.nvim_buf_set_keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts)
        vim.api.nvim_buf_set_keymap(0, "t", "jk", [[<C-\><C-n>]], opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
      end
      
      vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
      
      -- 创建终端命令
      local Terminal = require("toggleterm.terminal").Terminal
      
      local lazygit = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float",
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
      })
      
      function _LAZYGIT_TOGGLE()
        lazygit:toggle()
      end
      
      vim.keymap.set("n", "<leader>gg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", { noremap = true, silent = true, desc = "LazyGit" })
    end,
  },
  
  -- 会话管理
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    config = function()
      require("persistence").setup({
        dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
        options = { "buffers", "curdir", "tabpages", "winsize" },
        pre_save = nil,
      })
      
      -- 键位映射
      vim.keymap.set("n", "<leader>ss", function() require("persistence").load() end, { desc = "恢复会话" })
      vim.keymap.set("n", "<leader>sl", function() require("persistence").load({ last = true }) end, { desc = "恢复上次会话" })
      vim.keymap.set("n", "<leader>sd", function() require("persistence").stop() end, { desc = "不保存当前会话" })
    end,
  },
  
  -- 项目管理
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function()
      require("project_nvim").setup({
        patterns = { ".git", "Makefile", "package.json", "pyproject.toml", "go.mod" },
        detection_methods = { "pattern", "lsp" },
        silent_chdir = true,
        show_hidden = false,
        scope_chdir = "global",
      })
      
      require("telescope").load_extension("projects")
    end,
  },
  
  -- 大纲视图
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialInfo" },
    keys = { 
      { "<leader>a", "<cmd>AerialToggle!<CR>", desc = "符号大纲" },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("aerial").setup({
        on_attach = function(bufnr)
          vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
          vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
        end,
        layout = {
          max_width = { 40, 0.2 },
          width = nil,
          min_width = 20,
          default_direction = "prefer_right",
          placement = "window",
        },
        attach_mode = "global",
        close_behavior = "auto",
        filter_kind = false,
        highlight_mode = "split_width",
        highlight_closest = true,
        highlight_on_hover = true,
        icons = {
          Array = "󰅪 ",
          Boolean = "⊨ ",
          Class = "󰠱 ",
          Constant = "󰏿 ",
          Constructor = " ",
          Enum = " ",
          EnumMember = " ",
          Event = " ",
          Field = " ",
          File = "󰈙 ",
          Function = "󰊕 ",
          Interface = " ",
          Key = "󰌋 ",
          Method = "󰆧 ",
          Module = " ",
          Namespace = "󰌗 ",
          Null = "NULL ",
          Number = "󰎠 ",
          Object = "󰅩 ",
          Operator = "󰆕 ",
          Package = "󰏖 ",
          Property = " ",
          String = "󰀬 ",
          Struct = "󰙅 ",
          TypeParameter = " ",
          Variable = "󰆧 ",
        },
        show_guides = true,
        guides = {
          mid_item = "├─",
          last_item = "└─",
          nested_top = "│ ",
          whitespace = "  ",
        },
        lsp = {
          diagnostics_trigger_update = true,
          update_when_errors = true,
          update_delay = 300,
        },
        treesitter = {
          update_delay = 300,
        },
        markdown = {
          update_delay = 300,
        },
        man = {
          update_delay = 300,
        },
      })
    end,
  },
}
EOF

  echo -e "${GREEN}配置文件生成完成！${NC}"
}

# 主流程
main() {
  check_system_environment # P0改进：检查系统环境
  backup_config
  install_neovim
  generate_plugin_config

  # 安装 lazy.nvim
  local LAZY_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
  if [ ! -d "$LAZY_DIR" ]; then
    echo -e "${BLUE}正在安装 lazy.nvim...${NC}"
    git clone -q --filter=blob:none --branch=stable --depth=1 \
      https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
  fi

  # 完成提示
  echo -e "\n${GREEN}安装完成！${NC}"
  echo -e "使用建议："
  echo -e "1. 启动 Neovim: ${BLUE}nvim${NC}"
  echo -e "2. 插件安装完成后，执行: ${BLUE}:TSInstall lua python${NC}"
  echo -e "3. 安装 LSP 服务: ${BLUE}:Mason${NC}"
  echo -e "4. 重新加载终端或执行: ${BLUE}source ~/.bashrc${NC}\n"
}

main "$@"