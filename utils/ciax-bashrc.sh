#!/bin/bash
# Local functions
umask 022
shopt -s nullglob
export LANG="C"
export PATH="$PATH:$HOME/bin"
export RUBYLIB="$HOME/lib"
#Alias
alias chkxml=check_xml
alias devsim=device_simulator
alias jvw=json_view
alias jl=json_logview
alias ltcfg=lantronix-config
alias mkhtm=make_html.sh
alias mvw=marshal_view.rb
alias reg=register_files
