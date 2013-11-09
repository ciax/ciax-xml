#!/bin/bash
# Local functions
umask 022
shopt -s nullglob
export LANG="C"
export PATH="$PATH:$HOME/bin:$HOME/lib"
export XMLPATH=$HOME/ciax-xml
export RUBYLIB="$HOME/lib"
#Alias
alias clu=clean_up
alias chkxml=check_xml
alias devsim=device_simulator
alias jv=json_view
alias jl=json_logview
alias mkhtm=make_html
alias mvw=marshal_view
alias reg=register_files
