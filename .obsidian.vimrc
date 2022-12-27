" install plug by follwing curl
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'
"
" Make sure you use single quotes
"
" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'
"
" Any valid git URL is allowed
Plug 'https://github.com/junegunn/vim-github-dashboard.git'
Plug 'udalov/kotlin-vim'
"
" Multiple Plug commands can be written in a single line using | separators
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
"
" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'morhetz/gruvbox'
"
" Using a non-default branch
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }
"
" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
Plug 'fatih/vim-go', { 'tag': '*' }
"
" Plugin options
Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }
"
" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
"
" Unmanaged plugin (manually installed and updated)
" Plug '~/my-prototype-plugin'
"
" Initialize plugin system
call plug#end()

syntax on
set nu
set is
set hls
set autoindent

" Tell vim to remember certain things when we exit
"  '10  :  marks will be remembered for up to 10 previously edited files
"  "100 :  will save up to 100 lines for each register
"  :20  :  up to 20 linesof command-line history will be recommanded
"  %    :  saves and restores the buffer list
"  n... : where to save the viminfo files
set viminfo='10,\"100,:20,%,n~/.viminfo

" reset cursor to latest line
function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END

" mouse scroll
set mouse=a
if has("mouse_sgr")
  set ttymouse=sgr
else
  set ttymouse=xterm2
end

" yank to clipboard
set clipboard=unnamed
" copy (write) highlighted text to .vimbuffer
" vmap <C-c> y:new ~/.vimbuffer<CR>VGp:x<CR> \| :!cat ~/.vimbuffer \| clip.exe <CR><CR>
"autocmd TextYankPost * call system('echo '.shellescape(join(v:event.regcontents, "\<CR>")).' |  clip.exe')
" paste from buffer
" map <C-v> :r ~/.vimbuffer<CR>
" autocmd TextYankPost * call system('win32yank.exe -i --crlf', @")
" 
" 
" function! Paste(mode)
"   let @" = system('win32yank.exe -o --lf')
"   return a:mode
" endfunction
" 
" map <expr> p Paste('p')
" map <expr> P Paste('P')
" 
" autocmd TextYankPost * call YankDebounced()
" 
" function! Yank(timer)
"   call system('win32yank.exe -i --crlf', @")
"   redraw!
" endfunction
" 
" let g:yank_debounce_time_ms = 500
" let g:yank_debounce_timer_id = -1
" 
" function! YankDebounced()
"   let l:now = localtime()
"   call timer_stop(g:yank_debounce_timer_id)
"   let g:yank_debounce_timer_id = timer_start(g:yank_debounce_time_ms, 'Yank')
" endfunction
" end yank to clipboard


" let g:airline_theme='base16_google'
let g:airline_theme='powerlineish'
let g:airline_powerline_fonts='1'

" gruvbox settings
set bg=dark
colorscheme gruvbox


" Cursor in terminal
" https://vim.fandom.com/wiki/Configuring_the_cursor
" 1 or 0 -> blinking block
" 2 solid block
" 3 -> blinking underscore
" 4 solid underscore
" Recent versions of xterm (282 or above) also support
" 5 -> blinking vertical bar
" 6 -> solid vertical bar

" if &term =~ '^xterm'
"   " normal mode
"   let &t_EI .= "\<Esc>[0 q"
"   " insert mode
"   let &t_SI .= "\<Esc>[6 q"
" endif

set tabstop=2
set shiftwidth=2
set expandtab

