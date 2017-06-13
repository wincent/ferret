" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

""
" @plugin ferret Ferret plug-in for Vim
"
" # Intro
"
" > "ferret (verb)<br />
" > (ferret something out) search tenaciously for and find something: she had
" > the ability to ferret out the facts."
"
"                                                               *ferret-features*
" Ferret improves Vim's multi-file search in four ways:
"
" ## 1. Powerful multi-file search
"
" Ferret provides an |:Ack| command for searching across multiple files using
" ripgrep (https://github.com/BurntSushi/ripgrep), The Silver Searcher
" (https://github.com/ggreer/the_silver_searcher), or Ack
" (http://beyondgrep.com/). Support for passing options through to the
" underlying search command exists, along with the ability to use full regular
" expression syntax without doing special escaping. On modern versions
" of Vim (version 8 or higher, or Neovim), searches are performed
" asynchronously (without blocking the UI).
"
" Shortcut mappings are provided to start an |:Ack| search (<leader>a) or to
" search for the word currently under the cursor (<leader>s).
"
" Results are normally displayed in the |quickfix| window, but Ferret also
" provides a |:Lack| command that behaves like |:Ack| but uses the
" |location-list| instead, and a <leader>l mapping as a shortcut to |:Lack|.
"
" |:Back| and |:Black| are analogous to |:Ack| and |:Lack|, but scoped to search
" within currently open buffers only.
"
" ## 2. Streamlined multi-file replace
"
" The companion to |:Ack| is |:Acks| (mnemonic: "Ack substitute", accessible via
" shortcut <leader>r), which allows you to run a multi-file replace across all
" the files placed in the |quickfix| window by a previous invocation of |:Ack|
" (or |:Back|).
"
" ## 3. Quickfix listing enhancements
"
" The |quickfix| listing itself is enhanced with settings to improve its
" usability, and natural mappings that allow quick removal of items from the
" list (for example, you can reduce clutter in the listing by removing lines
" that you don't intend to make changes to).
"
" Additionally, Vim's |:cn|, |:cp|, |:cnf| and |:cpf| commands are tweaked to
" make it easier to immediately identify matches by centering them within the
" viewport.
"
" ## 4. Easy operations on files in the quickfix listing
"
" Finally, Ferret provides a |:Qargs| command that puts the files currently in
" the |quickfix| listing into the |:args| list, where they can be operated on in
" bulk via the |:argdo| command. This is what's used under the covers on older
" versions of Vim by |:Acks| to do its work (on newer versions the built-in
" |:cfdo| is used instead).
"
"
" # Installation
"
" To install Ferret, use your plug-in management system of choice.
"
" If you don't have a "plug-in management system of choice", I recommend
" Pathogen (https://github.com/tpope/vim-pathogen) due to its simplicity and
" robustness. Assuming that you have Pathogen installed and configured, and that
" you want to install Ferret into `~/.vim/bundle`, you can do so with:
"
" ```
" git clone https://github.com/wincent/ferret.git ~/.vim/bundle/ferret
" ```
"
" Alternatively, if you use a Git submodule for each Vim plug-in, you could do
" the following after `cd`-ing into the top-level of your Git superproject:
"
" ```
" git submodule add https://github.com/wincent/ferret.git ~/vim/bundle/ferret
" git submodule init
" ```
"
" To generate help tags under Pathogen, you can do so from inside Vim with:
"
" ```
" :call pathogen#helptags()
" ```
"
" @mappings
"
" ## Circumstances where mappings do not get set up
"
" Note that Ferret will not try to set up the <leader> mappings if any of the
" following are true:
"
" - A mapping with the same |{lhs}| already exists.
" - An alternative mapping for the same functionality has already been set up
"   from a |.vimrc|.
" - The mapping has been suppressed by setting |g:FerretMap| to 1 in your
"   |.vimrc|.
"
" ## Mappings specific to the quickfix window
"
" Additionally, Ferret will set up special mappings in |quickfix| listings,
" unless prevented from doing so by |g:FerretQFMap|:
"
" - `d` (|visual-mode|): delete visual selection
" - `dd` (|Normal-mode|): delete current line
" - `d`{motion} (|Normal-mode|): delete range indicated by {motion}
"
"
" @footer
"
" # Custom autocommands
"
"                                                *FerretWillWrite* *FerretDidWrite*
" For maximum compatibility with other plug-ins, Ferret runs the following
" "User" autocommands before and after running the file writing operations
" during |:Acks|:
"
" - FerretWillWrite
" - FerretDidWrite
"
" For example, to call a pair of custom functions in response to these events,
" you might do:
"
" ```
" autocmd! User FerretWillWrite
" autocmd User FerretWillWrite call CustomWillWrite()
" autocmd! User FerretDidWrite
" autocmd User FerretDidWrite call CustomDidWrite()
" ```
"
"
" # Overrides
"
" Ferret overrides the 'grepformat' and 'grepprg' settings, preferentially
" setting `rg`, `ag`, `ack` or `ack-grep` as the 'grepprg' (in that order) and
" configuring a suitable 'grepformat'.
"
" Additionally, Ferret includes an |ftplugin| for the |quickfix| listing that
" adjusts a number of settings to improve the usability of search results.
"
" @indent
"                                                                 *ferret-nolist*
"   'nolist'
"
"   Turned off to reduce visual clutter in the search results, and because
"   'list' is most useful in files that are being actively edited, which is not
"   the case for |quickfix| results.
"
"                                                       *ferret-norelativenumber*
"   'norelativenumber'
"
"   Turned off, because it is more useful to have a sense of absolute progress
"   through the results list than to have the ability to jump to nearby results
"   (especially seeing as the most common operations are moving to the next or
"   previous file, which are both handled nicely by |:cnf| and |:cpf|
"   respectively).
"
"                                                                 *ferret-nowrap*
"   'nowrap'
"
"   Turned off to avoid ugly wrapping that makes the results list hard to read,
"   and because in search results, the most relevant information is the
"   filename, which is on the left and is usually visible even without wrapping.
"
"                                                                 *ferret-number*
"   'number'
"
"   Turned on to give a sense of absolute progress through the results.
"
"                                                              *ferret-scrolloff*
"   'scrolloff'
"
"   Set to 0 because the |quickfix| listing is usually small by default, so
"   trying to keep the current line away from the edge of the viewpoint is
"   futile; by definition it is usually near the edge.
"
"                                                           *ferret-nocursorline*
"   'nocursorline'
"
"   Turned off to reduce visual clutter.
"
" @dedent
"
" To prevent any of these |quickfix|-specific overrides from being set up, you
" can set |g:FerretQFOptions| to 0 in your |.vimrc|:
"
" ```
" let g:FerretQFOptions=0
" ```
"
"
" # Troubleshooting
"
"                                                                 *ferret-quotes*
" ## Ferret fails to find patterns containing spaces
"
" As described in the documentation for |:Ack|, the search pattern is passed
" through as-is to the underlying search command, and no escaping is required
" other than preceding spaces by a single backslash.
"
" So, to find "foo bar", you would search like:
"
" ```
" :Ack foo\ bar
" ```
"
" Unescaped spaces in the search are treated as argument separators, so a
" command like the following means pass the `-w` option through, search for
" pattern "foo", and limit search to the "bar" directory:
"
" ```
" :Ack -w foo bar
" ```
"
" Note that including quotes will not do what you intend.
"
" ```
" " Search for '"foo' in the 'bar"' directory:
" :Ack "foo bar"
"
" " Search for "'foo' in the "bar'" directory:
" :Ack 'foo bar'
" ```
"
" This approach to escaping is taken in order to make it straightfoward to use
" powerful Perl-compatible regular expression syntax in an unambiguous way
" without having to worry about shell escaping rules:
"
" ```
" :Ack \blog\((['"]).*?\1\) -i --ignore-dir=src/vendor src dist build
" ```
"
" # FAQ
"
" ## Why do Ferret commands start with "Ack", "Lack" and so on?
"
" Ferret was originally the thinnest of wrappers (7 lines of code in my
" |.vimrc|) around `ack`. The earliest traces of it can be seen in the initial
" commit to my dotfiles repo in May, 2009 (https://rfr.to/h).
"
" So, even though Ferret has a new name now and actually prefers `rg` then `ag`
" over `ack`/`ack-grep` when available, I prefer to keep the command names
" intact and benefit from years of accumulated muscle-memory.
"
"
" # Related
"
" Just as Ferret aims to improve the multi-file search and replace experience,
" Loupe does the same for within-file searching:
"
"   https://github.com/wincent/loupe
"
"
" # Website
"
" The official Ferret source code repo is at:
"
"   http://git.wincent.com/ferret.git
"
" A mirror exists at:
"
"   https://github.com/wincent/ferret
"
" Official releases are listed at:
"
"   http://www.vim.org/scripts/script.php?script_id=5220
"
"
" # License
"
" Copyright 2015-present Greg Hurrell. All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice,
"    this list of conditions and the following disclaimer.
"
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.
"
"
" # Development
"
" ## Contributing patches
"
" Patches can be sent via mail to greg@hurrell.net, or as GitHub pull requests
" at: https://github.com/wincent/ferret/pulls
"
" ## Cutting a new release
"
" At the moment the release process is manual:
"
" - Perform final sanity checks and manual testing
" - Update the |ferret-history| section of the documentation
" - Verify clean work tree:
"
" ```
" git status
" ```
"
" - Tag the release:
"
" ```
" git tag -s -m "$VERSION release" $VERSION
" ```
"
" - Publish the code:
"
" ```
" git push origin master --follow-tags
" git push github master --follow-tags
" ```
"
" - Produce the release archive:
"
" ```
" git archive -o ferret-$VERSION.zip HEAD -- .
" ```
"
" - Upload to http://www.vim.org/scripts/script.php?script_id=5220
"
"
" # Authors
"
" Ferret is written and maintained by Greg Hurrell <greg@hurrell.net>.
"
" Other contributors that have submitted patches include (in alphabetical
" order):
"
" - Daniel Silva
" - Filip Szymański
" - Joe Lencioni
" - Nelo-Thara Wallus
" - Tom Dooner
" - Vaibhav Sagar
"
"
" # History
"
" ## 3.0 (13 June 2017)
"
" - Improve handling of backslash escapes
"   (https://github.com/wincent/ferret/issues/41).
" - Add |g:FerretAutojump|.
" - Drop support for vim-dispatch.
"
" ## 2.0 (6 June 2017)
"
" - Add support for Neovim, along with |g:FerretNvim| setting.
"
" ## 1.5 "Cinco de Cuatro" (4 May 2017)
"
" - Improvements to the handling of very large result sets (due to wide lines or
"   many results).
" - Added |g:FerretLazyInit|.
" - Added missing documentation for |g:FerretJob|.
" - Added |g:FerretMaxResults|.
" - Added feature-detection for `rg` and `ag`, allowing Ferret to gracefully
"   work with older versions of those tools that do not support all desired
"   command-line switches.
"
" ## 1.4 (21 January 2017)
"
" - Drop broken support for `grep`, printing a prompt to install `rg`, `ag`, or
"   `ack`/`ack-grep` instead.
" - If an `ack` executable is not found, search for `ack-grep`, which is the
"   name used on Debian-derived distros.
"
" ## 1.3 (8 January 2017)
"
" - Reset |'errorformat'| before each search (fixes issue #31).
" - Added |:Back| and |:Black| commands, analogous to |:Ack| and |:Lack| but
"   scoped to search within currently open buffers only.
" - Change |:Acks| to use |:cfdo| when available rather than |:Qargs| and
"   |:argdo|, to avoid polluting the |arglist|.
" - Remove superfluous |QuickFixCmdPost| autocommands, resolving clash with
"   Neomake plug-in (patch from Tom Dooner, #36).
" - Add support for searching with ripgrep (`rg`).
"
" ## 1.2a (16 May 2016)
"
" - Add optional support for running searches asynchronously using Vim's |+job|
"   feature (enabled by default in sufficiently recent versions of Vim); see
"   |g:FerretJob|, |:FerretCancelAsync| and |:FerretPullAsync|.
"
" ## 1.1.1 (7 March 2016)
"
" - Fix another edge case when searching for patterns containing "#", only
"   manifesting under dispatch.vim.
"
" ## 1.1 (7 March 2016)
"
" - Fix edge case when searching for strings of the form "<foo>".
" - Fix edge case when searching for patterns containing "#" and "%".
" - Provide completion for `ag` and `ack` options when using |:Ack| and |:Lack|.
" - Fix display of error messages under dispatch.vim.
"
" ## 1.0 (28 December 2015)
"
" - Fix broken |:Qargs| command (patch from Daniel Silva).
" - Add |g:FerretQFHandler| and |g:FerretLLHandler| options (patch from Daniel
"   Silva).
" - Make |<Plug>| mappings accessible even |g:FerretMap| is set to 0.
" - Fix failure to report filename when using `ack` and explicitly scoping
"   search to a single file (patch from Daniel Silva).
" - When using `ag`, report multiple matches per line instead of just the first
"   (patch from Daniel Silva).
" - Improve content and display of error messages.
"
" ## 0.3 (24 July 2015)
"
" - Added highlighting of search pattern and related |g:FerretHlsearch| option
"   (patch from Nelo-Thara Wallus).
" - Add better error reporting for failed or incorrect searches.
"
" ## 0.2 (16 July 2015)
"
" - Added |FerretDidWrite| and |FerretWillWrite| autocommands (patch from Joe
"   Lencioni).
" - Add |<Plug>(FerretAcks)| mapping (patch from Nelo-Thara Wallus).
"
" ## 0.1 (8 July 2015)
"
" - Initial release, extracted from my dotfiles
"   (https://github.com/wincent/wincent).

