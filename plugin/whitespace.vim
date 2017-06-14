" whitespace.vim - find and correct common whitespace errors
" Last Change:  2017 Jun 14
" Maintainer:   Steven Stallion <sstallion@gmail.com>
" License:      Simplified BSD License

if exists('g:loaded_whitespace')
  finish
endif
let g:loaded_whitespace = 1

let s:save_cpo = &cpo
set cpo&vim

let g:whitespace_autostrip = get(g:, 'whitespace_autostrip', 0)

let g:whitespace_hidden = get(g:, 'whitespace_hidden', 0)

let g:whitespace_highlight = get(g:, 'whitespace_highlight', 'ExtraWhitespace')

let g:whitespace_ignore = get(g:, 'whitespace_ignore', [])
let g:whitespace_ignore_splits = get(g:, 'whitespace_ignore_splits', 0)
let g:whitespace_ignore_tabs = get(g:, 'whitespace_ignore_tabs', [])

function! s:hidden()
  return g:whitespace_hidden || b:whitespace_hidden
endfunction

function! s:ignored()
  return !empty(&buftype) ||
        \ index(g:whitespace_ignore, &filetype) != -1
endfunction

function! s:tabsignored()
  return !empty(&buftype) ||
        \ index(g:whitespace_ignore_tabs, &filetype) != -1
endfunction

function! s:getpattern(mode)
  let list = []
  if a:mode ==# 'i'
    call add(list, '\s\+\%#\@<!$')
  else
    call add(list, '\s\+$')
  endif
  if !s:tabsignored()
    if &expandtab
      call add(list, '\t\+')
    else
      call add(list, ' \+\ze\t')
    endif
  endif
  return join(list, '\|')
endfunction

function! s:WhitespaceSetup()
  let b:whitespace_hidden = get(b:, 'whitespace_hidden', g:whitespace_hidden)
  let w:whitespace_matchnr = get(w:, 'whitespace_matchnr', 0)
endfunction

function! s:WhitespaceClear()
  call s:WhitespaceSetup()
  if w:whitespace_matchnr != 0
    call matchdelete(w:whitespace_matchnr)
    let w:whitespace_matchnr = 0
  endif
endfunction

function! s:WhitespaceMatch(mode)
  call s:WhitespaceSetup()
  if s:hidden() || s:ignored()
    return
  endif
  call s:WhitespaceClear()
  let w:whitespace_matchnr =
        \ matchadd(g:whitespace_highlight, s:getpattern(a:mode))
endfunction

function! s:WhitespaceUpdate()
  call s:WhitespaceSetup()
  if s:hidden() || s:ignored()
    call s:WhitespaceClear()
  else
    call s:WhitespaceMatch('n')
  endif
endfunction

function! s:WhitespaceShow()
  let b:whitespace_hidden = 0
  call s:WhitespaceMatch('n')
endfunction

function! s:WhitespaceHide()
  let b:whitespace_hidden = 1
  call s:WhitespaceClear()
endfunction

function! s:WhitespaceToggle()
  if s:hidden()
    call s:WhitespaceShow()
  else
    call s:WhitespaceHide()
  endif
endfunction

function! s:WhitespaceNext()
  if s:hidden() || s:ignored()
    return
  endif
  call search(s:getpattern('n'), 'w')
endfunction

function! s:WhitespacePrev()
  if s:hidden() || s:ignored()
    return
  endif
  call search(s:getpattern('n'), 'wb')
endfunction

function! s:WhitespaceStrip(start, end)
  if s:ignored()
    return
  endif
  let pos = getpos('.')
  try
    if !s:tabsignored()
      execute printf(':%d,%dretab', a:start, a:end)
    endif
    execute printf(':%d,%ds/%s//ge', a:start, a:end, s:getpattern('n'))
  finally
    call setpos('.', pos)
  endtry
endfunction

command -range=% WhitespaceStrip call <SID>WhitespaceStrip(<line1>, <line2>)

nnoremap <silent> <Plug>WhitespaceShow        :call <SID>WhitespaceShow()<CR>
nnoremap <silent> <Plug>WhitespaceHide        :call <SID>WhitespaceHide()<CR>
nnoremap <silent> <Plug>WhitespaceToggle      :call <SID>WhitespaceToggle()<CR>
nnoremap <silent> <Plug>WhitespaceNext        :call <SID>WhitespaceNext()<CR>
nnoremap <silent> <Plug>WhitespacePrev        :call <SID>WhitespacePrev()<CR>
nnoremap <silent> <Plug>WhitespaceStripBuffer :<C-U>1,$WhitespaceStrip<CR>
nnoremap <silent> <Plug>WhitespaceStripLine   :<C-U>.WhitespaceStrip<CR>
vnoremap <silent> <Plug>WhitespaceStripVisual :<C-U>'<,'>WhitespaceStrip<CR>

if !hasmapto('<Plug>WhitespaceToggle')
  nmap <unique> <Leader>w <Plug>WhitespaceToggle
endif

if !hasmapto('<Plug>WhitespaceNext')
  nmap <unique> ]w <Plug>WhitespaceNext
endif

if !hasmapto('<Plug>WhitespacePrev')
  nmap <unique> [w <Plug>WhitespacePrev
endif

if !hasmapto('<Plug>WhitespaceStripBuffer')
  nmap <unique> gS <Plug>WhitespaceStripBuffer
endif

if !hasmapto('<Plug>WhitespaceStripLine')
  nmap <unique> gs <Plug>WhitespaceStripLine
endif

if !hasmapto('<Plug>WhitespaceStripVisual')
  vmap <unique> gs <Plug>WhitespaceStripVisual
endif

nmenu Plugin.Whitespace.Show\ Matches     <Plug>WhitespaceShow
nmenu Plugin.Whitespace.Hide\ Matches     <Plug>WhitespaceHide
nmenu Plugin.Whitespace.Next\ Match       <Plug>WhitespaceNext
nmenu Plugin.Whitespace.Previous\ Match   <Plug>WhitespacePrev
nmenu Plugin.Whitespace.Strip\ Whitespace <Plug>WhitespaceStripBuffer

augroup Whitespace
  autocmd!
  autocmd BufReadPost * call <SID>WhitespaceUpdate()

  if !g:whitespace_ignore_splits
    autocmd VimEnter autocmd WinEnter * call <SID>WhitespaceUpdate()
  endif

  if v:version > 704 || v:version == 704 && has('patch786')
    autocmd OptionSet expandtab call <SID>WhitespaceUpdate()
  endif

  autocmd BufWinLeave * call <SID>WhitespaceClear()

  autocmd InsertEnter * call <SID>WhitespaceMatch('i')
  autocmd InsertLeave * call <SID>WhitespaceMatch('n')

  autocmd BufWritePre *
        \ if g:whitespace_autostrip | execute ':WhitespaceStrip' | endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
