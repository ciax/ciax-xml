#!/bin/bash
addenv(){
    name=$1;shift
    list=$(IFS=: eval echo \$$name)
    for j ; do
        for i in $list;do
            [ "$j" = "$i" ] && break 2
        done
        eval "export $name=$j:\$$name"
    done
}

# Local functions
umask 022
shopt -s nullglob
export LANG="C"
addenv PATH "$HOME/bin" "$HOME/lib"
addenv RUBYLIB "$HOME/lib"
export XMLPATH="$HOME/ciax-xml"

#Alias
alias chkxml=check-xml
alias devsim=device-simulator
alias jv=json-view
alias jl=json-logview
alias mkhtm=make-html
alias mvw=marshal-view
alias reg=register-files
