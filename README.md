# telescope-ctags-outline.nvim
get ctags outline for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)


### Installation
```
Plug 'nvim-telescope/telescope.nvim'
Plug 'fcying/telescope-ctags-outline.nvim'
```


### Usage
```
require('telescope').setup{
    extensions = {
        ctags_outline = {
            --specify the ctags executable
            ctags = {'ctags'} or default
            --ctags filetype options
            ft_opt =  {} or default
        }
    }
}

require('telescope').extensions.ctags_outline.outline()

require('telescope').load_extension('ctags_outline')
:Telescope ctags_outline outline
```
