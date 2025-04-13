# telescope-ctags-outline.nvim
get ctags outline for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)  
Use [exuberant-ctags](https://ctags.sourceforge.net) does not support all options, it is recommended to use [universal-ctags](https://github.com/universal-ctags/ctags).


### Installation
```
Plug 'nvim-telescope/telescope.nvim'
Plug 'fcying/telescope-ctags-outline.nvim'
```

### default option
```
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
```


### Usage
```
require('telescope').setup{
    extensions = {
        ctags_outline = {
            --ctags option
            ctags = {'ctags'},
            --ctags filetype option
            ft_opt = {
                vim = '--vim-kinds=fk',
                lua = '--lua-kinds=fk',
            },
            sorting_strategy = 'ascending',
        },
    },
}

require('telescope').load_extension('ctags_outline')

-- show current buf outline
:Telescope ctags_outline
require('telescope').extensions.ctags_outline.outline()

-- show all opened buf outline(use current buf filetype)
:Telescope ctags_outline buf=all
require('telescope').extensions.ctags_outline.outline({buf='all'})

-- snacks
require("telescope-ctags-outline").setup()
require("telescope-ctags-outline").snacks_ctags_outline()
```
