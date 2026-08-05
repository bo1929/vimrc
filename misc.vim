" Toggle netrw explorer window.
function! ToggleNetrwExplorer()
  if exists("t:expl_buf_num")
    let expl_win_num=bufwinnr(t:expl_buf_num)
    unlet t:expl_buf_num
    if expl_win_num != -1
      exec expl_win_num . "wincmd w"
      try
        close
      catch /^Vim\%((\a\+)\)\=:E444/
        b#
      endtry
      return
    endif
    " Explorer buffer was hidden, fall through and reopen it.
  endif
  25Lexplore
  let t:expl_buf_num=bufnr("%")
endfunction

" Swicth to netrw explorer window.
function! SwitchNetrwWindow()
  if exists("t:expl_buf_num")
    let expl_win_num=bufwinnr(t:expl_buf_num)
    if expl_win_num!=-1
      exec expl_win_num . "wincmd w"
    endif
  endif
endfunction

" Twiddle the case of text under the cursor.
function! TwiddleCase(str)
  if a:str ==# toupper(a:str)
    let result=tolower(a:str)
  elseif a:str ==# tolower(a:str)
    let result=substitute(a:str,'\(\<\w\+\>\)', '\u\1', 'g')
  else
    let result=toupper(a:str)
  endif
  return result
endfunction

" Alignment for tables using Tabularize.
function! AlignTable()
  let p='^\s*|\s.*\s|\s*$'
  if exists(":Tabularize") && getline('.') =~# '^\s*|' && (getline(line('.')-1) =~# p || getline(line('.')+1) =~# p)
    let column=strlen(substitute(getline('.')[0:col('.')],'[^|]','','g'))
    let position=strlen(matchstr(getline('.')[0:col('.')],'.*|\s*\zs.*'))
    Tabularize/|/l1
    normal! 0
    call search(repeat('[^|]*|',column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
  endif
endfunction

function! HiNoneBG()
  hi Normal guibg=NONE ctermbg=NONE
  hi Folded guibg=NONE ctermbg=NONE
  " hi CursorColumn cterm=NONE ctermbg=NONE ctermfg=NONE
  " hi CursorLine cterm=NONE ctermbg=NONE ctermfg=NONE
  " hi CursorLineNr cterm=NONE ctermbg=NONE ctermfg=NONE
  " hi SpecialKey ctermbg=NONE
  " hi NonText ctermbg=NONE
  " hi VertSplit ctermbg=NONE
  " hi LineNr ctermbg=NONE
  " hi SignColumn ctermbg=NONE
endfunction

function! HiClear()
  hi clear CursorLine
  " hi clear SignColumn
  " hi clear LineNr
endfunction

function! ToggleBG()
  let &background=( &background == "dark"? "light" : "dark" )
  if exists("g:colors_name")
    exe "colorscheme " . g:colors_name
  endif
  call HiClear()
  call HiNoneBG()
  redraw!
endfunction

function! DotFoldText()
  let nblines=v:foldend - v:foldstart + 1
  let w=winwidth(0) - &foldcolumn - (&number ? 3 : 0)
  let expansionString=repeat(".", w - strwidth(nblines.'"') - 1)
  let txt=nblines . " " . expansionString
  return txt
endfunction

fun! TrimWhitespace()
  let l:save=winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfun

function! OneSentencePerLine()
  if mode() =~# '^[iR]'
    return
  endif
  let indentation_level=indent('.') / &shiftwidth
  let indentation_command=repeat('>', indentation_level)
  let start=v:lnum
  let end=start + v:count - 1
  execute start.','.end.'join'
  s/\(^\s*\d\+\)\@<!\(\<al\)\@<![.!?] \zs\s*\ze\S/\r/g
  call TrimWhitespace()
  exec end+1.','.line(".").indentation_command
endfunction

function! LocalWrap(tw=0, sb='>', ba=' ^I!@*-+;:,./?')
  setlocal wrap
  setlocal nolist
  setlocal linebreak
  setlocal breakindent
  " Set tw=0 to soft wrap.
  let &l:textwidth=a:tw
  let &l:showbreak=a:sb
  let &l:breakat=a:ba
endfunction

function! LocalNoWrap()
  setlocal nowrap
  setlocal nolinebreak
  setlocal nojoinspaces
  setlocal sidescroll=1
  setlocal textwidth=0 
  setlocal wrapmargin=0
  setlocal listchars+=precedes:<,extends:>
endfunction

" Append timestamps.
if !exists(":AppendDate")
  command! AppendDate :normal a<C-R>=strftime("%Y-%m-%d %a %I:%M %p")<CR>
endif

" New commands for async 'grep' and 'make'.
if exists(":AsyncRun")
  if !exists(":AsyncMake") 
    command! -bang -nargs=* -complete=file -bar AsyncMake  AsyncRun<bang> -program=make -auto=make @ <args>
  endif
  if !exists(":AsyncGrep") 
    command! -bang -nargs=* -complete=file -bar AsyncGrep  AsyncRun<bang> -program=grep -auto=grep @ <args>
  endif
endif

augroup SetupAutoCompletion
  autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
augroup END

function! ToggleDiagnosticsLSP()
  if exists('*lsp#disable_diagnostics_for_buffer')
    if get(b:, 'lsp_diagnostics_enabled', 0)
        call lsp#disable_diagnostics_for_buffer()
        let b:lsp_diagnostics_enabled=0
        " echo "LSP diagnostics is disabled."
    else
        call lsp#enable_diagnostics_for_buffer()
        let b:lsp_diagnostics_enabled=1
        " echo "LSP diagnostics is enabled."
    endif
  else
    echo "LSP diagnostics is not available."
  endif
endfunction

" Record the initial (enabled) state once per buffer; the actual
" enable/disable is left to vim-lsp and the <leader>L toggle.
function! InitializeDiagnosticsLSP()
  if exists(":LspDocumentDiagnostics") && !exists("b:lsp_diagnostics_enabled")
    let b:lsp_diagnostics_enabled=1
  endif
endfunction

augroup InitDiagnosticsLSP
  autocmd!
  autocmd BufEnter * call InitializeDiagnosticsLSP()
augroup END

augroup ResetCursorShape
  autocmd!
  " Reset cursor on startup
  autocmd VimEnter * :normal :startinsert :stopinsert 
augroup END

augroup AdaptColorScheme
  autocmd!
  " Adapt color scheme.
  autocmd ColorScheme * call HiNoneBG()
  autocmd ColorScheme * call HiClear()
  " Re-apply custom LSP highlights after the colorscheme's :hi clear.
  " Set before vim-lsp loads so its 'highlight default link' won't override.
  autocmd ColorScheme * highlight link LspErrorHighlight Error
  autocmd ColorScheme * highlight lspReference ctermfg=red guifg=red ctermbg=green guibg=green
augroup END

augroup SetFormatOptions
  autocmd!
  " Format options.
  " autocmd Filetype * setlocal fo=tcq1lnp
  autocmd Filetype * setlocal fo-=r fo-=o
augroup END
