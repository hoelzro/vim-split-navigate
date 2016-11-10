" set default values if unset
if ! exists("g:splitnavigate_start_key")
  let g:splitnavigate_start_key = "<space>"
endif
if ! exists("g:splitnavigate_up_key")
  let g:splitnavigate_up_key = "k"
endif
if ! exists("g:splitnavigate_down_key")
  let g:splitnavigate_down_key = "j"
endif
if ! exists("g:splitnavigate_abort_key")
  let g:splitnavigate_abort_key = "<Esc>"
endif

function! s:SelectLower()
  let middle = <SID>GetMiddle()
  let b:binary_top = middle + 1
  call <SID>Refresh()
endfunction

function! s:SelectUpper()
  let middle = <SID>GetMiddle()
  let b:binary_bottom = middle
  call <SID>Refresh()
endfunction

function! s:SetupSeekBindings()
  execute "map <buffer> <silent> ". g:splitnavigate_down_key  ." :call <SID>SelectLower()<CR>"
  execute "map <buffer> <silent> ". g:splitnavigate_up_key    ." :call <SID>SelectUpper()<CR>"
  execute "map <buffer> <silent> ". g:splitnavigate_abort_key ." :call <SID>AbortSearch()<CR>"
endfunction

function! s:AbortSearch()
  call matchdelete(b:binary_matches[0])
  call matchdelete(b:binary_matches[1])
  unlet b:binary_matches

  call <SID>ResetSeekBindings()
endfunction

function! s:ResetSeekBindings()
  execute "unmap <buffer>" . g:splitnavigate_up_key
  execute "unmap <buffer>" . g:splitnavigate_down_key
  execute "unmap <buffer>" . g:splitnavigate_abort_key
endfunction

function! s:GetMiddle()
  return (b:binary_bottom - b:binary_top) / 2 + b:binary_top
endfunction

function! s:HighlightLinesBetween(start, finish)
  return '\%>' . (a:start - 1) . 'l\%<' . (a:finish + 1) . 'l'
endfunction

function! s:Refresh()
  if b:binary_top == b:binary_bottom
    call cursor(b:binary_top, 1)
    call <SID>AbortSearch()

    return
  endif

  if has_key(b:, 'binary_middle')
    let middle = b:binary_middle
    unlet b:binary_middle
  else
    let middle = <SID>GetMiddle()
  endif
  call cursor(middle, 1)

  let match_top    = <SID>HighlightLinesBetween(b:binary_top, middle)
  let match_bottom = <SID>HighlightLinesBetween(middle + 1, b:binary_bottom)

  if has_key(b:, 'binary_matches')
    call matchdelete(b:binary_matches[0])
    call matchdelete(b:binary_matches[1])
  endif

  let b:binary_matches = [0, 0]
  let b:binary_matches[0] = matchadd('TopHighlight', match_top)
  let b:binary_matches[1] = matchadd('BottomHighlight', match_bottom)
endfunction

function! BinarySeek()
  let current_line = line('.')
  let b:binary_top = current_line - winline() + 1
  let b:binary_bottom = min([b:binary_top + winheight(0) - 1, line('$')])
  let b:binary_middle = <SID>GetMiddle()

  call <SID>SetupSeekBindings()
  call <SID>Refresh()
endfunction


execute "try | unmap ". g:splitnavigate_start_key . " | catch | endtry"

execute "nnoremap <silent> ". g:splitnavigate_start_key ." :call BinarySeek()<CR>"

highlight default TopHighlight term=bold ctermfg=252 ctermbg=18 guifg=fg guibg=#000080
highlight default BottomHighlight term=standout ctermfg=186 ctermbg=88 guifg=#d0d090 guibg=#800000

" XXX Caveats:
"   - Doesn't really work with folds
