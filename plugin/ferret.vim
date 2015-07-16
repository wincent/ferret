" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

" Provide users with means to prevent loading, as recommended in `:h
" write-plugin`.
if exists('g:FerretLoaded') || &compatible || v:version < 700
  finish
endif
let g:FerretLoaded = 1

" Temporarily set 'cpoptions' to Vim default as per `:h use-cpo-save`.
let s:cpoptions = &cpoptions
set cpoptions&vim

if executable('ag') " The Silver Searcher: faster than ack.
  let s:ackprg = 'ag --column --nocolor --nogroup'
elseif executable('ack') " Ack: better than grep.
  let s:ackprg = 'ack --column'
elseif executable('grep') " Grep: it's just grep.
  let s:ackprg = &grepprg " default is: grep -n $* /dev/null
endif

if !empty(s:ackprg)
  let &grepprg=s:ackprg
  set grepformat=%f:%l:%c:%m
endif

if has('autocmd')
  augroup Ferret
    autocmd!
    autocmd QuickFixCmdPost [^l]* nested cwindow
    autocmd QuickFixCmdPost l* nested lwindow
  augroup END
endif

command! -nargs=+ -complete=file Ack call ferret#private#ack(<q-args>)
command! -nargs=+ -complete=file Lack call ferret#private#lack(<q-args>)
command! -nargs=1 Acks call ferret#private#acks(<q-args>)

let s:map=exists('g:FerretMap') ? g:FerretMap : 1
if s:map
  if !hasmapto('<Plug>(FerretAck)') && maparg('<leader>a', 'n') ==# ''
    nmap <unique> <leader>a <Plug>(FerretAck)
  endif
  nnoremap <Plug>(FerretAck) :Ack<space>

  if !hasmapto('<Plug>FerretLack') && maparg('<leader>l', 'n') ==# ''
    nmap <unique> <leader>l <Plug>(FerretLack)
  endif
  nnoremap <Plug>(FerretLack) :Lack<space>

  if !hasmapto('<Plug>(FerretAckWord)') && maparg('<leader>s', 'n') ==# ''
    " Call :Ack with word currently under cursor (mnemonic: selection).
    nmap <unique> <leader>s <Plug>(FerretAckWord)
  endif
  nnoremap <Plug>(FerretAckWord) :Ack <C-r><C-w><CR>

  if !hasmapto('<Plug>(FerretAcks)') && maparg('<leader>r', 'n') ==# ''
      nmap <unique> <leader>r <Plug>(FerretAcks)
  endif
  nnoremap <Plug>(FerretAcks) :Acks<space>/<c-r>=eval(g:ferret_lastsearch)<CR>/
endif

" Populate the :args list with the filenames currently in the quickfix window.
command! -bar Qargs execute 'args' ferret#qargs()

let s:commands=exists('g:FerretQFCommands') ? g:FerrerQFCommands : 1
if s:commands
  " Keep quickfix result centered, if possible, when jumping from result to result.
  cabbrev <silent> <expr> cn ((getcmdtype() == ':' && getcmdpos() == 3) ? 'cn <bar> normal zz<cr>' : 'cn')
  cabbrev <silent> <expr> cnf ((getcmdtype() == ':' && getcmdpos() == 4) ? 'cnf <bar> normal zz<cr>' : 'cnf')
  cabbrev <silent> <expr> cp ((getcmdtype() == ':' && getcmdpos() == 3) ? 'cp <bar> normal zz<cr>' : 'cp')
  cabbrev <silent> <expr> cpf ((getcmdtype() == ':' && getcmdpos() == 4) ? 'cpf <bar> normal zz<cr>' : 'cpf')
endif

" Restore 'cpoptions' to its former value.
let &cpoptions = s:cpoptions
unlet s:cpoptions