""
" @option g:FerretLoaded any
"
" To prevent Ferret from being loaded, set |g:FerretLoaded| to any value in your
" |.vimrc|. For example:
"
" ```
" let g:FerretLoaded=1
" ```
if exists('g:FerretLoaded') || &compatible || v:version < 700
  finish
endif
let g:FerretLoaded = 1

" Temporarily set 'cpoptions' to Vim default as per `:h use-cpo-save`.
let s:cpoptions = &cpoptions
set cpoptions&vim

""
" @option g:FerretLazyInit boolean 1
"
" In order to minimize impact on Vim start-up time Ferret will initialize itself
" lazily on first use by default. If you wish to force immediate initialization
" (for example, to cause |'grepprg'| and |'grepformat'| to be set as soon as Vim
" launches), then set |g:FerretLazyInit| to 0 in your |.vimrc|:
"
" ```
" let g:FerrerLazyInit=0
" ```
if !get(g:, 'FerretLazyInit', 1)
  call ferret#private#init()
endif

""
" @command :Ack {pattern} {options}
"
" Searches for {pattern} in all the files under the current directory (see
" |:pwd|), unless otherwise overridden via {options}, and displays the results
" in the |quickfix| listing.
"
" `rg` (ripgrep) then `ag` (The Silver Searcher) will be used preferentially if
" present on the system, because they are faster, falling back to
" `ack`/`ack-grep` as needed.
"
" On newer versions of Vim (version 8 and above), the search process runs
" asynchronously in the background and does not block the UI.
"
" Asynchronous searches are preferred because they do not block, despite the
" fact that Vim itself is single threaded.
"
" The {pattern} is passed through as-is to the underlying search program, and no
" escaping is required other than preceding spaces by a single backslash. For
" example, to search for "\bfoo[0-9]{2} bar\b" (ie. using `ag`'s Perl-style
" regular expression syntax), you could do:
"
" ```
" :Ack \bfoo[0-9]{2}\ bar\b
" ```
"
" Likewise, {options} are passed through. In this example, we pass the `-w`
" option (to search on word boundaries), and scope the search to the "foo" and
" "bar" subdirectories: >
"
" ```
" :Ack -w something foo bar
" ```
"
" As a convenience <leader>a is set-up (|<Plug>(FerretAck)|) as a shortcut to
" enter |Cmdline-mode| with `:Ack` inserted on the |Cmdline|. Likewise <leader>s
" (|<Plug>(FerretAckWord)|) is a shortcut for running |:Ack| with the word
" currently under the cursor.
"
" @command :Ack! {pattern} {options}
"
" Like |:Ack|, but returns all results irrespective of the value of
" |g:FerretMaxResults|.
"
command! -bang -nargs=1 -complete=customlist,ferret#private#ackcomplete Ack call ferret#private#ack(<bang>0, <q-args>)

