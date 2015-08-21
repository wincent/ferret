" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

" Remove lines a:first through a:last from the quickfix listing.
function! s:delete(first, last)
  let l:list=getqflist()
  let l:line=a:first

  while l:line >= a:first && l:line <= a:last
    " Non-dictionary items will be ignored. This effectively deletes the line.
    let l:list[l:line - 1]=0
    let l:line=l:line + 1
  endwhile
  call setqflist(l:list, 'r')

  " Show to next entry.
  execute 'cc ' . a:first

  " Move focus back to quickfix listing.
  execute "normal \<C-W>\<C-P>"
endfunction

" Returns 1 if we should/can use vim-dispatch.
function! s:dispatch()
  let l:dispatch=get(g:, 'FerretDispatch', 1)
  return l:dispatch && exists(':Make') == 2
endfunction

" Use `input()` to show error output to user. Ideally, we would do this in a way
" that didn't require user interaction, but this is the only reliable mechanism
" that works for all cases. Alternatives considered:
"
" (1) Using `:echomsg`
"
"     When not using vim-dispatch, the screen is getting cleared before the
"     user sees it, even with a pre-emptive `:redraw!` beforehand. Note that
"     we can get the message to linger on the screen by making it multi-line and
"     forcing Vim to show a prompt (see `:h hit-enter-prompt`), but this is not
"     reliable because the number of lines required to force the prompt will
"     vary by system, depending on the value of `'cmdheight'`.
"
"     When using vim-dispatch, anything we output ends up getting swallowed
"     before the user sees it, because something it is doing is clearing the
"     screen. This is true no matter how many lines we output.
"
" (2) Writing back into the quickfix/location list
"
"     This interacts poorly with vim-dispatch. If we write back an error message
"     and then call `:copen 1`, vim-dispatch ends up closing the listing before
"     the user sees it.
"
" (3) Using `:echoerr`
"
"     This works, but presents to the user as an exception (see `:h :echoerr`).
"
function! s:error(message) abort
  call inputsave()
  echohl ErrorMsg
  call input(a:message . ': press ENTER to continue')
  echohl NONE
  call inputrestore()
  echo
endfunction

" Parses arguments, extracting a search pattern (which is stored in
" g:ferret_lastsearch) and escaping space-delimited arguments for use by
" `system()`. A string containing all the escaped arguments is returned.
"
" The basic strategy is to split on spaces, expand wildcards for non-option
" arguments, shellescape each word, and join.
"
" To support an edge-case (the ability to search for strings with spaces in
" them, however, we swap out escaped spaces first (subsituting the unlikely
" "<!!S!!>") and then swap them back in at the end. This allows us to perform
" searches like:
"
"   :Ack -i \bFoo_?Bar\b
"   :Ack that's\ nice\ dear
"
" and so on...
function! s:parse(arg) abort
  if exists('g:ferret_lastsearch')
    unlet g:ferret_lastsearch
  endif

  let l:escaped_spaces_replaced_with_markers=substitute(a:arg, '\\ ', '<!!S!!>', 'g')
  let l:split_on_spaces=split(l:escaped_spaces_replaced_with_markers)
  let l:expanded_args=[]

  for l:arg in l:split_on_spaces
    if l:arg =~# '^-'
      " Options get passed through as-is.
      call add(l:expanded_args, l:arg)
    elseif exists('g:ferret_lastsearch')
      let l:file_args=glob(l:arg, 1, 1) " Ignore 'wildignore', return a list.
      if len(l:file_args)
        call extend(l:expanded_args, l:file_args)
      else
        " Let through to `ag`/`ack`/`grep`, which will throw ENOENT.
        call add(l:expanded_args, l:arg)
      endif
    else
      " First non-option arg is considered to be search pattern.
      let g:ferret_lastsearch=substitute(l:arg, '<!!S!!>', ' ', 'g')
      call add(l:expanded_args, l:arg)
    endif
  endfor

  let l:each_word_shell_escaped=map(l:expanded_args, 'shellescape(v:val)')
  let l:joined=join(l:each_word_shell_escaped)
  return substitute(l:joined, '<!!S!!>', ' ', 'g')
endfunction

