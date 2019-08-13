#!/bin/bash --rcfile
develop(){
    cd "$HOME/ciax-xml" || return
    git pull --all
    case $(git branch |grep '*') in
        *develop)
            # export NOCACHE=1
            alias sybeta='git push;giu beta;gim develop;git push;giu develop'
            ;;
        *beta)
            alias sydev='git push;giu develop;gim beta;git push;giu beta'
            ;;
        *);;
    esac
    cd
}
init_proj(){
    case $HOSTNAME in
        ciax|cxws2)
            proj ciax
            ;;
        moircsobcp)
            proj moircs
            ;;
	hecmprssrv)
	    proj cmp
	    ;;
        *)
            proj dmcs
            ;;
    esac
}

proj(){
    if [ "$1" ] ; then
        export PROJ=$1
    else
        echo PROJ=$PROJ;
        for i in  $HOME/ciax-xml/mdb-*.xml; do
            j=${i##*-}
            echo -n "${j%.*} "
        done
        echo
    fi
}

gm(){
    grep -i $1 libmcr* libman* libseq* librec* libstep*
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
alias renb='rep -e=rb'
alias jj='ruby -r json -e "jj(JSON.parse(gets(nil)))"'
alias js='fixjsstyle *.js'
alias sim='killall -q mos_sim && echo Terminated || mos_sim; psg mos_sim'
alias ds='nc -u localhost 54321'
alias loge='tail -f ~/.var/log/error_mcrsv.out'
init_proj
develop >/dev/null

