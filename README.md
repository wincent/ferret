<p align="center">
<img src="https://raw.githubusercontent.com/wincent/ferret/media/ferret.jpg" />
<img src="https://raw.githubusercontent.com/wincent/ferret/media/ferret.gif" />
</p>

# ferret<a name="ferret-ferret" href="#user-content-ferret-ferret"></a>


## Intro<a name="ferret-intro" href="#user-content-ferret-intro"></a>

> "ferret (verb)<br />(ferret something out) search tenaciously for and find something: she had the ability to ferret out the facts."

<p align="right"><a name="ferret-features" href="#user-content-ferret-features"><code>ferret-features</code></a></p>
Ferret improves Vim's multi-file search in four ways:


### 1. Powerful multi-file search<a name="ferret-1-powerful-multi-file-search" href="#user-content-ferret-1-powerful-multi-file-search"></a>

Ferret provides an <strong>[`:Ack`](#user-content-ack)</strong> command for searching across multiple files using ripgrep (https://github.com/BurntSushi/ripgrep), The Silver Searcher (https://github.com/ggreer/the_silver_searcher), or Ack (http://beyondgrep.com/). Support for passing options through to the underlying search command exists, along with the ability to use full regular expression syntax without doing special escaping. On modern versions of Vim (version 8 or higher, or Neovim), searches are performed asynchronously (without blocking the UI).

Shortcut mappings are provided to start an <strong>[`:Ack`](#user-content-ack)</strong> search (<leader>a) or to search for the word currently under the cursor (<leader>s).

Results are normally displayed in the <strong>`quickfix`</strong> window, but Ferret also provides a <strong>[`:Lack`](#user-content-lack)</strong> command that behaves like <strong>[`:Ack`](#user-content-ack)</strong> but uses the <strong>`location-list`</strong> instead, and a <leader>l mapping as a shortcut to <strong>[`:Lack`](#user-content-lack)</strong>.

<strong>[`:Back`](#user-content-back)</strong> and <strong>[`:Black`](#user-content-black)</strong> are analogous to <strong>[`:Ack`](#user-content-ack)</strong> and <strong>[`:Lack`](#user-content-lack)</strong>, but scoped to search within currently open buffers only.


### 2. Streamlined multi-file replace<a name="ferret-2-streamlined-multi-file-replace" href="#user-content-ferret-2-streamlined-multi-file-replace"></a>

The companion to <strong>[`:Ack`](#user-content-ack)</strong> is <strong>[`:Acks`](#user-content-acks)</strong> (mnemonic: "Ack substitute", accessible via shortcut <leader>r), which allows you to run a multi-file replace across all the files placed in the <strong>`quickfix`</strong> window by a previous invocation of <strong>[`:Ack`](#user-content-ack)</strong> (or <strong>[`:Back`](#user-content-back)</strong>).


### 3. Quickfix listing enhancements<a name="ferret-3-quickfix-listing-enhancements" href="#user-content-ferret-3-quickfix-listing-enhancements"></a>

The <strong>`quickfix`</strong> listing itself is enhanced with settings to improve its usability, and natural mappings that allow quick removal of items from the list (for example, you can reduce clutter in the listing by removing lines that you don't intend to make changes to).

Additionally, Vim's <strong>`:cn`</strong>, <strong>`:cp`</strong>, <strong>`:cnf`</strong> and <strong>`:cpf`</strong> commands are tweaked to make it easier to immediately identify matches by centering them within the viewport.


### 4. Easy operations on files in the quickfix listing<a name="ferret-4-easy-operations-on-files-in-the-quickfix-listing" href="#user-content-ferret-4-easy-operations-on-files-in-the-quickfix-listing"></a>

Finally, Ferret provides a <strong>[`:Qargs`](#user-content-qargs)</strong> command that puts the files currently in the <strong>`quickfix`</strong> listing into the <strong>`:args`</strong> list, where they can be operated on in bulk via the <strong>`:argdo`</strong> command. This is what's used under the covers on older versions of Vim by <strong>[`:Acks`](#user-content-acks)</strong> to do its work (on newer versions the built-in <strong>`:cfdo`</strong> is used instead).


## Installation<a name="ferret-installation" href="#user-content-ferret-installation"></a>

To install Ferret, use your plug-in management system of choice.

If you don't have a "plug-in management system of choice", I recommend Pathogen (https://github.com/tpope/vim-pathogen) due to its simplicity and robustness. Assuming that you have Pathogen installed and configured, and that you want to install Ferret into `~/.vim/bundle`, you can do so with:

```
git clone https://github.com/wincent/ferret.git ~/.vim/bundle/ferret
```

Alternatively, if you use a Git submodule for each Vim plug-in, you could do the following after `cd`-ing into the top-level of your Git superproject:

```
git submodule add https://github.com/wincent/ferret.git ~/vim/bundle/ferret
git submodule init
```

To generate help tags under Pathogen, you can do so from inside Vim with:

```
:call pathogen#helptags()
```


## Commands<a name="ferret-commands" href="#user-content-ferret-commands"></a>

<p align="right"><a name="ack" href="#user-content-ack"><code>:Ack</code></a></p>

### `:Ack {pattern} {options}`<a name="ferret-ack-pattern-options" href="#user-content-ferret-ack-pattern-options"></a>

Searches for {pattern} in all the files under the current directory (see <strong>`:pwd`</strong>), unless otherwise overridden via {options}, and displays the results in the <strong>`quickfix`</strong> listing.

`rg` (ripgrep) then `ag` (The Silver Searcher) will be used preferentially if present on the system, because they are faster, falling back to `ack`/`ack-grep` as needed.

On newer versions of Vim (version 8 and above), the search process runs asynchronously in the background and does not block the UI.

Asynchronous searches are preferred because they do not block, despite the fact that Vim itself is single threaded.

The {pattern} is passed through as-is to the underlying search program, and no escaping is required other than preceding spaces by a single backslash. For example, to search for "\bfoo[0-9]{2} bar\b" (ie. using `ag`'s Perl-style regular expression syntax), you could do:

```
:Ack \bfoo[0-9]{2}\ bar\b
```

Likewise, {options} are passed through. In this example, we pass the `-w` option (to search on word boundaries), and scope the search to the "foo" and "bar" subdirectories: >

```
:Ack -w something foo bar
```

As a convenience <leader>a is set-up (<strong>[`<Plug>(FerretAck)`](#user-content-plugferretack)</strong>) as a shortcut to enter <strong>`Cmdline-mode`</strong> with `:Ack` inserted on the <strong>`Cmdline`</strong>. Likewise <leader>s (<strong>[`<Plug>(FerretAckWord)`](#user-content-plugferretackword)</strong>) is a shortcut for running <strong>[`:Ack`](#user-content-ack)</strong> with the word currently under the cursor.

<p align="right"><a name="ack" href="#user-content-ack"><code>:Ack!</code></a></p>

### `:Ack! {pattern} {options}`<a name="ferret-ack-pattern-options" href="#user-content-ferret-ack-pattern-options"></a>

Like <strong>[`:Ack`](#user-content-ack)</strong>, but returns all results irrespective of the value of <strong>`g:FerretMaxResults`</strong>.

<p align="right"><a name="lack" href="#user-content-lack"><code>:Lack</code></a></p>

### `:Lack {pattern} {options}`<a name="ferret-lack-pattern-options" href="#user-content-ferret-lack-pattern-options"></a>

Just like <strong>[`:Ack`](#user-content-ack)</strong>, but instead of using the <strong>`quickfix`</strong> listing, which is global across an entire Vim instance, it uses the <strong>`location-list`</strong>, which is a per-window construct.

Note that <strong>[`:Lack`](#user-content-lack)</strong> always runs synchronously via <strong>`:cexpr`</strong>.

<p align="right"><a name="lack" href="#user-content-lack"><code>:Lack!</code></a></p>

### `:Lack! {pattern} {options}`<a name="ferret-lack-pattern-options" href="#user-content-ferret-lack-pattern-options"></a>

Like <strong>[`:Lack`](#user-content-lack)</strong>, but returns all results irrespective of the value of <strong>`g:FerretMaxResults`</strong>.

<p align="right"><a name="back" href="#user-content-back"><code>:Back</code></a></p>

### `:Back {pattern} {options}`<a name="ferret-back-pattern-options" href="#user-content-ferret-back-pattern-options"></a>

Like <strong>[`:Ack`](#user-content-ack)</strong>, but searches only listed buffers. Note that the search is still delegated to the underlying <strong>`'grepprg'`</strong> (`rg`, `ag`, `ack` or `ack-grep`), which means that only buffers written to disk will be searched. If no buffers are written to disk, then <strong>[`:Back`](#user-content-back)</strong> behaves exactly like <strong>[`:Ack`](#user-content-ack)</strong> and will search all files in the current directory.

<p align="right"><a name="back" href="#user-content-back"><code>:Back!</code></a></p>

### `:Back! {pattern} {options}`<a name="ferret-back-pattern-options" href="#user-content-ferret-back-pattern-options"></a>

Like <strong>[`:Back`](#user-content-back)</strong>, but returns all results irrespective of the value of <strong>`g:FerretMaxResults`</strong>.

<p align="right"><a name="black" href="#user-content-black"><code>:Black</code></a></p>

### `:Black {pattern} {options}`<a name="ferret-black-pattern-options" href="#user-content-ferret-black-pattern-options"></a>

Like <strong>[`:Lack`](#user-content-lack)</strong>, but searches only listed buffers. As with <strong>[`:Back`](#user-content-back)</strong>, the search is still delegated to the underlying <strong>`'grepprg'`</strong> (`rg`, `ag`, `ack` or `ack-grep`), which means that only buffers written to disk will be searched. Likewise, If no buffers are written to disk, then <strong>[`:Black`](#user-content-black)</strong> behaves exactly like <strong>[`:Lack`](#user-content-lack)</strong> and will search all files in the current directory.

<p align="right"><a name="black" href="#user-content-black"><code>:Black!</code></a></p>

### `:Black! {pattern} {options}`<a name="ferret-black-pattern-options" href="#user-content-ferret-black-pattern-options"></a>

Like <strong>[`:Black`](#user-content-black)</strong>, but returns all results irrespective of the value of <strong>`g:FerretMaxResults`</strong>.

<p align="right"><a name="acks" href="#user-content-acks"><code>:Acks</code></a></p>

### `:Acks /{pattern}/{replacement}/`<a name="ferret-acks-patternreplacement" href="#user-content-ferret-acks-patternreplacement"></a>

Takes all of the files currently in the <strong>`quickfix`</strong> listing and performs a substitution of all instances of {pattern} (a standard Vim search <strong>`pattern`</strong>) by {replacement}.

A typical sequence consists of an <strong>[`:Ack`](#user-content-ack)</strong> invocation to populate the <strong>`quickfix`</strong> listing and then <strong>[`:Acks`](#user-content-acks)</strong> (mnemonic: "Ack substitute") to perform replacements. For example, to replace "foo" with "bar" across all files in the current directory:

```
:Ack foo
:Acks /foo/bar/
```

<p align="right"><a name="qargs" href="#user-content-qargs"><code>:Qargs</code></a></p>

### `:Qargs`<a name="ferret-qargs" href="#user-content-ferret-qargs"></a>

This is a utility function that is used internally when running on older versions of Vim (prior to version 8) but is also generally useful enough to warrant being exposed publicly.

It takes the files currently in the <strong>`quickfix`</strong> listing and sets them as <strong>`:args`</strong> so that they can be operated on en masse via the <strong>`:argdo`</strong> command.


## Mappings<a name="ferret-mappings" href="#user-content-ferret-mappings"></a>


### Circumstances where mappings do not get set up<a name="ferret-circumstances-where-mappings-do-not-get-set-up" href="#user-content-ferret-circumstances-where-mappings-do-not-get-set-up"></a>

Note that Ferret will not try to set up the <leader> mappings if any of the following are true:

- A mapping with the same <strong>`{lhs}`</strong> already exists.
- An alternative mapping for the same functionality has already been set up from a <strong>`.vimrc`</strong>.
- The mapping has been suppressed by setting <strong>`g:FerretMap`</strong> to 1 in your <strong>`.vimrc`</strong>.


### Mappings specific to the quickfix window<a name="ferret-mappings-specific-to-the-quickfix-window" href="#user-content-ferret-mappings-specific-to-the-quickfix-window"></a>

Additionally, Ferret will set up special mappings in <strong>`quickfix`</strong> listings, unless prevented from doing so by <strong>`g:FerretQFMap`</strong>:

- `d` (<strong>`visual-mode`</strong>): delete visual selection
- `dd` (<strong>`Normal-mode`</strong>): delete current line
- `d`{motion} (<strong>`Normal-mode`</strong>): delete range indicated by {motion}


### `<Plug>(FerretAck)`<a name="ferret-plugferretack" href="#user-content-ferret-plugferretack"></a>

Ferret maps <leader>a to <strong>[`<Plug>(FerretAck)`](#user-content-plugferretack)</strong>, which triggers the <strong>[`:Ack`](#user-content-ack)</strong> command. To use an alternative mapping instead, create a different one in your <strong>`.vimrc`</strong> instead using <strong>`:nmap`</strong>:

```
" Instead of <leader>a, use <leader>x.
nmap <leader>x <Plug>(FerretAck)
```


### `<Plug>(FerretLack)`<a name="ferret-plugferretlack" href="#user-content-ferret-plugferretlack"></a>

Ferret maps <leader>l to <strong>[`<Plug>(FerretLack)`](#user-content-plugferretlack)</strong>, which triggers the <strong>[`:Lack`](#user-content-lack)</strong> command. To use an alternative mapping instead, create a different one in your <strong>`.vimrc`</strong> instead using <strong>`:nmap`</strong>:

```
" Instead of <leader>l, use <leader>y.
nmap <leader>y <Plug>(FerretLack)
```


### `<Plug>(FerretAckWord)`<a name="ferret-plugferretackword" href="#user-content-ferret-plugferretackword"></a>

Ferret maps <leader>s (mnemonix: "selection) to <strong>[`<Plug>(FerretAckWord)`](#user-content-plugferretackword)</strong>, which uses <strong>[`:Ack`](#user-content-ack)</strong> to search for the word currently under the cursor. To use an alternative mapping instead, create a different one in your <strong>`.vimrc`</strong> instead using <strong>`:nmap`</strong>:

```
" Instead of <leader>s, use <leader>z.
nmap <leader>z <Plug>(FerretAckWord)
```


### `<Plug>(FerretAcks)`<a name="ferret-plugferretacks" href="#user-content-ferret-plugferretacks"></a>

Ferret maps <leader>r (mnemonic: "replace") to <strong>[`<Plug>(FerretAcks)`](#user-content-plugferretacks)</strong>, which triggers the <strong>[`:Acks`](#user-content-acks)</strong> command and fills the prompt with the last search term from Ferret. to use an alternative mapping instead, create a different one in your <strong>`.vimrc`</strong> instead using <strong>`:nmap`</strong>:

```
" Instead of <leader>r, use <leader>u.
nmap <leader>u <Plug>(FerretAcks)
```


## Options<a name="ferret-options" href="#user-content-ferret-options"></a>

<p align="right"><a name="gferretnvim" href="#user-content-gferretnvim"><code>g:FerretNvim</code></a></p>

### `g:FerretNvim` (boolean, default: 1)<a name="ferret-gferretnvim-boolean-default-1" href="#user-content-ferret-gferretnvim-boolean-default-1"></a>

Controls whether to use Neovim's <strong>`job-control`</strong> features, when available, to run searches asynchronously. To prevent this from being used, set to 0, in which case Ferret will fall back to the next method in the list (Vim's built-in async primitives -- see <strong>`g:FerretJob`</strong> -- which are typically not available in Neovim, so will then fall back to the next available method).

```
let g:FerretNvim=0
```

<p align="right"><a name="gferretjob" href="#user-content-gferretjob"><code>g:FerretJob</code></a></p>

### `g:FerretJob` (boolean, default: 1)<a name="ferret-gferretjob-boolean-default-1" href="#user-content-ferret-gferretjob-boolean-default-1"></a>

Controls whether to use Vim's <strong>`+job`</strong> feature, when available, to run searches asynchronously. To prevent <strong>`+job`</strong> from being used, set to 0, in which case Ferret will fall back to the next available method.

```
let g:FerretJob=0
```

<p align="right"><a name="gferrethlsearch" href="#user-content-gferrethlsearch"><code>g:FerretHlsearch</code></a></p>

### `g:FerretHlsearch` (boolean, default: none)<a name="ferret-gferrethlsearch-boolean-default-none" href="#user-content-ferret-gferrethlsearch-boolean-default-none"></a>

Controls whether Ferret should attempt to highlight the search pattern when running <strong>[`:Ack`](#user-content-ack)</strong> or <strong>[`:Lack`](#user-content-lack)</strong>. If left unset, Ferret will respect the current 'hlsearch' setting. To force highlighting on or off irrespective of 'hlsearch', set <strong>`g:FerretHlsearch`</strong> to 1 (on) or 0 (off):

```
let g:FerretHlsearch=0
```

<p align="right"><a name="gferretexecutable" href="#user-content-gferretexecutable"><code>g:FerretExecutable</code></a></p>

### `g:FerretExecutable` (string, default: "rg,ag,ack,ack-grep")<a name="ferret-gferretexecutable-string-default-rgagackack-grep" href="#user-content-ferret-gferretexecutable-string-default-rgagackack-grep"></a>

Ferret will preferentially use `rg`, `ag` and finally `ack`/`ack-grep` (in that order, using the first found executable), however you can force your preference for a specific tool to be used by setting an override in your <strong>`.vimrc`</strong>. Valid values are a comma-separated list of "rg", "ag", "ack" or "ack-grep". If no requested executable exists, Ferret will fall-back to the next in the default list.

Example:

```
" Prefer `ag` over `rg`.
let g:FerretExecutable='ag,rg'
```

<p align="right"><a name="gferretmaxresults" href="#user-content-gferretmaxresults"><code>g:FerretMaxResults</code></a></p>

### `g:FerretMaxResults` (number, default: 100000)<a name="ferret-gferretmaxresults-number-default-100000" href="#user-content-ferret-gferretmaxresults-number-default-100000"></a>

Controls the maximum number of results Ferret will attempt to gather before displaying the results. Note that this only applies when searching asynchronously; that is, on recent versions of Vim with <strong>`+job`</strong> support and when <strong>`g:FerretJob`</strong> is not set to 0.

The intent of this option is to prevent runaway search processes that produce huge volumes of output (for example, searching for a common string like "test" inside a <strong>`$HOME`</strong> directory containing millions of files) from locking up Vim.

In the event that Ferret aborts a search that has hit the <strong>`g:FerretMaxResults`</strong> limit, a message will be printed prompting users to run the search again with <strong>[`:Ack!`](#user-content-ack)</strong> or <strong>[`:Lack!`](#user-content-lack)</strong> if they want to bypass the limit.

<p align="right"><a name="gferretautojump" href="#user-content-gferretautojump"><code>g:FerretAutojump</code></a></p>

### `g:FerretAutojump` (number, default: 1)<a name="ferret-gferretautojump-number-default-1" href="#user-content-ferret-gferretautojump-number-default-1"></a>

Controls whether Ferret will automatically jump to the first found match.

- Set to 0, Ferret will show the search results but perform no jump.
- Set to 1 (the default), Ferret will show the search results and focus the result listing.
- Set to 2, Ferret will show the search results and jump to the first found match.

Example override:

```
let g:FerretAutojump=2
```

<p align="right"><a name="gferretqfoptions" href="#user-content-gferretqfoptions"><code>g:FerretQFOptions</code></a></p>

### `g:FerretQFOptions` (boolean, default: 1)<a name="ferret-gferretqfoptions-boolean-default-1" href="#user-content-ferret-gferretqfoptions-boolean-default-1"></a>

Controls whether to set up setting overrides for <strong>`quickfix`</strong> windows. These are various settings, such as <strong>`norelativenumber`</strong>, <strong>`nolist`</strong> and <strong>`nowrap`</strong>, that are intended to make the <strong>`quickfix`</strong> window, which is typically very small relative to other windows, more usable.

A full list of overridden settings can be found in <strong>[`ferret-overrides`](#user-content-ferret-overrides)</strong>.

To prevent the custom settings from being applied, set <strong>`g:FerretQFOptions`</strong> to 0:

```
let g:FerretQFOptions=0
```

<p align="right"><a name="gferretqfmap" href="#user-content-gferretqfmap"><code>g:FerretQFMap</code></a></p>

### `g:FerretQFMap` (boolean, default: 1)<a name="ferret-gferretqfmap-boolean-default-1" href="#user-content-ferret-gferretqfmap-boolean-default-1"></a>

Controls whether to set up mappings in the <strong>`quickfix`</strong> results window for deleting results. The mappings include:

- `d` (<strong>`visual-mode`</strong>): delete visual selection
- `dd` (<strong>`Normal-mode`</strong>): delete current line
- `d`{motion} (<strong>`Normal-mode`</strong>): delete range indicated by {motion}

To prevent these mappings from being set up, set to 0:

```
let g:FerretQFMap=0
```

<p align="right"><a name="gferretloaded" href="#user-content-gferretloaded"><code>g:FerretLoaded</code></a></p>

### `g:FerretLoaded` (any, default: none)<a name="ferret-gferretloaded-any-default-none" href="#user-content-ferret-gferretloaded-any-default-none"></a>

To prevent Ferret from being loaded, set <strong>`g:FerretLoaded`</strong> to any value in your <strong>`.vimrc`</strong>. For example:

```
let g:FerretLoaded=1
```

<p align="right"><a name="gferretlazyinit" href="#user-content-gferretlazyinit"><code>g:FerretLazyInit</code></a></p>

### `g:FerretLazyInit` (boolean, default: 1)<a name="ferret-gferretlazyinit-boolean-default-1" href="#user-content-ferret-gferretlazyinit-boolean-default-1"></a>

In order to minimize impact on Vim start-up time Ferret will initialize itself lazily on first use by default. If you wish to force immediate initialization (for example, to cause <strong>`'grepprg'`</strong> and <strong>`'grepformat'`</strong> to be set as soon as Vim launches), then set <strong>`g:FerretLazyInit`</strong> to 0 in your <strong>`.vimrc`</strong>:

```
let g:FerrerLazyInit=0
```

<p align="right"><a name="gferretmap" href="#user-content-gferretmap"><code>g:FerretMap</code></a></p>

### `g:FerretMap` (boolean, default: 1)<a name="ferret-gferretmap-boolean-default-1" href="#user-content-ferret-gferretmap-boolean-default-1"></a>

Controls whether to set up the Ferret mappings, such as <strong>[`<Plug>(FerretAck)`](#user-content-plugferretack)</strong> (see <strong>[`ferret-mappings`](#user-content-ferret-mappings)</strong> for a full list). To prevent any mapping from being configured, set to 0:

```
let g:FerretMap=0
```

<p align="right"><a name="gferretqfcommands" href="#user-content-gferretqfcommands"><code>g:FerretQFCommands</code></a></p>

### `g:FerretQFCommands` (boolean, default: 1)<a name="ferret-gferretqfcommands-boolean-default-1" href="#user-content-ferret-gferretqfcommands-boolean-default-1"></a>

Controls whether to set up custom versions of the <strong>`quickfix`</strong> commands, <strong>`:cn`</strong>, <strong>`:cnf`</strong>, <strong>`:cp`</strong> an <strong>`:cpf`</strong>. These overrides vertically center the match within the viewport on each jump. To prevent the custom versions from being configured, set to 0:

```
let g:FerretQFCommands=0
```

<p align="right"><a name="gferretformat" href="#user-content-gferretformat"><code>g:FerretFormat</code></a></p>

### `g:FerretFormat` (string, default: "%f:%l:%c:%m")<a name="ferret-gferretformat-string-default-flcm" href="#user-content-ferret-gferretformat-string-default-flcm"></a>

Sets the '<strong>`grepformat`</strong>' used by Ferret.


## Custom autocommands<a name="ferret-custom-autocommands" href="#user-content-ferret-custom-autocommands"></a>

<p align="right"><a name="ferretdidwrite" href="#user-content-ferretdidwrite"><code>FerretDidWrite</code></a> <a name="ferretwillwrite" href="#user-content-ferretwillwrite"><code>FerretWillWrite</code></a></p>
For maximum compatibility with other plug-ins, Ferret runs the following "User" autocommands before and after running the file writing operations during <strong>[`:Acks`](#user-content-acks)</strong>:

- FerretWillWrite
- FerretDidWrite

For example, to call a pair of custom functions in response to these events, you might do:

```
autocmd! User FerretWillWrite
autocmd User FerretWillWrite call CustomWillWrite()
autocmd! User FerretDidWrite
autocmd User FerretDidWrite call CustomDidWrite()
```


## Overrides<a name="ferret-overrides" href="#user-content-ferret-overrides"></a>

Ferret overrides the 'grepformat' and 'grepprg' settings, preferentially setting `rg`, `ag`, `ack` or `ack-grep` as the 'grepprg' (in that order) and configuring a suitable 'grepformat'.

Additionally, Ferret includes an <strong>`ftplugin`</strong> for the <strong>`quickfix`</strong> listing that adjusts a number of settings to improve the usability of search results.

<p align="right"><a name="ferret-nolist" href="#user-content-ferret-nolist"><code>ferret-nolist</code></a></p>
'nolist'

Turned off to reduce visual clutter in the search results, and because 'list' is most useful in files that are being actively edited, which is not the case for <strong>`quickfix`</strong> results.

<p align="right"><a name="ferret-norelativenumber" href="#user-content-ferret-norelativenumber"><code>ferret-norelativenumber</code></a></p>
'norelativenumber'

Turned off, because it is more useful to have a sense of absolute progress through the results list than to have the ability to jump to nearby results (especially seeing as the most common operations are moving to the next or previous file, which are both handled nicely by <strong>`:cnf`</strong> and <strong>`:cpf`</strong> respectively).

<p align="right"><a name="ferret-nowrap" href="#user-content-ferret-nowrap"><code>ferret-nowrap</code></a></p>
'nowrap'

Turned off to avoid ugly wrapping that makes the results list hard to read, and because in search results, the most relevant information is the filename, which is on the left and is usually visible even without wrapping.

<p align="right"><a name="ferret-number" href="#user-content-ferret-number"><code>ferret-number</code></a></p>
'number'

Turned on to give a sense of absolute progress through the results.

<p align="right"><a name="ferret-scrolloff" href="#user-content-ferret-scrolloff"><code>ferret-scrolloff</code></a></p>
'scrolloff'

Set to 0 because the <strong>`quickfix`</strong> listing is usually small by default, so trying to keep the current line away from the edge of the viewpoint is futile; by definition it is usually near the edge.

<p align="right"><a name="ferret-nocursorline" href="#user-content-ferret-nocursorline"><code>ferret-nocursorline</code></a></p>
'nocursorline'

Turned off to reduce visual clutter.

To prevent any of these <strong>`quickfix`</strong>-specific overrides from being set up, you can set <strong>`g:FerretQFOptions`</strong> to 0 in your <strong>`.vimrc`</strong>:

```
let g:FerretQFOptions=0
```


## Troubleshooting<a name="ferret-troubleshooting" href="#user-content-ferret-troubleshooting"></a>

<p align="right"><a name="ferret-quotes" href="#user-content-ferret-quotes"><code>ferret-quotes</code></a></p>

### Ferret fails to find patterns containing spaces<a name="ferret-ferret-fails-to-find-patterns-containing-spaces" href="#user-content-ferret-ferret-fails-to-find-patterns-containing-spaces"></a>

As described in the documentation for <strong>[`:Ack`](#user-content-ack)</strong>, the search pattern is passed through as-is to the underlying search command, and no escaping is required other than preceding spaces by a single backslash.

So, to find "foo bar", you would search like:

```
:Ack foo\ bar
```

Unescaped spaces in the search are treated as argument separators, so a command like the following means pass the `-w` option through, search for pattern "foo", and limit search to the "bar" directory:

```
:Ack -w foo bar
```

Note that including quotes will not do what you intend.

```
 " Search for '"foo' in the 'bar"' directory:
 :Ack "foo bar"

 " Search for "'foo' in the "bar'" directory:
 :Ack 'foo bar'
```

This approach to escaping is taken in order to make it straightfoward to use powerful Perl-compatible regular expression syntax in an unambiguous way without having to worry about shell escaping rules:

```
:Ack \blog\((['"]).*?\1\) -i --ignore-dir=src/vendor src dist build
```


## FAQ<a name="ferret-faq" href="#user-content-ferret-faq"></a>


### Why do Ferret commands start with "Ack", "Lack" and so on?<a name="ferret-why-do-ferret-commands-start-with-ack-lack-and-so-on" href="#user-content-ferret-why-do-ferret-commands-start-with-ack-lack-and-so-on"></a>

Ferret was originally the thinnest of wrappers (7 lines of code in my <strong>`.vimrc`</strong>) around `ack`. The earliest traces of it can be seen in the initial commit to my dotfiles repo in May, 2009 (https://rfr.to/h).

So, even though Ferret has a new name now and actually prefers `rg` then `ag` over `ack`/`ack-grep` when available, I prefer to keep the command names intact and benefit from years of accumulated muscle-memory.


## Related<a name="ferret-related" href="#user-content-ferret-related"></a>

Just as Ferret aims to improve the multi-file search and replace experience, Loupe does the same for within-file searching:

https://github.com/wincent/loupe


## Website<a name="ferret-website" href="#user-content-ferret-website"></a>

The official Ferret source code repo is at:

http://git.wincent.com/ferret.git

A mirror exists at:

https://github.com/wincent/ferret

Official releases are listed at:

http://www.vim.org/scripts/script.php?script_id=5220


## License<a name="ferret-license" href="#user-content-ferret-license"></a>

Copyright 2015-present Greg Hurrell. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


## Development<a name="ferret-development" href="#user-content-ferret-development"></a>


### Contributing patches<a name="ferret-contributing-patches" href="#user-content-ferret-contributing-patches"></a>

Patches can be sent via mail to greg@hurrell.net, or as GitHub pull requests at: https://github.com/wincent/ferret/pulls


### Cutting a new release<a name="ferret-cutting-a-new-release" href="#user-content-ferret-cutting-a-new-release"></a>

At the moment the release process is manual:

- Perform final sanity checks and manual testing
- Update the <strong>[`ferret-history`](#user-content-ferret-history)</strong> section of the documentation
- Verify clean work tree:

```
git status
```

- Tag the release:

```
git tag -s -m "$VERSION release" $VERSION
```

- Publish the code:

```
git push origin master --follow-tags
git push github master --follow-tags
```

- Produce the release archive:

```
git archive -o ferret-$VERSION.zip HEAD -- .
```

- Upload to http://www.vim.org/scripts/script.php?script_id=5220


## Authors<a name="ferret-authors" href="#user-content-ferret-authors"></a>

Ferret is written and maintained by Greg Hurrell <greg@hurrell.net>.

Other contributors that have submitted patches include (in alphabetical order):

- Daniel Silva
- Filip Szymański
- Joe Lencioni
- Nelo-Thara Wallus
- Tom Dooner
- Vaibhav Sagar


## History<a name="ferret-history" href="#user-content-ferret-history"></a>


### 3.0 (13 June 2017)<a name="ferret-30-13-june-2017" href="#user-content-ferret-30-13-june-2017"></a>

- Improve handling of backslash escapes (https://github.com/wincent/ferret/issues/41).
- Add <strong>`g:FerretAutojump`</strong>.
- Drop support for vim-dispatch.


### 2.0 (6 June 2017)<a name="ferret-20-6-june-2017" href="#user-content-ferret-20-6-june-2017"></a>

- Add support for Neovim, along with <strong>`g:FerretNvim`</strong> setting.


### 1.5 "Cinco de Cuatro" (4 May 2017)<a name="ferret-15-cinco-de-cuatro-4-may-2017" href="#user-content-ferret-15-cinco-de-cuatro-4-may-2017"></a>

- Improvements to the handling of very large result sets (due to wide lines or many results).
- Added <strong>`g:FerretLazyInit`</strong>.
- Added missing documentation for <strong>`g:FerretJob`</strong>.
- Added <strong>`g:FerretMaxResults`</strong>.
- Added feature-detection for `rg` and `ag`, allowing Ferret to gracefully work with older versions of those tools that do not support all desired command-line switches.


### 1.4 (21 January 2017)<a name="ferret-14-21-january-2017" href="#user-content-ferret-14-21-january-2017"></a>

- Drop broken support for `grep`, printing a prompt to install `rg`, `ag`, or `ack`/`ack-grep` instead.
- If an `ack` executable is not found, search for `ack-grep`, which is the name used on Debian-derived distros.


### 1.3 (8 January 2017)<a name="ferret-13-8-january-2017" href="#user-content-ferret-13-8-january-2017"></a>

- Reset <strong>`'errorformat'`</strong> before each search (fixes issue #31).
- Added <strong>[`:Back`](#user-content-back)</strong> and <strong>[`:Black`](#user-content-black)</strong> commands, analogous to <strong>[`:Ack`](#user-content-ack)</strong> and <strong>[`:Lack`](#user-content-lack)</strong> but scoped to search within currently open buffers only.
- Change <strong>[`:Acks`](#user-content-acks)</strong> to use <strong>`:cfdo`</strong> when available rather than <strong>[`:Qargs`](#user-content-qargs)</strong> and <strong>`:argdo`</strong>, to avoid polluting the <strong>`arglist`</strong>.
- Remove superfluous <strong>`QuickFixCmdPost`</strong> autocommands, resolving clash with Neomake plug-in (patch from Tom Dooner, #36).
- Add support for searching with ripgrep (`rg`).


### 1.2a (16 May 2016)<a name="ferret-12a-16-may-2016" href="#user-content-ferret-12a-16-may-2016"></a>

- Add optional support for running searches asynchronously using Vim's <strong>`+job`</strong> feature (enabled by default in sufficiently recent versions of Vim); see <strong>`g:FerretJob`</strong>, <strong>`:FerretCancelAsync`</strong> and <strong>`:FerretPullAsync`</strong>.


### 1.1.1 (7 March 2016)<a name="ferret-111-7-march-2016" href="#user-content-ferret-111-7-march-2016"></a>

- Fix another edge case when searching for patterns containing "#", only manifesting under dispatch.vim.


### 1.1 (7 March 2016)<a name="ferret-11-7-march-2016" href="#user-content-ferret-11-7-march-2016"></a>

- Fix edge case when searching for strings of the form "<foo>".
- Fix edge case when searching for patterns containing "#" and "%".
- Provide completion for `ag` and `ack` options when using <strong>[`:Ack`](#user-content-ack)</strong> and <strong>[`:Lack`](#user-content-lack)</strong>.
- Fix display of error messages under dispatch.vim.


### 1.0 (28 December 2015)<a name="ferret-10-28-december-2015" href="#user-content-ferret-10-28-december-2015"></a>

- Fix broken <strong>[`:Qargs`](#user-content-qargs)</strong> command (patch from Daniel Silva).
- Add <strong>`g:FerretQFHandler`</strong> and <strong>`g:FerretLLHandler`</strong> options (patch from Daniel Silva).
- Make <strong>`<Plug>`</strong> mappings accessible even <strong>`g:FerretMap`</strong> is set to 0.
- Fix failure to report filename when using `ack` and explicitly scoping search to a single file (patch from Daniel Silva).
- When using `ag`, report multiple matches per line instead of just the first (patch from Daniel Silva).
- Improve content and display of error messages.


### 0.3 (24 July 2015)<a name="ferret-03-24-july-2015" href="#user-content-ferret-03-24-july-2015"></a>

- Added highlighting of search pattern and related <strong>`g:FerretHlsearch`</strong> option (patch from Nelo-Thara Wallus).
- Add better error reporting for failed or incorrect searches.


### 0.2 (16 July 2015)<a name="ferret-02-16-july-2015" href="#user-content-ferret-02-16-july-2015"></a>

- Added <strong>[`FerretDidWrite`](#user-content-ferretdidwrite)</strong> and <strong>[`FerretWillWrite`](#user-content-ferretwillwrite)</strong> autocommands (patch from Joe Lencioni).
- Add <strong>[`<Plug>(FerretAcks)`](#user-content-plugferretacks)</strong> mapping (patch from Nelo-Thara Wallus).


### 0.1 (8 July 2015)<a name="ferret-01-8-july-2015" href="#user-content-ferret-01-8-july-2015"></a>

- Initial release, extracted from my dotfiles (https://github.com/wincent/wincent).
