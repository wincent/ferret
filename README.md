# Ferret

![](https://raw.githubusercontent.com/wincent/ferret/media/ferret.gif)

Ferret improves Vim's multi-file search in four ways:

## Powerful multi-file search

Ferret provides an `:Ack` command for searching across multiple files using [The
Silver Searcher](https://github.com/ggreer/the_silver_searcher),
[Ack](http://beyondgrep.com/), or [Grep](http://www.gnu.org/software/grep/).
Support for passing options through to the underlying search command exists,
along with the ability to use full regular expression syntax without doing
special escaping.

Shortcut mappings are provided to start an `:Ack` search (<leader>a) or to
search for the word currently under the cursor (<leader>s).

Results are normally displayed in the `quickfix` window, but Ferret also
provides a `:Lack` command that behaves like `:Ack` but uses the
`location-list` instead, and a <leader>l mapping as a shortcut to `:Lack`.

Finally, Ferret offers integration with
[dispatch.vim](https://github.com/tpope/vim-dispatch), which enables
asynchronous searching despite the fact that Vim itself is single-threaded.

## Streamlined multi-file replace

The companion to `:Ack` is `:Acks` (mnemonic: "Ack substitute", accessible via
shortcut <leader>r), which allows you to run a multi-file replace across all
the files placed in the `quickfix` window by a previous invocation of `:Ack`.

## Quickfix listing enhancements

The `quickfix` listing itself is enhanced with settings to improve its
usability, and natural mappings that allow quick removal of items from the
list (for example, you can reduce clutter in the listing by removing lines
that you don't intend to make changes to).

Additionally, Vim's `:cn`, `:cp`, `:cnf` and `:cpf` commands are tweaked to
make it easier to immediately identify matches by centering them within the
viewport.

## Easy operations on files in the quickfix listing

Finally, Ferret provides a `:Qargs` command that puts the files currently in
the `quickfix` listing into the `:args` list, where they can be operated on in
bulk via the `:argdo` command. This is what's used under the covers by `:Acks`
to do its work.

---

For more information, see [the
documentation](https://github.com/wincent/ferret/blob/master/doc/ferret.txt).
