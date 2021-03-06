syntax enable
let python_highlight_all=1
set number                      " Show line numbers
set linebreak                   " Break lines at word (requires Wrap lines)
set showbreak=+++               " Wrap-broken line prefix
set textwidth=100               " Line wrap (number of cols)
set showmatch                   " Highlight matching brace
set visualbell                  " Use visual bell (no beeping)
 
set hlsearch                    " Highlight all search results
set smartcase                   " Enable smart-case search
set ignorecase                  " Always case-insensitive
set incsearch                   " Searches for strings incrementally
 
set autoindent                  " Auto-indent new lines
set expandtab                   " Use spaces instead of tabs
set shiftwidth=4                " Number of auto-indent spaces
set smartindent                 " Enable smart-indent
set smarttab                    " Enable smart-tabs
set softtabstop=4               " Number of spaces per Tab
set ts=4                        " set tabs to have 4 spaces

" Advanced
set ruler                       " Show row and column ruler information
 
set undolevels=1000             " Number of undo levels
set backspace=indent,eol,start  " Backspace behaviour
set mouse=a                     " Allow using mouse
set clipboard=unnamed
set clipboard=unnamedplus
autocmd VimLeave * call system("xsel -ib", getreg('+'))
set showbreak=+++

set undoreload=10000        " number of lines to save for undo
set cursorline
" set cursorcolumn
