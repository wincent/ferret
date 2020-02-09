" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

function! s:is_quickfix()
  if exists('*getwininfo')
    let l:info=getwininfo(win_getid())[0]
    return l:info.quickfix && !l:info.loclist
  else
    " On old Vim, degrade such that we at least handle the common case (ie.
    " quickfix windows).
    return 1
  endif
endfunction

" Remove lines a:first through a:last from the quickfix listing.
function! s:delete(first, last)
  let l:type=s:is_quickfix() ? 'qf' : 'location'
  let l:list=l:type == 'qf' ? getqflist() : getloclist(0)
  let l:line=a:first

  while l:line >= a:first && l:line <= a:last
    " Non-dictionary items will be ignored. This effectively deletes the line.
    let l:list[l:line - 1]=0
    let l:line=l:line + 1
  endwhile

  " Update listing and go to next entry.
  if l:type ==# 'qf'
    call setqflist(l:list, 'r')
    execute 'cc ' . a:first
  else
    call setloclist(0, l:list, 'r')
    execute 'll ' . a:first
  endif

  " Move focus back to listing.
  execute "normal! \<C-W>\<C-P>"
endfunction

" Returns 1 if we should use Neovim's |job-control| features.
function! ferret#private#nvim()
  ""
  " @option g:FerretNvim boolean 1
  "
  " Controls whether to use Neovim's |job-control| features, when
  " available, to run searches asynchronously. To prevent this from
  " being used, set to 0, in which case Ferret will fall back to the next
  " method in the list (Vim's built-in async primitives -- see
  " |g:FerretJob| -- which are typically not available in Neovim, so
  " will then fall back to the next available method).
  "
  " ```
  " let g:FerretNvim=0
  " ```
  let l:nvim=get(g:, 'FerretNvim', 1)

  return l:nvim && has('nvim')
endfunction

" Returns 1 if we can use Vim's built-in async primitives.
function! ferret#private#async()
  ""
  " @option g:FerretJob boolean 1
  "
  " Controls whether to use Vim's |+job| feature, when available, to run
  " searches asynchronously. To prevent |+job| from being used, set to 0, in
  " which case Ferret will fall back to the next available method.
  "
  " ```
  " let g:FerretJob=0
  " ```
  let l:async=get(g:, 'FerretJob', 1)

  " Nothing special about 1829; it's just the version I am testing with as I
  " write this.
  return l:async && has('patch-7-4-1829')
endfunction

function! ferret#private#error(message) abort
  if has('lambda') && has('timers')
    call timer_start(100, {-> s:print_error_with_echomsg(a:message)})
  else
    " Use `input()` to show error output to user. Ideally, we would do this
    " in a way that didn't require user interaction, but this is the only
    " reliable mechanism that works for all cases. Alternatives considered:
    "
    " (1) Using straight `:echomsg`
    "
    "     The screen gets cleared before the user sees it, even with a
    "     pre-emptive `:redraw!` beforehand. Note that we can get the
    "     message to linger on the screen by making it multi-line and
    "     forcing Vim to show a prompt (see `:h hit-enter-prompt`), but
    "     this is not reliable because the number of lines required to
    "     force the prompt will vary by system, depending on the value
    "     of `'cmdheight'`.
    "
    " (2) Using `:echoerr`
    "
    "     This works, but presents to the user as an exception (see `:h
    "     :echoerr`).
    "
    call inputsave()
    echohl ErrorMsg
    unsilent call input(a:message . ': press ENTER to continue')
    echohl NONE
    call inputrestore()
    unsilent echo
    redraw!
  endif
endfunction

function! s:print_error_with_echomsg(message)
  redraw!
  echohl ErrorMsg
  echomsg a:message
  echohl NONE
endfunction