""
" @command :Lack {pattern} {options}
"
" Just like |:Ack|, but instead of using the |quickfix| listing, which is global
" across an entire Vim instance, it uses the |location-list|, which is a
" per-window construct.
"
" Note that |:Lack| always runs synchronously via |:cexpr|.
"
" @command :Lack! {pattern} {options}
"
" Like |:Lack|, but returns all results irrespective of the value of
" |g:FerretMaxResults|.
"
command! -bang -nargs=1 -complete=customlist,ferret#private#lackcomplete Lack call ferret#private#lack(<bang>0, <q-args>)

""
" @command :Back {pattern} {options}
"
" Like |:Ack|, but searches only listed buffers. Note that the search is still
" delegated to the underlying |'grepprg'| (`rg`, `ag`, `ack` or `ack-grep`),
" which means that only buffers written to disk will be searched. If no buffers
" are written to disk, then |:Back| behaves exactly like |:Ack| and will search
" all files in the current directory.
"
" @command :Back! {pattern} {options}
"
" Like |:Back|, but returns all results irrespective of the value of
" |g:FerretMaxResults|.
"
command! -bang -nargs=1 -complete=customlist,ferret#private#backcomplete Back call ferret#private#back(<bang>0, <q-args>)

""
" @command :Black {pattern} {options}
"
" Like |:Lack|, but searches only listed buffers. As with |:Back|, the search is
" still delegated to the underlying |'grepprg'| (`rg`, `ag`, `ack` or
" `ack-grep`), which means that only buffers written to disk will be searched.
" Likewise, If no buffers are written to disk, then |:Black| behaves exactly
" like |:Lack| and will search all files in the current directory.
"
" @command :Black! {pattern} {options}
"
" Like |:Black|, but returns all results irrespective of the value of
" |g:FerretMaxResults|.
"
command! -bang -nargs=1 -complete=customlist,ferret#private#blackcomplete Black call ferret#private#black(<bang>0, <q-args>)

