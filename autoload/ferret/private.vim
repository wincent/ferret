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

  " Go to next entry.
  execute 'cc ' . a:first

  " Move focus back to quickfix listing.
  execute "normal \<C-W>\<C-P>"
endfunction

" Returns 1 if we should/can use vim-dispatch.
function! ferret#private#dispatch() abort
  let l:dispatch=get(g:, 'FerretDispatch', 1)
  return l:dispatch && exists(':Make') == 2
endfunction

" Returns 1 if we can use Vim's built-in async primitives.
function! ferret#private#async()
  let l:async=get(g:, 'FerretJob', 1)

  " Nothing special about 1829; it's just the version I am testing with as I
  " write this.
  return l:async && has('patch-7-4-1829')
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
function! ferret#private#error(message) abort
  call inputsave()
  echohl ErrorMsg
  unsilent call input(a:message . ': press ENTER to continue')
  echohl NONE
  call inputrestore()
  unsilent echo
  redraw!
endfunction

" Parses arguments, extracting a search pattern (which is stored in
" g:ferret_lastsearch) and escaping space-delimited arguments for use by
" `system()`. A string containing all the escaped arguments is returned.
function! s:parse(args) abort
  if exists('g:ferret_lastsearch')
    unlet g:ferret_lastsearch
  endif

  let l:expanded_args=[]

  for l:arg in a:args
    if ferret#private#option(l:arg)
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
      let g:ferret_lastsearch=l:arg
      call add(l:expanded_args, l:arg)
    endif
  endfor

  if ferret#private#async()
    return l:expanded_args
  endif

  let l:each_word_shell_escaped=map(l:expanded_args, 'shellescape(v:val)')
  let l:joined=join(l:each_word_shell_escaped)
  return escape(l:joined, '<>#')
endfunction

function! ferret#private#clearautocmd() abort
  if has('autocmd')
    augroup FerretPostQF
      autocmd!
    augroup END
  endif
endfunction

