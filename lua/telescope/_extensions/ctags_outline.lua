local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local ctags_conf = {
    ctags = { 'ctags' },
    ft_opt = {
        aspvbs= "--asp-kinds=f",
        awk= "--awk-kinds=f",
        c= "--c-kinds=fp",
        cpp= "--c++-kinds=fp --language-force=C++",
        cs= "--c#-kinds=m",
        erlang= "--erlang-kinds=f",
        fortran= "--fortran-kinds=f",
        java= "--java-kinds=m",
        javascript= "--javascript-kinds=f",
        lisp= "--lisp-kinds=f",
        lua= "--lua-kinds=f",
        matla= "--matlab-kinds=f",
        pascal= "--pascal-kinds=f",
        php= "--php-kinds=f",
        python= "--python-kinds=fm --language-force=Python",
        ruby= "--ruby-kinds=fF",
        scheme= "--scheme-kinds=f",
        sh= "--sh-kinds=f",
        sql= "--sql-kinds=f",
        tcl= "--tcl-kinds=m",
        verilog= "--verilog-kinds=f",
        vim= "--vim-kinds=f",
        go= "--go-kinds=f",
        rust= "--rust-kinds=fPM",
        ocaml= "--ocaml-kinds=mf",
    },
}

local function ctags_setup(opts)

    ctags_conf = vim.tbl_deep_extend("force", ctags_conf, opts)

end

local function get_outline_entry(opts)
    opts = opts or {}

    local displayer = entry_display.create {
        separator = " ",
        items = {
            { width = 4 },
            { remaining = true },
            { remaining = true },
        },
    }

    local function make_display(entry)
        return displayer {
            { entry.value.type, "TelescopeResultsVariable" },
            { entry.value.name, "TelescopeResultsFunction" },
            { "[" .. entry.value.line .. "]", "TelescopeResultsComment" },
        }
    end

    return function(entry)
        if entry == "" then
            return nil
        end

        local value = {}
        value.name, value.filename, value.line, value.type = string.match(entry, "(.-)\t(.-)\t(%d+).-\t(.*)")
        --print(entry)
        --print(value.filename, value.line, value.type)

        value.lnum = tonumber(value.line)
        value.name = vim.fn.trim(vim.fn.getbufline(opts.bufnr, value.lnum)[1])

        return {
            filename = value.filename,
            lnum = value.lnum,
            value = value,
            ordinal = value.line .. value.type .. value.name,
            display = make_display
        }
    end
end

local function outline(opts)
    opts = opts or {}
    local cmd = {}

    --init ctags options
    for _, v in ipairs(ctags_conf.ctags) do
        table.insert(cmd, v)
    end

    local str = ("-n -u --fields=k %s -f-"):format(ctags_conf.ft_opt[vim.fn.getbufvar(vim.fn.bufnr(), "&filetype")] or "")
    for _, v in ipairs(vim.fn.split(str)) do
        table.insert(cmd, v)
    end

    --maybe filename have space
    table.insert(cmd, vim.fn.expand("%:p"))

    --print(vim.inspect(cmd))

    opts.entry_maker = get_outline_entry(opts)
    opts.bufnr = vim.fn.bufnr()

    pickers.new(opts, {
        prompt_title = "Ctags Outline",
        finder = finders.new_oneshot_job(cmd, opts),
        sorter = conf.generic_sorter(opts),
        previewer = conf.grep_previewer(opts),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                vim.cmd("normal " .. selection.lnum .. "G^")
            end)
            return true
        end,
    }):find()
end

return require("telescope").register_extension {
    setup = ctags_setup,
    exports = { outline = outline },
}
