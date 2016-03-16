#!/bin/bash --rcfile
develop(){
    cd "$HOME/ciax-xml/script"
    git branch |grep '* develop' && export NOCACHE=1 || cd
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
develop >/dev/null