function! ferret#private#post(type) abort
  call ferret#private#clearautocmd()
  let l:lastsearch = get(g:, 'ferret_lastsearch', '')
  let l:qflist = a:type == 'qf' ? getqflist() : getloclist(0)
  let l:tip = ' [see `:help ferret-quotes`]'
  if len(l:qflist) == 0
    let l:base = 'No results for search pattern `' . l:lastsearch . '`'

    " Search pattern has no spaces and is entirely enclosed in quotes;
    " eg 'foo' or "bar"
    if l:lastsearch =~ '\v^([' . "'" . '"])[^ \1]+\1$'
      call ferret#private#error(l:base . l:tip)
    else
      call ferret#private#error(l:base)
    endif
  else
    " Find any "invalid" entries in the list.
    let l:invalid = filter(copy(l:qflist), 'v:val.valid == 0')
    if len(l:invalid) == len(l:qflist)
      " Every item in the list was invalid.
      redraw!
      echohl ErrorMsg
      for l:item in l:invalid
        unsilent echomsg l:item.text
      endfor
      echohl NONE

      let l:base = 'Search for `' . l:lastsearch . '` failed'

      " When using vim-dispatch, the messages printed above get cleared, so the
      " only way to see them is with `:messages`.
      let l:suffix = a:type == 'qf' && ferret#private#dispatch() ?
            \ ' (run `:messages` to see details)' :
            \ ''

      " If search pattern looks like `'foo` or `"bar`, it means the user
      " probably tried to search for 'foo bar' or "bar baz" etc.
      if l:lastsearch =~ '\v^[' . "'" . '"].+[^' . "'" . '"]$'
        call ferret#private#error(l:base . l:tip . l:suffix)
      else
        call ferret#private#error(l:base . l:suffix)
      endif
    endif
  endif
endfunction

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

function! ferret#private#ack(...) abort
  let l:command=s:parse(a:000)
  call ferret#private#hlsearch()

  if empty(&grepprg)
    return
  endif

  " Prefer built-in async, then vim-dispatch unless otherwise instructed.
  if ferret#private#async()
    call ferret#private#async#search(l:command, 1)
  elseif ferret#private#dispatch()
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
      call ferret#private#clearautocmd()
    finally
      let &l:makeprg=l:original_makeprg
      let &l:errorformat=l:original_errorformat
    endtry
  else
    let l:output=system(&grepprg . ' ' . l:command)
    call s:finalize_search(l:output, 1)
  endif
endfunction

function! ferret#private#lack(...) abort
  let l:command=s:parse(a:000)
  call ferret#private#hlsearch()

  if empty(&grepprg)
    return
  endif

  if ferret#private#async()
    call ferret#private#async#search(l:command, 0)
  else
    let l:output=system(&grepprg . ' ' . l:command)
    call s:finalize_search(l:output, 0)
  endif
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
    call ferret#private#error(
          \ 'Ferret: Expected a substitution expression (/foo/bar/); got: ' .
          \ a:command
          \ )
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
    call ferret#private#error(
          \ 'Ferret: Quickfix filenames must be present, but there are none ' .
          \ '(must use :Ack to find files before :Acks can be used)'
          \ )
    return
  endif

  execute 'args' l:filenames

  call ferret#private#autocmd('FerretWillWrite')
  execute 'argdo' '%s' . l:pattern . l:options . ' | update'
  call ferret#private#autocmd('FerretDidWrite')
endfunction

function! ferret#private#autocmd(cmd) abort
  if v:version > 703 || v:version == 703 && has('patch438')
    execute 'silent doautocmd <nomodeline> User ' . a:cmd
  else
    execute 'silent doautocmd User ' . a:cmd
  endif
endfunction

" Split on spaces, but not backslash-escaped spaces.
function! s:split(str) abort
  " Regular expression cheatsheet:
  "
  "   \%(...\)    Non-capturing subgroup.
  "   \@<!        Zero-width negative lookbehind (like Perl `(?<!pattern)`).
  "   \+          + (backslash needed due to Vim's "nomagic").
  "   \|          + (backslash needed due to Vim's "nomagic").
  "   \zs         Start match here.
  "
  " So, broken down, this means:
  "
  " - Split on any space not preceded by...
  " - a backslash at the start of the string or...
  " - a backslash preceded by a non-backslash character.
  " - Keep the separating whitespace at the end of each string
  "   (allows callers to track position within overall string).
  "
  return split(a:str, '\%(\%(\%(^\|[^\\]\)\\\)\@<!\s\)\+\zs')
endfunction

function! ferret#private#ackcomplete(arglead, cmdline, cursorpos) abort
  return ferret#private#complete('Ack', a:arglead, a:cmdline, a:cursorpos)
endfunction

function! ferret#private#lackcomplete(arglead, cmdline, cursorpos) abort
  return ferret#private#complete('Lack', a:arglead, a:cmdline, a:cursorpos)
endfunction

if executable('ag')
  let s:executable='ag'
elseif executable('ack')
  let s:executable='ack'
elseif executable('grep')
  let s:executable='grep'
else
  let s:executable=''
endif

let s:options = {
      \   'ack': [
      \     '--ignore-ack-defaults',
      \     '--ignore-case',
      \     '--ignore-dir',
      \     '--ignore-directory',
      \     '--invert-match',
      \     '--known-types',
      \     '--literal',
      \     '--no-recurse',
      \     '--recurse',
      \     '--sort-files',
      \     '--type',
      \     '--word-regexp',
      \     '-1',
      \     '-Q',
      \     '-R',
      \     '-i',
      \     '-k',
      \     '-r',
      \     '-v',
      \     '-w',
      \   ],
      \   'ag': [
      \     '--all-types',
      \     '--all-text',
      \     '--case-sensitive',
      \     '--depth',
      \     '--follow',
      \     '--ignore',
      \     '--ignore-case',
      \     '--ignore-dir',
      \     '--invert-match',
      \     '--literal',
      \     '--max-count',
      \     '--skip-vcs-ignores',
      \     '--unrestricted',
      \     '--word-regexp',
      \     '-Q',
      \     '-U',
      \     '-a',
      \     '-i',
      \     '-m',
      \     '-s',
      \     '-t',
      \     '-u',
      \     '-v',
      \     '-w'
      \   ]
      \ }

" We provide our own custom command completion because the default
" -complete=file completion will expand special characters in the pattern (like
" "#") before we get a chance to see them, breaking the search. As a bonus, this
" means we can provide option completion for `ack` and `ag` options as well.
function! ferret#private#complete(cmd, arglead, cmdline, cursorpos) abort
  let l:args=s:split(a:cmdline[:a:cursorpos])

  let l:command_seen=0
  let l:pattern_seen=0
  let l:position=0

  for l:arg in l:args
    let l:position=l:position + len(l:arg)
    let l:stripped=substitute(l:arg, '\s\+$', '', '')

    if ferret#private#option(l:stripped)
      if a:cursorpos <= l:position
        let l:options=get(s:options, s:executable, [])
        return filter(l:options, 'match(v:val, l:stripped) == 0')
      endif
    elseif l:pattern_seen
      if a:cursorpos <= l:position
        " Assume this is a filename, and it's the one we're trying to complete.
        " Do -complete=file style completion.
        return glob(a:arglead . '*', 1, 1)
      end
    elseif l:command_seen
      " Let the pattern through unaltered.
      let l:pattern_seen=1
    elseif l:stripped ==# a:cmd
      let l:command_seen=1
    else
      " Haven't seen command yet, this must be a range or a count.
      " (Not valid, but nothing we can do about it here).
    end
  endfor

  " Didn't get to a filename; nothing to complete.
  return []
endfunction

" Returns true (1) if `str` looks like a command-line option.
function! ferret#private#option(str) abort
  return a:str =~# '^-'
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
