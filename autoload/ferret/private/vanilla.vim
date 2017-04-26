" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

function! s:finalize_search(output, ack)
  let l:original_errorformat=&errorformat
  try
    let &errorformat=g:FerretFormat
    let s:output=a:output " For passing to `s:swallow()`.
    if a:ack
      call s:swallow('cexpr s:output')
      execute get(g:, 'FerretQFHandler', 'botright cwindow')
      call ferret#private#post('qf')
    else
      call s:swallow('lexpr s:output')
      execute get(g:, 'FerretLLHandler', 'lwindow')
      call ferret#private#post('location')
    endif
  finally
    let &errorformat=l:original_errorformat
    unlet s:output
  endtry
endfunction

function! ferret#private#vanilla#search(command, ack) abort
  let l:executable=FerretExecutable()
  let l:output=system(l:executable . ' ' . a:command)
  call s:finalize_search(l:output, a:ack)
endfunction

" Execute `executable` expression, swallowing errors.
" The intention is that this should catch "innocuous" errors, like a bad
" modeline causing `cexpr` to throw an error when it tries to jump to that file.
function! s:swallow(executable)
  try
    execute a:executable
  catch
    echomsg 'Caught: ' . v:exception
  endtry
endfunction