""
" @command :Acks /{pattern}/{replacement}/
"
" Takes all of the files currently in the |quickfix| listing and performs a
" substitution of all instances of {pattern} (a standard Vim search |pattern|)
" by {replacement}.
"
" A typical sequence consists of an |:Ack| invocation to populate the |quickfix|
" listing and then |:Acks| (mnemonic: "Ack substitute") to perform replacements.
" For example, to replace "foo" with "bar" across all files in the current
" directory:
"
" ```
" :Ack foo
" :Acks /foo/bar/
" ```
command! -nargs=1 Acks call ferret#private#acks(<q-args>)
command! FerretCancelAsync call ferret#private#async#cancel()
command! FerretPullAsync call ferret#private#async#pull()

nnoremap <Plug>(FerretAck) :Ack<space>
nnoremap <Plug>(FerretLack) :Lack<space>
nnoremap <Plug>(FerretAckWord) :Ack <C-r><C-w><CR>
nnoremap <Plug>(FerretAcks)
      \ :Acks <c-r>=(exists('g:ferret_lastsearch') ? '/' . g:ferret_lastsearch . '//' : ' ')<CR><Left>

""
" @option g:FerretMap boolean 1
"
" Controls whether to set up the Ferret mappings, such as |<Plug>(FerretAck)|
" (see |ferret-mappings| for a full list). To prevent any mapping from being
" configured, set to 0:
"
" ```
" let g:FerretMap=0
" ```
let s:map=get(g:, 'FerretMap', 1)
if s:map
  if !hasmapto('<Plug>(FerretAck)') && maparg('<leader>a', 'n') ==# ''
    ""
    " @mapping <Plug>(FerretAck)
    "
    " Ferret maps <leader>a to |<Plug>(FerretAck)|, which triggers the |:Ack|
    " command. To use an alternative mapping instead, create a different one in
    " your |.vimrc| instead using |:nmap|:
    "
    " ```
    " " Instead of <leader>a, use <leader>x.
    " nmap <leader>x <Plug>(FerretAck)
    " ```
    nmap <unique> <leader>a <Plug>(FerretAck)
  endif

  if !hasmapto('<Plug>FerretLack') && maparg('<leader>l', 'n') ==# ''
    ""
    " @mapping <Plug>(FerretLack)
    "
    " Ferret maps <leader>l to |<Plug>(FerretLack)|, which triggers the |:Lack|
    " command. To use an alternative mapping instead, create a different one in
    " your |.vimrc| instead using |:nmap|:
    "
    " ```
    " " Instead of <leader>l, use <leader>y.
    " nmap <leader>y <Plug>(FerretLack)
    " ```
    nmap <unique> <leader>l <Plug>(FerretLack)
  endif

  if !hasmapto('<Plug>(FerretAckWord)') && maparg('<leader>s', 'n') ==# ''
    ""
    " @mapping <Plug>(FerretAckWord)
    "
    " Ferret maps <leader>s (mnemonix: "selection) to |<Plug>(FerretAckWord)|,
    " which uses |:Ack| to search for the word currently under the cursor. To
    " use an alternative mapping instead, create a different one in your
    " |.vimrc| instead using |:nmap|:
    "
    " ```
    " " Instead of <leader>s, use <leader>z.
    " nmap <leader>z <Plug>(FerretAckWord)
    " ```
    nmap <unique> <leader>s <Plug>(FerretAckWord)
  endif

  if !hasmapto('<Plug>(FerretAcks)') && maparg('<leader>r', 'n') ==# ''
    ""
    " @mapping <Plug>(FerretAcks)
    "
    " Ferret maps <leader>r (mnemonic: "replace") to |<Plug>(FerretAcks)|, which
    " triggers the |:Acks| command and fills the prompt with the last search
    " term from Ferret. to use an alternative mapping instead, create a
    " different one in your |.vimrc| instead using |:nmap|:
    "
    " ```
    " " Instead of <leader>r, use <leader>u.
    " nmap <leader>u <Plug>(FerretAcks)
    " ```
    nmap <unique> <leader>r <Plug>(FerretAcks)
  endif
