" whitespace.vim - find and correct common whitespace errors
" Last Change:  2016 Sep 13
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
let g:whitespace_ignore_tabs = get(g:, 'whitespace_ignore_tabs', [])

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

function! s:WhitespaceShow()
  let g:whitespace_hidden = 0
  call s:WhitespaceMatch('n')
endfunction

function! s:WhitespaceHide()
  let g:whitespace_hidden = 1
  call s:WhitespaceClear()
endfunction

function! s:WhitespaceToggle()
  if g:whitespace_hidden
    call s:WhitespaceShow()
  else
    call s:WhitespaceHide()
  endif
endfunction

function! s:WhitespaceClear()
  if get(w:, 'whitespace_matchnr', 0)
    call matchdelete(w:whitespace_matchnr)
    let w:whitespace_matchnr = 0
  endif
endfunction

function! s:WhitespaceMatch(mode)
  if s:ignored() || g:whitespace_hidden
    return
  endif
  call s:WhitespaceClear()
  let w:whitespace_matchnr =
        \ matchadd(g:whitespace_highlight, s:getpattern(a:mode))
endfunction

function! s:WhitespaceNext()
  if s:ignored() || g:whitespace_hidden
    return
  endif
  call search(s:getpattern('n'), 'w')
endfunction

function! s:WhitespacePrev()
  if s:ignored() || g:whitespace_hidden
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

noremap <unique> <script> <Plug>WhitespaceShow   <SID>WhitespaceShow
noremap <unique> <script> <Plug>WhitespaceHide   <SID>WhitespaceHide
noremap <unique> <script> <Plug>WhitespaceToggle <SID>WhitespaceToggle
noremap <unique> <script> <Plug>WhitespaceNext   <SID>WhitespaceNext
noremap <unique> <script> <Plug>WhitespacePrev   <SID>WhitespacePrev
noremap <unique> <script> <Plug>WhitespaceStrip  <SID>WhitespaceStrip

noremap <silent> <SID>WhitespaceShow   :call <SID>WhitespaceShow()<CR>
noremap <silent> <SID>WhitespaceHide   :call <SID>WhitespaceHide()<CR>
noremap <silent> <SID>WhitespaceToggle :call <SID>WhitespaceToggle()<CR>
noremap <silent> <SID>WhitespaceNext   :call <SID>WhitespaceNext()<CR>
noremap <silent> <SID>WhitespacePrev   :call <SID>WhitespacePrev()<CR>
noremap <silent> <SID>WhitespaceStrip  :call <SID>WhitespaceStrip(1, line('$'))<CR>

noremenu <script> Plugin.Whitespace.Show\ Matches   <SID>WhitespaceShow
noremenu <script> Plugin.Whitespace.Hide\ Matches   <SID>WhitespaceHide
noremenu <script> Plugin.Whitespace.Next\ Match     <SID>WhitespaceNext
noremenu <script> Plugin.Whitespace.Previous\ Match <SID>WhitespacePrev
noremenu <script> Plugin.Whitespace.Strip\ Whitespace <SID>WhitespaceStrip

if !hasmapto('<Plug>WhitespaceToggle')
  nmap <unique> <Leader>w <Plug>WhitespaceToggle
endif

if !hasmapto('<Plug>WhitespaceNext')
  nmap <unique> ]w <Plug>WhitespaceNext
endif

if !hasmapto('<Plug>WhitespacePrev')
  nmap <unique> [w <Plug>WhitespacePrev
endif

if !exists(':WhitespaceStrip')
  command -range=% WhitespaceStrip :call s:WhitespaceStrip(<line1>, <line2>)

  noremap  <silent> gS :<C-U>1,$WhitespaceStrip<CR>
  nnoremap <silent> gs :<C-U>.WhitespaceStrip<CR>
  vnoremap <silent> gs :<C-U>'<,'>WhitespaceStrip<CR>
endif

augroup Whitespace
  autocmd!
  autocmd BufReadPost,InsertLeave   * call <SID>WhitespaceMatch('n')
  autocmd InsertEnter               * call <SID>WhitespaceMatch('i')
  autocmd BufWinLeave               * call <SID>WhitespaceClear()

  autocmd FileType,Syntax           * call <SID>WhitespaceMatch('n')

  if v:version > 704 || v:version == 704 && has('patch786')
    autocmd OptionSet expandtab       call <SID>WhitespaceMatch('n')
  endif

  autocmd BufWritePre *
        \ if g:whitespace_autostrip | execute ':WhitespaceStrip' | endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