" Parses arguments, extracting a search pattern (which is stored in
" g:ferret_lastsearch) and escaping space-delimited arguments for use by
" `system()`. A string containing all the escaped arguments is returned.
function! s:parse(args) abort
  if exists('g:ferret_lastsearch')
    unlet g:ferret_lastsearch
  endif

  " Split on unescaped spaces:
  "
  "   foo bar     -> [foo, bar]
  "   foo\ bar    -> [foo\ bar] (no split)
  "   foo\\ bar   -> [foo\\, bar]
  "   foo\\\ bar  -> [foo\\\ bar] (no split)
  "   foo\\\\ bar -> [foo\\\\, bar]
  "
  " We build a regex for this as follows:
  "
  "   - match an odd number of "X": X(XX)*
  "   - add negative lookbehind (don't match after an "X"): X\@<!X(XX)*
  "   - with whitespace (for readability): X \@<! X(XX)*
  "   - add negative lookahead (don't match before an "X"): X\@<!X(XX)*X\@!
  "   - with whitespace: X \@<! X(XX)* X\@!
  "   - denote this "..."
  "   - match a "Y" not preceded by the above: (...)\@<!Y
  "   - with whitespace: (...) \@<! Y
  "   - replace "..." with actual pattern: (X\@<!X(XX)*X\@!)\@<!Y
  "   - escape ( and ): \(X\@<!X\(XX\)*X\@!\)\@<!Y
  "   - replace "X" with "\\": \(\\\@<!\\\(\\\\\)*\\\@!\)\@<!Y
  "   - replace "Y" with " ": '\(\\\@<!\\\(\\\\\)*\\\@!\)\@<! '
  "
  let l:odd_number_of_backslashes='\\\@<!\\\(\\\\\)*\\\@!'
  let l:unescaped_space='\('.l:odd_number_of_backslashes.'\)\@<! '
  let l:args=split(a:args, l:unescaped_space)
  let l:expanded_args=[]

  for l:arg in l:args
    " Because we split on unescaped spaces, we know any escaped spaces remaining
    " inside arguments really are supposed to be just spaces.
    let l:arg=substitute(l:arg, '\\ ', ' ', 'g')

    if ferret#private#option(l:arg)
      " Options get passed through as-is.
      call add(l:expanded_args, l:arg)
    elseif exists('g:ferret_lastsearch')
      let l:file_args=glob(l:arg, 1, 1) " Ignore 'wildignore', return a list.
      if len(l:file_args)
        call extend(l:expanded_args, l:file_args)
      else
        " Let through to `rg`/`ag`/`ack`/`ack-grep`, which will throw ENOENT.
        call add(l:expanded_args, l:arg)
      endif
    else
      " First non-option arg is considered to be search pattern.
      let g:ferret_lastsearch=l:arg
      call add(l:expanded_args, l:arg)
    endif
  endfor

  if ferret#private#nvim() || ferret#private#async()
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

function! s:qfsize(type) abort
  if has('patch-8.0.1112')
    if a:type ==# 'qf'
      return get(getqflist({'size' : 0}), 'size', 0)
    else
      return get(getloclist(0, {'size' : 0}), 'size', 0)
    endif
  else
    let l:qflist=a:type ==# 'qf' ? getqflist() : getloclist(0)
    return len(l:qflist)
  endif
endfunction

