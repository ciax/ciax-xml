#!/bin/bash --rcfile
addenv(){
    name=$1;shift
    list=$(IFS=: eval echo \$$name)
    if [ "$list" ] ; then
        for j; do
            for i in $list;do
                [ "$j" = "$i" ] && break 2
            done
            eval "export $name=$j:\$$name"
        done
    else
        eval "export $name=${*// /:}"
    fi
}

# Local functions
umask 022
shopt -s nullglob
export LANG="C"
addenv PATH "$HOME/bin" "$HOME/lib"
addenv RUBYLIB "$HOME/ciax-xml/script"

#Alias
alias chkxml=check-xml
alias devsim=devsim-sql
alias jv=json-view
alias jlv=json-logview
alias jlp=json-logpick
alias mkhtm=make-html
alias msv=marshal-view
alias logj=sqlog-json
alias vc=view-ctrl
alias rub='rubocop -a -c .rubocop_todo.yml'
alias rgen='rubocop --auto-gen-config'
