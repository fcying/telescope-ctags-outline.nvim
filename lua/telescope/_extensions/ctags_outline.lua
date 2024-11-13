local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
    error('telescope-ctags-outline.nvim requires nvim-telescope/telescope.nvim')
end

local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local entry_display = require('telescope.pickers.entry_display')

local ctags_conf

-- default value fork from https://github.com/Yggdroot/LeaderF/blob/master/autoload/leaderf/python/leaderf/functionExpl.py
local ctags_default_conf = {
    ctags = { 'ctags' },
    ft_opt = {
        aspvbs = '--asp-kinds=f',
        awk = '--awk-kinds=f',
        c = '--c-kinds=fp',
        cpp = '--c++-kinds=fp --language-force=C++',
        cs = '--c#-kinds=m',
        erlang = '--erlang-kinds=f',
        fortran = '--fortran-kinds=f',
        java = '--java-kinds=m',
        lisp = '--lisp-kinds=f',
        lua = '--lua-kinds=f',
        matla = '--matlab-kinds=f',
        pascal = '--pascal-kinds=f',
        php = '--php-kinds=f',
        python = '--python-kinds=fm --language-force=Python',
        ruby = '--ruby-kinds=fF',
        scheme = '--scheme-kinds=f',
        sh = '--sh-kinds=f',
        sql = '--sql-kinds=f',
        tcl = '--tcl-kinds=m',
        verilog = '--verilog-kinds=f',
        vim = '--vim-kinds=f',
        -- universal ctags
        javascript = '--javascript-kinds=f',
        go = '--go-kinds=f',
        rust = '--rust-kinds=fPM',
        ocaml = '--ocaml-kinds=mf',
    },
    sorting_strategy = nil,
}

local function get_outline_entry(opts)
    opts = opts or {}

    local display_items = {
        { width = 4 },
        { remaining = true },
        { remaining = true },
    }

    if opts.buf == 'all' then
        table.insert(display_items, { remaining = true })
    end

    local displayer = entry_display.create({
        separator = ' ',
        items = display_items,
    })

    local function make_display(entry)
        local display_columns = {
            { entry.value.type, 'TelescopeResultsVariable' },
            { entry.value.name, 'TelescopeResultsFunction' },
        }
        if opts.buf == 'all' then
            table.insert(display_columns, { '  [' .. entry.filename, 'TelescopeResultsComment' })
            table.insert(display_columns, { ':' .. entry.value.line .. ']', 'TelescopeResultsComment' })
        else
            table.insert(display_columns, { '[' .. entry.value.line .. ']', 'TelescopeResultsComment' })
        end
        return displayer(display_columns)
    end

    return function(entry)
        if entry == '' then
            return nil
        end

        local value = {}
        value.name, value.filename, value.line, value.type = string.match(entry, '(.-)\t(.-)\t(%d+).-\t(.*)')
        --print(entry)
        --print(value.filename, value.line, value.type)

        value.lnum = tonumber(value.line)
        value.name = vim.fn.trim(vim.fn.getbufline(opts.bufnr, value.lnum)[1])

        local ordinal = value.line .. value.type .. value.name
        if opts.buf == 'all' then
            ordinal = ordinal .. value.filename
        end

        return {
            filename = value.filename,
            lnum = value.lnum,
            value = value,
            ordinal = ordinal,
            display = make_display,
        }
    end
end

local function outline(opts)
    opts = opts or { buf = 'cur' }
    local cmd = {}

    --init ctags options
    for _, v in ipairs(ctags_conf.ctags) do
        table.insert(cmd, v)
    end

    local str = ('-n -u --fields=k %s -f-'):format(
        ctags_conf.ft_opt[vim.fn.getbufvar(vim.fn.bufnr(), '&filetype')] or ''
    )
    for _, v in ipairs(vim.fn.split(str)) do
        table.insert(cmd, v)
    end

    --maybe filename have space
    if opts.buf == 'all' then
        local buffers = vim.fn.getbufinfo({ bufloaded = 1, buflisted = 1 })
        for _, v in ipairs(buffers) do
            table.insert(cmd, v.name)
        end
    else
        table.insert(cmd, vim.fn.expand('%:p'))
    end

    --print(vim.inspect(ctags_conf))
    --print(vim.inspect(cmd))

    opts.entry_maker = get_outline_entry(opts)
    opts.bufnr = vim.fn.bufnr()

    pickers
        .new(opts, {
            prompt_title = 'Ctags Outline',
            finder = finders.new_oneshot_job(cmd, opts),
            sorter = conf.generic_sorter(opts),
            previewer = conf.grep_previewer(opts),
            sorting_strategy = ctags_conf.sorting_strategy,
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    vim.cmd('normal ' .. selection.lnum .. 'G^')
                end)
                return true
            end,
        })
        :find()
end

return telescope.register_extension({
    setup = function(ext_config)
        ctags_conf = vim.tbl_deep_extend('force', ctags_default_conf, ext_config)
    end,
    exports = { ctags_outline = outline, outline = outline },
})
