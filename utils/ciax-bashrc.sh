#!/bin/bash
addenv(){
    name=$1;shift
    list=$(IFS=: eval echo \$$name)
    for j ; do
        for i in $list;do
            [ "$j" = "$i" ] && break 1
        done
        eval "export $name=$j:\$$name"
    done
}

# Local functions
umask 022
shopt -s nullglob
export LANG="C"
addenv PATH "$HOME/bin" "$HOME/lib/b"
addenv XMLPATH "$HOME/ciax-xml"
addenv RUBYLIB "$HOME/lib"

#Alias
alias clu=clean_up
alias chkxml=check_xml
alias devsim=device_simulator
alias jv=json_view
alias jl=json_logview
alias mkhtm=make_html
alias mvw=marshal_view
alias reg=register_files
