#!/bin/bash --rcfile
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
addenv RUBYLIB "$HOME/ciax-xml/script"
export XMLPATH="$HOME/ciax-xml"

#Alias
alias chkxml=check-xml
alias devsim=devsim-sql
alias jv=json-view
alias jlv=json-logview
alias mkhtm=make-html
alias msv=marshal-view
alias logj=sqlog-json
