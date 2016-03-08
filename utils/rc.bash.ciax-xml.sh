#!/bin/bash --rcfile
develop(){
    pushd "$HOME/ciax-xml/script"
    git branch |grep '* develop'
    popd
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
develop >/dev/null && export NOCACHE=1
