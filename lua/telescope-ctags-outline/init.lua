local M = {}
local ctags_conf = {}

-- default value fork from https://github.com/Yggdroot/LeaderF/blob/master/autoload/leaderf/python/leaderf/functionExpl.py
local ctags_default_conf = {
    ctags = { "ctags" },
    ft_opt = {
        aspvbs = "--asp-kinds=f",
        awk = "--awk-kinds=f",
        c = "--c-kinds=fp",
        cpp = "--c++-kinds=fp --language-force=C++",
        cs = "--c#-kinds=m",
        erlang = "--erlang-kinds=f",
        fortran = "--fortran-kinds=f",
        java = "--java-kinds=m",
        lisp = "--lisp-kinds=f",
        lua = "--lua-kinds=f",
        matla = "--matlab-kinds=f",
        pascal = "--pascal-kinds=f",
        php = "--php-kinds=f",
        python = "--python-kinds=fm --language-force=Python",
        ruby = "--ruby-kinds=fF",
        scheme = "--scheme-kinds=f",
        sh = "--sh-kinds=f",
        sql = "--sql-kinds=f",
        tcl = "--tcl-kinds=m",
        verilog = "--verilog-kinds=f",
        vim = "--vim-kinds=f",
        -- universal ctags
        javascript = "--javascript-kinds=f",
        go = "--go-kinds=f",
        rust = "--rust-kinds=fPM",
        ocaml = "--ocaml-kinds=mf",
    },
    sorting_strategy = nil,
}

M.get_conf = function()
    return ctags_conf
end

M.get_cmd = function(opts)
    opts = opts or { buf = "cur" }
    local cmd = {}

    --init ctags options
    for _, v in ipairs(ctags_conf.ctags) do
        table.insert(cmd, v)
    end

    local str = ("-n -u --fields=k %s -f-"):format(
        ctags_conf.ft_opt[vim.fn.getbufvar(vim.fn.bufnr(), "&filetype")] or ""
    )

    for _, v in ipairs(vim.fn.split(str)) do
        table.insert(cmd, v)
    end

    --maybe filename have space
    if opts.buf == "all" then
        local buffers = vim.fn.getbufinfo({ bufloaded = 1, buflisted = 1 })
        for _, v in ipairs(buffers) do
            table.insert(cmd, v.name)
        end
    else
        table.insert(cmd, vim.fn.expand("%:p"))
    end

    -- vim.print(cmd)
    return cmd
end

M.snacks_ctags_outline = function(opts)
    opts = opts or { buf = "cur" }

    local outline = require("telescope-ctags-outline")
    local output = vim.fn.systemlist(outline.get_cmd(opts))
    local items = {}
    for i, item in ipairs(output) do
        name, filename, line, tag = string.match(item, "(.-)\t(.-)\t(%d+).-\t(.*)")

        if opts.buf == "cur" then
            bufnr = vim.fn.bufnr()
        else
            bufnr = vim.fn.bufnr(filename)
        end
        full_name = vim.fn.trim(vim.fn.getbufline(bufnr, line)[1])

        if name and line then
            table.insert(items, {
                idx = i,
                score = i,
                text = full_name,
                file = filename,
                line = tonumber(line),
                tag = tag,
            })
        end
    end
    return Snacks.picker({
        items = items,
        format = function(item)
            local ret = {}
            ret[#ret + 1] = { item.tag, "SnacksPickerLabel" }
            ret[#ret + 1] = { ("\t%s"):format(item.text), "SnacksPickerCmd" }
            ret[#ret + 1] = { (" [%d]"):format(item.line), "SnacksPickerComment" }
            return ret
        end,
        confirm = function(picker, item)
            picker:close()
            vim.api.nvim_win_set_cursor(0, { item.line, 0 })
        end,
    })
end

M.setup = function(ext_config)
    ctags_conf = vim.tbl_deep_extend("force", ctags_default_conf, ext_config)
end

return M
