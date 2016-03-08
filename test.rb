#!/usr/bin/env ruby

%x{tmux new-session -d -s ferret-test}
%x{tmux send-keys -t ferret-test 'vim -u NONE' Enter}
%x{tmux send-keys -t ferret-test ':set nocompatible' Enter}
%x{tmux send-keys -t ferret-test ':set rtp+=#{Dir.pwd}' Enter}
%x{tmux send-keys -t ferret-test ':runtime! plugin/ferret.vim' Enter}

%x{tmux send-keys -t ferret-test \\\\ a usr/bin/env\\\\ Space ruby Enter}

sleep 1
%x{tmux capture-pane -t ferret-test}
buffer = %x{tmux show-buffer}
%x{tmux delete-buffer}
puts buffer
