" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

function! ferret#private#dispatch#search(command) abort
  if has('autocmd')
    augroup FerretPostQF
      autocmd!
      autocmd QuickfixCmdPost cgetfile call ferret#private#post('qf')
    augroup END
  endif
  let l:original_makeprg=&l:makeprg
  let l:original_errorformat=&l:errorformat
  try
    let &l:makeprg=&grepprg . ' ' . a:command
    let &l:errorformat=&grepformat
    echomsg &l:makeprg
    Make
  catch
    call ferret#private#clearautocmd()
  finally
    let &l:makeprg=l:original_makeprg
    let &l:errorformat=l:original_errorformat
  endtry
endfunction