function! ferret#private#post(type) abort
  call ferret#private#clearautocmd()
  let l:lastsearch=get(g:, 'ferret_lastsearch', '')
  let l:tip=' [see `:help ferret-quotes`]'
  let l:len=s:qfsize(a:type)
  if l:len == 0
    let l:base='No results for search pattern `' . l:lastsearch . '`'

    " Search pattern has no spaces and is entirely enclosed in quotes;
    " eg 'foo' or "bar"
    if l:lastsearch =~ '\v^([' . "'" . '"])[^ \1]+\1$'
      call ferret#private#error(l:base . l:tip)
    else
      call ferret#private#error(l:base)
    endif
  else
    " Find any "invalid" entries in the list.
    let l:qflist=a:type ==# 'qf' ? getqflist() : getloclist(0)
    let l:invalid=filter(copy(l:qflist), 'v:val.valid == 0')
    if len(l:invalid) == l:len
      " Every item in the list was invalid.
      redraw!
      echohl ErrorMsg
      for l:item in l:invalid
        unsilent echomsg l:item.text
      endfor
      echohl NONE

      let l:base='Search for `' . l:lastsearch . '` failed'

      " If search pattern looks like `'foo` or `"bar`, it means the user
      " probably tried to search for 'foo bar' or "bar baz" etc.
      if l:lastsearch =~ '\v^[' . "'" . '"].+[^' . "'" . '"]$'
        call ferret#private#error(l:base . l:tip)
      else
        call ferret#private#error(l:base)
      endif
    endif
  endif
  return l:len
endfunction

function! ferret#private#ack(bang, args) abort
  let l:command=s:parse(a:args)
  call ferret#private#hlsearch()

  let l:executable=ferret#private#executable()
  if empty(l:executable)
    call ferret#private#installprompt()
    return
  endif

  if ferret#private#nvim()
    call ferret#private#nvim#search(l:command, 1, a:bang)
  elseif ferret#private#async()
    call ferret#private#async#search(l:command, 1, a:bang)
  else
    call ferret#private#vanilla#search(l:command, 1)
  endif
endfunction

function! ferret#private#buflist() abort
  let l:buflist=getbufinfo({'buflisted': 1})
  let l:bufpaths=filter(map(l:buflist, 'v:val.name'), 'v:val !=# ""')
  return join(l:bufpaths, ' ')
endfunction

function! ferret#private#back(bang, args) abort
  call call('ferret#private#ack', [a:bang, a:args . ' ' . ferret#private#buflist()])
endfunction

function! ferret#private#black(bang, args) abort
  call call('ferret#private#lack', [a:bang, a:args . ' ' . ferret#private#buflist()])
endfunction

function! ferret#private#quack(bang, args) abort
  if s:qfsize('qf') == 0
    call ferret#private#error('Cannot search in empty quickfix list')
  else
    call call('ferret#private#ack', [a:bang, a:args . ' ' . ferret#private#args('qf')])
  endif
endfunction

function! ferret#private#installprompt() abort
  call ferret#private#error(
        \   'Unable to find suitable executable; install rg, ag, ack or ack-grep'
        \ )
endfunction

function! ferret#private#lack(bang, args) abort
  let l:command=s:parse(a:args)
  call ferret#private#hlsearch()

  let l:executable=ferret#private#executable()
  if empty(l:executable)
    call ferret#private#installprompt()
    return
  endif

  if ferret#private#nvim()
    call ferret#private#nvim#search(l:command, 0, a:bang)
  elseif ferret#private#async()
    call ferret#private#async#search(l:command, 0, a:bang)
  else
    call ferret#private#vanilla#search(l:command, 0)
  endif
endfunction

function! ferret#private#hlsearch() abort
  if has('extra_search')
    ""
    " @option g:FerretHlsearch boolean
    "
    " Controls whether Ferret should attempt to highlight the search pattern
    " when running |:Ack| or |:Lack|. If left unset, Ferret will respect the
    " current 'hlsearch' setting. To force highlighting on or off irrespective
    " of 'hlsearch', set |g:FerretHlsearch| to 1 (on) or 0 (off):
    "
    " ```
    " let g:FerretHlsearch=0
    " ```
    let l:hlsearch=get(g:, 'FerretHlsearch', &hlsearch)
    if l:hlsearch && exists('g:ferret_lastsearch')
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
" is equivalent to the following prior to Vim 8:
"
"   :Ack foo
"   :Qargs
"   :argdo %substitute/foo/bar/ge | update
"
" and the following on Vim 8 or after:
"
"   :Ack foo
"   :cdo substitute/foo/bar/ge | update
"
" Note that if |g:FerretAcksCommand| is set to "cfdo" then this will be used
" instead:
"
"   :Ack foo
"   :cfdo %substitute/foo/bar/ge | update
"
" (Note: there's nothing specific to Ack in this function; it's just named this
" way for mnemonics, as it will most often be preceded by an :Ack invocation.)
function! ferret#private#acks(command, type) abort
  " Accept any pattern allowed by E146 (crude sanity check).
  let l:matches=matchlist(a:command, '\v\C^\s*(([^|"\\a-zA-Z0-9]).+\2.*\2)([cgeiI]*)\s*$')
  if !len(l:matches)
    call ferret#private#error(
          \ 'Ferret: Expected a substitution expression (/foo/bar/); got: ' .
          \ a:command
          \ )
    return
  endif

  " Pass through options `c`, `i`/`I` to `:substitute`.
  " Add options `e`, and `g` (if appropriate), if not already present.
  let l:pattern=l:matches[1]
  let l:options=l:matches[3]
  if l:options !~# 'e'
    let l:options.='e'
  endif
  if !&gdefault
    if l:options !~# 'g'
      let l:options.='g'
    else
      " Make sure there is exactly one 'g' flag present, otherwise an even
      " number of 'g' flags will actually cancel each other out.
      let l:options=substitute(l:options, 'g', '', 'g') . 'g'
    endif
  elseif &gdefault && l:options =~# 'g'
    " 'gdefault' inverts the meaning of the 'g' flag, so we must strip it.
    let l:options=substitute(l:options, 'g', '', 'g')
  endif

  let l:cdo=has('listcmds') && exists(':cdo') == 2
  if !l:cdo
    let l:filenames=ferret#private#args(a:type)
    if l:filenames ==# ''
      call ferret#private#error(
            \ 'Ferret: Quickfix filenames must be present, but there are none ' .
            \ '(must use :Ack to find files before :Acks can be used)'
            \ )
      return
    endif
    execute 'args' l:filenames
  endif

  call ferret#private#autocmd('FerretWillWrite')

  if l:cdo
    if a:type == 'qf'
      ""
      " @option g:FerretAcksCommand string "cdo"
      "
      " Controls the underlying Vim command that |:Acks| uses to peform
      " substitutions. On versions of Vim that have it, defaults to |:cdo|, which
      " means that substitutions will apply to the specific lines currently in the
      " |quickfix| listing. Can be set to "cfdo" to instead use |:cfdo| (if
      " available), which means that the substitutions will be applied on a
      " per-file basis to all the files in the |quickfix| listing. This
      " distinction is important if you have used Ferret's bindings to delete
      " entries from the listing.
      "
      " ```
      " let g:FerretAcksCommand='cfdo'
      " ```
      "
      if get(g:, 'FerretAcksCommand', 'cdo') == 'cfdo'
        let l:command='cfdo'
        let l:substitute='%substitute'
      else
        let l:command='cdo'
        let l:substitute='substitute'
      endif
    else
      ""
      " @option g:FerretLacksCommand string "ldo"
      "
      " Controls the underlying Vim command that |:Lacks| uses to peform
      " substitutions. On versions of Vim that have it, defaults to |:ldo|, which
      " means that substitutions will apply to the specific lines currently in the
      " |location-list|. Can be set to "lfdo" to instead use |:lfdo| (if
      " available), which means that the substitutions will be applied on a
      " per-file basis to all the files in the |location-list|. This
      " distinction is important if you have used Ferret's bindings to delete
      " entries from the listing.
      "
      " ```
      " let g:FerretLacksCommand='lfdo'
      " ```
      "
      if get(g:, 'FerretLacksCommand', 'ldo') == 'lfdo'
        let l:command='lfdo'
        let l:substitute='%substitute'
      else
        let l:command='ldo'
        let l:substitute='substitute'
      endif
    endif
  else
    let l:command='argdo'
    let l:substitute='%substitute'
  endif

  execute l:command l:substitute . l:pattern . l:options . ' | update'

  call ferret#private#autocmd('FerretDidWrite')
