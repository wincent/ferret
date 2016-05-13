" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

function! s:finalize_search(output, ack)
  if a:ack
    cexpr a:output
    execute get(g:, 'FerretQFHandler', 'botright cwindow')
    call ferret#private#post('qf')
  else
    lexpr a:output
    execute get(g:, 'FerretLLHandler', 'lwindow')
    call ferret#private#post('location')
  endif
endfunction

function! ferret#private#vanilla#search(command, ack) abort
  let l:output=system(&grepprg . ' ' . a:command)
  call s:finalize_search(l:output, a:ack)
endfunction