endif

""
" @command :Qargs
"
" This is a utility function that is used internally when running on older
" versions of Vim (prior to version 8) but is also generally useful enough to
" warrant being exposed publicly.
"
" It takes the files currently in the |quickfix| listing and sets them as
" |:args| so that they can be operated on en masse via the |:argdo| command.
command! -bar Qargs execute 'args' ferret#private#qargs()

""
" @option g:FerretQFCommands boolean 1
"
" Controls whether to set up custom versions of the |quickfix| commands, |:cn|,
" |:cnf|, |:cp| an |:cpf|. These overrides vertically center the match within
" the viewport on each jump. To prevent the custom versions from being
" configured, set to 0:
"
" ```
" let g:FerretQFCommands=0
" ```
let s:commands=get(g:, 'FerretQFCommands', 1)
if s:commands
  " Keep quickfix result centered, if possible, when jumping from result to result.
  cabbrev <silent> <expr> cn ((getcmdtype() == ':' && getcmdpos() == 3) ? 'cn <bar> normal zz' : 'cn')
  cabbrev <silent> <expr> cnf ((getcmdtype() == ':' && getcmdpos() == 4) ? 'cnf <bar> normal zz' : 'cnf')
  cabbrev <silent> <expr> cp ((getcmdtype() == ':' && getcmdpos() == 3) ? 'cp <bar> normal zz' : 'cp')
  cabbrev <silent> <expr> cpf ((getcmdtype() == ':' && getcmdpos() == 4) ? 'cpf <bar> normal zz' : 'cpf')
endif

""
" @option g:FerretFormat string "%f:%l:%c:%m"
"
" Sets the '|grepformat|' used by Ferret.
let g:FerretFormat=get(g:, 'FerretFormat', '%f:%l:%c:%m')

" Restore 'cpoptions' to its former value.
let &cpoptions = s:cpoptions
unlet s:cpoptions