endfunction

""
" @option g:FerretVeryMagic boolean 1
"
" Controls whether the |<Plug>(FerretAck)| mapping should populate the command
" line with the |/\v| "very magic" marker. Given that the argument passed to
" |:Acks| is handed straight to Vim, using "very magic" makes it more likely
" that the (probably Perl-compatible) regular expression used in the initial
" search can be used directly with Vim's (famously not-Perl-compatible) regular
" expression engine.
"
" To prevent the automatic use of |/\v|, set this option to 0:
"
" ```
" let g:FerretVeryMagic=0
" ```
function! ferret#private#acks_prompt() abort
  let l:magic=get(g:, 'FerretVeryMagic', 1)
  let l:mode=l:magic ? '\v' : ''
  if exists('g:ferret_lastsearch')
    return '/' . l:mode . g:ferret_lastsearch . '// '
  else
    return '/' . l:mode . '//'
  endif
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
  return ferret#private#complete('Ack', a:arglead, a:cmdline, a:cursorpos, 1)
endfunction

function! ferret#private#backcomplete(arglead, cmdline, cursorpos) abort
  return ferret#private#complete('Back', a:arglead, a:cmdline, a:cursorpos, 0)
endfunction

function! ferret#private#blackcomplete(arglead, cmdline, cursorpos) abort
  return ferret#private#complete('Black', a:arglead, a:cmdline, a:cursorpos, 0)
