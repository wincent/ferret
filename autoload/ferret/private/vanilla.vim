" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

function! s:finalize_search(output, ack)
  let l:original_errorformat=&errorformat
  try
    let &errorformat=g:FerretFormat
    if a:ack
      cexpr a:output
      execute get(g:, 'FerretQFHandler', 'botright cwindow')
      call ferret#private#post('qf')
    else
      lexpr a:output
      execute get(g:, 'FerretLLHandler', 'lwindow')
      call ferret#private#post('location')
    endif
  finally
    let &errorformat=l:original_errorformat
  endtry
endfunction

function! ferret#private#vanilla#search(command, ack) abort
  let l:executable=FerretExecutable()
  let l:output=system(l:executable . ' ' . a:command)
  call s:finalize_search(l:output, a:ack)
endfunction
