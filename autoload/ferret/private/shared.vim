" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

function! ferret#private#shared#finalize_search(output, ack)
  let l:original_errorformat=&errorformat
  try
    let &errorformat=g:FerretFormat
    if a:ack
      call s:swallow('cexpr a:1', a:output)
      execute get(g:, 'FerretQFHandler', 'botright cwindow')
      call ferret#private#post('qf')
    else
      call s:swallow('lexpr a:1', a:output)
      execute get(g:, 'FerretLLHandler', 'lwindow')
      call ferret#private#post('location')
    endif
  finally
    let &errorformat=l:original_errorformat
  endtry
endfunction

" Execute `executable` expression, swallowing errors.
" The intention is that this should catch "innocuous" errors, like a bad
" modeline causing `cexpr` to throw an error when it tries to jump to that file.
function! s:swallow(executable, ...)
  try
    execute a:executable
  catch
    echomsg 'Caught: ' . v:exception
  endtry
endfunction