endfunction

function! ferret#private#lackcomplete(arglead, cmdline, cursorpos) abort
  return ferret#private#complete('Lack', a:arglead, a:cmdline, a:cursorpos, 1)
endfunction

function! ferret#private#quackcomplete(arglead, cmdline, cursorpos) abort
  return ferret#private#complete('Quack', a:arglead, a:cmdline, a:cursorpos, 0)
endfunction

" Return first word (the name of the binary) of the executable string.
function! ferret#private#executable_name()
  let l:executable=ferret#private#executable()
  return matchstr(l:executable, '\v\w+')
endfunction

let s:options={
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
      \   ],
      \   'rg': [
      \     '--case-sensitive',
      \     '--files-with-matches',
      \     '--follow',
      \     '--glob',
      \     '--hidden',
      \     '--ignore-case',
      \     '--invert-match',
      \     '--max-count',
      \     '--maxdepth',
      \     '--mmap',
      \     '--no-ignore',
      \     '--no-ignore-parent',
      \     '--no-ignore-vcs',
      \     '--no-mmap',
      \     '--regexp',
      \     '--smart-case',
      \     '--text',
      \     '--threads',
      \     '--type',
      \     '--type-not',
      \     '--unrestricted',
      \     '--word-regexp',
      \     '-F',
      \     '-L',
      \     '-R',
      \     '-T',
      \     '-a',
      \     '-e',
      \     '-g',
      \     '-i',
      \     '-j',
      \     '-m',
      \     '-s',
      \     '-t',
      \     '-u',
      \     '-v',
      \     '-w'
      \   ]
      \ }
let s:options['ack-grep']=s:options['ack']

