#!/bin/bash --rcfile
develop(){
    cd "$HOME/ciax-xml/webapp"
    git pull --all
    case $(git branch |grep '*') in
        *develop)
            export PROJ=dummy
            export NOCACHE=1
            alias sybeta='git push;giu beta;gim develop;git push;giu develop'
            ;;
        *beta)
            alias sydev='git push;giu develop;gim beta;git push;giu beta'
            ;;
        *)
            cd;;
    esac
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
