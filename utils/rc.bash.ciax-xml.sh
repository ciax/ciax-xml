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
develop(){
    cd "$HOME/ciax-xml/script"
    git branch |grep '* develop'
}
    
# Local functions
umask 022
shopt -s nullglob
export LANG="C"
addenv PATH "$HOME/bin" "$HOME/lib"
addenv RUBYLIB "$HOME/ciax-xml/script"

#Alias
alias rub='rubocop -a -c .rubocop_todo.yml'
alias rgen='rubocop --auto-gen-config'
develop && export NOCACHE=1
