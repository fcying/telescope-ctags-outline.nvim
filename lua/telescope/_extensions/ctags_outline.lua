local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error("telescope-ctags-outline.nvim requires nvim-telescope/telescope.nvim")
end

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")



local function get_outline_entry(opts)
    opts = opts or {}

    local display_items = {
        { width = 4 },
        { remaining = true },
        { remaining = true },
    }

    if opts.buf == "all" then
        table.insert(display_items, { remaining = true })
    end

    local displayer = entry_display.create({
        separator = " ",
        items = display_items,
    })

    local function make_display(entry)
        local display_columns = {
            { entry.value.type, "TelescopeResultsVariable" },
            { entry.value.name, "TelescopeResultsFunction" },
        }
        if opts.buf == "all" then
            table.insert(display_columns, { "  [" .. entry.filename, "TelescopeResultsComment" })
            table.insert(display_columns, { ":" .. entry.value.line .. "]", "TelescopeResultsComment" })
        else
            table.insert(display_columns, { "[" .. entry.value.line .. "]", "TelescopeResultsComment" })
        end
        return displayer(display_columns)
    end

    return function(entry)
        if entry == "" then
            return nil
        end

        local value = {}
        local bufnr

        value.name, value.filename, value.line, value.type = string.match(entry, "(.-)\t(.-)\t(%d+).-\t(.*)")
        -- vim.print(entry)
        -- vim.print(value.filename, value.line, value.type)

        if opts.buf == "cur" then
            bufnr = vim.fn.bufnr()
        else
            bufnr = vim.fn.bufnr(value.filename)
        end

        value.lnum = tonumber(value.line)
        value.name = vim.fn.trim(vim.fn.getbufline(bufnr, value.lnum)[1])

        local ordinal = value.line .. value.type .. value.name
        if opts.buf == "all" then
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
    opts = opts or { buf = "cur" }
    local cmd = require("ctags-outline").get_cmd(opts)
    local ctags_conf = require("ctags-outline").get_conf()

    opts.entry_maker = get_outline_entry(opts)

    pickers
        .new(opts, {
            prompt_title = "Ctags Outline",
            finder = finders.new_oneshot_job(cmd, opts),
            sorter = conf.generic_sorter(opts),
            previewer = conf.grep_previewer(opts),
            sorting_strategy = ctags_conf.sorting_strategy,
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection ~= nil then
                        local bufnr = vim.fn.bufnr(selection.filename)
                        vim.api.nvim_set_current_buf(bufnr)
                        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
                    end
                end)
                return true
            end,
        })
        :find()
end

return telescope.register_extension({
    setup = function(ext_config)
        require("ctags-outline").setup(ext_config)
    end,
    exports = { ctags_outline = outline, outline = outline },
})
