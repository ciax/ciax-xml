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
alias chkxml=check-xml
alias devsim=device-simulator
alias jv=json-view
alias jl=json-logview
alias mkhtm=make-html
alias mvw=marshal-view
alias reg=register-files
