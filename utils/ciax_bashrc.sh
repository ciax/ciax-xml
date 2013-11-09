#!/bin/bash
# Local functions
umask 022
shopt -s nullglob
export LANG="C"
export PATH="$PATH;$HOME/bin"
export RUBYLIB="$RUBYLIB;$HOME/lib"
#Alias
alias chkxml=check_xml
alias devsim=device_simulator
alias jv=json_view
alias jl=json_logview
alias ltcfg=lantronix-config
alias mkhtm=make_html.sh
alias marv=marshal_view.rb
alias reg=register_files
alias sconv=sqlog_stream_to_status
alias attgrep=xml_agrep
