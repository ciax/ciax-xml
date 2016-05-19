#!/bin/bash --rcfile
develop(){
    cd "$HOME/ciax-xml/webapp"
    if git branch |grep '* develop' ; then
        export PROJ=dummy
        export VER=Initiate
        export NOCACHE=1
        alias sybeta='giu beta;gim develop;git push;giu develop'
    else
        cd
    fi
}

# Local functions
umask 022
shopt -s nullglob
export LANG="C"
export PATH="$HOME/bin:$PATH"
export RUBYLIB="$HOME/ciax-xml/script:$RUBYLIB"

#Alias
alias rub='rubocop -a -c .rubocop_todo.yml'
alias rgen='rubocop --auto-gen-config'
alias jj='ruby -r json -e "jj(JSON.parse(gets(nil)))"'
alias js='fixjsstyle *.js'
alias sim='killall -q mos_sim && echo Terminated || mos_sim; psg mos_sim'
develop >/dev/null
