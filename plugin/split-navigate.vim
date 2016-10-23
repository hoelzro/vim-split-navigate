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
  map <buffer> <silent> j :call <SID>SelectLower()<CR>
  map <buffer> <silent> k :call <SID>SelectUpper()<CR>
  map <buffer> <silent> <Esc> :call <SID>ResetSeekBindings()<CR>
endfunction

function! s:ResetSeekBindings()
  call matchdelete(b:binary_matches[0])
  call matchdelete(b:binary_matches[1])
  unlet b:binary_matches

  unmap <buffer> j
  unmap <buffer> k
  unmap <buffer> <Esc>
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
    call <SID>ResetSeekBindings()

    return
  endif

  let middle = <SID>GetMiddle()

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

  call <SID>SetupSeekBindings()
  call <SID>Refresh()
endfunction

try
  unmap <Space>
catch
endtry

nnoremap <silent> <Space> :call BinarySeek()<CR>

highlight TopHighlight term=bold ctermfg=252 ctermbg=18 guifg=fg guibg=#000080
highlight BottomHighlight term=standout ctermfg=186 ctermbg=88 guifg=#d0d090 guibg=#800000

function! OverrideJK(cmd)
  if v:count == 0
    return a:cmd
  endif

  let time = reltime()
  if (time[1] % 5) != 0
    return a:cmd
  endif
  echomsg 'Use split seek to do it'
  return "\u0020"
endfunction

nmap <silent> <expr> j OverrideJK('j')
nmap <silent> <expr> k OverrideJK('k')

" XXX Caveats:
"   - Doesn't really work with folds
"   - Uses <Space>/j/k
"   - colors are hardcoded