" We provide our own custom command completion because the default
" -complete=file completion will expand special characters in the pattern (like
" "#") before we get a chance to see them, breaking the search. As a bonus, this
" means we can provide option completion for `ack`/`ack-grep`/`ag`/`rg` options
" as well.
function! ferret#private#complete(cmd, arglead, cmdline, cursorpos, files) abort
  let l:args=s:split(a:cmdline[:a:cursorpos])

  let l:command_seen=0
  let l:pattern_seen=0
  let l:position=0

  for l:arg in l:args
    let l:position=l:position + len(l:arg)
    let l:stripped=substitute(l:arg, '\s\+$', '', '')

    if ferret#private#option(l:stripped)
      if a:cursorpos <= l:position
        let l:options=get(s:options, ferret#private#executable_name(), [])
        return filter(l:options, 'match(v:val, l:stripped) == 0')
      endif
    elseif l:pattern_seen && a:files
      if a:cursorpos <= l:position
        " Assume this is a filename, and it's the one we're trying to complete.
        " Do -complete=file style completion.
        return map(glob(a:arglead . '*', 1, 1), 'isdirectory(v:val) ? v:val . "/" : v:val')
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

" Populate the :args list with the filenames currently in the quickfix window or
" location list.
function! ferret#private#args(type) abort
  let l:buffer_numbers={}
  let l:items=a:type == 'qf' ? getqflist() : getloclist(0)
  for l:item in l:items
    let l:number=l:item['bufnr']
    if !has_key(l:buffer_numbers, l:number)
      let l:buffer_numbers[l:number]=bufname(l:number)
    endif
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

""
" @option g:FerretExecutable string "rg,ag,ack,ack-grep"
"
" Ferret will preferentially use `rg`, `ag` and finally `ack`/`ack-grep` (in
" that order, using the first found executable), however you can force your
" preference for a specific tool to be used by setting an override in your
" |.vimrc|. Valid values are a comma-separated list of "rg", "ag", "ack" or
" "ack-grep". If no requested executable exists, Ferret will fall-back to the
" next in the default list.
"
" Example:
"
" ```
" " Prefer `ag` over `rg`.
" let g:FerretExecutable='ag,rg'
" ```
let s:force=get(g:, 'FerretExecutable', 'rg,ag,ack,ack-grep')

" Base set of default arguments for each executable; these get extended by
" ferret#private#init() upon startup.
let s:executables={
      \   'rg': '--vimgrep --no-heading',
      \   'ag': '',
      \   'ack': '--column --with-filename',
      \   'ack-grep': '--column --with-filename'
      \ }

let s:init_done=0

function! ferret#private#executables() abort
  return copy(s:executables)
endfunction

function! ferret#private#init() abort
  if s:init_done
    return
  endif

  if executable('rg')
    let l:rg_help=system('rg --help')
    if match(l:rg_help, '--no-config') != -1
      let s:executables['rg'].=' --no-config'
    endif
    if match(l:rg_help, '--max-columns') != -1
      let s:executables['rg'].=' --max-columns 4096'
    endif
  endif

  if executable('ag')
    let l:ag_help=system('ag --help')
    if match(l:ag_help, '--vimgrep') != -1
      let s:executables['ag'].='--vimgrep'
    else
      let s:executables['ag'].='--column'
    endif
    if match(l:ag_help, '--width') != -1
      let s:executables['ag'].=' --width 4096'
    endif
  endif

  let l:executable=ferret#private#executable()
  if !empty(l:executable)
    let &grepprg=l:executable
    let &grepformat=g:FerretFormat
  endif

  let s:init_done=1
endfunction

function! ferret#private#executable() abort
  let l:valid=keys(s:executables)
  let l:executables=split(s:force, '\v\s*,\s*')
  let l:executables=filter(l:executables, 'index(l:valid, v:val) != -1')
  if index(l:executables, 'rg') == -1
    call add(l:executables, 'rg')
  endif
  if index(l:executables, 'ag') == -1
    call add(l:executables, 'ag')
  endif
  if index(l:executables, 'ack') == -1
    call add(l:executables, 'ack')
  endif
  if index(l:executables, 'ack-grep') == -1
    call add(l:executables, 'ack-grep')
  endif
  for l:executable in l:executables
    if executable(l:executable)
      ""
      " @option g:FerretExecutableArguments dict {}
      "
      " Allows you to override the default arguments that get passed to the
      " underlying search executables. For example, to add `-s` to the default
      " arguments passed to `ack` (`--column --with-filename`):
      "
      " ```
      " let g:FerretExecutableArguments = {
      "   \   'ack': '--column --with-filename -s'
      "   \ }
      " ```
      "
      " To find out the default arguments for a given executable, see
      " |ferret#get_default_arguments()|.
      "
      let l:overrides=get(g:, 'FerretExecutableArguments', {})
      let l:type=exists('v:t_dict') ? v:t_dict : 4
      if type(l:overrides) == l:type && has_key(l:overrides, l:executable)
        return l:executable . ' ' . l:overrides[l:executable]
      else
        return l:executable . ' ' . s:executables[l:executable]
      endif
    endif
  endfor
  return ''
endfunction

function! ferret#private#limit() abort
  ""
  " @option g:FerretMaxResults number 100000
  "
  " Controls the maximum number of results Ferret will attempt to gather before
  " displaying the results. Note that this only applies when searching
  " asynchronously; that is, on recent versions of Vim with |+job| support and
  " when |g:FerretJob| is not set to 0.
  "
  " The intent of this option is to prevent runaway search processes that produce
  " huge volumes of output (for example, searching for a common string like "test"
  " inside a |$HOME| directory containing millions of files) from locking up Vim.
  "
  " In the event that Ferret aborts a search that has hit the |g:FerretMaxResults|
  " limit, a message will be printed prompting users to run the search again
  " with |:Ack!| or |:Lack!| if they want to bypass the limit.
  "
  return max([1, +get(g:, 'FerretMaxResults', 100000)]) - 1
endfunction

call ferret#private#init()