function! ferret#private#post(type) abort
  if has('autocmd')
    augroup FerretPostQF
      autocmd!
    augroup END
  endif

  let l:lastsearch = get(g:, 'ferret_lastsearch', '')
  let l:qflist = a:type == 'qf' ? getqflist() : getloclist(0)
  let l:tip = ' [see `:help ferret-quotes`]'
  if len(l:qflist) == 0
    let l:base = 'No results for search pattern `' . l:lastsearch . '`'

    " Search pattern has no spaces and is entirely enclosed in quotes;
    " eg 'foo' or "bar"
    if l:lastsearch =~ '\v^([' . "'" . '"])[^ \1]+\1$'
      call s:error(l:base . l:tip)
    else
      call s:error(l:base)
    endif
  else
    " Find any "invalid" entries in the list.
    let l:invalid = filter(copy(l:qflist), 'v:val.valid == 0')
    if len(l:invalid) == len(l:qflist)
      " Every item in the list was invalid.
      redraw!
      echohl ErrorMsg
      for l:item in l:invalid
        echomsg l:item.text
      endfor
      echohl NONE

      let l:base = 'Search for `' . l:lastsearch . '` failed'

      " When using vim-dispatch, the messages printed above get cleared, so the
      " only way to see them is with `:messages`.
      let l:suffix = a:type == 'qf' && s:dispatch() ?
            \ ' (run `:messages` to see details)' :
            \ ''

      " If search pattern looks like `'foo` or `"bar`, it means the user
      " probably tried to search for 'foo bar' or "bar baz" etc.
      if l:lastsearch =~ '\v^[' . "'" . '"].+[^' . "'" . '"]$'
        call s:error(l:base . l:tip . l:suffix)
      else
        call s:error(l:base . l:suffix)
      endif
    endif
  endif
endfunction

function! ferret#private#ack(command) abort
  let l:command=s:parse(a:command)
  call ferret#private#hlsearch()

  if empty(&grepprg)
    return
  endif

  " Prefer vim-dispatch unless otherwise instructed.
  if s:dispatch()
    if has('autocmd')
      augroup FerretPostQF
        autocmd!
        autocmd QuickfixCmdPost cgetfile call ferret#private#post('qf')
      augroup END
    endif
    let l:original_makeprg=&l:makeprg
    let l:original_errorformat=&l:errorformat
    try
      let &l:makeprg=&grepprg . ' ' . l:command
      let &l:errorformat=&grepformat
      Make
    catch
      if has('autocmd')
        augroup! FerretPostQF
      endif
    finally
      let &l:makeprg=l:original_makeprg
      let &l:errorformat=l:original_errorformat
    endtry
  else
    cexpr system(&grepprg . ' ' . l:command)
    execute get(g:, 'FerretQFHandler', 'botright cwindow')
    call ferret#private#post('qf')
  endif
endfunction

function! ferret#private#lack(command) abort
  let l:command=s:parse(a:command)
  call ferret#private#hlsearch()

  if empty(&grepprg)
    return
  endif

  lexpr system(&grepprg . ' ' . l:command)
  execute get(g:, 'FerretLLHandler', 'lwindow')
  call ferret#private#post('location')
endfunction

function! ferret#private#hlsearch() abort
  if has('extra_search')
    let l:hlsearch=get(g:, 'FerretHlsearch', &hlsearch)
    if l:hlsearch
      let @/=g:ferret_lastsearch
      call feedkeys(":let &hlsearch=1 | echo \<CR>", 'n')
    endif
  endif
endfunction

" Run the specified substitution command on all the files in the quickfix list
" (mnemonic: "Ack substitute").
"
" Specifically, the sequence:
"
"   :Ack foo
"   :Acks /foo/bar/
"
" is equivalent to:
"
"   :Ack foo
"   :Qargs
"   :argdo %s/foo/bar/ge | update
"
" (Note: there's nothing specific to Ack in this function; it's just named this
" way for mnemonics, as it will most often be preceded by an :Ack invocation.)
function! ferret#private#acks(command) abort
  " Accept any pattern allowed by E146 (crude sanity check).
  let l:matches = matchlist(a:command, '\v\C^(([^|"\\a-zA-Z0-9]).+\2.*\2)([cgeiI]*)$')
  if !len(l:matches)
    echoerr 'Ferret: Expected a substitution expression (/foo/bar/); got: ' . a:command
    return
  endif

  " Pass through options `c`, `i`/`I` to `:substitute`.
  " Add options `e` and `g` if not already present.
  let l:pattern = l:matches[1]
  let l:options = l:matches[3]
  if l:options !~# 'e'
    let l:options .= 'e'
  endif
  if l:options !~# 'g'
    let l:options .= 'g'
  endif

  let l:filenames=ferret#private#qargs()
  if l:filenames ==# ''
    echoerr 'Ferret: Quickfix filenames must be present, but there are none'
    return
  endif

  execute 'args' l:filenames

  if v:version > 703 || v:version == 703 && has('patch438')
    silent doautocmd <nomodeline> User FerretWillWrite
  else
    silent doautocmd User FerretWillWrite
  endif
  execute 'argdo' '%s' . l:pattern . l:options . ' | update'
  if v:version > 703 || v:version == 703 && has('patch438')
    silent doautocmd <nomodeline> User FerretDidWrite
  else
    silent doautocmd User FerretDidWrite
  endif

endfunction

" Populate the :args list with the filenames currently in the quickfix window.
function! ferret#private#qargs() abort
  let l:buffer_numbers={}
  for l:item in getqflist()
    let l:buffer_numbers[l:item['bufnr']]=bufname(l:item['bufnr'])
  endfor
  return join(map(values(l:buffer_numbers), 'fnameescape(v:val)'))
endfunction

" Visual mode deletion and `dd` mapping (special case).
function! ferret#private#qf_delete() range
  call s:delete(a:firstline, a:lastline)
endfunction

" Motion-based deletion from quickfix listing.
function! ferret#private#qf_delete_motion(type, ...)
  " Save.
  let l:selection=&selection
  let &selection='inclusive'

  let l:firstline=line("'[")
  let l:lastline=line("']")
  call s:delete(l:firstline, l:lastline)

  " Restore.
  let &selection=l:selection
endfunction
