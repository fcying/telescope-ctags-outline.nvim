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

    local output = vim.fn.systemlist(M.get_cmd(opts))
    local items = {}
    local bufnr
    for i, item in ipairs(output) do
        name, filename, line, tag = string.match(item, "(.-)\t(.-)\t(%d+).-\t(.*)")

        if filename then
            bufnr = vim.fn.bufnr(filename)
            full_name = vim.fn.trim(vim.fn.getbufline(bufnr, line)[1])
            table.insert(items, {
                idx = i,
                score = i,
                text = full_name,
                file = filename,
                line = tonumber(line),
                tag = tag,
                bufnr = bufnr,
                pos = { tonumber(line), 0 },
            })
        end
    end

    return Snacks.picker({
        title = "CtagsOutline",
        items = items,
        preview = "file",
        format = function(item)
            local ret = {}
            ret[#ret + 1] = { item.tag, "SnacksPickerLabel" }
            ret[#ret + 1] = { ("\t%s"):format(item.text), "SnacksPickerCmd" }
            if opts.buf == "all" then
                ret[#ret + 1] = { (" [%s:%d]"):format(item.file, item.line), "SnacksPickerComment" }
            else
                ret[#ret + 1] = { (" [%d]"):format(item.line), "SnacksPickerComment" }
            end
            return ret
        end,
        confirm = function(picker, item)
            picker:close()
            if item ~= nil then
                if opts.buf == "all" then
                    vim.api.nvim_set_current_buf(item.bufnr)
                end
                vim.api.nvim_win_set_cursor(0, { item.line, 0 })
            end
        end,
    })
end

M.setup = function(ext_config)
    ctags_conf = vim.tbl_deep_extend("force", ctags_default_conf, ext_config)
end

return M
